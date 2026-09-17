import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/localization/number_formatter.dart';
import '../../../core/localization/strings/module_strings.dart';
import 'indicator_style.dart';
import 'theme/indicator_theme.dart';

export 'indicator_style.dart';

/// "3 / 5" — the other way to say where a reader is.
///
/// A dot row does not scale: past a dozen pages the dots are either
/// too small to read or too wide to fit, and `scrollingDots` only
/// pushes that further out. A count says it in two characters at any
/// length.
///
/// It lived as a raw `Text` inside three separate modules — the page
/// view, the carousel and the carousel view — each with its own
/// `TextStyle(fontSize: 12)`, none of them themeable, and all three
/// writing ASCII digits, so Arabic read `3 / 5` beside `٣ / ٥`
/// everywhere else on the page.
class GlobalPageCounter extends StatelessWidget {
  const GlobalPageCounter({
    super.key,
    required this.count,
    required this.activeIndex,
    this.style,
    this.textStyle,
    this.separator = ' / ',
  }) : assert(count > 0, 'count must be > 0');

  final int count;

  /// 0-based. Out-of-range values clamp at render.
  final int activeIndex;

  /// Only the COLOUR is read from here — the count has no dots to
  /// size. It takes the same bag so a caller styling an indicator does
  /// not have to know which variant they landed on.
  final DotIndicatorStyle? style;

  /// Wins over the resolved colour and the theme's type.
  final TextStyle? textStyle;

  /// What sits between the two numbers.
  final String separator;

  @override
  Widget build(BuildContext context) {
    final resolved = (style ?? const DotIndicatorStyle()).resolve(context);
    final position = activeIndex.clamp(0, count - 1);

    final base = (context.textTheme.labelMedium ?? const TextStyle()).copyWith(
      color: resolved.activeColor,
      fontWeight: FontWeight.w600,
      // Digits that do not shift the row as they change — a
      // proportional `1` is narrower than a `0`, and the count
      // jittered as pages turned.
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Semantics(
      container: true,
      readOnly: true,
      label: IndicatorStrings.pageOf(position + 1, count),
      child: ExcludeSemantics(
        child: Text(
          // Through `AppNumbers`, like every other number in the app.
          '${AppNumbers.decimal(position + 1)}$separator'
          '${AppNumbers.decimal(count)}',
          style: base.merge(textStyle),
        ),
      ),
    );
  }
}
