import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// The floor for [GlobalMarkdown]'s look.
abstract final class MarkdownDefaults {
  /// Line height for body copy. Prose, not UI text.
  static const paragraphHeight = 1.55;

  /// Space between blocks.
  static const blockSpacing = 12.0;

  static const h1Padding = EdgeInsets.symmetric(vertical: 8);
  static const h2Padding = EdgeInsets.only(top: 16, bottom: 6);
  static const h3Padding = EdgeInsets.only(top: 12, bottom: 4);

  /// The bar down the side of a blockquote.
  static const blockquoteBarWidth = 3.0;
  static const blockquotePadding = EdgeInsets.fromLTRB(12, 8, 12, 8);

  /// How strongly the blockquote's own fill tints the surface behind
  /// it.
  static const blockquoteFillOpacity = 0.4;

  static const codeRadius = 8.0;
  static const codePadding = EdgeInsets.all(12);
  static const codeFillOpacity = 0.5;

  /// The font a code span is set in. Not a token: this is the one
  /// place in the app where the FACE carries meaning.
  static const codeFontFamily = 'monospace';

  static const tableCellPadding = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 6,
  );
  static const tableBorderWidth = 1.0;

  /// Padding around the spinner while a source is loading.
  static const loadingPadding = EdgeInsets.all(24);
}

/// How a [GlobalMarkdown] LOOKS.
///
/// Every field is nullable: unanswered means "ask the theme, then the
/// floor".
///
/// **It carries no colours and no text styles.** Both come from the
/// palette and the app's type scale at build time, so a document
/// tracks role, brightness, saturation and the reader's font size
/// like everything else. What lives here is the geometry the style
/// sheet used to hard-code — the spacings, the corner, the width of
/// the bar down a blockquote.
///
/// A house that wants more than that passes a whole
/// `MarkdownStyleSheet` through [styleSheetBuilder]; a caller that
/// wants it for one document passes `MarkdownOptions.styleSheet`.
@immutable
class MarkdownStyle {
  const MarkdownStyle({
    this.paragraphHeight,
    this.blockSpacing,
    this.h1Padding,
    this.h2Padding,
    this.h3Padding,
    this.blockquoteBarWidth,
    this.blockquotePadding,
    this.blockquoteFillOpacity,
    this.codeRadius,
    this.codePadding,
    this.codeFillOpacity,
    this.codeFontFamily,
    this.tableCellPadding,
    this.tableBorderWidth,
    this.loadingPadding,
    this.styleSheetBuilder,
  });

  /// The floor — the only place a compile-time constant lives.
  static const defaults = MarkdownStyle(
    paragraphHeight: MarkdownDefaults.paragraphHeight,
    blockSpacing: MarkdownDefaults.blockSpacing,
    h1Padding: MarkdownDefaults.h1Padding,
    h2Padding: MarkdownDefaults.h2Padding,
    h3Padding: MarkdownDefaults.h3Padding,
    blockquoteBarWidth: MarkdownDefaults.blockquoteBarWidth,
    blockquotePadding: MarkdownDefaults.blockquotePadding,
    blockquoteFillOpacity: MarkdownDefaults.blockquoteFillOpacity,
    codeRadius: MarkdownDefaults.codeRadius,
    codePadding: MarkdownDefaults.codePadding,
    codeFillOpacity: MarkdownDefaults.codeFillOpacity,
    codeFontFamily: MarkdownDefaults.codeFontFamily,
    tableCellPadding: MarkdownDefaults.tableCellPadding,
    tableBorderWidth: MarkdownDefaults.tableBorderWidth,
    loadingPadding: MarkdownDefaults.loadingPadding,
  );

  /// Tighter, for a document inside a card or a sheet rather than on
  /// a page of its own.
  static const compact = MarkdownStyle(
    blockSpacing: 8,
    h1Padding: EdgeInsets.symmetric(vertical: 4),
    h2Padding: EdgeInsets.only(top: 10, bottom: 4),
    h3Padding: EdgeInsets.only(top: 8, bottom: 2),
    codePadding: EdgeInsets.all(8),
    loadingPadding: EdgeInsets.all(12),
  );

  final double? paragraphHeight;
  final double? blockSpacing;
  final EdgeInsets? h1Padding;
  final EdgeInsets? h2Padding;
  final EdgeInsets? h3Padding;
  final double? blockquoteBarWidth;
  final EdgeInsets? blockquotePadding;
  final double? blockquoteFillOpacity;
  final double? codeRadius;
  final EdgeInsets? codePadding;
  final double? codeFillOpacity;
  final String? codeFontFamily;
  final EdgeInsets? tableCellPadding;
  final double? tableBorderWidth;
  final EdgeInsets? loadingPadding;

  /// The last word on the sheet.
  ///
  /// Handed the sheet this bag produced, so a house can adjust one
  /// thing without restating the other forty. Returning a fresh sheet
  /// replaces it outright.
  final MarkdownStyleSheetBuilder? styleSheetBuilder;

  /// Field-by-field: whatever `other` answers wins, and what it leaves
  /// null keeps this bag's answer.
  MarkdownStyle mergedWith(MarkdownStyle? other) {
    if (other == null) return this;
    return MarkdownStyle(
      paragraphHeight: other.paragraphHeight ?? paragraphHeight,
      blockSpacing: other.blockSpacing ?? blockSpacing,
      h1Padding: other.h1Padding ?? h1Padding,
      h2Padding: other.h2Padding ?? h2Padding,
      h3Padding: other.h3Padding ?? h3Padding,
      blockquoteBarWidth: other.blockquoteBarWidth ?? blockquoteBarWidth,
      blockquotePadding: other.blockquotePadding ?? blockquotePadding,
      blockquoteFillOpacity:
          other.blockquoteFillOpacity ?? blockquoteFillOpacity,
      codeRadius: other.codeRadius ?? codeRadius,
      codePadding: other.codePadding ?? codePadding,
      codeFillOpacity: other.codeFillOpacity ?? codeFillOpacity,
      codeFontFamily: other.codeFontFamily ?? codeFontFamily,
      tableCellPadding: other.tableCellPadding ?? tableCellPadding,
      tableBorderWidth: other.tableBorderWidth ?? tableBorderWidth,
      loadingPadding: other.loadingPadding ?? loadingPadding,
      styleSheetBuilder: other.styleSheetBuilder ?? styleSheetBuilder,
    );
  }

  MarkdownStyle copyWith({
    double? paragraphHeight,
    double? blockSpacing,
    EdgeInsets? h1Padding,
    EdgeInsets? h2Padding,
    EdgeInsets? h3Padding,
    double? blockquoteBarWidth,
    EdgeInsets? blockquotePadding,
    double? blockquoteFillOpacity,
    double? codeRadius,
    EdgeInsets? codePadding,
    double? codeFillOpacity,
    String? codeFontFamily,
    EdgeInsets? tableCellPadding,
    double? tableBorderWidth,
    EdgeInsets? loadingPadding,
    MarkdownStyleSheetBuilder? styleSheetBuilder,
  }) => MarkdownStyle(
    paragraphHeight: paragraphHeight ?? this.paragraphHeight,
    blockSpacing: blockSpacing ?? this.blockSpacing,
    h1Padding: h1Padding ?? this.h1Padding,
    h2Padding: h2Padding ?? this.h2Padding,
    h3Padding: h3Padding ?? this.h3Padding,
    blockquoteBarWidth: blockquoteBarWidth ?? this.blockquoteBarWidth,
    blockquotePadding: blockquotePadding ?? this.blockquotePadding,
    blockquoteFillOpacity: blockquoteFillOpacity ?? this.blockquoteFillOpacity,
    codeRadius: codeRadius ?? this.codeRadius,
    codePadding: codePadding ?? this.codePadding,
    codeFillOpacity: codeFillOpacity ?? this.codeFillOpacity,
    codeFontFamily: codeFontFamily ?? this.codeFontFamily,
    tableCellPadding: tableCellPadding ?? this.tableCellPadding,
    tableBorderWidth: tableBorderWidth ?? this.tableBorderWidth,
    loadingPadding: loadingPadding ?? this.loadingPadding,
    styleSheetBuilder: styleSheetBuilder ?? this.styleSheetBuilder,
  );

  @override
  bool operator ==(Object other) =>
      other is MarkdownStyle &&
      other.paragraphHeight == paragraphHeight &&
      other.blockSpacing == blockSpacing &&
      other.h1Padding == h1Padding &&
      other.h2Padding == h2Padding &&
      other.h3Padding == h3Padding &&
      other.blockquoteBarWidth == blockquoteBarWidth &&
      other.blockquotePadding == blockquotePadding &&
      other.blockquoteFillOpacity == blockquoteFillOpacity &&
      other.codeRadius == codeRadius &&
      other.codePadding == codePadding &&
      other.codeFillOpacity == codeFillOpacity &&
      other.codeFontFamily == codeFontFamily &&
      other.tableCellPadding == tableCellPadding &&
      other.tableBorderWidth == tableBorderWidth &&
      other.loadingPadding == loadingPadding &&
      other.styleSheetBuilder == styleSheetBuilder;

  @override
  int get hashCode => Object.hashAll([
    paragraphHeight,
    blockSpacing,
    h1Padding,
    h2Padding,
    h3Padding,
    blockquoteBarWidth,
    blockquotePadding,
    blockquoteFillOpacity,
    codeRadius,
    codePadding,
    codeFillOpacity,
    codeFontFamily,
    tableCellPadding,
    tableBorderWidth,
    loadingPadding,
    styleSheetBuilder,
  ]);
}

/// Signature for [MarkdownStyle.styleSheetBuilder].
typedef MarkdownStyleSheetBuilder =
    MarkdownStyleSheet Function(
      BuildContext context,
      MarkdownStyleSheet sheet,
    );
