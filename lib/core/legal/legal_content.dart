import 'package:flutter/foundation.dart';

/// Whether the resolved legal payload is HTML (from the backend) or
/// Markdown (remote / cached / bundled). The screen picks the
/// renderer based on this discriminator.
enum LegalContentKind { html, markdown }

/// Where the rendered content came from. Used by the screen to show
/// a "served from cache" / "bundled" hint when relevant.
enum LegalContentOrigin { backend, remoteMarkdown, cache, bundled }

@immutable
class LegalContent {
  const LegalContent({
    required this.kind,
    required this.origin,
    required this.body,
  });

  final LegalContentKind kind;
  final LegalContentOrigin origin;
  final String body;

  bool get isHtml => kind == LegalContentKind.html;
  bool get isStale =>
      origin == LegalContentOrigin.cache ||
      origin == LegalContentOrigin.bundled;
}
