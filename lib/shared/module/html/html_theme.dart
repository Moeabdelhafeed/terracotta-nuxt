import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../../core/extensions/theme_colors_extension.dart';

/// Builds a theme-aware `Map<String, Style>` for [GlobalHtml].
///
/// Centralizes typography + color decisions so every HTML render in
/// the app inherits the active theme + saturation. Callers can pass
/// `HtmlOptions.styleOverrides` to tweak individual tags or
/// `HtmlOptions.style` to replace the whole map.
class HtmlTheme {
  const HtmlTheme._();

  static Map<String, Style> build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final tx = context.textColors;
    final btn = context.buttonsColors;
    final bg = context.backgroundColors;

    return {
      'body': Style(
        color: tx.primary,
        fontSize: FontSize(tt.bodyLarge?.fontSize ?? 16),
        lineHeight: const LineHeight(1.55),
        margin: Margins.zero,
      ),
      'h1': Style(
        color: tx.primary,
        fontSize: FontSize(tt.headlineMedium?.fontSize ?? 28),
        fontWeight: FontWeight.w700,
        margin: Margins.only(top: 8, bottom: 8),
      ),
      'h2': Style(
        color: tx.primary,
        fontSize: FontSize(tt.titleLarge?.fontSize ?? 22),
        fontWeight: FontWeight.w700,
        margin: Margins.only(top: 16, bottom: 6),
      ),
      'h3': Style(
        color: tx.primary,
        fontSize: FontSize(tt.titleMedium?.fontSize ?? 18),
        fontWeight: FontWeight.w600,
        margin: Margins.only(top: 12, bottom: 4),
      ),
      'h4': Style(
        color: tx.primary,
        fontSize: FontSize(tt.titleSmall?.fontSize ?? 16),
        fontWeight: FontWeight.w600,
      ),
      'p': Style(margin: Margins.only(bottom: 12)),
      'a': Style(
        color: btn.primary,
        textDecoration: TextDecoration.underline,
      ),
      'li': Style(color: tx.primary, padding: HtmlPaddings.only(bottom: 4)),
      'ul': Style(margin: Margins.only(bottom: 12)),
      'ol': Style(margin: Margins.only(bottom: 12)),
      'blockquote': Style(
        backgroundColor: bg.outlineVariant.withValues(alpha: 0.4),
        border: Border(left: BorderSide(color: btn.primary, width: 3)),
        padding: HtmlPaddings.symmetric(horizontal: 12, vertical: 8),
        fontStyle: FontStyle.italic,
        color: tx.secondary,
      ),
      'code': Style(
        fontFamily: 'monospace',
        backgroundColor: bg.outlineVariant.withValues(alpha: 0.5),
        padding: HtmlPaddings.symmetric(horizontal: 4, vertical: 2),
      ),
      'pre': Style(
        backgroundColor: bg.outlineVariant.withValues(alpha: 0.5),
        padding: HtmlPaddings.all(12),
        margin: Margins.only(bottom: 12),
      ),
      'hr': Style(
        border: Border(
          bottom: BorderSide(color: bg.outlineVariant),
        ),
        margin: Margins.symmetric(vertical: 16),
      ),
      'table': Style(
        border: Border.all(color: bg.outlineVariant),
      ),
      'th': Style(
        backgroundColor: bg.outlineVariant.withValues(alpha: 0.4),
        padding: HtmlPaddings.symmetric(horizontal: 8, vertical: 6),
        fontWeight: FontWeight.w700,
        color: tx.primary,
      ),
      'td': Style(
        padding: HtmlPaddings.symmetric(horizontal: 8, vertical: 6),
        color: tx.primary,
      ),
      'strong': Style(fontWeight: FontWeight.w700),
      'em': Style(fontStyle: FontStyle.italic),
    };
  }
}
