import 'package:flutter/material.dart';

import '../../../../core/animations/animation_presets.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/tokens/extensions.dart';
import '../../../../core/utils/color_codec.dart';

/// Live color swatch shown as the prefix of the `ColorField` wrapper. Parses
/// the field's text in ANY supported format (hex / rgb / hsl …) and animates
/// the swatch fill.
class TextFieldColorPreview extends StatefulWidget {
  const TextFieldColorPreview({super.key, required this.controller});

  final TextEditingController controller;

  @override
  State<TextFieldColorPreview> createState() => _TextFieldColorPreviewState();
}

class _TextFieldColorPreviewState extends State<TextFieldColorPreview> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final color = ColorCodec.parseAny(widget.controller.text);
    final outline = context.backgroundColors.outline;
    return Padding(
      padding: EdgeInsets.all(context.spacing.sm),
      child: AnimatedContainer(
        duration: AppDurations.quick,
        width: context.iconSizes.lg,
        height: context.iconSizes.lg,
        decoration: BoxDecoration(
          color: color ?? outline.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(context.radii.xs),
          border: Border.all(color: outline.withValues(alpha: 0.4)),
        ),
      ),
    );
  }
}
