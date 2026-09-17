import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/button_strings.dart';
import '../../../module/buttons/global_icon_button.dart';

/// Voice-input toggle. Caller owns [isListening] + flips it in
/// [onPressed]. Pair with `SpeechToTextService` for the actual
/// recognition pipeline.
class MicIconButton extends StatelessWidget {
  const MicIconButton({
    super.key,
    required this.isListening,
    required this.onPressed,
    this.iconSize,
    this.color,
    this.tooltip,
    this.enabled = true,
    this.style,
  });

  final bool isListening;
  final VoidCallback onPressed;
  final double? iconSize;
  final Color? color;
  final String? tooltip;
  final bool enabled;
  final ButtonStateStyle? style;

  @override
  Widget build(BuildContext context) {
    final resolvedColor =
        color ??
        (isListening ? context.statusColors.error : context.textColors.primary);
    final base = ButtonStateStyle(foregroundColor: resolvedColor);
    return GlobalIconButton(
      iconData: isListening ? Icons.mic : Icons.mic_none_rounded,
      iconSize: iconSize ?? 22,
      tooltip:
          tooltip ??
          (isListening
              ? ButtonStrings.stopListeningTooltip
              : ButtonStrings.startVoiceInputTooltip),
      enabled: enabled,
      onPressed: onPressed,
      style: base.merge(style),
    );
  }
}
