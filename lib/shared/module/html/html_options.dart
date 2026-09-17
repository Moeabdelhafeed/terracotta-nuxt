import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

/// Per-instance config + builder slots for [GlobalHtml].
///
/// Cheap, near-universal features default ON (selectable text, link
/// tap, image cache). Heavier opt-ins (lightbox) default OFF.
@immutable
class HtmlOptions {
  const HtmlOptions({
    this.tapLinks = true,
    this.cacheNetworkImages = true,
    this.imageLightbox = false,
    this.style,
    this.styleOverrides,
    this.padding,
    this.shrinkWrap = true,
    this.physics,
    this.extensions,
    this.linkBuilder,
    this.imageBuilder,
    this.contentBuilder,
    this.onLinkTap,
  });

  final bool tapLinks;
  final bool cacheNetworkImages;

  /// Tap an `<img>` to open it fullscreen with pinch-to-zoom.
  final bool imageLightbox;

  /// Replace the auto-derived style map entirely.
  final Map<String, Style>? style;

  /// Merge with the auto-derived style map. Use this to tweak a few
  /// tags without losing the themed defaults.
  final Map<String, Style>? styleOverrides;

  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  /// Plug-in extensions — see `flutter_html`'s `extensions` slot for
  /// tag-level custom rendering / behaviour.
  final List<HtmlExtension>? extensions;

  /// Replace `<a>` rendering. Receives href + text; return any widget.
  final Widget Function(String href, String text)? linkBuilder;

  /// Replace `<img>` rendering. Bypasses cache + lightbox flags.
  final Widget Function(Uri uri, String? alt)? imageBuilder;

  /// Total override for the rendered tree. Receives the raw HTML
  /// body. When set, every other field is ignored.
  final Widget Function(BuildContext context, String body)? contentBuilder;

  /// Override link-tap behaviour. Default opens external URLs via
  /// `url_launcher`.
  final Future<void> Function(String href)? onLinkTap;

  HtmlOptions copyWith({
    bool? tapLinks,
    bool? cacheNetworkImages,
    bool? imageLightbox,
    Map<String, Style>? style,
    Map<String, Style>? styleOverrides,
    EdgeInsetsGeometry? padding,
    bool? shrinkWrap,
    ScrollPhysics? physics,
    List<HtmlExtension>? extensions,
    Widget Function(String, String)? linkBuilder,
    Widget Function(Uri, String?)? imageBuilder,
    Widget Function(BuildContext, String)? contentBuilder,
    Future<void> Function(String)? onLinkTap,
  }) {
    return HtmlOptions(
      tapLinks: tapLinks ?? this.tapLinks,
      cacheNetworkImages: cacheNetworkImages ?? this.cacheNetworkImages,
      imageLightbox: imageLightbox ?? this.imageLightbox,
      style: style ?? this.style,
      styleOverrides: styleOverrides ?? this.styleOverrides,
      padding: padding ?? this.padding,
      shrinkWrap: shrinkWrap ?? this.shrinkWrap,
      physics: physics ?? this.physics,
      extensions: extensions ?? this.extensions,
      linkBuilder: linkBuilder ?? this.linkBuilder,
      imageBuilder: imageBuilder ?? this.imageBuilder,
      contentBuilder: contentBuilder ?? this.contentBuilder,
      onLinkTap: onLinkTap ?? this.onLinkTap,
    );
  }
}
