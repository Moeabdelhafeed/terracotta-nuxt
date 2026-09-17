import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../_shared/terracotta_cta_style.dart';

/// "اعادة ارسال الرمز" — the secondary action under the verify button,
/// with its own cooldown.
///
/// The countdown lives HERE rather than on each OTP screen. Both the
/// registration and the reset step draw the same control with the same
/// clock, and a timer duplicated across two `State`s is two places to
/// forget to cancel.
///
/// Same bar as the primary CTA (full width, 52 tall, radius 11) on a
/// wash of the brand brown instead of the solid, so it reads as the
/// quieter of the two without becoming a bare line of text. The design
/// gives the fill as `#81261A` at 9% — a hair off the `#81341A` chrome,
/// and kept as drawn rather than snapped to the palette.
class OtpResendButton extends StatefulWidget {
  const OtpResendButton({
    required this.cooldown,
    required this.onResend,
    super.key,
  });

  /// How long the clock runs before the control becomes tappable.
  final Duration cooldown;

  /// Called on a tap once the clock has run out. The clock restarts
  /// itself immediately after.
  final VoidCallback onResend;

  /// `#81261a17` from the design.
  static const Color fill = Color(0x1781261A);

  @override
  State<OtpResendButton> createState() => _OtpResendButtonState();
}

class _OtpResendButtonState extends State<OtpResendButton> {
  Timer? _ticker;
  late Duration _left = widget.cooldown;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
    _ticker?.cancel();
    setState(() => _left = widget.cooldown);
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_left.inSeconds <= 1) {
        t.cancel();
        setState(() => _left = Duration.zero);
      } else {
        setState(() => _left -= const Duration(seconds: 1));
      }
    });
  }

  bool get _ready => _left == Duration.zero;

  /// `m:ss`. Digits are localized by the number formatter, so Arabic
  /// gets ١:٤٥ rather than 1:45 without this getter knowing about it.
  String get _clock {
    final m = _left.inMinutes;
    final s = (_left.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _onTap() {
    widget.onResend();
    _start();
  }

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(kTerracottaCtaRadius);
    final label = _ready
        ? AuthStrings.otpResend
        : AuthStrings.otpResendTimer(_clock);

    return Semantics(
      button: true,
      enabled: _ready,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: OtpResendButton.fill,
        borderRadius: shape,
        child: InkWell(
          onTap: _ready ? _onTap : null,
          borderRadius: shape,
          child: SizedBox(
            height: kTerracottaCtaHeight,
            width: double.infinity,
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: kTerracottaCtaLabelSize,
                  // Dimmed while the clock runs, so "not yet" is visible
                  // without the label changing colour entirely.
                  color: context.primaryColors.primary.withValues(
                    alpha: _ready ? 1 : 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
