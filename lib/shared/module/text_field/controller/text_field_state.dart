part of '../global_text_field.dart';

// Layout constants live in [TextFieldDefaults] — the single source for every
// hard-coded module value.

class _GlobalTextFormFieldState extends State<GlobalTextFormField>
    with TickerProviderStateMixin {
  // ─── Core state ──────────────────────────────────────────────
  late bool _obscureText;
  TextAlign _textAlign = TextAlign.start;
  TextDirection? _textDirection;
  FocusNode? _internalFocusNode;
  FocusNode? _focusListenerNode;

  // ─── Validation ──────────────────────────────────────────────
  late final FieldValidationController _validation;
  Timer? _onChangedTimer;

  // ─── Focus / identifier animation ────────────────────────────
  bool _isFocused = false;

  // ─── Suggestions overlay ─────────────────────────────────────
  bool _isInteractingWithOverlay = false;
  final LayerLink _suggestionsLayerLink = LayerLink();
  final GlobalKey _suggestionsAnchorKey = GlobalKey();
  final GlobalPopupController _anchoredOverlay = GlobalPopupController();
  List<String> _filteredSuggestions = [];

  /// Drives the overlay list's edge fade — the bottom fade signals "more
  /// rows below" when the content exceeds the popup's height cap.
  final ScrollController _suggestionsScroll = ScrollController();

  // ─── Inline completion ───────────────────────────────────────
  String _completionText = '';
  InlineGhostTextController? _ghostController;

  // ─── Instant obscure (screen-capture protection) ─────────────
  InstantObscureTextController? _instantObscureCtrl;

  // ─── Obscure reveal (timeout) / caps lock / strength ─────────
  Timer? _revealTimer;
  bool _capsLockOn = false;
  bool _capsHandlerAdded = false;
  double? _lastStrength;

  // ─── Undo/Redo ───────────────────────────────────────────────
  final UndoRedoStack _undoRedo = UndoRedoStack();
  bool _isUndoRedoAction = false;

  // ─── Async suggestions ───────────────────────────────────────
  bool _isLoadingSuggestions = false;
  Timer? _asyncSuggestionsTimer;
  int _asyncRequestId = 0;

  // ─── Chips ───────────────────────────────────────────────────
  List<String> _chips = [];

  /// Duplicate-add feedback: the existing chip a rejected value matched,
  /// plus a tick so repeat dups on the same chip replay the pulse.
  String? _dupPulseChip;
  int _dupPulseTick = 0;

  /// Keyboard-highlighted suggestion row (index into
  /// [_filteredSuggestions]); -1 = none. Arrow keys move it, Enter picks
  /// it, Escape closes the overlay. Reset on every text change.
  int _highlightedSuggestion = -1;

  // ─── Animations ──────────────────────────────────────────────
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _inputPulseController;

  // ─── Voice input ─────────────────────────────────────────────
  bool _isListening = false;

  // ─── Resolved style (materialized once per frame in build) ───
  late ResolvedTextFieldStyle _rs;

  // ─── Effective getters ───────────────────────────────────────

  BorderRadius get _effectiveBorderRadius => _rs.borderRadius;

  FocusNode? get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  /// Whether any border state uses a gradient — these are painted by us
  /// (not InputDecoration), so focus transitions need an explicit rebuild.
  bool get _hasGradientBorder {
    if (widget.style.border?.hasAnyGradient ?? false) return true;
    return GlobalTextFieldTheme.maybeOf(
          context,
        )?.style?.border?.hasAnyGradient ??
        false;
  }

  Color get _suffixIconColor => widget.behavior.enabled
      ? _rs.iconColor
      : Theme.of(context).colorScheme.outline;

  /// Resolved formatters — appends [MaskInputFormatter] if mask configured.
  List<TextInputFormatter>? get _effectiveFormatters {
    if (widget.behavior.inputMask == null) {
      return widget.behavior.inputFormatters;
    }
    final maskFormatter = MaskInputFormatter(widget.behavior.inputMask!);
    return [
      ...?widget.behavior.inputFormatters,
      maskFormatter,
    ];
  }

  // ─── Lifecycle ───────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // `obscureText` says the field IS a password field; `revealed`
    // says whether it is showing right now.
    _obscureText =
        widget.behavior.obscureText && !(widget.behavior.revealed ?? false);
    _validation = FieldValidationController(
      config: () => widget.validation,
      currentText: () => widget.controller.text,
      shakeEnabled: () => widget.features.animations.shakeOnError,
      isMounted: () => mounted,
      requestRebuild: () {
        if (mounted) setState(() {});
      },
      triggerShake: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _shakeController.forward(from: 0);
        });
      },
    );
    _ensureInternalFocusNode();
    _wireExternalChipKeys();
    _attachFocusListener();
    widget.controller.addListener(_updateTextDirection);
    _updateTextDirection();

    if (widget.features.enableUndoRedo) {
      _undoRedo.reset(widget.controller.text);
    }

    if (widget.features.suggestions?.showInlineCompletion ?? false) {
      _ghostController = InlineGhostTextController(source: widget.controller);
    }

    if (widget.behavior.instantObscure && widget.behavior.obscureText) {
      _instantObscureCtrl = InstantObscureTextController(
        source: widget.controller,
      );
    }

    _syncCapsLockHandler();

    final chipsCfg = widget.features.chips;
    if (chipsCfg != null && chipsCfg.initial != null) {
      _chips = List<String>.from(chipsCfg.initial!);
    }

    _shakeController = AnimationController(
      duration: AppDurations.deliberate,
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _inputPulseController = AnimationController(
      duration: AppDurations.fast,
      vsync: this,
    );

    // Standalone fields have no Form to auto-validate them, so honour
    // `showErrorImmediately` with an initial pass once the first frame is up.
    if (widget.validation.showErrorImmediately &&
        !widget.validation.deferToParentForm) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _validation.perform();
      });
    }
  }

  /// The locale the visible error was resolved in.
  ///
  /// A validator returns a resolved STRING, and the controller stores
  /// it. Nothing re-runs on a language change, so an error raised in
  /// English stayed in English while the form around it turned Arabic —
  /// the same freeze the onboarding copy had, one layer down.
  Locale? _errorLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.maybeLocaleOf(context);
    // Only when one is actually on screen. Re-running the validator on
    // an untouched field would raise an error nobody has earned yet.
    if (_errorLocale != null &&
        _errorLocale != locale &&
        _validation.effectiveError != null) {
      _validation.perform();
    }
    _errorLocale = locale;
  }

  @override
  void didUpdateWidget(covariant GlobalTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldInline =
        oldWidget.features.suggestions?.showInlineCompletion ?? false;
    final newInline =
        widget.features.suggestions?.showInlineCompletion ?? false;

    // Picker-mode flip (readOnly + onTap): the internal node is created with
    // `canRequestFocus: false` in picker mode — that can't be changed in
    // place, so recreate the node when the mode flips.
    final oldPicker =
        oldWidget.behavior.readOnly && oldWidget.callbacks.onTap != null;
    final wantsPicker =
        widget.behavior.readOnly && widget.callbacks.onTap != null;

    if (widget.focusNode == null &&
        (oldInline != newInline || oldPicker != wantsPicker)) {
      _detachFocusListener();
      _internalFocusNode?.dispose();
      _internalFocusNode = null;
    }

    _ensureInternalFocusNode();

    if (oldWidget.focusNode != widget.focusNode ||
        oldInline != newInline ||
        oldPicker != wantsPicker) {
      _detachFocusListener();
      _attachFocusListener();
    }

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_updateTextDirection);
      widget.controller.addListener(_updateTextDirection);
      // Rebind engines that captured the old controller. Disposing the ghost
      // here is safe: build (which swaps the field's controller) runs after
      // didUpdateWidget, and ChangeNotifier.removeListener tolerates disposed
      // instances.
      if (_ghostController != null) {
        _ghostController!.dispose();
        _ghostController = newInline
            ? InlineGhostTextController(source: widget.controller)
            : null;
      }
      if (_instantObscureCtrl != null) {
        _instantObscureCtrl!.dispose();
        _instantObscureCtrl = InstantObscureTextController(
          source: widget.controller,
        );
      }
      if (widget.features.enableUndoRedo) {
        _undoRedo.reset(widget.controller.text);
      }
    }

    // Inline-completion toggle: create/dispose the ghost controller to match.
    if (oldInline != newInline) {
      if (newInline) {
        _ghostController ??= InlineGhostTextController(
          source: widget.controller,
        );
      } else if (_ghostController != null) {
        _ghostController!.dispose();
        _ghostController = null;
      }
    }

    if (oldWidget.behavior.obscureText != widget.behavior.obscureText ||
        oldWidget.behavior.revealed != widget.behavior.revealed) {
      _obscureText =
          widget.behavior.obscureText && !(widget.behavior.revealed ?? false);
    }

    // Instant-obscure toggle (flips at runtime when screen capture starts).
    final wantsInstant =
        widget.behavior.instantObscure && widget.behavior.obscureText;
    if (wantsInstant && _instantObscureCtrl == null) {
      _instantObscureCtrl = InstantObscureTextController(
        source: widget.controller,
      );
    } else if (!wantsInstant && _instantObscureCtrl != null) {
      _instantObscureCtrl!.dispose();
      _instantObscureCtrl = null;
    }

    _syncCapsLockHandler();

    if (oldWidget.validation.validator != widget.validation.validator ||
        oldWidget.validation.mode != widget.validation.mode ||
        oldWidget.validation.asyncValidator !=
            widget.validation.asyncValidator ||
        oldWidget.validation.asyncDebounce != widget.validation.asyncDebounce) {
      _validation.cancelTimer();
    }

    // Rules changed (revalidateKey differs): a field the user already
    // touched — or one showing an error — re-checks NOW instead of waiting
    // for the next keystroke (e.g. a phone field's allowLandline or
    // country flips while an error row is visible).
    if (oldWidget.validation.revalidateKey != widget.validation.revalidateKey &&
        (_validation.hasInteracted || _validation.effectiveError != null)) {
      _validation.perform();
    }

    final oldChips = oldWidget.features.chips;
    final newChips = widget.features.chips;
    if (newChips != null && !listEquals(oldChips?.initial, newChips.initial)) {
      _chips = List<String>.from(newChips.initial ?? []);
    }
  }

  @override
  void dispose() {
    if (_externalKeyHandlerAttached) widget.focusNode?.onKeyEvent = null;
    widget.controller.removeListener(_updateTextDirection);
    _detachFocusListener();
    _validation.dispose();
    _onChangedTimer?.cancel();
    _asyncSuggestionsTimer?.cancel();
    if (_isListening) {
      widget.features.voice?.adapter.cancel();
    }
    _internalFocusNode?.dispose();
    _anchoredOverlay.dispose();
    _suggestionsScroll.dispose();
    _ghostController?.dispose();
    _instantObscureCtrl?.dispose();
    _revealTimer?.cancel();
    if (_capsHandlerAdded) {
      HardwareKeyboard.instance.removeHandler(_onHardwareKey);
    }
    _shakeController.dispose();
    _inputPulseController.dispose();
    super.dispose();
  }

  // ─── Focus ────────────────────────────────────────────────────

  void _attachFocusListener() {
    _focusListenerNode = _effectiveFocusNode;
    _focusListenerNode?.addListener(_onFocusChanged);
  }

  void _detachFocusListener() {
    _focusListenerNode?.removeListener(_onFocusChanged);
    _focusListenerNode = null;
  }

  void _onFocusChanged() {
    final node = _focusListenerNode;
    if (node == null || !mounted) return;

    // Gradient borders are painted by us, so repaint the active stroke when
    // focus flips (InputDecoration handles solid-border transitions itself).
    if (_hasGradientBorder) setState(() {});

    if (node.hasFocus) {
      // Do NOT clear the error on focus gain: with universal column errors
      // an auto-validating Form re-stores it immediately, so the row would
      // unmount + remount and replay its entrance animation on every
      // refocus. Typing already clears + revalidates.
      // `_isFocused` tracks unconditionally (one rebuild per focus flip) —
      // the identifier animation AND the centered-hint hide both read it.
      if (!_isFocused) {
        setState(() => _isFocused = true);
      }
      _updateSuggestions(widget.controller.text);
    } else {
      if (_isFocused) {
        setState(() => _isFocused = false);
      }

      // Stay-open mode: scroll-driven focus loss should NOT close the
      // overlay. The page can scroll while the user reads suggestions;
      // explicit tap-outside (via the overlay scrim) is what closes it.
      final stayOpen =
          widget.features.suggestions?.overlayOptions.closeOnScroll == false;

      // Defer overlay removal so taps/scrolls inside the overlay can land.
      Future.delayed(AppDurations.fast, () {
        if (!mounted) return;
        if (_effectiveFocusNode?.hasFocus == true) return;
        if (_isInteractingWithOverlay) {
          _effectiveFocusNode?.requestFocus();
          return;
        }
        if (!stayOpen) {
          _removeSuggestionsOverlay();
          if (_filteredSuggestions.isNotEmpty || _completionText.isNotEmpty) {
            setState(() {
              _filteredSuggestions = [];
              _completionText = '';
            });
          }
        }
      });

      _validation.handleTrigger(widget.controller.text, isOnFocusLoss: true);
    }
  }

  /// Backspace-pop needs a key handler on the ACTIVE node. The internal
  /// node gets it at construction; a caller-provided node gets it wired
  /// here (only when free — never clobbers a caller's own handler) and
  /// released in dispose.
  bool _externalKeyHandlerAttached = false;

  void _wireExternalChipKeys() {
    final ext = widget.focusNode;
    final wantsKeys =
        widget.features.chips?.removeLastOnBackspace == true ||
        widget.features.suggestions != null;
    if (ext == null || !wantsKeys) return;
    if (ext.onKeyEvent == null) {
      ext.onKeyEvent = _onKeyEventForCompletion;
      _externalKeyHandlerAttached = true;
    }
  }

  void _ensureInternalFocusNode() {
    if (widget.focusNode != null) return;

    final inline = widget.features.suggestions?.showInlineCompletion ?? false;
    final chipKeys = widget.features.chips?.removeLastOnBackspace ?? false;
    // Overlay keyboard nav (↑/↓/Enter/Esc) wants the handler whenever a
    // suggestions overlay can appear.
    final overlayNav = widget.features.suggestions != null;
    if (widget.behavior.readOnly && widget.callbacks.onTap != null) {
      _internalFocusNode ??= FocusNode(
        canRequestFocus: false,
        skipTraversal: true,
      );
    } else {
      _internalFocusNode ??= FocusNode(
        onKeyEvent: (inline || chipKeys || overlayNav)
            ? _onKeyEventForCompletion
            : null,
      );
    }
  }

  KeyEventResult _onKeyEventForCompletion(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    // Chips: backspace in an EMPTY editor pops the last chip.
    if (widget.features.chips?.removeLastOnBackspace == true &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        widget.controller.text.isEmpty &&
        _chips.isNotEmpty) {
      _removeLastChip();
      return KeyEventResult.handled;
    }
    // Overlay keyboard nav: ↑/↓ move the highlight, Enter picks it,
    // Escape closes. Only while the overlay is actually showing rows —
    // otherwise arrows/enter keep their editor meaning.
    if (_anchoredOverlay.isOpen && _filteredSuggestions.isNotEmpty) {
      final count = _filteredSuggestions.length;
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(
          () => _highlightedSuggestion = (_highlightedSuggestion + 1) % count,
        );
        _anchoredOverlay.markNeedsLayout();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(
          () => _highlightedSuggestion = _highlightedSuggestion <= 0
              ? count - 1
              : _highlightedSuggestion - 1,
        );
        _anchoredOverlay.markNeedsLayout();
        return KeyEventResult.handled;
      }
      if ((event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter) &&
          _highlightedSuggestion >= 0 &&
          _highlightedSuggestion < count) {
        _selectSuggestion(_filteredSuggestions[_highlightedSuggestion]);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _removeSuggestionsOverlay();
        return KeyEventResult.handled;
      }
    }
    if (_completionText.isEmpty) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.tab ||
        event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _acceptInlineCompletion();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ─── Text direction ──────────────────────────────────────────

  void _updateTextDirection() {
    if (!mounted || !widget.behavior.autoDetectDirection) return;

    final text = widget.controller.text;
    // Empty → `start` so the hint follows the ambient Directionality
    // (right in an RTL app, left in LTR). Only a non-empty value pins an
    // explicit side based on detected content direction.
    var newAlign = TextAlign.start;
    TextDirection? newDirection;

    if (text.isNotEmpty) {
      newDirection = AppBidi.detect(text);
      newAlign = newDirection == TextDirection.rtl
          ? TextAlign.right
          : TextAlign.left;
    }

    if (_textAlign != newAlign || _textDirection != newDirection) {
      setState(() {
        _textAlign = newAlign;
        _textDirection = newDirection;
      });
    }
  }

  Future<void> _toggleObscureText() async {
    // Revealing while the screen is captured (instantObscure is the capture
    // signal) — confirm first: anyone watching the share/recording would see
    // the password.
    if (_obscureText && widget.behavior.instantObscure) {
      final ok = await GlobalDialog.confirm(
        context: context,
        type: DialogType.warning,
        isDestructive: true,
        title: TextFieldStrings.revealPasswordTitle,
        message: TextFieldStrings.revealPasswordMessage,
        confirmText: TextFieldStrings.reveal,
        cancelText: TextFieldStrings.cancel,
      );
      if (!ok || !mounted) return;
    }
    _setObscured(!_obscureText);
  }

  /// Single write-path for the obscure state — owns the
  /// [TextFieldBehavior.revealTimeout] timer (a toggle-mode reveal auto
  /// re-obscures after the timeout; generate-reveals ride the same path).
  void _setObscured(bool obscured) {
    _revealTimer?.cancel();
    setState(() => _obscureText = obscured);
    widget.callbacks.onObscureToggled?.call(obscured);
    final timeout = widget.behavior.revealTimeout;
    if (!obscured &&
        timeout != null &&
        widget.behavior.revealMode == TextFieldRevealMode.toggle) {
      _revealTimer = Timer(timeout, () {
        if (mounted && !_obscureText) {
          setState(() => _obscureText = true);
          widget.callbacks.onObscureToggled?.call(true);
        }
      });
    }
  }

  // ─── Caps lock (hardware keyboards) ──────────────────────────

  /// Register/unregister the [HardwareKeyboard] handler to match
  /// `features.warnCapsLock` (called from initState + didUpdateWidget).
  void _syncCapsLockHandler() {
    final wants = widget.features.warnCapsLock;
    if (wants && !_capsHandlerAdded) {
      HardwareKeyboard.instance.addHandler(_onHardwareKey);
      _capsHandlerAdded = true;
      _capsLockOn = HardwareKeyboard.instance.lockModesEnabled.contains(
        KeyboardLockMode.capsLock,
      );
    } else if (!wants && _capsHandlerAdded) {
      HardwareKeyboard.instance.removeHandler(_onHardwareKey);
      _capsHandlerAdded = false;
    }
  }

  bool _onHardwareKey(KeyEvent event) {
    final caps = HardwareKeyboard.instance.lockModesEnabled.contains(
      KeyboardLockMode.capsLock,
    );
    if (caps != _capsLockOn && mounted) {
      setState(() => _capsLockOn = caps);
    }
    return false; // observe only — never consume the event
  }

  // ─── Strength notification ───────────────────────────────────

  /// Fire `validation.onStrengthChanged` when the computed strength moves.
  void _notifyStrength(String value) {
    final cb = widget.validation.onStrengthChanged;
    if (cb == null) return;
    final strength = widget.validation.strengthOf(value);
    if (strength == null || strength == _lastStrength) return;
    _lastStrength = strength;
    cb(strength);
  }

  // ─── Validation ──────────────────────────────────────────────

  // Validation logic lives in [_validation] (FieldValidationController) —
  // perform / schedule / handleTrigger / formValidator / autovalidateMode.

  // ─── Input callbacks ─────────────────────────────────────────

  /// Identifies the raw editor so the caret can be inspected after a
  /// keystroke — see [_healCaretIfStuck].
  final GlobalKey _rawFieldKey = GlobalKey();

  /// Tries at healing a stuck caret in the current focus session.
  ///
  /// Capped: only ONE cause (a stranded floating cursor) is repairable
  /// from outside, and retrying the others every keystroke would just
  /// log forever.
  int _caretHealAttempts = 0;

  /// Restores a caret that has stopped painting while the field is still
  /// taking input — a field that accepts text with no visible caret
  /// reads as broken even though nothing is.
  ///
  /// Runs after a keystroke on purpose: `EditableText` relights the
  /// caret on every value change, so a caret that is still dark one
  /// frame later is genuinely stuck rather than mid-blink. That makes
  /// the check exact without polling and guessing the blink phase.
  void _healCaretIfStuck() {
    if (!kDebugMode) return;
    if (_caretHealAttempts >= 3) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (CaretWatchdog.inspect(_rawFieldKey)) {
        case CaretStatus.ok:
        case CaretStatus.unknown:
          return;
        case CaretStatus.floatingCursorStuck:
          _caretHealAttempts++;
          if (CaretWatchdog.endStuckFloatingCursor(_rawFieldKey)) {
            Logger.m.w(
              '[TextField] caret was hidden by a floating cursor that was '
              'started and never ended — sent the missing End',
            );
          }
        case CaretStatus.transparent:
          _caretHealAttempts++;
          // Should be unreachable: `cursorErrorColor` is set explicitly
          // below precisely so the collapsed errorStyle cannot bleed
          // into the caret. If it fires, something upstream reintroduced
          // a transparent caret colour.
          Logger.m.w(
            '[TextField] caret is blinking but painted transparent — check '
            'cursorErrorColor / errorStyle.color',
          );
        case CaretStatus.dark:
          _caretHealAttempts++;
          // Nothing to send: the remaining causes (blink timer stopped,
          // TickerMode disabled for this subtree, selection not
          // collapsed) all live in private EditableText state. Say so,
          // rather than looking like the field is at fault.
          Logger.m.w(
            '[TextField] caret is not painting though the field has focus. '
            'Not a floating cursor — check for a TickerMode(enabled: false) '
            'ancestor or a non-collapsed selection.',
          );
      }
    });
  }

  void _handleOnChanged(String value) {
    _healCaretIfStuck();
    // Chips separators: a typed/pasted separator commits everything
    // before it as chips; the editor keeps only the remainder.
    final remainder = _consumeSeparators(value);
    if (remainder != value) {
      widget.controller.value = TextEditingValue(
        text: remainder,
        selection: TextSelection.collapsed(offset: remainder.length),
      );
      value = remainder;
    }

    if (widget.features.enableUndoRedo && !_isUndoRedoAction) {
      _undoRedo.record(value);
    }

    setState(() {
      _validation.markInteracted();
      _validation.clearError();
    });

    final delay = widget.behavior.onChangedDelay;
    if (delay > Duration.zero) {
      _onChangedTimer?.cancel();
      _onChangedTimer = Timer(
        delay,
        () => widget.callbacks.onChanged?.call(value),
      );
    } else {
      widget.callbacks.onChanged?.call(value);
    }

    _validation.handleTrigger(value);
    _notifyStrength(value);

    if (widget.features.animations.pulseOnInput &&
        !_inputPulseController.isAnimating) {
      _inputPulseController.forward(from: 0).then((_) {
        if (mounted) _inputPulseController.reverse();
      });
    }

    _updateSuggestions(value);
  }

  void _handleFieldSubmitted(String value) {
    final out = widget.behavior.trimOnSubmit ? value.trim() : value;
    if (widget.behavior.trimOnSubmit && out != value) {
      widget.controller.text = out;
    }
    // Chips add-on-submit: non-empty text becomes a chip instead of a
    // form submit. On success the editor clears and keeps focus for the
    // next tag; a rejected add (veto / duplicate / max) keeps the text
    // visible. Either way the submit is swallowed.
    if (widget.features.chips?.addOnSubmit == true && out.isNotEmpty) {
      if (_tryAddChip(out)) {
        widget.controller.clear();
        _validation.handleTrigger('');
      }
      _effectiveFocusNode?.requestFocus();
      return;
    }
    // Keyboard submit is the trigger for `ValidationMode.onSubmit` — runs the
    // sync validator and, when it passes, the async one.
    _validation.handleTrigger(out, isOnSubmit: true);
    widget.callbacks.onSubmitted?.call(out);
  }

  void _handleTapOutside(PointerDownEvent event) {
    widget.callbacks.onTapOutside?.call(event);
    // Pointer went down INSIDE the suggestions overlay — its Listener
    // (in the hit-test path) flags this before TapRegion's global route
    // fires. A row tap is not an "outside" tap: scheduling the unfocus
    // watcher here would blur the field on pointer-up and close the
    // overlay mid-pick (chips multi-add keeps it open).
    if (_isInteractingWithOverlay) return;
    // Stay-open mode: a scroll-start fires PointerDownEvent outside the
    // field. We don't want that to unfocus or trigger focus-loss
    // validation — the user is reading suggestions while scrolling. The
    // overlay scrim still handles actual taps outside (it calls
    // unfocus + hide explicitly).
    final stayOpen =
        _anchoredOverlay.isOpen &&
        widget.features.suggestions?.overlayOptions.closeOnScroll == false;
    if (stayOpen) return;

    if (widget.behavior.unfocusOnScroll) {
      // Legacy: any pointer-down outside dismisses focus immediately.
      _unfocusFromTapOutside();
      return;
    }

    // Default: only a genuine tap dismisses focus. Watch this pointer until
    // it lifts — a scroll drags past kTouchSlop and is ignored, so the
    // field keeps focus while the page scrolls.
    _watchTapForUnfocus(event);
  }

  void _unfocusFromTapOutside() {
    FocusManager.instance.primaryFocus?.unfocus();
    _validation.handleTrigger(widget.controller.text, isOnFocusLoss: true);
  }

  void _watchTapForUnfocus(PointerDownEvent down) {
    final pointer = down.pointer;
    final start = down.position;
    var moved = false;
    void route(PointerEvent e) {
      if (e.pointer != pointer) return;
      if (e is PointerMoveEvent && (e.position - start).distance > kTouchSlop) {
        moved = true;
      } else if (e is PointerUpEvent || e is PointerCancelEvent) {
        GestureBinding.instance.pointerRouter.removeGlobalRoute(route);
        if (!moved && e is PointerUpEvent && mounted) {
          _unfocusFromTapOutside();
        }
      }
    }

    GestureBinding.instance.pointerRouter.addGlobalRoute(route);
  }

  // ─── Suggestions filter / overlay ─────────────────────────────

  List<String> _filterRecentSearches(String lowerQuery) =>
      SuggestionFilter.recents(
        widget.features.suggestions?.recent ?? const [],
        lowerQuery,
      );

  void _fetchAsyncSuggestions(String query) {
    final cfg = widget.features.suggestions;
    if (cfg?.async == null) return;

    _asyncSuggestionsTimer?.cancel();
    final trimmed = query.trim();
    _asyncRequestId++;
    final requestId = _asyncRequestId;

    if (trimmed.isEmpty) {
      if (_isLoadingSuggestions && mounted) {
        setState(() => _isLoadingSuggestions = false);
      }
      return;
    }

    if (!mounted) return;

    _asyncSuggestionsTimer = Timer(cfg!.asyncDebounce, () async {
      if (!mounted || requestId != _asyncRequestId) return;
      // Loading flips ON only when the debounce settles and the fetch really
      // fires — flipping it per keystroke made the row flicker while typing.
      setState(() => _isLoadingSuggestions = true);
      if (_anchoredOverlay.isOpen) {
        _anchoredOverlay.markNeedsLayout();
      } else if (_effectiveFocusNode?.hasFocus ?? false) {
        _showSuggestionsOverlay();
      }
      try {
        final results = await cfg.async!(trimmed);
        if (!mounted || requestId != _asyncRequestId) return;

        final lowerQuery = trimmed.toLowerCase();
        final staticFiltered = SuggestionFilter.byQuery(
          cfg.items ?? const [],
          lowerQuery,
          cfg.maxItems,
        );
        final merged = SuggestionFilter.mergeAsync(
          staticFiltered,
          results,
          cfg.maxItems,
        );

        setState(() {
          _filteredSuggestions = merged;
          _highlightedSuggestion = -1;
          _isLoadingSuggestions = false;
          // Async results join the ghost-completion candidates — without
          // this, async-only fields (search) never ghost.
          if (cfg.showInlineCompletion && cfg.completion == null) {
            _completionText = SuggestionFilter.completion(
              merged,
              trimmed,
              lowerQuery,
            );
            _ghostController?.ghost = _completionText;
          }
        });
        if (_anchoredOverlay.isOpen) {
          _anchoredOverlay.markNeedsLayout();
        } else if (_filteredSuggestions.isNotEmpty) {
          _showSuggestionsOverlay();
        }
      } catch (e) {
        // Same staleness guard as the success path: a failure from a
        // superseded request must not clear the newer request's spinner.
        if (!mounted || requestId != _asyncRequestId) return;
        setState(() => _isLoadingSuggestions = false);
        cfg.onAsyncError?.call(e.toString());
      }
    });
  }

  void _updateSuggestions(String query) {
    final cfg = widget.features.suggestions;
    if (cfg == null) return;

    final hasItems = cfg.items != null && cfg.items!.isNotEmpty;
    final hasAsync = cfg.async != null;
    final hasRecent = cfg.recent != null && cfg.recent!.isNotEmpty;
    final hasCompletion = cfg.completion != null;

    if (!hasItems && !hasAsync && !hasRecent && !hasCompletion) return;

    if (hasAsync) _fetchAsyncSuggestions(query);

    final lowerQuery = query.toLowerCase().trim();
    final filtered = SuggestionFilter.byQuery(
      cfg.items ?? const [],
      lowerQuery,
      cfg.maxItems,
    );

    _filteredSuggestions = filtered;
    // Text changed under the highlight — old index points at stale rows.
    _highlightedSuggestion = -1;

    if (cfg.showInlineCompletion && lowerQuery.isNotEmpty) {
      // A completion callback (dynamic, derived from the live text — e.g.
      // email-domain ghosting) overrides the list-based candidate match.
      if (hasCompletion) {
        _completionText = cfg.completion!(query) ?? '';
      } else {
        final allCandidates = <String>[
          ...filtered,
          if (hasRecent)
            ...cfg.recent!.where((s) => s.toLowerCase().startsWith(lowerQuery)),
        ];
        _completionText = SuggestionFilter.completion(
          allCandidates,
          query,
          lowerQuery,
        );
      }
    } else {
      _completionText = '';
    }

    _ghostController?.ghost = _completionText;
    if (cfg.inline) return;

    final focusNode = _effectiveFocusNode;
    if (focusNode == null || !focusNode.hasFocus) {
      _removeSuggestionsOverlay();
      return;
    }

    // A configured async source with a non-empty query counts as content:
    // a fetch is (about to be) in flight, so keep the overlay open — the
    // stale rows / shimmer swap in place. Closing here and reopening from
    // the debounce timer tore the row InkWells down every keystroke
    // ("Looking up a deactivated widget's ancestor" storms).
    final hasContent =
        filtered.isNotEmpty ||
        (hasRecent && cfg.recent!.isNotEmpty) ||
        _isLoadingSuggestions ||
        (hasAsync && lowerQuery.isNotEmpty);
    if (!hasContent) {
      _removeSuggestionsOverlay();
      return;
    }

    if (_anchoredOverlay.isOpen) {
      _anchoredOverlay.markNeedsLayout();
    } else {
      _showSuggestionsOverlay();
    }
  }

  void _showSuggestionsOverlay() {
    final cfg = widget.features.suggestions;
    if (cfg == null) return;
    final anchorContext = _suggestionsAnchorKey.currentContext;
    if (anchorContext == null) return;

    _anchoredOverlay.show(
      context: context,
      anchorContext: anchorContext,
      link: _suggestionsLayerLink,
      vsync: this,
      // Suggestion content swaps constantly (recents → shimmer → results) —
      // animate the surface height between states by default. Caller
      // overlayOptions still win.
      options: cfg.overlayOptions.animateContentSize == null
          ? cfg.overlayOptions.copyWith(animateContentSize: true)
          : cfg.overlayOptions,
      builder: (ctx, layout) => _buildSuggestionsOverlayContent(layout),
    );
  }

  void _removeSuggestionsOverlay({bool immediate = false}) {
    _isInteractingWithOverlay = false;
    _anchoredOverlay.hide(immediate: immediate);
  }

  /// The chip an overlay row corresponds to, when already added.
  /// Case-insensitive — `beforeAdd` normalization (lowercase) may have
  /// reshaped the stored casing.
  String? _chipForSuggestion(String suggestion) {
    final lower = suggestion.toLowerCase();
    for (final c in _chips) {
      if (c.toLowerCase() == lower) return c;
    }
    return null;
  }

  void _selectSuggestion(String suggestion) {
    final cfg = widget.features.suggestions;
    final chipsCfg = widget.features.chips;
    if (chipsCfg != null) {
      // Toggle: a row that's already a chip removes it; otherwise the
      // pick adds through the central path (beforeAdd + dup/max checks).
      final existing = _chipForSuggestion(suggestion);
      if (existing != null) {
        _removeChip(existing);
      } else if (_tryAddChip(suggestion)) {
        widget.controller.clear();
        cfg?.onSelected?.call(suggestion);
      }
      // Multi-add UX: the overlay STAYS OPEN — rows re-render with the
      // fresh selected state, the list resets to the now-empty query.
      _updateSuggestions(widget.controller.text);
      if (_anchoredOverlay.isOpen) _anchoredOverlay.markNeedsLayout();
      setState(() {});
      return;
    }
    widget.controller.text = suggestion;
    widget.controller.selection = TextSelection.collapsed(
      offset: suggestion.length,
    );
    cfg?.onSelected?.call(suggestion);
    _removeSuggestionsOverlay();
    _filteredSuggestions = [];
    // Programmatic write skips _handleOnChanged — clear the ghost remainder
    // explicitly or it lingers until the next keystroke.
    _completionText = '';
    _ghostController?.ghost = '';
    setState(() {});
  }

  // ─── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _rs = widget.style.resolve(context);
    Widget fieldArea = KeyedSubtree(
      key: _suggestionsAnchorKey,
      child: CompositedTransformTarget(
        link: _suggestionsLayerLink,
        child: _buildTextField(context),
      ),
    );

    if (widget.features.animations.shakeOnError) {
      fieldArea = AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          final dx =
              _shakeAnimation.value *
              10 *
              sin(_shakeController.value * 3 * 3.14159);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: fieldArea,
      );
    }

    if (widget.features.animations.pulseOnInput) {
      fieldArea = AnimatedBuilder(
        animation: _inputPulseController,
        builder: (context, child) {
          final scale = 1.0 + _inputPulseController.value * 0.008;
          return Transform.scale(scale: scale, child: child);
        },
        child: fieldArea,
      );
    }

    // Read-only chips field = a display surface: chips render (delete /
    // edit affordances already dropped), the dead editor box hides.
    final chipsDisplayOnly =
        widget.behavior.readOnly && widget.features.chips != null;

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(context),
        _buildChips(context),
        if (!chipsDisplayOnly) fieldArea,
        // Messages + counter share one horizontal band: message rows
        // (error / info / …) at the start, the char/word/tag counter
        // top-aligned at the end — not stacked on its own line.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildFieldMessages(context)),
            _buildCountRow(context),
          ],
        ),
        _buildStrengthBar(context),
        _buildRequirements(context),
        _buildInlineSuggestions(context),
      ],
    );

    // Fit-width only self-sizes the INPUT (an inner IntrinsicWidth in
    // `_buildTextField`); the header / messages / counter rows around it stay
    // width-driven by the parent. Dropped into a Row as a non-flex child, that
    // parent hands them UNBOUNDED width — and the header's `Row(spaceBetween)`
    // + `Expanded` (or any max-size row) then fails `hasSize`, aborting layout
    // mid-frame and cascading into a per-frame `!semantics.parentDataDirty`
    // storm. Bounding the whole column to its intrinsic width fixes the crash
    // and makes the header/messages hug the field consistently.
    if (widget.sizing.fitWidthToContent && widget.sizing.width == null) {
      return IntrinsicWidth(child: column);
    }
    return column;
  }

  // ─── Text field core build ────────────────────────────────────

  Widget _buildTextField(BuildContext context) {
    final theme = Theme.of(context);
    final rs = _rs;
    final borderRadius = rs.borderRadius;
    final behavior = widget.behavior;
    final validation = widget.validation;

    final fillColor = rs.fillColor;
    final gradientBorder = rs.hasGradientBorder;

    // ── Sizing ───────────────────────────────────────────────────
    // `boxHeight` bridges the legacy `style.height` into the sizing path.
    // A height constraint (or explicit dense flag) flips `isDense` on via
    // `TextFieldSizing.resolvedIsDense` so the `InputDecorator` stops
    // enforcing its baked-in minimum and the height actually takes effect;
    // `isCollapsed` supersedes it for tight boxes. The trailing `rs.height`
    // bridge covers the legacy `style.height` the model can't see.
    final sizing = widget.sizing;
    final boxHeight = sizing.height ?? rs.height;
    final isCollapsed = sizing.isCollapsed ?? false;
    final isDense = isCollapsed
        ? null
        : (sizing.resolvedIsDense ?? (rs.height != null ? true : null));

    // In gradient mode the InputDecoration borders are transparent and the
    // active stroke is painted by [_TextFieldBorderPainter]; otherwise each
    // state maps to a solid OutlineInputBorder. `resting: true` keeps the
    // enabled border invisible unless a color/gradient/width was supplied.
    OutlineInputBorder ob(ResolvedBorderSide side) {
      // `BorderSide.none`, NOT a width of zero. A zero-width
      // `BorderSide` is a HAIRLINE in Flutter — "as thin as the device
      // can draw", which is one physical pixel, not nothing. That is
      // the one-pixel border that would not go away however the style
      // asked for no border.
      //
      // And `paints` is honoured for EVERY state, not just the resting
      // one: `focused: TextFieldBorderSide(width: 0)` is the only way
      // to ask for a field with no focus ring, and it was ignored.
      final invisible = gradientBorder || !side.paints;
      return OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: invisible
            ? BorderSide.none
            : BorderSide(width: side.width, color: side.color),
      );
    }

    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      color: behavior.enabled
          ? rs.textColor ?? theme.textTheme.bodyMedium?.color
          : theme.colorScheme.outline,
    );

    final hintStyle =
        rs.hintStyle ??
        theme.textTheme.bodyMedium?.copyWith(
          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
        );

    final subduedTextStyle = TextStyle(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
    );

    final hideError =
        validation.requirements != null &&
        validation.requirements!.isNotEmpty &&
        validation.hideErrorWhenRequirements;

    // EVERY validator error renders in the message column (the "error" message
    // state: icon + status color) — consistent with success / warning / info.
    // Form fields stay integrated: the Form validator remains wired (validity,
    // error border, semantics) and stores its result for the column, while
    // Material's duplicate string is visually collapsed via `errorStyle`.
    // `_buildFieldMessages` re-derives the column error from the same inputs.

    // Internal error to surface — the combined sync-or-async result
    // (`formValidator` stores Form-driven sync results too). External
    // `errorText` wins.
    final internalError = _validation.effectiveError;
    final displayedError = hideError
        ? null
        : (validation.errorText ?? internalError);

    // Force the error border only for a standalone column error — a deferring
    // field keeps Material's automatic error state via its `validator` — or
    // when a caller passed an error-type message.
    final callerHasError = widget.messages.any(
      (m) => m.type == FieldMessageType.error,
    );
    final forceErr =
        (!validation.deferToParentForm && displayedError != null) ||
        callerHasError;

    final resolvedContentPadding = _resolveContentPadding(textStyle);

    // A CENTERED hint sits exactly under the caret while the empty field is
    // focused — the caret slices through the glyph (worst on short hints:
    // OTP cells, quantity '0'). Hide the hint for a focused+empty centered
    // field; it returns on blur, and typing hides it anyway.
    final effectiveAlign =
        behavior.textAlign ??
        (behavior.autoDetectDirection ? _textAlign : TextAlign.start);
    final hideCenteredHint =
        _isFocused &&
        effectiveAlign == TextAlign.center &&
        widget.controller.text.isEmpty;

    final decoration = InputDecoration(
      labelText: widget.features.animations.floatingLabel
          ? (widget.label ?? widget.identifier)
          : widget.label,
      floatingLabelBehavior: widget.features.animations.floatingLabel
          ? FloatingLabelBehavior.auto
          : FloatingLabelBehavior.never,
      // Required + no header identifier → the `*` rides on the hint
      // inside the field (the header star has no home).
      hintText: hideCenteredHint
          ? null
          : (widget.required &&
                    widget.identifier == null &&
                    widget.hint.isNotEmpty
                ? '${widget.hint} *'
                : widget.hint),
      hintStyle: hintStyle,
      // null → hint follows ambient Directionality (correct for an empty
      // field). An EXPLICIT behavior.textDirection pins the hint with the
      // editor — textAlign start/end resolve per-direction, so a hint on
      // a different direction would land on the opposite edge. A detected
      // content direction also pins it.
      hintTextDirection:
          behavior.textDirection ??
          (behavior.autoDetectDirection ? _textDirection : null),
      // ALL validator errors render in the message column (icon + color) —
      // never as a visible Material string. Form fields still inject
      // field.errorText for validity, hidden by the collapsed errorStyle.
      errorText: null,
      counterText: behavior.showCounter ? null : '',
      // InputDecorator re-themes affix icons by VISUAL DENSITY (compact —
      // any height-pinned field: joined pickers, dropdown triggers —
      // shrinks them to 18). Pin the ambient icon size so a form mixes
      // dense and standard fields with IDENTICAL icons; explicit
      // per-icon sizes still win.
      prefixIcon: widget.slots.prefixIcon == null
          ? null
          : IconTheme.merge(
              data: IconThemeData(size: IconTheme.of(context).size ?? 24),
              child: widget.slots.prefixIcon!,
            ),
      // Default to size-to-content (drop Material's 48×48 min) so a small
      // leading/trailing widget isn't inflated + centered in a big box.
      // Callers can pass an explicit min for a fixed tap target.
      prefixIconConstraints:
          widget.slots.prefixIconConstraints ??
          TextFieldDefaults.tightSlotConstraints,
      suffixIconConstraints:
          widget.slots.suffixIconConstraints ??
          TextFieldDefaults.tightSlotConstraints,
      suffixIcon: switch (_buildSuffixIcon()) {
        null => null,
        final s => IconTheme.merge(
          data: IconThemeData(size: IconTheme.of(context).size ?? 24),
          child: s,
        ),
      },
      prefix: widget.slots.prefixText != null
          ? Text(widget.slots.prefixText!, style: subduedTextStyle)
          : null,
      suffix: widget.slots.suffixText != null
          ? Text(widget.slots.suffixText!, style: subduedTextStyle)
          : null,
      // The column owns error text, so Material's string stays invisible
      // WITHOUT nulling the Form validator: a collapsed errorStyle preserves
      // `Form.validate()` correctness plus Material's automatic error border
      // + semantics while hiding the duplicate text.
      errorStyle: const TextStyle(
        fontSize: 0.01,
        height: 0.01,
        color: Colors.transparent,
      ),
      // `forceErr` paints the error border for a column/caller error that
      // Material's own error state won't cover (its errorText is null here).
      focusedBorder: ob(forceErr ? rs.focusedErrorBorder : rs.focusedBorder),
      enabledBorder: ob(forceErr ? rs.errorBorder : rs.enabledBorder),
      disabledBorder: ob(rs.disabledBorder),
      errorBorder: ob(rs.errorBorder),
      focusedErrorBorder: ob(rs.focusedErrorBorder),
      border: ob(forceErr ? rs.errorBorder : rs.enabledBorder),
      filled: true,
      fillColor: fillColor,
      isDense: isDense,
      isCollapsed: isCollapsed,
      contentPadding: resolvedContentPadding,
    );

    EditableTextContextMenuBuilder? contextMenuBuilder;
    if (!behavior.enablePaste || !behavior.enableCopy) {
      contextMenuBuilder = (ctx, editableTextState) {
        final items = editableTextState.contextMenuButtonItems.where((item) {
          if (!behavior.enablePaste &&
              item.type == ContextMenuButtonType.paste) {
            return false;
          }
          if (!behavior.enableCopy &&
              (item.type == ContextMenuButtonType.copy ||
                  item.type == ContextMenuButtonType.cut)) {
            return false;
          }
          return true;
        }).toList();
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: editableTextState.contextMenuAnchors,
          buttonItems: items,
        );
      };
    }

    // Ghost text color picked from theme so it lives well in dark/light.
    _ghostController?.setGhostColor(
      theme.colorScheme.onSurface.withValues(alpha: 0.35),
    );

    // Instant obscure: while the field is obscured AND instantObscure is on,
    // WE render the bullets (every char, no last-char peek) via the wrapper
    // controller — Flutter's own obscureText must then be OFF (it would
    // double-obscure), with autocorrect/suggestions forced off since the
    // platform no longer sees a secure field. The eye toggle still reveals
    // plain text (_obscureText false → normal path).
    final useInstantObscure =
        behavior.instantObscure && _obscureText && _instantObscureCtrl != null;

    final rawField = TextFormField(
      key: _rawFieldKey,
      autofocus: behavior.autofocus,
      // Read-only fields never show a caret, but RenderEditable still
      // reserves cursorWidth + gap after the text — visible slack on
      // fit-width triggers (dropdowns). Zero it.
      cursorWidth: behavior.readOnly ? 0 : 2.0,
      // MUST be explicit. In an error state Material derives the caret
      // colour from `errorStyle.color`, and this module deliberately
      // collapses that style to transparent so its own message column
      // owns the error text. The caret inherited the transparency and
      // vanished the moment a field went invalid — the field still took
      // input, so it read as broken. `cursorErrorColor` outranks
      // `errorStyle.color`, so setting it restores a visible caret
      // without un-collapsing Material's duplicate string.
      cursorErrorColor: context.statusColors.error,
      focusNode: _effectiveFocusNode,
      controller: useInstantObscure
          ? _instantObscureCtrl!
          : (_ghostController ?? widget.controller),
      enabled: behavior.enabled,
      obscureText: useInstantObscure ? false : _obscureText,
      autocorrect: !useInstantObscure,
      enableSuggestions: !useInstantObscure,
      maxLength: behavior.maxLength,
      maxLines: behavior.maxLines,
      minLines: behavior.minLines,
      keyboardType: behavior.keyboardType,
      style: textStyle,
      textAlignVertical: TextAlignVertical.center,
      readOnly: behavior.readOnly,
      textInputAction: behavior.textInputAction,
      autofillHints: behavior.autofillHints,
      textCapitalization: behavior.textCapitalization,
      inputFormatters: _effectiveFormatters,
      textAlign:
          behavior.textAlign ??
          (behavior.autoDetectDirection ? _textAlign : TextAlign.start),
      // Explicit pin wins; else the detected direction; else ambient.
      textDirection:
          behavior.textDirection ??
          (behavior.autoDetectDirection ? _textDirection : null),
      decoration: decoration,
      onChanged: _handleOnChanged,
      onTap: widget.callbacks.onTap,
      onTapOutside: _handleTapOutside,
      onFieldSubmitted: _handleFieldSubmitted,
      // Every deferring field keeps its Form validator — rich fields too:
      // the collapsed errorStyle hides Material's string while the message
      // column renders the rich error, so `Form.validate()` stays correct.
      validator: validation.deferToParentForm
          ? (value) => _validation.formValidator(
              value,
              // A Form with AutovalidateMode.disabled (Flutter's
              // default) can only reach this validator through an
              // explicit Form.validate() — the pre-interaction gate
              // must not swallow that, or an untouched required field
              // passes while empty.
              parentAutoValidates:
                  Form.maybeOf(context)?.widget.autovalidateMode !=
                  AutovalidateMode.disabled,
            )
          : null,
      autovalidateMode: _validation.autovalidateMode(),
      contextMenuBuilder:
          contextMenuBuilder ??
          (BuildContext ctx, EditableTextState state) =>
              AdaptiveTextSelectionToolbar.editableText(
                editableTextState: state,
              ),
    );

    Widget field = rawField;

    // Gradient (and, in gradient mode, all) strokes are painted by us since
    // OutlineInputBorder only accepts a solid color. Pick the active state's
    // side and overlay a stroke painter; focus changes trigger a rebuild via
    // _onFocusChanged when _hasGradientBorder.
    if (gradientBorder) {
      final hasError = forceErr || displayedError != null;
      final focused = _effectiveFocusNode?.hasFocus ?? false;
      final active = !behavior.enabled
          ? rs.disabledBorder
          : (hasError && focused)
          ? rs.focusedErrorBorder
          : hasError
          ? rs.errorBorder
          : focused
          ? rs.focusedBorder
          : rs.enabledBorder;
      field = Stack(
        children: [
          field,
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _TextFieldBorderPainter(
                  side: active,
                  radius: borderRadius,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // ── Blur background ──────────────────────────────────────────
    // The Stack sizes to the field; Positioned.fill keeps the frosted layer
    // matching the real field bounds (multiline, dense, any height) instead
    // of guessing a fixed height.
    if (rs.enableBlur) {
      field = Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: borderRadius,
              // WITH A SAVE LAYER: a plain antialiased clip does not
              // contain a `BackdropFilter`, so the field's rounded
              // corners come back SQUARE.
              clipBehavior: Clip.antiAliasWithSaveLayer,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: rs.blurSigma,
                  sigmaY: rs.blurSigma,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: borderRadius,
                  ),
                ),
              ),
            ),
          ),
          field,
        ],
      );
    }

    // ── Width: exact > fit-to-content > fill parent ──────────────
    if (sizing.width != null) {
      field = SizedBox(width: sizing.width, child: field);
    } else if (sizing.fitWidthToContent) {
      // Size to content WITHOUT manual text measurement (which mis-measured
      // the render width — leaving slack or clipping, and flipping the slack
      // to the start in RTL). An invisible ghost copy of the text drives the
      // width via IntrinsicWidth; the real field fills it (Positioned, so it's
      // skipped by the intrinsic pass — EditableText has no intrinsic width).
      // Both go through the same RenderParagraph, so the box matches the
      // glyphs exactly: no slack, no clip, RTL-correct, no typing jitter. The
      // ghost padding mirrors the field's fit-width contentPadding so the text
      // areas line up. The min/max block below clamps the result.
      final content = widget.controller.text.isEmpty
          ? widget.hint
          : widget.controller.text;
      // Invisible copies of the REAL slot widgets size the ghost exactly —
      // a fixed per-slot heuristic over-reserved and read as dead space
      // between content and suffix. (Caveat: a slot widget carrying a
      // GlobalKey would conflict with its ghost copy — slots shouldn't.)
      final suffixGhost = _buildSuffixIcon();
      // Mirror the field's contentPadding — but ONLY on sides without a slot:
      // InputDecorator drops the horizontal contentPadding on sides where an
      // icon slot sits (the slot replaces the inset), so reserving it in the
      // ghost would funnel orphaned width into the editable area.
      final basePadding =
          rs.contentPadding?.resolve(Directionality.of(context)) ??
          const EdgeInsets.symmetric(
            horizontal: TextFieldDefaults.fitWidthHPad,
            vertical: TextFieldDefaults.fitWidthVPad,
          );
      // Read-only fit-width fields (dropdown triggers) get NO slot gap:
      // any width the ghost reserves beyond the glyphs becomes trailing
      // space INSIDE the start-aligned editable — visible dead space
      // between the label and the chevron. Editable fields keep the gap
      // (caret + typing need the breathing room).
      final slotGap = widget.behavior.readOnly
          ? 0.0
          : TextFieldDefaults.fitWidthSlotGap;
      final ghostPadding = EdgeInsetsDirectional.only(
        start: widget.slots.prefixIcon != null ? slotGap : basePadding.left,
        end: suffixGhost != null ? slotGap : basePadding.right,
        top: basePadding.top,
        bottom: basePadding.bottom,
      );
      field = IntrinsicWidth(
        child: Stack(
          children: [
            Padding(
              padding: ghostPadding,
              // Measurement-only twin: invisible but keeps its size to drive
              // the intrinsic width. ExcludeSemantics because it embeds REAL
              // slot copies (e.g. a dropdown's chevron IconButton) whose
              // interactive semantics would otherwise duplicate the field's.
              // Visibility (not Opacity) so it doesn't paint or take taps.
              child: ExcludeSemantics(
                child: Visibility(
                  visible: false,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.slots.prefixIcon != null)
                        widget.slots.prefixIcon!,
                      Text(
                        content,
                        style: textStyle,
                        maxLines: 1,
                        softWrap: false,
                      ),
                      // End-side room for the caret + border inset. In a Row it
                      // lands after the text → the caret side in both LTR and
                      // RTL. Reserve it when a caret shows (editable) OR when a
                      // suffix follows: InputDecorator always inserts an
                      // internal text→suffix gap the ghost's Row otherwise
                      // omits, so a readOnly picker trigger (dropdown chevron)
                      // would clip its last glyph without it.
                      if (!behavior.readOnly || suffixGhost != null)
                        const SizedBox(
                          width: TextFieldDefaults.fitWidthCaretRoom,
                        ),
                      if (suffixGhost != null) suffixGhost,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(child: field),
          ],
        ),
      );
    }

    // ── Height: exact box (isDense/isCollapsed let it take hold) ──
    if (boxHeight != null) {
      field = SizedBox(height: boxHeight, child: field);
    }

    // ── Soft min/max bounds for the unfixed axes ─────────────────
    // An exact height/width wins over its axis' clamps, so skip them there.
    // Fit-width keeps the width clamps — they bound the measured width.
    final minH = boxHeight != null ? null : sizing.minHeight;
    final maxH = boxHeight != null ? null : sizing.maxHeight;
    final minW = sizing.width != null ? null : sizing.minWidth;
    final maxW = sizing.width != null ? null : sizing.maxWidth;
    if (minH != null || maxH != null || minW != null || maxW != null) {
      field = ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: minH ?? 0.0,
          maxHeight: maxH ?? double.infinity,
          minWidth: minW ?? 0.0,
          maxWidth: maxW ?? double.infinity,
        ),
        child: field,
      );
    }

    return field;
  }

  EdgeInsetsGeometry? _resolveContentPadding(TextStyle? textStyle) {
    if (_rs.contentPadding != null) return _rs.contentPadding;
    final sizing = widget.sizing;
    final height = sizing.height ?? _rs.height;

    // Fit-to-content with no explicit height: pin a known symmetric padding
    // so the box hugs the text evenly (the fit-width ghost in `_buildTextField`
    // mirrors this padding so the text areas line up).
    if (height == null && sizing.fitWidthToContent && sizing.width == null) {
      return const EdgeInsets.symmetric(
        horizontal: TextFieldDefaults.fitWidthHPad,
        vertical: TextFieldDefaults.fitWidthVPad,
      );
    }

    if (height == null) return null;

    // Multiline with an explicit height: the single-line centering formula
    // below would mis-place a wrapping text — keep a plain symmetric inset
    // and let the text top-align + scroll inside the fixed box.
    if ((widget.behavior.maxLines ?? 1) != 1) {
      return const EdgeInsets.symmetric(
        horizontal: TextFieldDefaults.contentHPad,
        vertical: TextFieldDefaults.multilineVPad,
      );
    }

    // Estimate the RENDERED line height (respecting the app's font scaling —
    // an unscaled estimate overestimates the padding, squeezing the line box
    // until the caret clips invisible while glyphs still show).
    final fontSize = MediaQuery.textScalerOf(
      context,
    ).scale(textStyle?.fontSize ?? 14.0);
    final lineHeight = fontSize * (textStyle?.height ?? 1.4);
    final verticalPadding = ((height - lineHeight) / 2).clamp(0.0, height / 2);

    return EdgeInsets.symmetric(
      horizontal: TextFieldDefaults.contentHPad,
      vertical: verticalPadding,
    );
  }

  // ─── Suggestions overlay content ──────────────────────────────

  Widget _buildSuggestionsOverlayContent(GlobalPopupLayout layout) {
    final cfg = widget.features.suggestions!;
    final overlayWidth = cfg.isFullScreenWidth
        ? MediaQuery.of(context).size.width - cfg.horizontalPadding * 2
        : layout.width;

    final theme = Theme.of(context);
    final borderRadius = _effectiveBorderRadius;

    return Listener(
      onPointerDown: (_) {
        _isInteractingWithOverlay = true;
        _effectiveFocusNode?.requestFocus();
      },
      onPointerUp: (_) => _isInteractingWithOverlay = false,
      onPointerCancel: (_) => _isInteractingWithOverlay = false,
      child: Material(
        elevation: 10,
        borderRadius: borderRadius,
        color: theme.colorScheme.surface,
        child: ClipRRect(
          borderRadius: borderRadius,
          child: SizedBox(
            width: overlayWidth,
            // AnimatedSize sits ABOVE the height cap: it measures its child
            // with loose constraints, so with the cap inside, a long list is
            // properly height-limited (and scrolls) while grow/shrink still
            // tween. With the cap outside, the list laid out full-height
            // past the clip and scrolling broke.
            child: AnimatedSize(
              duration: AppDurations.quick,
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: layout.fixedHeight ?? 0,
                  maxHeight: layout.maxHeight,
                ),
                // Transparent Material INSIDE the clip: row ripples paint
                // here (not on the outer surface Material, which sits below
                // the ClipRRect) — so the first/last rows' ink respects the
                // popup's rounded corners.
                child: Material(
                  type: MaterialType.transparency,
                  // Edge fade = the scroll affordance: when the list exceeds
                  // the popup's height cap, the faded bottom edge shows more
                  // rows exist below (smart mode hides it at the true end —
                  // where the last row's rounded corners take over).
                  child: GlobalEdgeFade(
                    controller: _suggestionsScroll,
                    style: const EdgeFadeStyle(size: 20),
                    child: ListView(
                      controller: _suggestionsScroll,
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      children: _suggestionRows(
                        context,
                        includeLoading: true,
                        onClearTap: () {
                          cfg.onRecentCleared?.call();
                          _removeSuggestionsOverlay();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSearchItem(
    BuildContext context,
    String recent, {
    BorderRadius? inkRadius,
  }) {
    final theme = Theme.of(context);
    final cfg = widget.features.suggestions!;
    return Semantics(
      button: true,
      label: recent,
      child: InkWell(
        // Overlay rows are rebuilt per keystroke — a focusable InkWell's
        // focus node outliving its deactivated element storms "Looking up a
        // deactivated widget's ancestor".
        canRequestFocus: false,
        // First/last overlay rows round their ink to the popup corners.
        borderRadius: inkRadius,
        onTap: () => _selectSuggestion(recent),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.spacing.md,
            vertical: context.spacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                cfg.recentIcon,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(recent, style: theme.textTheme.bodyMedium),
              ),
              if (cfg.onRecentDeleted != null)
                // Nested InkResponse INSIDE the tile: it wins the gesture
                // arena for its own taps and paints its own compact splash
                // (the old whole-tile-ripple bug came from a bare
                // GestureDetector; an ink surface doesn't have it). No
                // IconButton — its tap-target floor inflates the row.
                Semantics(
                  button: true,
                  label: Tr.t('text_field.remove_recent', 'Remove'),
                  child: InkResponse(
                    canRequestFocus: false,
                    radius: 16,
                    onTap: () {
                      cfg.onRecentDeleted?.call(recent);
                      _anchoredOverlay.markNeedsLayout();
                    },
                    child: Padding(
                      padding: EdgeInsets.all(context.spacing.xs),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(
    BuildContext context,
    String suggestion,
    String query, {
    BorderRadius? inkRadius,
  }) {
    final theme = Theme.of(context);
    final cfg = widget.features.suggestions!;
    final lowerSuggestion = suggestion.toLowerCase();
    final lowerQuery = query.toLowerCase().trim();
    // Chips mode: "selected" = already added as a chip (the editor text
    // is transient). Plain mode: the editor holds the suggestion.
    final isSelected = widget.features.chips != null
        ? _chipForSuggestion(suggestion) != null
        : widget.controller.text.trim().toLowerCase() == lowerSuggestion;
    // Keyboard-nav focus ring (↑/↓) — distinct from "selected".
    final isHighlighted =
        _highlightedSuggestion >= 0 &&
        _highlightedSuggestion < _filteredSuggestions.length &&
        _filteredSuggestions[_highlightedSuggestion] == suggestion;

    Widget textWidget;
    if (lowerQuery.isNotEmpty && lowerSuggestion.contains(lowerQuery)) {
      final startIndex = lowerSuggestion.indexOf(lowerQuery);
      final endIndex = startIndex + lowerQuery.length;
      textWidget = RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isSelected ? theme.colorScheme.primary : null,
            fontWeight: isSelected ? FontWeight.w600 : null,
          ),
          children: [
            TextSpan(text: suggestion.substring(0, startIndex)),
            TextSpan(
              text: suggestion.substring(startIndex, endIndex),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            TextSpan(text: suggestion.substring(endIndex)),
          ],
        ),
      );
    } else {
      textWidget = Text(
        suggestion,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isSelected ? theme.colorScheme.primary : null,
          fontWeight: isSelected ? FontWeight.w600 : null,
        ),
      );
    }

    return Semantics(
      button: true,
      selected: isSelected,
      label: suggestion,
      child: InkWell(
        canRequestFocus: false, // see _buildRecentSearchItem
        borderRadius: inkRadius,
        onTap: () => _selectSuggestion(suggestion),
        child: Container(
          // Fill rounds natively (popup's first/last corners when applicable).
          decoration: isSelected
              ? BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: inkRadius,
                )
              : isHighlighted
              ? BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                  borderRadius: inkRadius,
                )
              : null,
          child: Stack(
            children: [
              if (isSelected)
                // The classic full-height accent bar at the reading edge —
                // as a positioned rounded stripe (a BorderDirectional stroke
                // can't have rounded corners).
                PositionedDirectional(
                  start: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(context.radii.xs),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.md,
                  vertical: TextFieldDefaults.suggestionRowVPad,
                ),
                child: Row(
                  children: [
                    if (cfg.suggestionIcon != null) ...[
                      Icon(
                        cfg.suggestionIcon,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(child: textWidget),
                    if (cfg.trailingBuilder != null)
                      // Focus-excluded for the same overlay-rebuild hazard as
                      // the rows; taps inside don't select the row.
                      ExcludeFocus(
                        child: cfg.trailingBuilder!(context, suggestion),
                      ),
                    if (isSelected)
                      Icon(
                        Icons.check,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _TextFieldBorderPainter — strokes the active border side (gradient mode)
// ---------------------------------------------------------------------------

class _TextFieldBorderPainter extends CustomPainter {
  _TextFieldBorderPainter({required this.side, required this.radius});

  final ResolvedBorderSide side;
  final BorderRadius radius;

  @override
  void paint(Canvas canvas, Size size) {
    final w = side.width;
    if (w <= 0 || (!side.paints && side.gradient == null)) return;

    final rect = Offset.zero & size;
    // Inset by half the stroke so the border sits inside the field bounds.
    final rrect = radius.toRRect(rect).deflate(w / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w;
    if (side.gradient != null) {
      paint.shader = side.gradient!.createShader(rect);
    } else {
      paint.color = side.color;
    }
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_TextFieldBorderPainter old) =>
      old.side.color != side.color ||
      old.side.width != side.width ||
      old.side.gradient != side.gradient ||
      old.radius != radius;
}
