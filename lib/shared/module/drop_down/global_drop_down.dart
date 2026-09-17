// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Project imports:
import '../../../core/animations/animation_presets.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/drop_down_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../popup/popup.dart';
import '../text_field/global_text_field.dart';
import 'drop_down_models.dart';
import 'models/drop_down_configs.dart';
import 'models/drop_down_style.dart';
import 'surfaces/dropdown_surface.dart';
import 'surfaces/dropdown_triggers.dart';

export 'drop_down_form_fields.dart';
export 'drop_down_models.dart';
export 'models/drop_down_configs.dart';
export 'models/drop_down_style.dart';
export 'surfaces/dropdown_surface.dart';
export 'surfaces/dropdown_triggers.dart';
export 'theme/drop_down_theme.dart';

// ---------------------------------------------------------------------------
// GlobalDropdown — composition of GlobalTextFormField + GlobalPopupController
// ---------------------------------------------------------------------------

/// Select field built as a COMPOSITION of two engines:
///
/// * **Trigger** — a [GlobalTextFormField] in read-only picker mode
///   (`readOnly + onTap`). The selection summary renders as the field text;
///   `identifier`, `errorText`, `messages`, `style` and `sizing` flow
///   straight into the field, so dropdowns get the exact same header /
///   message-column / theming treatment as every other field.
/// * **Overlay** — a [GlobalPopupController] anchored to the trigger. All
///   placement, flip, keyboard-avoidance, scroll-reposition, tap-outside
///   and route-change behavior comes from the popup engine; override any of
///   it per call via [popupOptions].
///
/// Config is grouped like the text field's: data + selection top-level,
/// then [behavior] (interaction/layout knobs), [chips] (multi-select chip
/// trigger), [slots] (builder hooks + info label), [style] (trigger
/// visuals, themeable via `GlobalTextFieldTheme`), [dropdownStyle] (open
/// surface row visuals, themeable via `GlobalDropdownTheme`), [sizing],
/// [popupOptions] and [messages].
///
/// The open-session body (search, async loading + error, list, multi-select
/// footer) is [DropdownSurface] — shared between the overlay and
/// `behavior.inline: true`.
///
/// Fully controlled: the trigger displays [selectedValue] /
/// [selectedValues] as provided by the parent — selections are reported via
/// [onChanged] / [onMultiChanged] and never mutated internally.
///
/// EXCEPTION: `chips.display: true` keeps a custom wrap-height trigger
/// ([DropdownChipTrigger]) because the text field is single-line; it is
/// styled from the same resolved [TextFieldStyle] and renders the SAME
/// message column ([FieldMessagesColumn]) below the wrap.
class GlobalDropdown<T> extends StatefulWidget {
  const GlobalDropdown({
    super.key,
    this.items = const [],
    this.groups,
    this.selectedValue,
    this.onChanged,
    this.selectedValues,
    this.onMultiChanged,
    this.multiSelect = false,
    this.asyncItemsLoader,
    this.hint,
    this.identifier,
    this.required = false,
    this.enabled = true,
    this.errorText,
    this.controller,
    this.behavior = const DropdownBehavior(),
    this.chips = const DropdownChips(),
    this.slots = const DropdownSlots(),
    this.style,
    this.dropdownStyle,
    this.sizing,
    this.popupOptions,
    this.messages,
  }) : assert(
         multiSelect == (onMultiChanged != null),
         'Must provide onMultiChanged for multiSelect',
       ),
       assert(
         !multiSelect == (onChanged != null),
         'Must provide onChanged for singleSelect',
       );

  final List<DropdownItem<T>> items;
  final List<DropdownGroup<T>>? groups;
  final T? selectedValue;
  final ValueChanged<T?>? onChanged;
  final List<T>? selectedValues;
  final ValueChanged<List<T>>? onMultiChanged;
  final bool multiSelect;

  /// Remote items: called (debounced) with the search query; also fired
  /// once with an empty query on open. Failures render a retryable row.
  /// Top-level (not in [slots]) because it's a DATA source, not a UI hook.
  final Future<List<DropdownItem<T>>> Function(String query)? asyncItemsLoader;

  /// Placeholder when empty. Null → localized "Select an option(s)".
  final String? hint;

  /// Static label above the trigger — the text field's identifier header.
  final String? identifier;

  /// Whether [identifier] wears the red `*` a required text field's does.
  ///
  /// It marks the LABEL only — the validator is still the caller's, the
  /// same division the text field keeps. Without it a required picker
  /// sat in a form of starred fields looking optional.
  final bool required;

  final bool enabled;

  /// External error — renders in the trigger field's message column and
  /// drives its error border.
  final String? errorText;

  /// Programmatic open / close / clear.
  final GlobalDropdownController? controller;

  /// Interaction + layout knobs (search, inline, dense trigger, caps…).
  final DropdownBehavior behavior;

  /// Multi-select chip trigger options.
  final DropdownChips chips;

  /// Builder hooks (item/empty/create-new) + prefix icon + info label.
  final DropdownSlots<T> slots;

  /// Trigger visual override — merged over `GlobalTextFieldTheme` exactly
  /// like any text field.
  final TextFieldStyle? style;

  /// Open-surface row visuals — merged over `GlobalDropdownTheme`.
  final DropdownStyle? dropdownStyle;

  /// Trigger box geometry (height / width / density).
  final TextFieldSizing? sizing;

  /// Overlay overrides, merged over the dropdown's computed defaults
  /// (width, `behavior.maxHeight`, auto placement, reposition-on-scroll).
  final GlobalPopupOptions? popupOptions;

  /// Status rows under the trigger (error / success / warning / info).
  final List<FieldMessage>? messages;

  @override
  State<GlobalDropdown<T>> createState() => _GlobalDropdownState<T>();
}

class _GlobalDropdownState<T> extends State<GlobalDropdown<T>>
    with TickerProviderStateMixin {
  final LayerLink _link = LayerLink();
  final GlobalKey _anchorKey = GlobalKey(debugLabel: 'GlobalDropdown.anchor');
  final GlobalPopupController _popupCtrl = GlobalPopupController();
  final TextEditingController _displayCtrl = TextEditingController();
  final FocusNode _triggerFocusNode = FocusNode();

  /// Open state — mirrors the popup controller via hooks; toggled directly
  /// in inline mode. Drives the chevron + semantics hint.
  bool _open = false;

  /// Items picked during a session — lets the trigger resolve labels for
  /// values that aren't in [GlobalDropdown.items] (async-loaded picks).
  /// Display-only cache; parent-owned selection state is never mutated.
  final Map<T, DropdownItem<T>> _knownItems = {};

  List<DropdownItem<T>> get _allItems => (widget.groups?.isNotEmpty ?? false)
      ? widget.groups!.expand((g) => g.items).toList()
      : widget.items;

  bool get _hasValue => widget.multiSelect
      ? (widget.selectedValues?.isNotEmpty ?? false)
      : widget.selectedValue != null;

  String get _effectiveHint =>
      widget.hint ??
      (widget.multiSelect
          ? DropDownStrings.selectOptions
          : DropDownStrings.selectOption);

  /// Haptic gate — the trigger side reads the TRIGGER style's flag.
  bool _hapticEnabled(BuildContext context) =>
      (widget.style ?? const TextFieldStyle()).resolve(context).enableHaptic;

  void _haptic(BuildContext context) {
    if (_hapticEnabled(context)) HapticFeedback.selectionClick();
  }

  // ─── Lifecycle ────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Seed the trigger's text BEFORE the first frame.
    //
    // The build path defers this to a post-frame callback, correctly:
    // writing the controller during build notifies the inner
    // `TextFormField`, whose `didChange` marks an ancestor `Form` dirty
    // mid-build. But that leaves frame one EMPTY and frame two filled.
    //
    // Invisible for a dropdown mounted once at startup. Very visible for
    // one built fresh mid-flight — a Hero shuttle constructs its own
    // copy, so the dial code blinked in as the box travelled. Here there
    // is no `Form` below us yet and nothing to notify.
    _displayCtrl.text = _displayText(_selectedItems());
    _attachController(widget.controller);
    // Repaint the chip trigger's focused border on keyboard focus changes.
    _triggerFocusNode.addListener(_onTriggerFocusChanged);
  }

  void _onTriggerFocusChanged() {
    if (mounted && widget.chips.display && widget.multiSelect) setState(() {});
  }

  @override
  void didUpdateWidget(covariant GlobalDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.detach(owner: this);
      _attachController(widget.controller);
    }
    // A field disabled (or flipped to the loading shimmer) mid-session
    // must drop its open session: the surface rows have no enabled gate,
    // and the loading trigger unmounts the popup's anchor.
    if ((!widget.enabled || widget.behavior.isLoading) && _open) {
      _closeDropdown();
    }
    // Push the new configuration into the open overlay — the popup stores
    // the builder closure from `show`, so parent rebuilds (new items,
    // selection, options) would otherwise never reach it.
    if (!widget.behavior.inline && _popupCtrl.isOpen) {
      _popupCtrl.refresh(
        builder: _buildOverlaySurface,
        options: _effectiveOptions(),
      );
    }
  }

  @override
  void dispose() {
    // Owner-guarded: on remount the NEW state attaches before this
    // (deferred) dispose runs — detaching unconditionally would kill it.
    widget.controller?.detach(owner: this);
    _popupCtrl.dispose();
    _displayCtrl.dispose();
    _triggerFocusNode
      ..removeListener(_onTriggerFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _attachController(GlobalDropdownController? controller) {
    controller?.attach(
      owner: this,
      onOpen: _openDropdown,
      onClose: _closeDropdown,
      onClear: _clearSelection,
      isOpenGetter: () => _open,
    );
  }

  // ─── Open / close ─────────────────────────────────────────────

  void _toggle() => _open ? _closeDropdown() : _openDropdown();

  void _openDropdown() {
    if (_open || !widget.enabled || widget.behavior.isLoading || !mounted) {
      return;
    }
    if (widget.behavior.inline) {
      setState(() => _open = true);
      // Inline mode has no popup engine to fire the session hooks —
      // deliver them here so caller hooks (and the form wrapper's
      // on-close validate) behave identically in both modes.
      widget.popupOptions?.hooks?.onOpen?.call();
      return;
    }
    final anchorContext = _anchorKey.currentContext;
    if (anchorContext == null) return;
    _popupCtrl.show(
      context: context,
      anchorContext: anchorContext,
      link: _link,
      vsync: this,
      options: _effectiveOptions(),
      builder: _buildOverlaySurface,
    );
  }

  void _closeDropdown() {
    if (widget.behavior.inline) {
      if (_open && mounted) {
        setState(() => _open = false);
        widget.popupOptions?.hooks?.onClose?.call();
      }
      return;
    }
    _popupCtrl.hide();
  }

  /// Overlay defaults with caller [GlobalDropdown.popupOptions] overrides
  /// layered on top (caller wins field-by-field).
  GlobalPopupOptions _effectiveOptions() {
    final b = widget.behavior;
    final user = widget.popupOptions ?? const GlobalPopupOptions();
    final maxHeight = user.maxHeight ?? b.maxHeight;
    return user.copyWith(
      width:
          user.width ??
          (b.isFullScreenWidth
              ? GlobalPopupWidth.screenInset(inset: b.horizontalPadding)
              : const GlobalPopupWidth.matchAnchor()),
      maxHeight: maxHeight,
      // Keep the resize floor within the requested cap for short overlays.
      minHeight: user.minHeight ?? (maxHeight < 100 ? maxHeight : null),
      closeOnScroll: user.closeOnScroll ?? false,
      hooks: GlobalPopupHooks(
        onOpen: () {
          if (mounted) setState(() => _open = true);
          user.hooks?.onOpen?.call();
        },
        onClose: () {
          if (mounted) setState(() => _open = false);
          user.hooks?.onClose?.call();
        },
        onWillClose: user.hooks?.onWillClose,
      ),
    );
  }

  // ─── Selection plumbing ───────────────────────────────────────

  Widget _buildOverlaySurface(BuildContext ctx, GlobalPopupLayout layout) =>
      _buildSurface(layout: layout);

  Widget _buildSurface({GlobalPopupLayout? layout}) {
    return DropdownSurface<T>(
      items: widget.items,
      groups: widget.groups,
      multiSelect: widget.multiSelect,
      selectedValue: widget.selectedValue,
      selectedValues: widget.selectedValues ?? <T>[],
      enableSearch: widget.behavior.enableSearch,
      searchIdentifier: widget.behavior.searchIdentifier,
      asyncItemsLoader: widget.asyncItemsLoader,
      itemBuilder: widget.slots.itemBuilder,
      onCreateNew: widget.slots.onCreateNew,
      maxSelections: widget.behavior.maxSelections,
      emptyBuilder: widget.slots.emptyBuilder,
      onSelected: widget.multiSelect ? null : _handleSelected,
      onMultiChanged: widget.multiSelect ? _handleMultiChanged : null,
      onCloseRequested: _closeDropdown,
      layout: layout,
      surfaceStyle: widget.popupOptions?.surfaceStyle,
      dropdownStyle: widget.dropdownStyle,
      inlineMaxHeight: widget.behavior.maxHeight,
    );
  }

  void _handleSelected(DropdownItem<T> item) {
    _knownItems[item.value] = item;
    widget.onChanged?.call(item.value);
    if (mounted) setState(() {});
  }

  void _handleMultiChanged(List<T> values, List<DropdownItem<T>> known) {
    for (final item in known) {
      _knownItems[item.value] = item;
    }
    widget.onMultiChanged?.call(values);
    if (mounted) setState(() {});
  }

  void _clearSelection() {
    if (mounted) _haptic(context);
    if (widget.multiSelect) {
      widget.onMultiChanged?.call(<T>[]);
    } else {
      widget.onChanged?.call(null);
    }
  }

  void _removeChip(DropdownItem<T> item) {
    _haptic(context);
    final values = List<T>.of(widget.selectedValues ?? <T>[])
      ..remove(item.value);
    widget.onMultiChanged?.call(values);
  }

  // ─── Display resolution ───────────────────────────────────────

  DropdownItem<T>? _resolveItem(T value) {
    for (final item in _allItems) {
      if (item.value == value) return item;
    }
    return _knownItems[value];
  }

  /// Selected items resolvable to a [DropdownItem] (from [GlobalDropdown.items],
  /// [GlobalDropdown.groups] or the session cache). Unknown values render
  /// as the hint — they are never pruned back into the parent's state.
  List<DropdownItem<T>> _selectedItems() {
    if (widget.multiSelect) {
      return [
        for (final v in widget.selectedValues ?? <T>[])
          if (_resolveItem(v) case final item?) item,
      ];
    }
    final value = widget.selectedValue;
    if (value == null) return const [];
    final item = _resolveItem(value);
    return item == null ? const [] : [item];
  }

  String _displayText(List<DropdownItem<T>> selectedItems) {
    if (!widget.multiSelect) {
      return selectedItems.isEmpty ? '' : selectedItems.first.label;
    }
    final labs = selectedItems.map((i) => i.label).toList();
    if (labs.isEmpty) return '';
    if (labs.length <= 2) return labs.join(', ');
    return DropDownStrings.moreItems(
      labs.take(2).join(', '),
      labs.length - 2,
    );
  }

  // ─── Keyboard ─────────────────────────────────────────────────

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (!widget.enabled || widget.behavior.isLoading) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      _toggle();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape && _open) {
      _closeDropdown();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.behavior.isLoading) {
      return DropdownLoadingTrigger(
        style: widget.style ?? const TextFieldStyle(),
        height:
            widget.sizing?.height ??
            widget.style?.height ??
            kDropdownTriggerHeight,
        identifier: widget.identifier,
        required: widget.required,
        infoLabel: widget.slots.infoLabel,
        onInfoLabelTap: widget.slots.onInfoLabelTap,
        enabled: widget.enabled,
      );
    }

    final selectedItems = _selectedItems();
    final display = _displayText(selectedItems);
    // Deferred to post-frame: writing the controller DURING build notifies
    // the trigger's inner TextFormField, whose didChange marks an ancestor
    // Form dirty mid-build ("setState() called during build"). Post-frame,
    // the same notification is a legal setState.
    if (_displayCtrl.text != display) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _displayCtrl.text != display) {
          _displayCtrl.text = display;
        }
      });
    }

    final useChip = widget.chips.display && widget.multiSelect;
    var trigger = useChip
        ? _buildChipTrigger(context, selectedItems)
        : _buildFieldTrigger(context, selectedItems);

    trigger = Focus(
      focusNode: _triggerFocusNode,
      onKeyEvent: _onKeyEvent,
      child: CompositedTransformTarget(
        link: _link,
        child: KeyedSubtree(key: _anchorKey, child: trigger),
      ),
    );

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final body = widget.behavior.inline
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              trigger,
              AnimatedSize(
                duration: reduceMotion
                    ? AppDurations.instant
                    : AppDurations.fast,
                curve: Curves.easeOut,
                alignment: AlignmentDirectional.topStart,
                child: _open
                    ? Padding(
                        padding: EdgeInsets.only(top: context.spacing.sm),
                        child: _buildSurface(),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          )
        : trigger;

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.identifier ?? _effectiveHint,
      value: display.isEmpty ? null : display,
      hint: _open ? DropDownStrings.tapToClose : DropDownStrings.tapToOpen,
      child: body,
    );
  }

  Widget _buildFieldTrigger(
    BuildContext context,
    List<DropdownItem<T>> selectedItems,
  ) {
    final selected = widget.multiSelect || selectedItems.isEmpty
        ? null
        : selectedItems.first;
    // A selected item's own leading (flag) wins; else the fixed
    // field-level prefix icon.
    final leading =
        selected?.leading ??
        (widget.slots.prefixIcon == null
            ? null
            : Icon(
                widget.slots.prefixIcon,
                color: widget.style?.iconColor ?? context.iconColors.primary,
              ));
    // While open, paint the FOCUSED border on the resting state — the
    // picker-mode focus node can't take real focus, so the field would
    // otherwise never look active (regardless of whether the tap or the
    // chevron button opened it).
    final baseStyle = widget.style ?? const TextFieldStyle();
    final openBorder = TextFieldBorderStyle(
      enabled: TextFieldBorderSide(
        color: context.primaryColors.primary,
        width: TextFieldDefaults.focusedBorderWidth,
      ),
    );
    final triggerStyle = !_open
        ? baseStyle
        : baseStyle.copyWith(
            border: baseStyle.border?.mergedWith(openBorder) ?? openBorder,
          );
    return GlobalTextFormField(
      controller: _displayCtrl,
      hint: _effectiveHint,
      identifier: widget.identifier,
      required: widget.required,
      style: triggerStyle,
      sizing: widget.sizing ?? const TextFieldSizing(),
      messages: widget.messages ?? const [],
      behavior: TextFieldBehavior(
        readOnly: true,
        enabled: widget.enabled,
        textAlign: widget.behavior.triggerTextAlign,
      ),
      validation: TextFieldValidation(errorText: widget.errorText),
      callbacks: TextFieldCallbacks(onTap: _onTriggerTap),
      slots: TextFieldSlots(
        prefixIcon: _buildTriggerPrefix(context, leading, selected),
        suffix: widget.behavior.controlsAtStart
            ? null
            : TextFieldSuffix.widget(
                _buildTriggerControls(selectedTrailing: selected?.trailing),
              ),
        infoLabel: widget.slots.infoLabel,
        onInfoLabelTap: widget.slots.onInfoLabelTap,
      ),
    );
  }

  void _onTriggerTap() {
    if (!_open) _haptic(context);
    _toggle();
  }

  /// Field-trigger prefix: the selected item's leading widget — preceded
  /// by the chevron/clear controls when `behavior.controlsAtStart`.
  Widget? _buildTriggerPrefix(
    BuildContext context,
    Widget? leading,
    DropdownItem<T>? selected,
  ) {
    if (!widget.behavior.controlsAtStart) {
      return leading == null
          ? null
          : Padding(
              padding: EdgeInsetsDirectional.only(
                start: context.spacing.sm + context.spacing.xs,
                end: context.spacing.sm,
              ),
              child: leading,
            );
    }
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: context.spacing.xs,
        end: context.spacing.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTriggerControls(selectedTrailing: selected?.trailing),
          if (leading != null) ...[
            SizedBox(width: context.spacing.xs),
            leading,
          ],
        ],
      ),
    );
  }

  Widget _buildChipTrigger(
    BuildContext context,
    List<DropdownItem<T>> selectedItems,
  ) {
    return MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTap: widget.enabled ? _onTriggerTap : null,
        behavior: HitTestBehavior.opaque,
        child: DropdownChipTrigger<T>(
          selectedItems: selectedItems,
          hint: _effectiveHint,
          style: widget.style ?? const TextFieldStyle(),
          identifier: widget.identifier,
          required: widget.required,
          infoLabel: widget.slots.infoLabel,
          onInfoLabelTap: widget.slots.onInfoLabelTap,
          errorText: widget.errorText,
          messages: widget.messages ?? const [],
          minHeight:
              widget.sizing?.height ??
              widget.sizing?.minHeight ??
              widget.style?.height ??
              kDropdownTriggerHeight,
          enabled: widget.enabled,
          focused: _triggerFocusNode.hasFocus || _open,
          showLeadingInChip: widget.chips.showLeading,
          showTrailingInChip: widget.chips.showTrailing,
          onDeleteItem: widget.enabled ? _removeChip : null,
          trailing: _buildTriggerControls(),
        ),
      ),
    );
  }

  Widget _buildTriggerControls({Widget? selectedTrailing}) {
    return DropdownTriggerControls(
      open: _open,
      enabled: widget.enabled,
      showClear: widget.behavior.showClearButton && _hasValue,
      onClear: _clearSelection,
      onToggle: _toggle,
      iconColor: widget.style?.iconColor,
      selectedTrailing: selectedTrailing,
      dense: widget.behavior.denseTrigger,
      showChevron: widget.behavior.showChevron,
    );
  }
}
