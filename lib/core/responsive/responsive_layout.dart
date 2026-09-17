import 'package:flutter/widgets.dart';

import 'extensions.dart';
import 'fallback_resolver.dart';
import 'window_size_class.dart';

/// Picks a [WidgetBuilder] from a set of named per-bucket slots, with
/// "smaller-first" fallback (see [resolveFallback]).
///
/// At least one slot must be non-`null` — asserted at runtime.
///
/// Example:
///
///     ResponsiveLayout(
///       compact:  (_) => _PhoneScaffold(),
///       expanded: (_) => _TwoPaneScaffold(),
///     );
///
/// At `medium` width: no `medium` slot → walk down → `compact` matches.
/// At `large` width: no `large` slot → walk down → `expanded` matches.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    this.compact,
    this.medium,
    this.expanded,
    this.large,
    this.extraLarge,
  });

  final WidgetBuilder? compact;
  final WidgetBuilder? medium;
  final WidgetBuilder? expanded;
  final WidgetBuilder? large;
  final WidgetBuilder? extraLarge;

  @override
  Widget build(BuildContext context) {
    final builder = resolveFallbackOrThrow<WindowSizeClass, WidgetBuilder>(
      buckets: WindowSizeClass.values,
      current: context.windowSize,
      slots: [compact, medium, expanded, large, extraLarge],
      label: 'ResponsiveLayout',
    );
    return builder(context);
  }
}
