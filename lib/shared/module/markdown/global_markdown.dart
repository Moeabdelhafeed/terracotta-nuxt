import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/strings/common_strings.dart';
import '../../../core/utils/loggers/logger.dart';
import '../buttons/global_outlined_button.dart';
import '../empty_state/global_empty_state.dart';
import '../image/global_image.dart';
import '../progress/global_progress.dart';
import 'extensions/callout.dart';
import 'extensions/code_copy.dart';
import 'extensions/frontmatter.dart';
import 'extensions/heading_outline.dart';
import 'extensions/image_lightbox.dart';
import 'extensions/math_block.dart';
import 'extensions/syntax_highlighter.dart';
import 'markdown_loader.dart';
import 'markdown_options.dart';
import 'markdown_source.dart';
import 'markdown_style.dart';
import 'theme/markdown_theme_extension.dart';

export 'markdown_loader.dart'
    show MarkdownLoadResult, MarkdownLoaded, MarkdownLoadFailed;
export 'markdown_options.dart';
export 'markdown_source.dart';
export 'markdown_style.dart';
export 'theme/markdown_theme_extension.dart';

/// Themed, source-flexible markdown renderer.
///
/// Use the named constructors for source variants:
/// ```dart
/// GlobalMarkdown(data: '# Hello')
/// GlobalMarkdown.asset('assets/legal/tos.md')
/// GlobalMarkdown.url('https://example.com/changelog.md',
///   options: MarkdownOptions(syntaxHighlight: true, codeCopy: true))
/// ```
///
/// Customization tiers:
/// 1. Default — themed via app palette + typography
/// 2. App-level — pass [MarkdownOptions.styleSheet] for full sheet override
/// 3. Per-feature — toggle flags for code copy, syntax highlight, math, etc.
/// 4. Builder slots — `headingBuilder`, `codeBuilder`, `imageBuilder`, etc.
/// 5. Total override — `MarkdownOptions.contentBuilder` replaces everything
class GlobalMarkdown extends StatefulWidget {
  GlobalMarkdown({
    String? data,
    MarkdownSource? source,
    this.options = const MarkdownOptions(),
    this.style = const MarkdownStyle(),
    this.errorBuilder,
    this.semanticLabel,
    super.key,
  }) : assert(
         data != null || source != null,
         'Pass `data` or `source`',
       ),
       source = source ?? MarkdownSource.inline(data ?? '');

  GlobalMarkdown.asset(
    String path, {
    this.options = const MarkdownOptions(),
    this.style = const MarkdownStyle(),
    this.errorBuilder,
    this.semanticLabel,
    super.key,
  }) : source = MarkdownSource.asset(path);

  GlobalMarkdown.url(
    String url, {
    this.options = const MarkdownOptions(),
    this.style = const MarkdownStyle(),
    this.errorBuilder,
    this.semanticLabel,
    super.key,
  }) : source = MarkdownSource.url(url);

  GlobalMarkdown.file(
    String path, {
    this.options = const MarkdownOptions(),
    this.style = const MarkdownStyle(),
    this.errorBuilder,
    this.semanticLabel,
    super.key,
  }) : source = MarkdownSource.file(path);

  GlobalMarkdown.future(
    Future<String> Function() loader, {
    this.options = const MarkdownOptions(),
    this.style = const MarkdownStyle(),
    this.errorBuilder,
    this.semanticLabel,
    super.key,
  }) : source = MarkdownSource.future(loader);

  final MarkdownSource source;
  final MarkdownOptions options;

  /// How the document LOOKS — spacings, the code corner, the
  /// blockquote bar. Themeable through `GlobalMarkdownTheme`.
  final MarkdownStyle style;

  /// Drawn when the source could not be read.
  ///
  /// A failed load used to render NOTHING: the loader returned an
  /// empty string and empty renders `SizedBox.shrink()`, so a missing
  /// legal document and a blank one looked identical — on a screen
  /// whose whole job is to show that document. The default is the
  /// app's own error state with a Retry.
  final Widget Function(BuildContext context, Object error, VoidCallback retry)?
  errorBuilder;

  /// Names the document for a screen reader.
  final String? semanticLabel;

  @override
  State<GlobalMarkdown> createState() => _GlobalMarkdownState();
}

class _GlobalMarkdownState extends State<GlobalMarkdown> {
  final MarkdownLoader _loader = MarkdownLoader();
  late Future<MarkdownLoadResult> _future;

  /// An INLINE source, which is a string already in memory.
  ///
  /// It used to go through the loader and a `FutureBuilder` like every
  /// other source, so a widget that already had its body rendered a
  /// SPINNER for one frame and then the document. In a lazy list that
  /// is a height change on every remount: scroll a document off,
  /// scroll back, and the page moves under you.
  String? get _inline {
    final source = widget.source;
    return source is MarkdownInline ? source.data : null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _future = _loader.resolve(widget.source);

  /// Fetches again, past the cache.
  void _retry() {
    final source = widget.source;
    // Past the cache, or Retry re-reads the same failure.
    switch (source) {
      case MarkdownUrl(:final url):
        MarkdownLoader.invalidate('url:$url');
      case MarkdownAsset(:final path):
        MarkdownLoader.invalidate('asset:$path');
      case MarkdownFile(:final path):
        MarkdownLoader.invalidate('file:$path');
      case MarkdownInline():
      case MarkdownFuture():
        break;
    }
    setState(_load);
  }

  @override
  void didUpdateWidget(GlobalMarkdown old) {
    super.didUpdateWidget(old);
    // Re-fetch only when the payload behind the source actually
    // differs. Identity check would refetch on every parent rebuild
    // (most callers inline a fresh `MarkdownSource.inline(...)` /
    // `.asset(...)` factory call), causing a refetch loop.
    if (_sourceKey(widget.source) != _sourceKey(old.source)) {
      _load();
    }
  }

  static String _sourceKey(MarkdownSource s) => switch (s) {
    MarkdownInline(:final data) => 'inline:$data',
    MarkdownAsset(:final path) => 'asset:$path',
    MarkdownUrl(:final url) => 'url:$url',
    MarkdownFile(:final path) => 'file:$path',
    // Future loaders are opaque closures — fall back to identity.
    MarkdownFuture(:final loader) => 'future:${identityHashCode(loader)}',
  };

  /// A document is CONTENT. Naming it gives a reader something to land
  /// on, and `explicitChildNodes` keeps every link, heading and code
  /// block inside it reachable rather than flattening the lot into one
  /// string.
  Widget _wrap(Widget body) => widget.semanticLabel == null
      ? body
      : Semantics(
          label: widget.semanticLabel,
          explicitChildNodes: true,
          child: body,
        );

  @override
  Widget build(BuildContext context) {
    final rs = widget.style.resolve(context);
    final inline = _inline;
    if (inline != null) {
      return _wrap(
        inline.isEmpty
            ? const SizedBox.shrink()
            : _RenderedBody(raw: inline, options: widget.options, style: rs),
      );
    }
    return FutureBuilder<MarkdownLoadResult>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: rs.loadingPadding,
            child: Center(
              child: GlobalProgress.loading(type: ProgressType.circular),
            ),
          );
        }
        final result = snap.data;
        if (result is MarkdownLoadFailed) {
          return widget.errorBuilder?.call(context, result.error, _retry) ??
              _MarkdownError(onRetry: _retry);
        }
        final raw = result is MarkdownLoaded ? result.body : '';
        if (raw.isEmpty) return const SizedBox.shrink();
        return _wrap(
          _RenderedBody(raw: raw, options: widget.options, style: rs),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Renderer — runs once per resolved string.
// ─────────────────────────────────────────────────────────────

class _RenderedBody extends StatefulWidget {
  const _RenderedBody({
    required this.raw,
    required this.options,
    required this.style,
  });

  final String raw;
  final MarkdownOptions options;
  final ResolvedMarkdownStyle style;

  @override
  State<_RenderedBody> createState() => _RenderedBodyState();
}

class _RenderedBodyState extends State<_RenderedBody> {
  late String _body;

  @override
  void initState() {
    super.initState();
    _process();
  }

  @override
  void didUpdateWidget(_RenderedBody old) {
    super.didUpdateWidget(old);
    // Re-process only when content or *behaviour-changing* options
    // actually flip. Comparing the whole `MarkdownOptions` by identity
    // re-triggers on every parent rebuild (callers usually inline a
    // fresh options instance), which would loop:
    //   process → onMetadata callback → caller setState → rebuild
    //   → new options identity → process → ...
    final relevantChanged =
        widget.raw != old.raw ||
        widget.options.parseFrontmatter != old.options.parseFrontmatter ||
        widget.options.autoAnchorHeadings != old.options.autoAnchorHeadings;
    if (relevantChanged) _process();
  }

  void _process() {
    var body = widget.raw;
    Map<String, dynamic>? metadata;
    List<MarkdownHeading>? headings;
    if (widget.options.parseFrontmatter) {
      final r = parseFrontmatter(body);
      body = r.body;
      metadata = r.metadata;
    }
    if (widget.options.autoAnchorHeadings) {
      headings = extractHeadings(body);
    }
    _body = body;
    // Defer callbacks to post-frame — `_process()` runs from initState
    // / didUpdateWidget, so a synchronous setState in the callback
    // would land mid-build and trip "setState() during build".
    if (metadata != null || headings != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (metadata != null) widget.options.onMetadata?.call(metadata);
        if (headings != null) widget.options.onHeadings?.call(headings);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final opts = widget.options;
    if (opts.contentBuilder != null) {
      return opts.contentBuilder!(context, _body);
    }
    if (opts.math) {
      return _renderWithMath(context, _body, opts, widget.style);
    }
    return _renderMarkdown(context, _body, opts, widget.style);
  }
}

// ─────────────────────────────────────────────────────────────
// Render paths
// ─────────────────────────────────────────────────────────────

Widget _renderMarkdown(
  BuildContext context,
  String body,
  MarkdownOptions opts,
  ResolvedMarkdownStyle style, {

  /// Distinguishes one segment from another on the MATH path, where
  /// several of these sit side by side in one `Column`.
  int slot = 0,
}) {
  // A caller's whole sheet still wins outright; otherwise the bag
  // builds one against the live palette.
  final styleSheet = opts.styleSheet ?? style.sheet(context);
  // `MarkdownBody` memoises its parsed tree against the previous
  // widget's `data` + `styleSheet`. Flipping a feature flag
  // (`codeCopy`, `syntaxHighlight`, `callouts`, `imageLightbox`,
  // `cacheNetworkImages`) changes our `builders` / `sizedImageBuilder`
  // but not `data`, so the cached tree wins and the toggle appears
  // to have no effect until hot-restart. Keying on the flag combo
  // forces a fresh State on each flip.
  //
  // The [slot] is part of it. Without it the math path built several
  // `MarkdownBody`s with the SAME key as siblings in one Column —
  // "Duplicate keys found", every frame, on any document mixing text
  // and `\$\$…\$\$`.
  final featureKey = ValueKey<int>(
    Object.hash(
      slot,
      opts.codeCopy,
      opts.syntaxHighlight,
      opts.syntaxHighlightTheme,
      opts.callouts,
      opts.imageLightbox,
      opts.cacheNetworkImages,
      opts.tapLinks,
      opts.selectable,
    ),
  );
  return MarkdownBody(
    key: featureKey,
    data: body,
    styleSheet: styleSheet,
    selectable: opts.selectable,
    onTapLink: opts.tapLinks
        ? (_, href, _) => _handleLink(href, opts.onLinkTap)
        : null,
    builders: _builders(context, opts),
    sizedImageBuilder: _sizedImageBuilderFor(opts),
    blockSyntaxes: const [],
  );
}

/// Math-aware path: split the body into `$$...$$` blocks and plain
/// markdown segments, render each separately so the math block can
/// be a real `Math.tex` widget instead of a code-fence.
Widget _renderWithMath(
  BuildContext context,
  String body,
  MarkdownOptions opts,
  ResolvedMarkdownStyle style,
) {
  final segments = splitMathSegments(body);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < segments.length; i++)
        segments[i].kind == MathSegmentKind.text
            ? _renderMarkdown(context, segments[i].value, opts, style, slot: i)
            : MarkdownMathBlock(
                key: ValueKey<int>(i),
                tex: segments[i].value,
              ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────
// Builder dispatchers
// ─────────────────────────────────────────────────────────────

Map<String, MarkdownElementBuilder> _builders(
  BuildContext context,
  MarkdownOptions opts,
) {
  final builders = <String, MarkdownElementBuilder>{};
  if (opts.codeBuilder != null || opts.codeCopy || opts.syntaxHighlight) {
    builders['code'] = _CodeBuilder(opts: opts);
  }
  if (opts.callouts || opts.calloutBuilder != null) {
    builders['blockquote'] = _BlockquoteBuilder(opts: opts);
  }
  return builders;
}

class _CodeBuilder extends MarkdownElementBuilder {
  _CodeBuilder({required this.opts});

  final MarkdownOptions opts;

  @override
  Widget? visitElementAfter(element, preferredStyle) {
    final lang = (element.attributes['class'] ?? '').replaceFirst(
      'language-',
      '',
    );
    final body = element.textContent;
    // Inline `code` (single line, no newline) — let default styling
    // win. Only fenced multi-line blocks get the fancy treatment.
    if (!body.contains('\n')) return null;

    if (opts.codeBuilder != null) return opts.codeBuilder!(lang, body);
    if (opts.syntaxHighlight) {
      return MarkdownSyntaxBlock(
        body: body,
        language: lang,
        themeName: opts.syntaxHighlightTheme,
      );
    }
    if (opts.codeCopy) {
      return MarkdownCodeBlock(body: body, language: lang);
    }
    return null;
  }
}

class _BlockquoteBuilder extends MarkdownElementBuilder {
  _BlockquoteBuilder({required this.opts});

  final MarkdownOptions opts;

  @override
  Widget? visitElementAfter(element, preferredStyle) {
    if (!opts.callouts && opts.calloutBuilder == null) return null;
    final text = element.textContent;
    final detected = detectCallout(text);
    if (detected == null) return null;
    final body = MarkdownBody(data: detected.body);
    if (opts.calloutBuilder != null) {
      return opts.calloutBuilder!(detected.type.name, body);
    }
    return MarkdownCallout(type: detected.type, child: body);
  }
}

// ─────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────

MarkdownSizedImageBuilder? _sizedImageBuilderFor(MarkdownOptions opts) {
  if (opts.imageBuilder == null &&
      !opts.cacheNetworkImages &&
      !opts.imageLightbox) {
    return null;
  }
  return (config) {
    final uri = config.uri;
    if (opts.imageBuilder != null) {
      return opts.imageBuilder!(uri, config.alt);
    }
    if (opts.imageLightbox) {
      return MarkdownLightboxImage(
        uri: uri,
        alt: config.alt,
        cache: opts.cacheNetworkImages,
      );
    }
    return GlobalImage.n(
      uri.toString(),
      // The alt text IS the picture's name — markdown carries one and
      // the raw `Image.network` this replaced threw it away.
      semanticLabel: config.alt,
      cacheNetwork: opts.cacheNetworkImages,
    );
  };
}

Future<void> _handleLink(
  String? href,
  Future<void> Function(String)? override,
) async {
  if (href == null || href.isEmpty) return;
  if (href.toLowerCase().startsWith('javascript:')) return;
  if (override != null) {
    await override(href);
    return;
  }
  final uri = Uri.tryParse(href);
  if (uri == null) return;
  try {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  } catch (e) {
    Logger.m.w('[Markdown] link tap failed: $e');
  }
}

/// The default failure state.
///
/// The app's own empty state with a Retry — not a bare string, and
/// certainly not the blank screen a failed load used to produce.
class _MarkdownError extends StatelessWidget {
  const _MarkdownError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => GlobalEmptyState(
    title: CommonStrings.somethingWentWrong,
    icon: Icons.description_outlined,
    variant: EmptyStateVariant.compact,
    primaryAction: GlobalOutlinedButton(
      text: CommonStrings.retry,
      icon: Icons.refresh_rounded,
      shrinkWidth: true,
      onPressed: onRetry,
    ),
  );
}
