import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../../../core/extensions/theme_colors_extension.dart';

/// LaTeX block rendered via `flutter_math_fork`. Used when
/// [MarkdownOptions.math] is true. Display style is centered + has
/// horizontal scroll for long equations.
class MarkdownMathBlock extends StatelessWidget {
  const MarkdownMathBlock({required this.tex, this.inline = false, super.key});

  final String tex;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final tx = context.textColors;
    final widget = Math.tex(
      tex,
      mathStyle: inline ? MathStyle.text : MathStyle.display,
      textStyle: TextStyle(color: tx.primary, fontSize: 16),
      onErrorFallback: (err) => Text(
        '⚠ math: ${err.message}',
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontFamily: 'monospace',
          fontSize: 12,
        ),
      ),
    );
    if (inline) return widget;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: widget,
      ),
    );
  }
}

/// Detects display math blocks `$$...$$` in a markdown body and
/// returns the segments + math captures so [GlobalMarkdown] can splice
/// them into the rendered tree.
List<MathSegment> splitMathSegments(String input) {
  final segments = <MathSegment>[];
  final pattern = RegExp(r'\$\$([\s\S]+?)\$\$', multiLine: true);
  var cursor = 0;
  for (final m in pattern.allMatches(input)) {
    if (m.start > cursor) {
      segments.add(MathSegment.text(input.substring(cursor, m.start)));
    }
    segments.add(MathSegment.math(m.group(1)!.trim()));
    cursor = m.end;
  }
  if (cursor < input.length) {
    segments.add(MathSegment.text(input.substring(cursor)));
  }
  return segments;
}

@immutable
class MathSegment {
  const MathSegment._(this.kind, this.value);

  factory MathSegment.text(String s) => MathSegment._(MathSegmentKind.text, s);
  factory MathSegment.math(String s) => MathSegment._(MathSegmentKind.math, s);

  final MathSegmentKind kind;
  final String value;
}

enum MathSegmentKind { text, math }
