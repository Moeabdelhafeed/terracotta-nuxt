import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/loggers/logger.dart';
import '../image/global_image.dart';
import '../markdown/extensions/image_lightbox.dart';
import '../progress/global_progress.dart';
import 'html_loader.dart';
import 'html_options.dart';
import 'html_source.dart';
import 'html_theme.dart';

/// Themed, source-flexible HTML renderer. Mirrors `GlobalMarkdown`
/// but keeps the surface tight — HTML payloads are rare and most
/// styling already lives in the source markup.
///
/// Use the named constructors for source variants:
/// ```dart
/// GlobalHtml(data: '<h1>Hi</h1>')
/// GlobalHtml.asset('assets/legal/tos.html')
/// GlobalHtml.url('https://api.example.com/privacy')
/// ```
class GlobalHtml extends StatefulWidget {
  GlobalHtml({
    String? data,
    HtmlSource? source,
    this.options = const HtmlOptions(),
    super.key,
  }) : assert(
         data != null || source != null,
         'Pass `data` or `source`',
       ),
       source = source ?? HtmlSource.inline(data ?? '');

  GlobalHtml.asset(
    String path, {
    this.options = const HtmlOptions(),
    super.key,
  }) : source = HtmlSource.asset(path);

  GlobalHtml.url(
    String url, {
    this.options = const HtmlOptions(),
    super.key,
  }) : source = HtmlSource.url(url);

  GlobalHtml.file(
    String path, {
    this.options = const HtmlOptions(),
    super.key,
  }) : source = HtmlSource.file(path);

  GlobalHtml.future(
    Future<String> Function() loader, {
    this.options = const HtmlOptions(),
    super.key,
  }) : source = HtmlSource.future(loader);

  final HtmlSource source;
  final HtmlOptions options;

  @override
  State<GlobalHtml> createState() => _GlobalHtmlState();
}

class _GlobalHtmlState extends State<GlobalHtml> {
  final HtmlLoader _loader = HtmlLoader();
  late Future<String> _future;

  @override
  void initState() {
    super.initState();
    _future = _loader.resolve(widget.source);
  }

  @override
  void didUpdateWidget(GlobalHtml old) {
    super.didUpdateWidget(old);
    if (widget.source != old.source) {
      _future = _loader.resolve(widget.source);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: GlobalProgress.loading(type: ProgressType.circular),
            ),
          );
        }
        final raw = snap.data ?? '';
        if (raw.isEmpty) return const SizedBox.shrink();
        return _RenderedHtml(raw: raw, options: widget.options);
      },
    );
  }
}

class _RenderedHtml extends StatelessWidget {
  const _RenderedHtml({required this.raw, required this.options});

  final String raw;
  final HtmlOptions options;

  @override
  Widget build(BuildContext context) {
    if (options.contentBuilder != null) {
      return options.contentBuilder!(context, raw);
    }
    final base = options.style ?? HtmlTheme.build(context);
    final mergedStyle = options.styleOverrides == null
        ? base
        : {...base, ...options.styleOverrides!};

    final extensions = <HtmlExtension>[
      if (options.imageBuilder != null ||
          options.cacheNetworkImages ||
          options.imageLightbox)
        TagExtension(
          tagsToExtend: const {'img'},
          builder: _imageExtensionBuilder,
        ),
      if (options.linkBuilder != null)
        TagExtension(
          tagsToExtend: const {'a'},
          builder: _linkExtensionBuilder,
        ),
      ...?options.extensions,
    ];

    return Html(
      data: raw,
      style: mergedStyle,
      extensions: extensions,
      onLinkTap: options.tapLinks
          ? (href, _, _) => _handleLink(href, options.onLinkTap)
          : null,
    );
  }

  Widget _imageExtensionBuilder(ExtensionContext ctx) {
    final src = ctx.attributes['src'] ?? '';
    final alt = ctx.attributes['alt'];
    final uri = Uri.tryParse(src);
    if (uri == null) return const SizedBox.shrink();
    if (options.imageBuilder != null) {
      return options.imageBuilder!(uri, alt);
    }
    if (options.imageLightbox) {
      return MarkdownLightboxImage(
        uri: uri,
        alt: alt,
        cache: options.cacheNetworkImages,
      );
    }
    return GlobalImage.n(
      uri.toString(),
      semanticLabel: alt,
      cacheNetwork: options.cacheNetworkImages,
    );
  }

  Widget _linkExtensionBuilder(ExtensionContext ctx) {
    final href = ctx.attributes['href'] ?? '';
    final text = ctx.element?.text ?? '';
    return options.linkBuilder!(href, text);
  }
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
    Logger.m.w('[Html] link tap failed: $e');
  }
}
