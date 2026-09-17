import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/otp_field_strings.dart';
import '../../../../core/localization/strings/validator_strings.dart';
import '../../../../core/tokens/extensions.dart';
import '../../../../core/utils/validators/validators.dart';
import '../../../module/text_field/global_text_field.dart';
import 'joined_pair_radii.dart';

/// What characters the code is made of — drives the per-cell filter, the
/// keyboard, and the whole-group validation.
enum OtpMode {
  /// `0–9` only (SMS codes). Number keyboard.
  digits,

  /// `A–Z` only (letter codes). Uppercased as typed.
  letters,

  /// `A–Z` + `0–9` (mixed codes). Uppercased as typed.
  alphanumeric;

  RegExp get _allow => switch (this) {
    OtpMode.digits => RegExp('[0-9]'),
    OtpMode.letters => RegExp('[a-zA-Z]'),
    OtpMode.alphanumeric => RegExp('[a-zA-Z0-9]'),
  };

  /// Strips everything outside the charset (and uppercases letters).
  String clean(String text) {
    final kept = _allow.allMatches(text).map((m) => m.group(0)!).join();
    return this == OtpMode.digits ? kept : kept.toUpperCase();
  }

  TextInputType get keyboard => switch (this) {
    OtpMode.digits => TextInputType.number,
    // visiblePassword blocks autocorrect/suggestions for letter codes.
    _ => TextInputType.visiblePassword,
  };

  String get cellHint => this == OtpMode.digits ? '0' : 'A';
}

/// One-time-code field — one BOX PER CHARACTER (the segmented-color
/// treatment): typing fills a cell and advances, backspace on an empty cell
/// hops back (clearing the previous one), pasting a full code distributes it
/// across the cells, and focusing a filled cell selects it so typing
/// replaces. The whole group validates as ONE code ([OtpMode] charset +
/// exact [length]); [onCompleted] fires when the last cell lands.
///
/// The [controller] holds the JOINED code (`"482913"`) — programmatic writes
/// (clear, prefill) re-seed the cells.
///
/// `boxed: false` restores the legacy single centered input.
class OtpField extends StatefulWidget {
  const OtpField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onCompleted,
    this.label,
    this.identifier,
    this.hint = '000000',
    this.length = 6,
    this.mode = OtpMode.digits,
    this.boxed = true,
    this.joined = false,
    this.obscure = false,
    this.enableSmsAutofill = true,
    this.autoClearOnError = false,
    this.success = false,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.validator,
    this.focusNode,
    this.validationMode = ValidationMode.onInteraction,
  }) : assert(length > 0);

  /// Holds the joined code; two-way synced with the cells.
  final TextEditingController controller;

  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;

  /// Fires once each time the code becomes complete (all cells filled).
  final ValueChanged<String>? onCompleted;

  final String? label;
  final String? identifier;

  /// Placeholder for the legacy single-box mode only.
  final String hint;

  /// Number of characters = number of cells.
  final int length;

  /// Charset — digits / letters / alphanumeric.
  final OtpMode mode;

  /// One box per character (default). `false` → legacy single input.
  final bool boxed;

  /// Cells render as ONE attached control: no gaps, inner corners squared
  /// (only the chain's outer corners keep the radius). Boxed mode only.
  final bool joined;

  /// PIN entry — cells show `•` instead of the character.
  final bool obscure;

  /// Tag the cells with [AutofillHints.oneTimeCode] so iOS offers the code
  /// from Messages in the keyboard bar (accepting it enters the full code,
  /// which the paste-distribution fans out). Digits mode only.
  final bool enableSmsAutofill;

  /// When [errorText] arrives (server rejected the code) the cells SHAKE —
  /// always. With this on they ALSO wipe + refocus the first cell; off
  /// (default) the typed code stays for the user to inspect/correct.
  final bool autoClearOnError;

  /// Paint the cells with the success border (code accepted). Caller-owned —
  /// flip it back off yourself.
  final bool success;

  final bool enabled;
  final bool readOnly;

  /// External error (e.g. "wrong code" from the server) — rendered in the
  /// group's error row.
  final String? errorText;

  /// Sync check on the JOINED code. Null → charset + exact-length.
  final String? Function(String?)? validator;

  /// Legacy single-box mode only.
  final FocusNode? focusNode;

  final ValidationMode validationMode;

  @override
  State<OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<OtpField>
    with SingleTickerProviderStateMixin {
  List<TextEditingController> _cells = const [];
  List<FocusNode> _nodes = const [];

  /// Horizontal shake played when the server rejects the code.
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  /// Guards the cell↔controller mirror from echoing.
  bool _syncing = false;

  /// Last code [OtpField.onCompleted] fired for — fires once per completion.
  String? _completedFor;

  /// Whether the user has edited (gates the incomplete error row).
  bool _touched = false;

  /// PIN reveal — mirrored across ALL cells from the last cell's eye toggle
  /// (each module field only owns its own obscure state).
  bool _revealed = false;

  /// Cell briefly scaled up to show where a tap-redirect landed.
  int? _pulseIndex;
  Timer? _pulseTimer;

  @override
  void initState() {
    super.initState();
    _buildCells();
    widget.controller.addListener(_onExternalText);
  }

  @override
  void didUpdateWidget(covariant OtpField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onExternalText);
      widget.controller.addListener(_onExternalText);
    }
    if (old.length != widget.length || old.mode != widget.mode) {
      _disposeCells();
      _buildCells();
    }
    if (old.obscure != widget.obscure) _revealed = false;
    // Server rejection just arrived → shake (and optionally wipe + refocus).
    if (widget.errorText != null && old.errorText != widget.errorText) {
      _rejectCode();
    }
  }

  /// Shake with the wrong code visible; wipe + refocus only when opted in.
  Future<void> _rejectCode() async {
    if (widget.boxed) await _shake.forward(from: 0);
    if (!mounted || !widget.autoClearOnError) return;
    for (final c in _cells) {
      c.clear();
    }
    _completedFor = null;
    setState(_pushToController);
    if (widget.boxed) _moveFocusLater(to: _nodes.first);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onExternalText);
    _disposeCells();
    _shake.dispose();
    _pulseTimer?.cancel();
    super.dispose();
  }

  void _buildCells() {
    _cells = List.generate(widget.length, (_) => TextEditingController());
    _nodes = List.generate(widget.length, (i) {
      final node = FocusNode();
      node.onKeyEvent = (n, event) => _onCellKey(i, event);
      // Focusing a filled cell selects it, so typing replaces.
      node.addListener(() {
        if (node.hasFocus && _cells[i].text.isNotEmpty) {
          _cells[i].selection = TextSelection(
            baseOffset: 0,
            extentOffset: _cells[i].text.length,
          );
        }
      });
      return node;
    });
    _seedFromController();
  }

  void _disposeCells() {
    for (final c in _cells) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
  }

  String get _joined => _cells.map((c) => c.text).join();

  bool get _complete => _joined.length == widget.length;

  // ── controller ↔ cells mirror ─────────────────────────────────────
  void _onExternalText() {
    if (_syncing) return;
    if (widget.controller.text != _joined) {
      setState(_seedFromController);
    }
  }

  void _seedFromController() {
    final code = widget.mode.clean(widget.controller.text);
    for (var i = 0; i < _cells.length; i++) {
      _cells[i].text = i < code.length ? code[i] : '';
    }
  }

  void _pushToController() {
    _syncing = true;
    widget.controller.text = _joined;
    _syncing = false;
    widget.onChanged?.call(_joined);
    if (_complete && _completedFor != _joined) {
      _completedFor = _joined;
      widget.onCompleted?.call(_joined);
    }
    if (!_complete) _completedFor = null;
  }

  // ── cell interaction ──────────────────────────────────────────────
  /// Focus moves are deferred to after the frame — requesting focus
  /// synchronously inside `onChanged` (while the field subtree is mid-
  /// rebuild) makes Material's InkWell focus listeners look up MediaQuery on
  /// a deactivated element ("Looking up a deactivated widget's ancestor").
  void _moveFocusLater({FocusNode? to, FocusNode? drop}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (to != null) to.requestFocus();
      if (drop != null) drop.unfocus();
    });
  }

  void _onCellChanged(int i, String value) {
    _touched = true;
    final cleaned = widget.mode.clean(value);

    if (cleaned.length > 1) {
      // Paste — a whole code goes into the cells from the START.
      final code = cleaned.length > widget.length
          ? cleaned.substring(0, widget.length)
          : cleaned;
      for (var j = 0; j < _cells.length; j++) {
        _cells[j].text = j < code.length ? code[j] : '';
      }
      _moveFocusLater(drop: _nodes[i]);
    } else {
      if (_cells[i].text != cleaned) {
        _cells[i].value = TextEditingValue(
          text: cleaned,
          selection: TextSelection.collapsed(offset: cleaned.length),
        );
      }
      if (cleaned.isNotEmpty) {
        // Advance; after the last cell, drop the keyboard.
        if (i < widget.length - 1) {
          _moveFocusLater(to: _nodes[i + 1]);
        } else {
          _moveFocusLater(drop: _nodes[i]);
        }
      }
    }
    setState(_pushToController);
  }

  /// Backspace on an EMPTY cell hops back and clears the previous cell
  /// (backspace inside a filled cell just deletes normally — no jump).
  KeyEventResult _onCellKey(int i, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }
    if (_cells[i].text.isNotEmpty || i == 0) return KeyEventResult.ignored;
    _touched = true;
    _cells[i - 1].clear();
    _moveFocusLater(to: _nodes[i - 1]);
    setState(_pushToController);
    return KeyEventResult.handled;
  }

  // ── validation (whole group) ──────────────────────────────────────
  String? get _groupError {
    if (widget.errorText != null) return widget.errorText;
    if (widget.validator != null) return widget.validator!(_joined);
    if (!_touched || widget.validationMode == ValidationMode.none) return null;
    if (_joined.isEmpty || _complete) return null;
    return widget.mode == OtpMode.digits
        ? ValidatorStrings.otpMustBeNDigits(widget.length)
        : OtpFieldStrings.mustBeNChars(widget.length);
  }

  /// Tapping an EMPTY cell with earlier empties jumps to the FIRST empty
  /// one — codes fill left-to-right, no gaps. Filled cells keep their tap
  /// (select-all → typing replaces). The landing cell PULSES briefly so the
  /// redirect reads as intentional, not as a missed tap.
  void _onCellTap(int i) {
    if (_cells[i].text.isNotEmpty) return;
    final first = _cells.indexWhere((c) => c.text.isEmpty);
    if (first < 0 || first == i) return;
    _moveFocusLater(to: _nodes[first]);
    _pulseTimer?.cancel();
    setState(() => _pulseIndex = first);
    _pulseTimer = Timer(const Duration(milliseconds: 160), () {
      if (mounted) setState(() => _pulseIndex = null);
    });
  }

  // ── build ─────────────────────────────────────────────────────────
  Widget _cell(BuildContext context, int i) {
    // Joined: flat seams, only the chain's outer corners rounded. Success:
    // paint the accepted-code border on every cell.
    // Tight symmetric inset — the module's default 12px horizontal padding
    // pushes the centered glyph off-center once the cell narrows.
    var style = const TextFieldStyle(
      contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 16),
    );
    if (widget.joined) {
      style = style.copyWith(
        borderRadius: edgeRadii(
          context,
          roundStart: i == 0,
          roundEnd: i == widget.length - 1,
        ),
      );
    }
    if (widget.success) {
      style = style.copyWith(
        border: TextFieldBorderStyle(
          base: TextFieldBorderSide(color: context.statusColors.success),
        ),
      );
    }
    final isLast = i == widget.length - 1;
    final field = GlobalTextFormField(
      controller: _cells[i],
      focusNode: _nodes[i],
      hint: widget.mode.cellHint,
      style: style,
      behavior: TextFieldBehavior(
        keyboardType: widget.mode.keyboard,
        textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
        textAlign: TextAlign.center,
        // The LAST cell keeps its widget-level obscure constant — its own
        // toggle manages the reveal internally (and the eye suffix is gated
        // on widget-level obscureText, so flipping it would drop the eye).
        // Siblings mirror the reveal via `_revealed`.
        obscureText: widget.obscure && (isLast || !_revealed),
        // iOS offers the Messages code in the keyboard bar; accepting it
        // types the whole code → the paste path distributes it.
        autofillHints: widget.enableSmsAutofill && widget.mode == OtpMode.digits
            ? const [AutofillHints.oneTimeCode]
            : null,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        autoDetectDirection: false,
      ),
      // Obscured cells: ONE eye toggle on the last cell only — its flips are
      // mirrored onto the siblings via onObscureToggled.
      features: TextFieldFeatures(showObscureToggle: isLast),
      callbacks: TextFieldCallbacks(
        onChanged: (v) => _onCellChanged(i, v),
        onSubmitted: isLast ? widget.onSubmitted : null,
        onTap: () => _onCellTap(i),
        onObscureToggled: isLast && widget.obscure
            ? (obscured) => setState(() => _revealed = !obscured)
            : null,
      ),
    );
    // Tap-redirect landing pulse.
    return AnimatedScale(
      scale: _pulseIndex == i ? 1.08 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: field,
    );
  }

  Widget _boxedBuild(BuildContext context) {
    final error = _groupError;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.identifier != null)
          Padding(
            padding: EdgeInsets.only(bottom: context.spacing.sm),
            child: Text(
              widget.identifier!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        AnimatedBuilder(
          animation: _shake,
          builder: (context, child) {
            // Damped horizontal wobble: 3 full oscillations fading out.
            final t = _shake.value;
            final dx = math.sin(t * math.pi * 6) * 8 * (1 - t);
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          // Codes are LTR digit/letter sequences — the cells fill
          // left-to-right even under an RTL locale (standard OTP UX). Only
          // the cell row is pinned; the identifier + error row stay ambient.
          // Cells build under the INNER context so the joined `edgeRadii`
          // rounds the correct outer corners.
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              // CENTRED. The row is capped at code width, so in a
              // stretched column it otherwise sat against the start
              // edge with the spare width trailing off the far side.
              builder: (cellContext) => Align(
                child: ConstrainedBox(
                  // Cells stay code-sized on wide screens; the obscured last
                  // cell carries the eye toggle → extra room.
                  constraints: BoxConstraints(
                    maxWidth: widget.length * 64 + (widget.obscure ? 36 : 0),
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < widget.length; i++) ...[
                        // Joined cells abut — squared inner corners = the seam.
                        if (i > 0 && !widget.joined)
                          SizedBox(width: context.spacing.sm),
                        Expanded(
                          // The eye-bearing last cell is ~1.6× — just enough
                          // room for the toggle without a hollow start gap.
                          flex: widget.obscure && i == widget.length - 1
                              ? 8
                              : 5,
                          child: _cell(cellContext, i),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: EdgeInsets.only(top: context.spacing.xs),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 14,
                  color: context.statusColors.error,
                ),
                SizedBox(width: context.spacing.xs),
                Flexible(
                  child: Text(
                    error,
                    style: TextStyle(
                      color: context.statusColors.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _singleBuild() {
    return GlobalTextFormField(
      controller: widget.controller,
      label: widget.label,
      identifier: widget.identifier,
      hint: widget.hint,
      focusNode: widget.focusNode,
      behavior: TextFieldBehavior(
        keyboardType: widget.mode.keyboard,
        textInputAction: TextInputAction.done,
        inputFormatters: [
          FilteringTextInputFormatter.allow(widget.mode._allow),
        ],
        maxLength: widget.length,
        textAlign: TextAlign.center,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        autoDetectDirection: false,
      ),
      validation: TextFieldValidation(
        validator:
            widget.validator ??
            (widget.mode == OtpMode.digits
                ? (v) => Validators.validateOtp(v, length: widget.length)
                : (v) {
                    final t = v ?? '';
                    if (t.isEmpty) return ValidatorStrings.otpCannotBeEmpty;
                    if (widget.mode.clean(t) != t ||
                        t.length != widget.length) {
                      return OtpFieldStrings.mustBeNChars(widget.length);
                    }
                    return null;
                  }),
        errorText: widget.errorText,
        mode: widget.validationMode,
      ),
      callbacks: TextFieldCallbacks(
        onChanged: (v) {
          widget.onChanged?.call(v);
          if (v.length == widget.length && _completedFor != v) {
            _completedFor = v;
            widget.onCompleted?.call(v);
          }
        },
        onSubmitted: widget.onSubmitted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.boxed ? _boxedBuild(context) : _singleBuild();
  }
}
