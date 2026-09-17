import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../markdown_style.dart';

/// App-wide defaults for `GlobalMarkdown`.
///
/// The look of a document was a static builder — one function, the
/// same for every app that forks this template, with every spacing and
/// corner written into it. This is the hook that was missing.
@immutable
class GlobalMarkdownTheme extends ThemeExtension<GlobalMarkdownTheme> {
  const GlobalMarkdownTheme({this.style});

  final MarkdownStyle? style;

  static GlobalMarkdownTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalMarkdownTheme>();

  @override
  GlobalMarkdownTheme copyWith({MarkdownStyle? style}) =>
      GlobalMarkdownTheme(style: style ?? this.style);

  @override
  GlobalMarkdownTheme lerp(
    ThemeExtension<GlobalMarkdownTheme>? other,
    double t,
  ) {
    if (other is! GlobalMarkdownTheme) return this;
    return GlobalMarkdownTheme(style: _lerpStyle(style, other.style, t));
  }

  /// Measurements interpolate. The FONT FAMILY and the builder snap —
  /// half of one typeface is not a typeface.
  static MarkdownStyle? _lerpStyle(
    MarkdownStyle? a,
    MarkdownStyle? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    final pick = t < 0.5 ? a : b;
    return MarkdownStyle(
      paragraphHeight: lerpDouble(a?.paragraphHeight, b?.paragraphHeight, t),
      blockSpacing: lerpDouble(a?.blockSpacing, b?.blockSpacing, t),
      h1Padding: EdgeInsets.lerp(a?.h1Padding, b?.h1Padding, t),
      h2Padding: EdgeInsets.lerp(a?.h2Padding, b?.h2Padding, t),
      h3Padding: EdgeInsets.lerp(a?.h3Padding, b?.h3Padding, t),
      blockquoteBarWidth: lerpDouble(
        a?.blockquoteBarWidth,
        b?.blockquoteBarWidth,
        t,
      ),
      blockquotePadding: EdgeInsets.lerp(
        a?.blockquotePadding,
        b?.blockquotePadding,
        t,
      ),
      blockquoteFillOpacity: lerpDouble(
        a?.blockquoteFillOpacity,
        b?.blockquoteFillOpacity,
        t,
      ),
      codeRadius: lerpDouble(a?.codeRadius, b?.codeRadius, t),
      codePadding: EdgeInsets.lerp(a?.codePadding, b?.codePadding, t),
      codeFillOpacity: lerpDouble(a?.codeFillOpacity, b?.codeFillOpacity, t),
      codeFontFamily: pick?.codeFontFamily,
      tableCellPadding: EdgeInsets.lerp(
        a?.tableCellPadding,
        b?.tableCellPadding,
        t,
      ),
      tableBorderWidth: lerpDouble(
        a?.tableBorderWidth,
        b?.tableBorderWidth,
        t,
      ),
      loadingPadding: EdgeInsets.lerp(a?.loadingPadding, b?.loadingPadding, t),
      styleSheetBuilder: pick?.styleSheetBuilder,
    );
  }
}

extension MarkdownStyleResolve on MarkdownStyle {
  /// Stacks `caller > GlobalMarkdownTheme.style > MarkdownStyle.defaults`.
  ResolvedMarkdownStyle resolve(BuildContext context) {
    final merged = MarkdownStyle.defaults
        .mergedWith(GlobalMarkdownTheme.maybeOf(context)?.style)
        .mergedWith(this);
    const floor = MarkdownStyle.defaults;

    return ResolvedMarkdownStyle(
      paragraphHeight: merged.paragraphHeight ?? floor.paragraphHeight!,
      blockSpacing: merged.blockSpacing ?? floor.blockSpacing!,
      h1Padding: merged.h1Padding ?? floor.h1Padding!,
      h2Padding: merged.h2Padding ?? floor.h2Padding!,
      h3Padding: merged.h3Padding ?? floor.h3Padding!,
      blockquoteBarWidth:
          merged.blockquoteBarWidth ?? floor.blockquoteBarWidth!,
      blockquotePadding: merged.blockquotePadding ?? floor.blockquotePadding!,
      blockquoteFillOpacity:
          merged.blockquoteFillOpacity ?? floor.blockquoteFillOpacity!,
      codeRadius: merged.codeRadius ?? floor.codeRadius!,
      codePadding: merged.codePadding ?? floor.codePadding!,
      codeFillOpacity: merged.codeFillOpacity ?? floor.codeFillOpacity!,
      codeFontFamily: merged.codeFontFamily ?? floor.codeFontFamily!,
      tableCellPadding: merged.tableCellPadding ?? floor.tableCellPadding!,
      tableBorderWidth: merged.tableBorderWidth ?? floor.tableBorderWidth!,
      loadingPadding: merged.loadingPadding ?? floor.loadingPadding!,
      styleSheetBuilder: merged.styleSheetBuilder,
    );
  }
}

/// A [MarkdownStyle] with every question answered, and the sheet it
/// produces.
@immutable
class ResolvedMarkdownStyle {
  const ResolvedMarkdownStyle({
    required this.paragraphHeight,
    required this.blockSpacing,
    required this.h1Padding,
    required this.h2Padding,
    required this.h3Padding,
    required this.blockquoteBarWidth,
    required this.blockquotePadding,
    required this.blockquoteFillOpacity,
    required this.codeRadius,
    required this.codePadding,
    required this.codeFillOpacity,
    required this.codeFontFamily,
    required this.tableCellPadding,
    required this.tableBorderWidth,
    required this.loadingPadding,
    this.styleSheetBuilder,
  });

  final double paragraphHeight;
  final double blockSpacing;
  final EdgeInsets h1Padding;
  final EdgeInsets h2Padding;
  final EdgeInsets h3Padding;
  final double blockquoteBarWidth;
  final EdgeInsets blockquotePadding;
  final double blockquoteFillOpacity;
  final double codeRadius;
  final EdgeInsets codePadding;
  final double codeFillOpacity;
  final String codeFontFamily;
  final EdgeInsets tableCellPadding;
  final double tableBorderWidth;
  final EdgeInsets loadingPadding;
  final MarkdownStyleSheetBuilder? styleSheetBuilder;

  /// The sheet, built from this bag and the ambient palette.
  ///
  /// Colours and text styles are NOT bag fields: they come from
  /// `context.<group>Colors` and the app's type scale, so a document
  /// tracks role, brightness, saturation and the reader's font size.
  MarkdownStyleSheet sheet(BuildContext context) {
    final tt = context.textTheme;
    final tx = context.textColors;
    final bg = context.backgroundColors;
    final btn = context.buttonsColors;

    final built = MarkdownStyleSheet(
      p: tt.bodyLarge?.copyWith(color: tx.primary, height: paragraphHeight),
      h1: tt.headlineMedium?.copyWith(
        color: tx.primary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      h2: tt.titleLarge?.copyWith(
        color: tx.primary,
        fontWeight: FontWeight.w700,
      ),
      h3: tt.titleMedium?.copyWith(
        color: tx.primary,
        fontWeight: FontWeight.w600,
      ),
      h4: tt.titleSmall?.copyWith(
        color: tx.primary,
        fontWeight: FontWeight.w600,
      ),
      h5: tt.bodyLarge?.copyWith(
        color: tx.primary,
        fontWeight: FontWeight.w600,
      ),
      h6: tt.bodyMedium?.copyWith(
        color: tx.primary,
        fontWeight: FontWeight.w600,
      ),
      a: TextStyle(color: btn.primary, decoration: TextDecoration.underline),
      blockquote: tt.bodyMedium?.copyWith(
        color: tx.secondary,
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: BoxDecoration(
        color: bg.outlineVariant.withValues(alpha: blockquoteFillOpacity),
        border: Border(
          left: BorderSide(color: btn.primary, width: blockquoteBarWidth),
        ),
      ),
      blockquotePadding: blockquotePadding,
      // Inline `code` spans + fenced code text. NO `backgroundColor`
      // here — flutter_markdown applies this to chars inside fenced
      // blocks too, painting a second layer over the outer
      // `codeblockDecoration` and creating a visible inset rectangle
      // behind the text.
      code: tt.bodyMedium?.copyWith(
        fontFamily: codeFontFamily,
        color: tx.primary,
      ),
      codeblockDecoration: BoxDecoration(
        color: bg.outlineVariant.withValues(alpha: codeFillOpacity),
        borderRadius: BorderRadius.circular(codeRadius),
      ),
      codeblockPadding: codePadding,
      tableHead: tt.bodyMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: tx.primary,
      ),
      tableBody: tt.bodyMedium?.copyWith(color: tx.primary),
      tableBorder: TableBorder.all(
        color: bg.outlineVariant,
        width: tableBorderWidth,
      ),
      tableCellsPadding: tableCellPadding,
      listBullet: tt.bodyLarge?.copyWith(color: tx.primary),
      checkbox: tt.bodyLarge?.copyWith(color: btn.primary),
      h1Padding: h1Padding,
      h2Padding: h2Padding,
      h3Padding: h3Padding,
      blockSpacing: blockSpacing,
    );
    return styleSheetBuilder?.call(context, built) ?? built;
  }
}
