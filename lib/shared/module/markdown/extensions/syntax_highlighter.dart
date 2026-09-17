import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/common_strings.dart';
import '../../buttons/global_icon_button.dart';
import '../../toast/global_toast.dart';

/// Code block rendered with `flutter_highlight` syntax colorization.
/// Used when [MarkdownOptions.syntaxHighlight] is true.
class MarkdownSyntaxBlock extends StatelessWidget {
  const MarkdownSyntaxBlock({
    required this.body,
    required this.language,
    this.themeName,
    super.key,
  });

  final String body;
  final String language;

  /// Pass an explicit `flutter_highlight` theme name to override the
  /// auto-pick (atom-one-dark in dark mode, atom-one-light in light).
  /// Currently we only ship atom-one variants — extend to the full
  /// catalog by importing additional theme maps.
  final String? themeName;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tx = context.textColors;
    final bg = context.backgroundColors;
    final base = isDark ? atomOneDarkTheme : atomOneLightTheme;
    // `flutter_highlight` paints its theme's `root` background behind
    // the code text — that produces the inset light box inside our
    // outer container. Strip the root background so the outer
    // container's color shows through edge-to-edge.
    final theme = Map<String, TextStyle>.from(base);
    final root = theme['root'] ?? const TextStyle();
    theme['root'] = root.copyWith(backgroundColor: Colors.transparent);
    final lang = language.isEmpty ? 'plaintext' : language;

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
            decoration: BoxDecoration(
              color: bg.outlineVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 56, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: HighlightView(
                body,
                language: lang,
                theme: theme,
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.45,
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    lang,
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
