import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/extensions/theme_colors_extension.dart';
import '../../shared/module/marquee/global_marquee.dart';

/// The words in an app bar's title slot, in one widget for both bars.
///
/// It was a private `_MarqueeTitle` in each of them, which was fine
/// until the title started FLYING between the two: a flight shuttle
/// gets handed the widget it is carrying and has to be able to say
/// something about it, and it can say nothing about a private class in
/// a file it does not import.
///
/// ## The marquee has to stop while it travels
///
/// `GlobalMarquee` scrolls when its content does not fit, which is the
/// right rule standing still and the wrong one mid-air. A hero's box is
/// INTERPOLATED between the two ends, so a title flying from a short
/// word to a long one spends the flight inside a box narrower than
/// either — the text genuinely overflows, the marquee is right to say
/// so, and the reader watches a title that fits perfectly well scroll
/// itself for 300ms and then stop.
///
/// [still] is the same words with the marquee taken out, and it is what
/// `pageTitleShuttle` carries.
class PageBarTitle extends StatelessWidget {
  const PageBarTitle({
    required this.text,
    this.style,
    this.marquee = true,
    super.key,
  });

  final String text;

  /// Null takes the house title treatment — `titleMedium` w700 in the
  /// primary ink, which is what both bars ask for.
  final TextStyle? style;

  /// Whether it scrolls when it does not fit. Off in flight — see the
  /// class doc.
  final bool marquee;

  /// The same title, held still.
  PageBarTitle get still =>
      PageBarTitle(text: text, style: style, marquee: false, key: key);

  TextStyle? _style(BuildContext context) =>
      style ??
      context.textTheme.titleMedium?.copyWith(
        color: context.textColors.primary,
        fontWeight: FontWeight.w700,
      );

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      maxLines: 1,
      softWrap: false,
      // CLIPPED either way. An ellipsis appearing for the length of a
      // flight and then leaving again is the same flicker the marquee
      // was — and standing still the marquee is what handles a title
      // too long for the bar.
      overflow: TextOverflow.clip,
      style: _style(context),
    );

    if (!marquee) return label;

    // A workshop's name is the studio's to write, and «ورشة صناعة كوبك
    // مع احتفال» does not fit a bar that also holds a back arrow and
    // three actions. `GlobalMarquee` only moves when the content
    // actually overflows, so a short title costs nothing.
    return GlobalMarquee(semanticLabel: text, child: label);
  }
}
