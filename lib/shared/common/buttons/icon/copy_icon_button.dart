// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Project imports:
import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/button_strings.dart';
import '../../../module/buttons/global_icon_button.dart';

/// Copy-to-clipboard button. Writes [value] to the system clipboard
/// on tap; swaps the icon to a checkmark for [feedbackDuration] to
/// confirm the copy landed.
class CopyIconButton extends StatefulWidget {
  const CopyIconButton({
    super.key,
    required this.value,
    this.onCopied,
    this.feedbackDuration = const Duration(seconds: 1),
    this.iconSize,
    this.color,
    this.tooltip,
    this.enabled = true,
    this.style,
  });

  final String value;

  /// Called after the clipboard write completes (e.g. to show a toast).
  final VoidCallback? onCopied;
  final Duration feedbackDuration;

  final double? iconSize;
  final Color? color;
  final String? tooltip;
  final bool enabled;
  final ButtonStateStyle? style;

  @override
  State<CopyIconButton> createState() => _CopyIconButtonState();
}

class _CopyIconButtonState extends State<CopyIconButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.value));
    if (!mounted) return;
    setState(() => _copied = true);
    widget.onCopied?.call();
    await Future<void>.delayed(widget.feedbackDuration);
    if (!mounted) return;
    setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final resolvedColor =
        widget.color ??
        (_copied ? context.statusColors.success : context.textColors.primary);
    final base = ButtonStateStyle(foregroundColor: resolvedColor);
    return GlobalIconButton(
      iconData: _copied ? Icons.check_rounded : Icons.copy_rounded,
      iconSize: widget.iconSize ?? 22,
      tooltip: widget.tooltip ?? ButtonStrings.copyTooltip,
      enabled: widget.enabled,
      onPressed: _copy,
      style: base.merge(widget.style),
    );
  }
}
