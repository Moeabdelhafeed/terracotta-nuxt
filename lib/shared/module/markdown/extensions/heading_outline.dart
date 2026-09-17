import '../markdown_options.dart';

/// Extract heading entries from a markdown body. Cheap scan — handles
/// both ATX (`# Heading`) and Setext (`Title\n===`) forms but not
/// inside fenced code blocks.
List<MarkdownHeading> extractHeadings(String body) {
  final lines = body.split('\n');
  final headings = <MarkdownHeading>[];
  var inFence = false;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trim();
    if (trimmed.startsWith('```')) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;
    final atx = RegExp(r'^(#{1,6})\s+(.+?)\s*#*\s*$').firstMatch(trimmed);
    if (atx != null) {
      final level = atx.group(1)!.length;
      final text = atx.group(2)!.trim();
      headings.add(
        MarkdownHeading(
          level: level,
          text: text,
          anchor: _slugify(text),
        ),
      );
      continue;
    }
    if (i + 1 < lines.length) {
      final next = lines[i + 1].trim();
      if (trimmed.isNotEmpty && next.isNotEmpty) {
        if (RegExp(r'^=+$').hasMatch(next)) {
          headings.add(
            MarkdownHeading(
              level: 1,
              text: trimmed,
              anchor: _slugify(trimmed),
            ),
          );
        } else if (RegExp(r'^-+$').hasMatch(next)) {
          headings.add(
            MarkdownHeading(
              level: 2,
              text: trimmed,
              anchor: _slugify(trimmed),
            ),
          );
        }
      }
    }
  }
  return headings;
}

String _slugify(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s-]'), '')
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'-+'), '-');
}
