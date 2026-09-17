import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Per-instance config + builder slots for [GlobalMarkdown].
///
/// All feature flags default to OFF except the cheap, always-useful
/// ones (selectable text, image cache, link tap). Heavy features
/// (syntax highlighting, math, lightbox) are opt-in to keep the
/// import graph + bundle small for plain-prose use.
@immutable
class MarkdownOptions {
  const MarkdownOptions({
    this.selectable = true,
    this.tapLinks = true,
    this.cacheNetworkImages = true,
    this.codeCopy = false,
    this.syntaxHighlight = false,
    this.syntaxHighlightTheme,
    this.math = false,
    this.callouts = false,
    this.autoAnchorHeadings = false,
    this.imageLightbox = false,
    this.parseFrontmatter = false,
    this.styleSheet,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.headingBuilder,
    this.codeBuilder,
    this.imageBuilder,
    this.linkBuilder,
    this.blockquoteBuilder,
    this.calloutBuilder,
    this.contentBuilder,
    this.onLinkTap,
    this.onMetadata,
    this.onHeadings,
  });

  // ─── Cheap features (default ON) ─────────────────────────

  final bool selectable;
  final bool tapLinks;
  final bool cacheNetworkImages;

  // ─── Opt-in features ─────────────────────────────────────

  /// Adds a "copy" button to fenced code blocks.
  final bool codeCopy;

  /// Wraps fenced code blocks with `flutter_highlight` per the
  /// fence's language tag (` ```dart ... ``` `). Falls back to plain
  /// rendering when language is unknown.
  final bool syntaxHighlight;

  /// Optional theme map name passed to `flutter_highlight`. Null =
  /// auto-pick from app brightness (atom-one-dark / atom-one-light).
  final String? syntaxHighlightTheme;

  /// Renders `$$ ... $$` blocks via `flutter_math_fork`.
  final bool math;

  /// Renders GitHub-style callouts: `> [!info]`, `> [!warning]`,
  /// `> [!tip]`, `> [!danger]`. The first line of any blockquote
  /// matching the syntax becomes a styled callout block.
  final bool callouts;

  /// Auto-emit `id` attributes on headings so a ToC widget or deep
  /// link can scroll to them. Surfaced via [onHeadings].
  final bool autoAnchorHeadings;

  /// Tap an `![alt](url)` image to open a fullscreen lightbox.
  final bool imageLightbox;

  /// Strip a YAML frontmatter block (`---\n...\n---`) from the start
  /// of the input, parse it as `Map<String, dynamic>`, and pass to
  /// [onMetadata]. The remaining markdown is rendered normally.
  final bool parseFrontmatter;

  // ─── Styling ─────────────────────────────────────────────

  /// Override the auto-derived style sheet entirely.
  final MarkdownStyleSheet? styleSheet;

  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  // ─── Builder slots ───────────────────────────────────────

  /// Replace heading rendering. Receives the level (1..6) and text.
  final Widget Function(int level, String text)? headingBuilder;

  /// Replace fenced code block rendering. Receives the language
  /// (may be empty) and the body. When [syntaxHighlight] or [codeCopy]
  /// are on and this slot is set, the slot wins — the caller composes.
  final Widget Function(String language, String body)? codeBuilder;

  /// Replace image rendering. Receives the resolved URI + alt text.
  final Widget Function(Uri uri, String? alt)? imageBuilder;

  /// Replace link rendering. Receives href + display text.
  final Widget Function(String href, String text)? linkBuilder;

  final Widget Function(Widget child)? blockquoteBuilder;

  /// Replace the callout block. Receives `[!type]` (without the
  /// brackets) and the body widget. Only invoked when [callouts] is
  /// true.
  final Widget Function(String type, Widget body)? calloutBuilder;

  /// Total override for the rendered tree. Receives the parsed
  /// markdown body (after frontmatter stripped). When set, every
  /// other field is ignored.
  final Widget Function(BuildContext context, String body)? contentBuilder;

  /// Override link-tap behaviour. Default opens external URLs via
  /// `url_launcher`.
  final Future<void> Function(String href)? onLinkTap;

  /// Called once per render with the parsed YAML frontmatter (or
  /// empty map when none). Only fires when [parseFrontmatter] is true.
  final void Function(Map<String, dynamic> metadata)? onMetadata;

  /// Called once per render with the heading outline — list of
  /// `(level, text, id)`. Use to build a ToC.
  final void Function(List<MarkdownHeading> headings)? onHeadings;

  MarkdownOptions copyWith({
    bool? selectable,
    bool? tapLinks,
    bool? cacheNetworkImages,
    bool? codeCopy,
    bool? syntaxHighlight,
    String? syntaxHighlightTheme,
    bool? math,
    bool? callouts,
    bool? autoAnchorHeadings,
    bool? imageLightbox,
    bool? parseFrontmatter,
    MarkdownStyleSheet? styleSheet,
    EdgeInsetsGeometry? padding,
    bool? shrinkWrap,
    ScrollPhysics? physics,
  }) {
    return MarkdownOptions(
      selectable: selectable ?? this.selectable,
      tapLinks: tapLinks ?? this.tapLinks,
      cacheNetworkImages: cacheNetworkImages ?? this.cacheNetworkImages,
      codeCopy: codeCopy ?? this.codeCopy,
      syntaxHighlight: syntaxHighlight ?? this.syntaxHighlight,
      syntaxHighlightTheme: syntaxHighlightTheme ?? this.syntaxHighlightTheme,
      math: math ?? this.math,
      callouts: callouts ?? this.callouts,
      autoAnchorHeadings: autoAnchorHeadings ?? this.autoAnchorHeadings,
      imageLightbox: imageLightbox ?? this.imageLightbox,
      parseFrontmatter: parseFrontmatter ?? this.parseFrontmatter,
      styleSheet: styleSheet ?? this.styleSheet,
      padding: padding ?? this.padding,
      shrinkWrap: shrinkWrap ?? this.shrinkWrap,
      physics: physics ?? this.physics,
      headingBuilder: headingBuilder,
      codeBuilder: codeBuilder,
      imageBuilder: imageBuilder,
      linkBuilder: linkBuilder,
      blockquoteBuilder: blockquoteBuilder,
      calloutBuilder: calloutBuilder,
      contentBuilder: contentBuilder,
      onLinkTap: onLinkTap,
      onMetadata: onMetadata,
      onHeadings: onHeadings,
    );
  }
}

/// Heading outline entry surfaced via [MarkdownOptions.onHeadings].
@immutable
class MarkdownHeading {
  const MarkdownHeading({
    required this.level,
    required this.text,
    required this.anchor,
  });

  final int level;
  final String text;

  /// Slugified anchor (lowercase, hyphenated). Stable for a given
  /// document so it can be used as a deep-link target.
  final String anchor;
}
