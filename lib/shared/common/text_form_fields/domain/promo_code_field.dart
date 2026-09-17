import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/promo_field_strings.dart';
import '../../../../core/tokens/extensions.dart';
import '../../../module/buttons/global_filled_button.dart';
import '../../../module/buttons/global_icon_button.dart';
import '../../../module/text_field/global_text_field.dart';

/// What the server said about a submitted code — returned by
/// [PromoCodeField.onApply]. The server owns the copy ("20% off
/// applied" / "Code expired"); the field owns the choreography.
sealed class PromoOutcome {
  const PromoOutcome();
}

final class PromoSuccess extends PromoOutcome {
  const PromoSuccess(this.message);

  /// Shown as the success row while the code stays applied.
  final String message;
}

final class PromoFailure extends PromoOutcome {
  const PromoFailure(this.message);

  /// Shown as the error row; the code stays editable for correction.
  final String message;
}

/// The field's lifecycle, emitted via [PromoCodeField.onStateChanged] —
/// mirror it in a cubit to recalculate order totals.
sealed class PromoCodeState {
  const PromoCodeState();
}

final class PromoIdle extends PromoCodeState {
  const PromoIdle();
}

final class PromoApplying extends PromoCodeState {
  const PromoApplying(this.code);
  final String code;
}

final class PromoApplied extends PromoCodeState {
  const PromoApplied(this.code, this.message);
  final String code;
  final String message;
}

final class PromoFailed extends PromoCodeState {
  const PromoFailed(this.code, this.message);
  final String code;
  final String message;
}

/// Promo / coupon / referral code input — the checkout apply flow as a
/// state machine: `idle → applying → applied | failed`.
///
///  * Trailing APPLY button (Enter/done triggers it too), disabled until
///    [minLength] characters are in.
///  * Applying: the button swaps to the module's suffix spinner and the
///    field locks against edits mid-flight.
///  * Applied: success row with the server's message, field read-only,
///    the button becomes ✕ REMOVE (one code at a time — swap by
///    removing). Success haptic, gated by [enableHaptic].
///  * Failed: error row with the server's message; typing clears it.
///
/// Input is uppercased as typed, restricted to `A–Z 0–9 -`, pasted noise
/// stripped, capped at [maxLength]. No client-side code validation
/// beyond charset — codes are server-truth by definition.
///
/// ```dart
/// PromoCodeField(
///   controller: promo,
///   onApply: (code) async => switch (await api.applyPromo(code)) {
///     ApplyOk(:final label) => PromoSuccess(label),
///     ApplyErr(:final reason) => PromoFailure(reason),
///   },
///   onStateChanged: (s) => cubit.promoChanged(s),
/// )
/// ```
class PromoCodeField extends StatefulWidget {
  const PromoCodeField({
    super.key,
    required this.controller,
    required this.onApply,
    this.onStateChanged,
    this.onRemoved,
    this.onChanged,
    this.label,
    this.identifier,
    this.hint,
    this.enabled = true,
    this.readOnly = false,
    this.focusNode,
    this.minLength = 3,
    this.maxLength = 20,
    this.enableHaptic = true,
    this.initialAppliedCode,
    this.initialAppliedMessage,
    this.showPrefixIcon = true,
    this.messages = const [],
    this.style,
    this.sizing,
  }) : assert(
         initialAppliedCode == null || initialAppliedMessage != null,
         'initialAppliedCode needs initialAppliedMessage (the success row '
         'text to restore).',
       );

  final TextEditingController controller;

  /// Submit the code to the server. The returned [PromoOutcome] drives
  /// the applied / failed transition.
  final Future<PromoOutcome> Function(String code) onApply;

  /// Every lifecycle transition (idle / applying / applied / failed).
  final ValueChanged<PromoCodeState>? onStateChanged;

  /// The user removed an applied code (field is editable again).
  final VoidCallback? onRemoved;

  /// Raw text as displayed.
  final void Function(String)? onChanged;

  final String? label;
  final String? identifier;

  /// Null → localized "Enter promo code".
  final String? hint;

  final bool enabled;
  final bool readOnly;
  final FocusNode? focusNode;

  /// Apply stays disabled below this many characters.
  final int minLength;

  /// Hard input cap.
  final int maxLength;

  /// Success haptic on apply.
  final bool enableHaptic;

  /// Restore a checkout that already has a code applied — mounts
  /// directly in the applied state (with [initialAppliedMessage] as the
  /// success row).
  final String? initialAppliedCode;
  final String? initialAppliedMessage;

  final bool showPrefixIcon;

  /// Extra status rows below the field.
  final List<FieldMessage> messages;

  /// Per-call visual override (wins over the app-wide theme).
  final TextFieldStyle? style;

  /// Box geometry (height / width / fit-to-content / density).
  final TextFieldSizing? sizing;

  @override
  State<PromoCodeField> createState() => _PromoCodeFieldState();
}

enum _PromoPhase { idle, applying, applied, failed }

class _PromoCodeFieldState extends State<PromoCodeField> {
  _PromoPhase _phase = _PromoPhase.idle;

  /// Server copy for the current applied / failed state.
  String? _resultMessage;

  FocusNode? _internalFocus;

  FocusNode get _focus => widget.focusNode ?? (_internalFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    final restored = widget.initialAppliedCode;
    if (restored != null) {
      widget.controller.text = restored.toUpperCase();
      _phase = _PromoPhase.applied;
      _resultMessage = widget.initialAppliedMessage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _emit();
      });
    }
  }

  @override
  void dispose() {
    _internalFocus?.dispose();
    super.dispose();
  }

  String get _code => widget.controller.text.trim().toUpperCase();

  void _emit() {
    final cb = widget.onStateChanged;
    if (cb == null) return;
    cb(switch (_phase) {
      _PromoPhase.idle => const PromoIdle(),
      _PromoPhase.applying => PromoApplying(_code),
      _PromoPhase.applied => PromoApplied(_code, _resultMessage ?? ''),
      _PromoPhase.failed => PromoFailed(_code, _resultMessage ?? ''),
    });
  }

  Future<void> _apply() async {
    if (_phase == _PromoPhase.applying || _phase == _PromoPhase.applied) {
      return;
    }
    final code = _code;
    if (code.length < widget.minLength) {
      setState(() {
        _phase = _PromoPhase.failed;
        _resultMessage = PromoFieldStrings.empty;
      });
      _emit();
      return;
    }
    setState(() {
      _phase = _PromoPhase.applying;
      _resultMessage = null;
    });
    _emit();
    final outcome = await widget.onApply(code);
    if (!mounted) return;
    switch (outcome) {
      case PromoSuccess(:final message):
        setState(() {
          _phase = _PromoPhase.applied;
          _resultMessage = message;
        });
        if (widget.enableHaptic) unawaited(HapticFeedback.mediumImpact());
      case PromoFailure(:final message):
        setState(() {
          _phase = _PromoPhase.failed;
          _resultMessage = message;
        });
    }
    _emit();
  }

  void _remove() {
    widget.controller.clear();
    setState(() {
      _phase = _PromoPhase.idle;
      _resultMessage = null;
    });
    widget.onRemoved?.call();
    _emit();
    if (widget.enabled && !widget.readOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  bool get _locked =>
      _phase == _PromoPhase.applied || _phase == _PromoPhase.applying;

  TextFieldSuffix _suffix(BuildContext context) {
    switch (_phase) {
      case _PromoPhase.applying:
        return const TextFieldSuffix.loading();
      case _PromoPhase.applied:
        return TextFieldSuffix.widget(
          GlobalIconButton(
            iconData: Icons.close,
            iconSize: 20,
            tooltip: PromoFieldStrings.remove,
            semanticLabel: PromoFieldStrings.remove,
            enabled: widget.enabled,
            enforceMinTouchTarget: false,
            style: const ButtonStateStyle(width: 32, height: 32),
            onPressed: _remove,
          ),
        );
      case _PromoPhase.idle:
      case _PromoPhase.failed:
        final canApply =
            widget.enabled &&
            !widget.readOnly &&
            _code.length >= widget.minLength;
        // Compact filled pill — reads as the field's primary action (a
        // bare text button looked like a label); GlobalFilledButton's
        // disabled treatment carries while the code is too short. The
        // 32px style.height keeps the pill inside the suffix band
        // (ButtonSize.small alone is 36px).
        return TextFieldSuffix.widget(
          Padding(
            padding: EdgeInsetsDirectional.only(end: context.spacing.xs + 2),
            child: GlobalFilledButton(
              text: PromoFieldStrings.apply,
              shrinkWidth: true,
              size: ButtonSize.small,
              enabled: canApply,
              enforceMinTouchTarget: false,
              onPressed: _apply,
              style: ButtonStateStyle(
                height: 32,
                borderRadius: BorderRadius.circular(context.radii.full),
                padding: EdgeInsets.symmetric(horizontal: context.spacing.md),
                textStyle: context.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlobalTextFormField(
      controller: widget.controller,
      label: widget.label,
      identifier: widget.identifier,
      hint: widget.hint ?? PromoFieldStrings.hint,
      focusNode: _focus,
      style: widget.style ?? const TextFieldStyle(),
      sizing: widget.sizing ?? const TextFieldSizing(),
      messages: [
        ...widget.messages,
        if (_phase == _PromoPhase.applied && _resultMessage != null)
          FieldMessage.success(_resultMessage!),
      ],
      behavior: TextFieldBehavior(
        keyboardType: TextInputType.visiblePassword, // letters + digits
        textInputAction: TextInputAction.done,
        inputFormatters: [
          UpperCaseInputFormatter(),
          FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9-]')),
          LengthLimitingTextInputFormatter(widget.maxLength),
        ],
        enabled: widget.enabled,
        // Mid-flight and applied codes are not editable.
        readOnly: widget.readOnly || _locked,
        autoDetectDirection: false,
      ),
      validation: TextFieldValidation(
        // Server-driven: the failed message renders through the standard
        // error row; there is no client-side sync validator.
        errorText: _phase == _PromoPhase.failed ? _resultMessage : null,
        deferToParentForm: false,
      ),
      slots: TextFieldSlots(
        prefixIcon: widget.showPrefixIcon
            ? Padding(
                padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
                child: Icon(
                  Icons.local_offer_outlined,
                  color: context.iconColors.primary,
                ),
              )
            : null,
        suffix: _suffix(context),
      ),
      callbacks: TextFieldCallbacks(
        onChanged: (value) {
          widget.onChanged?.call(value);
          // Editing after a rejection clears the stale error; the Apply
          // button's enabled state tracks the length live.
          setState(() {
            if (_phase == _PromoPhase.failed) {
              _phase = _PromoPhase.idle;
              _resultMessage = null;
              _emit();
            }
          });
        },
        onSubmitted: (_) => _apply(),
      ),
    );
  }
}
