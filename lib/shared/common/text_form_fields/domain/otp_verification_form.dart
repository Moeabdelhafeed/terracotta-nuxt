import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/otp_form_strings.dart';
import '../../../../core/tokens/extensions.dart';
import '../../../module/buttons/global_text_button.dart';
import 'otp_field.dart';

/// The OTP-verification composite — [OtpField] + the surrounding
/// ceremony every verify screen re-implements:
///
///  * "Code sent to {destination}" line (pass the MASKED destination —
///    `+962 79 *** 4567` — the form never masks for you).
///  * Resend row with a live cooldown ("Resend in 28s"), disabled until
///    it expires. [onResend] may be async — the button shows a spinner
///    and the cooldown restarts AFTER it completes.
///  * [onCompleted] fires when the last cell lands (auto-submit).
///  * [errorText] / [success] drive the field's error / success visuals
///    from your verify call; error auto-clears the cells by default.
///
/// ```dart
/// OtpVerificationForm(
///   destination: maskedPhone,
///   errorText: state.error,
///   success: state.verified,
///   onCompleted: (code) => cubit.verify(code),
///   onResend: () => cubit.resend(),
/// )
/// ```
class OtpVerificationForm extends StatefulWidget {
  const OtpVerificationForm({
    super.key,
    this.controller,
    this.length = 6,
    this.destination,
    this.onCompleted,
    this.onChanged,
    this.onResend,
    this.resendCooldown = const Duration(seconds: 30),
    this.autoStartCooldown = true,
    this.errorText,
    this.success = false,
    this.autoClearOnError = true,
    this.enableSmsAutofill = true,
    this.boxed = true,
    this.joined = false,
    this.obscure = false,
    this.enabled = true,
    this.identifier,
  });

  /// Optional — the form owns one when absent.
  final TextEditingController? controller;

  final int length;

  /// MASKED display string ('+962 79 *** 4567' / 'j***@x.co'). Null hides
  /// the sent-to line.
  final String? destination;

  /// The full code, fired when the last cell lands.
  final ValueChanged<String>? onCompleted;

  final ValueChanged<String>? onChanged;

  /// Re-send the code. Async supported — button spins, cooldown restarts
  /// after completion. Null hides the resend row.
  final Future<void> Function()? onResend;

  /// Lockout between resends.
  final Duration resendCooldown;

  /// Start the cooldown on mount (the first code was just sent).
  final bool autoStartCooldown;

  /// Verify-failure message under the field (from your server call).
  final String? errorText;

  /// Verified — cells flip to the success state.
  final bool success;

  /// Clear all cells when [errorText] lands, ready for retype.
  final bool autoClearOnError;

  /// SMS one-time-code autofill (Android retriever / iOS keyboard chip).
  final bool enableSmsAutofill;

  /// Cell rendering — see [OtpField].
  final bool boxed;
  final bool joined;
  final bool obscure;

  final bool enabled;

  /// Header above the cells.
  final String? identifier;

  @override
  State<OtpVerificationForm> createState() => _OtpVerificationFormState();
}

class _OtpVerificationFormState extends State<OtpVerificationForm> {
  TextEditingController? _owned;
  Timer? _ticker;
  int _secondsLeft = 0;
  bool _resending = false;

  TextEditingController get _controller =>
      widget.controller ?? (_owned ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    if (widget.autoStartCooldown && widget.onResend != null) _startCooldown();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _owned?.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _ticker?.cancel();
    setState(() => _secondsLeft = widget.resendCooldown.inSeconds);
    if (_secondsLeft == 0) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsLeft = _secondsLeft - 1);
      if (_secondsLeft <= 0) t.cancel();
    });
  }

  Future<void> _resend() async {
    if (_resending || _secondsLeft > 0) return;
    setState(() => _resending = true);
    try {
      await widget.onResend?.call();
    } finally {
      if (mounted) {
        setState(() => _resending = false);
        _startCooldown();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.destination != null) ...[
          Text(
            OtpFormStrings.sentTo(widget.destination!),
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.textColors.secondary,
            ),
          ),
          SizedBox(height: context.spacing.md),
        ],
        OtpField(
          controller: _controller,
          length: widget.length,
          identifier: widget.identifier,
          boxed: widget.boxed,
          joined: widget.joined,
          obscure: widget.obscure,
          enableSmsAutofill: widget.enableSmsAutofill,
          autoClearOnError: widget.autoClearOnError,
          errorText: widget.errorText,
          success: widget.success,
          enabled: widget.enabled && !widget.success,
          onChanged: widget.onChanged,
          onCompleted: widget.onCompleted,
        ),
        if (widget.onResend != null) ...[
          SizedBox(height: context.spacing.sm),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                OtpFormStrings.noCode,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.textColors.secondary,
                ),
              ),
              SizedBox(width: context.spacing.xs),
              GlobalTextButton(
                text: _secondsLeft > 0
                    ? OtpFormStrings.resendIn(_secondsLeft)
                    : OtpFormStrings.resend,
                enabled: _secondsLeft == 0 && !_resending && widget.enabled,
                isLoading: _resending,
                shrinkWidth: true,
                enforceMinTouchTarget: false,
                onPressed: _resend,
              ),
            ],
          ),
        ],
      ],
    );
  }
}
