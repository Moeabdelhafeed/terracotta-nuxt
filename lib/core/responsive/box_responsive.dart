import 'package:flutter/widgets.dart';

import 'box_size_class.dart';
import 'fallback_resolver.dart';

/// Container query — classifies the *local* box (not the window) and
/// invokes the matching slot with smaller-first fallback. Pair with
/// [ResponsiveLayout] (page-level) for components that need to react
/// to their own constraints (e.g. cards inside a narrow side panel).
///
/// At least one slot must be non-null.
///
///     BoxResponsive(
///       narrow: (ctx, _, __) => _IconOnly(),
///       wide:   (ctx, _, __) => _IconAndLabel(),
///     )
class BoxResponsive extends StatelessWidget {
  const BoxResponsive({
    super.key,
    this.narrow,
    this.regular,
    this.wide,
    this.extraWide,
  });

  final BoxResponsiveBuilder? narrow;
  final BoxResponsiveBuilder? regular;
  final BoxResponsiveBuilder? wide;
  final BoxResponsiveBuilder? extraWide;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxClass = BoxSizeClass.fromWidth(constraints.maxWidth);
        final builder =
            resolveFallbackOrThrow<BoxSizeClass, BoxResponsiveBuilder>(
              buckets: BoxSizeClass.values,
              current: boxClass,
              slots: [narrow, regular, wide, extraWide],
              label: 'BoxResponsive',
            );
        return builder(context, constraints, boxClass);
      },
    );
  }
}

typedef BoxResponsiveBuilder =
    Widget Function(
      BuildContext context,
      BoxConstraints constraints,
      BoxSizeClass boxClass,
    );

/// Per-bucket value picker for container queries — same shape as
/// [ResponsiveValue] but keyed off [BoxSizeClass]. Resolve inside a
/// [LayoutBuilder] / [BoxResponsive] body.
@immutable
class BoxResponsiveValue<T extends Object> {
  const BoxResponsiveValue({
    this.narrow,
    this.regular,
    this.wide,
    this.extraWide,
  });

  final T? narrow;
  final T? regular;
  final T? wide;
  final T? extraWide;

  T resolveFor(BoxSizeClass boxClass) {
    return resolveFallbackOrThrow<BoxSizeClass, T>(
      buckets: BoxSizeClass.values,
      current: boxClass,
      slots: [narrow, regular, wide, extraWide],
      label: 'BoxResponsiveValue<$T>',
    );
  }

  T resolveForWidth(double width) => resolveFor(BoxSizeClass.fromWidth(width));

  T? resolveOrNull(BoxSizeClass boxClass) {
    return resolveFallback<BoxSizeClass, T>(
      buckets: BoxSizeClass.values,
      current: boxClass,
      slots: [narrow, regular, wide, extraWide],
    );
  }
}
