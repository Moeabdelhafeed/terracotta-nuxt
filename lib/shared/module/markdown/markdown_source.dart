/// Sealed source variants for [GlobalMarkdown]. Each constructor
/// captures everything the loader needs to fetch the body.
sealed class MarkdownSource {
  const MarkdownSource();

  factory MarkdownSource.inline(String data) = MarkdownInline;
  factory MarkdownSource.asset(String path) = MarkdownAsset;
  factory MarkdownSource.url(String url) = MarkdownUrl;
  factory MarkdownSource.file(String path) = MarkdownFile;
  factory MarkdownSource.future(Future<String> Function() loader) =
      MarkdownFuture;
}

class MarkdownInline extends MarkdownSource {
  const MarkdownInline(this.data);
  final String data;
}

class MarkdownAsset extends MarkdownSource {
  const MarkdownAsset(this.path);
  final String path;
}

class MarkdownUrl extends MarkdownSource {
  const MarkdownUrl(this.url);
  final String url;
}

class MarkdownFile extends MarkdownSource {
  const MarkdownFile(this.path);
  final String path;
}

class MarkdownFuture extends MarkdownSource {
  const MarkdownFuture(this.loader);
  final Future<String> Function() loader;
}
