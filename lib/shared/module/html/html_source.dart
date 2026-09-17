/// Sealed source variants for [GlobalHtml]. Mirrors
/// [MarkdownSource] — same idea, different media type.
sealed class HtmlSource {
  const HtmlSource();

  factory HtmlSource.inline(String data) = HtmlInline;
  factory HtmlSource.asset(String path) = HtmlAsset;
  factory HtmlSource.url(String url) = HtmlUrl;
  factory HtmlSource.file(String path) = HtmlFile;
  factory HtmlSource.future(Future<String> Function() loader) = HtmlFuture;
}

class HtmlInline extends HtmlSource {
  const HtmlInline(this.data);
  final String data;
}

class HtmlAsset extends HtmlSource {
  const HtmlAsset(this.path);
  final String path;
}

class HtmlUrl extends HtmlSource {
  const HtmlUrl(this.url);
  final String url;
}

class HtmlFile extends HtmlSource {
  const HtmlFile(this.path);
  final String path;
}

class HtmlFuture extends HtmlSource {
  const HtmlFuture(this.loader);
  final Future<String> Function() loader;
}
