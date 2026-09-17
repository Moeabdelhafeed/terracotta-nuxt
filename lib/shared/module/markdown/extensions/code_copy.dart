import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/common_strings.dart';
import '../../buttons/global_icon_button.dart';
import '../../toast/global_toast.dart';

/// Wraps a code block with a copy-to-clipboard button overlay.
class MarkdownCodeBlock extends StatelessWidget {
  const MarkdownCodeBlock({
    required this.body,
    this.language,
    super.key,
  });

  final String body;
  final String? language;

  @override
  Widget build(BuildContext context) {
    final tx = context.textColors;
    final bg = context.backgroundColors;
    // CODE IS LTR, in every language.
    //
    // A fenced block inherited the app's direction, so in Arabic
    // `void main() {}` rendered right-aligned and reversed — and the
    // copy button, pinned to the visual right, landed on top of the
    // first characters. Source is not prose: its direction is a
    // property of the language it is written in, not of the reader.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bg.outlineVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                body,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.45,
                  color: tx.primary,
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if ((language ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      language!,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w600,
                        color: tx.secondary,
                      ),
                    ),
                  ),
                GlobalIconButton(
                  tooltip: CommonStrings.copy,
                  iconData: Icons.copy_rounded,
                  onPressed: _copy,
                  iconSize: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: body));
    GlobalToast.s(CommonStrings.copiedToClipboard);
  }
}
