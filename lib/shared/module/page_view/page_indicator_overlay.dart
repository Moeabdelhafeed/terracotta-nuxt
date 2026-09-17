import 'package:flutter/material.dart';

import '../indicator/global_indicator.dart';
import '../indicator/global_page_counter.dart';
import 'page_view_models.dart';

/// The page family's indicator overlay, built on `GlobalDotIndicator`
/// and `GlobalPageCounter`.
///
/// ONE of these, used by `GlobalPageView` and `GlobalCarousel` alike.
/// The carousel had its own copy — the same thirty lines, its own
/// hard-coded pill radius — so the two drifted apart the moment either
/// was touched, which is exactly what happened to the A-Z scrubber
/// before it was extracted.
///
/// It honours the scroll axis, so a vertical deck gets a vertical
/// indicator without the caller asking.
class PageIndicatorOverlay extends StatelessWidget {
  const PageIndicatorOverlay({
    super.key,
    required this.style,
    required this.axis,
    required this.current,
    required this.total,
    required this.onTap,
    this.onHover,
    this.continuousIndex,
  });

  final ResolvedPageViewStyle style;
  final Axis axis;
  final int current;
  final int total;
  final ValueChanged<int>? onTap;
  final ValueChanged<int?>? onHover;

  /// Fractional page position (PageController.page). When non-null
  /// the underlying `GlobalDotIndicator` reads this directly instead
  /// of running its own snap animation, so the dots track the swipe
  /// 1:1.
  final double? continuousIndex;

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (style.indicatorStyle == PageIndicatorStyle.numbered) {
      // ONE counter, in the indicator module beside the dots. The
      // same seven lines lived in three modules, each with its own
      // font size and all three writing ASCII digits.
      content = GlobalPageCounter(
        count: total,
        activeIndex: current,
        style: style.dotStyle,
        textStyle: style.numberedActiveColor == null
            ? null
            : TextStyle(color: style.numberedActiveColor),
      );
    } else {
      content = GlobalDotIndicator(
        count: total,
        activeIndex: current,
        continuousIndex: continuousIndex,
        effect: style.indicatorEffect,
        style: style.dotStyle,
        axis: axis,
        onTap: onTap,
        onHover: onHover,
      );
    }
    if (style.indicatorBackground != null) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          color: style.indicatorBackground,
          borderRadius: BorderRadius.circular(style.indicatorPillRadius),
        ),
        child: Padding(
          padding: style.indicatorPillPadding,
          child: content,
        ),
      );
    }
    return content;
  }
}
