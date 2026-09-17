import 'package:flutter/widgets.dart';

import 'extensions.dart';
import 'fallback_resolver.dart';
import 'window_size_class.dart';

/// Per-bucket value picker with the same fallback semantics as
/// [ResponsiveLayout] — but for plain data (column counts, paddings,
/// font sizes, durations …) instead of widgets.
///
/// `const`-friendly. Use either as a literal:
///
///     const cols = ResponsiveValue<int>(compact: 1, medium: 2, expanded: 4);
///     final value = cols.resolve(context);
///
/// …or via the inline ergonomic [BuildContext.responsive].
@immutable
class ResponsiveValue<T extends Object> {
  const ResponsiveValue({
    this.compact,
    this.medium,
    this.expanded,
    this.large,
    this.extraLarge,
  });

  final T? compact;
  final T? medium;
  final T? expanded;
  final T? large;
  final T? extraLarge;

  /// Resolve against [context]'s [WindowSizeClass].
  T resolve(BuildContext context) {
    return resolveFallbackOrThrow<WindowSizeClass, T>(
      buckets: WindowSizeClass.values,
      current: context.windowSize,
      slots: [compact, medium, expanded, large, extraLarge],
      label: 'ResponsiveValue<$T>',
    );
  }

  /// Resolve directly against a [WindowSizeClass] (no [BuildContext]).
  T resolveFor(WindowSizeClass windowSize) {
    return resolveFallbackOrThrow<WindowSizeClass, T>(
      buckets: WindowSizeClass.values,
      current: windowSize,
      slots: [compact, medium, expanded, large, extraLarge],
      label: 'ResponsiveValue<$T>',
    );
  }

  /// Like [resolve] but returns `null` instead of throwing when every
  /// slot is null.
  T? resolveOrNull(BuildContext context) {
    return resolveFallback<WindowSizeClass, T>(
      buckets: WindowSizeClass.values,
      current: context.windowSize,
      slots: [compact, medium, expanded, large, extraLarge],
    );
  }
}

/// Inline helper — equivalent to building a [ResponsiveValue] and calling
/// `.resolve(context)`, but cheaper to read at the call-site.
extension ResponsiveValueContext on BuildContext {
  T responsive<T extends Object>({
    T? compact,
    T? medium,
    T? expanded,
    T? large,
    T? extraLarge,
  }) {
    return ResponsiveValue<T>(
      compact: compact,
      medium: medium,
      expanded: expanded,
      large: large,
      extraLarge: extraLarge,
    ).resolve(this);
  }

  T? responsiveOrNull<T extends Object>({
    T? compact,
    T? medium,
    T? expanded,
    T? large,
    T? extraLarge,
  }) {
    return ResponsiveValue<T>(
      compact: compact,
      medium: medium,
      expanded: expanded,
      large: large,
      extraLarge: extraLarge,
    ).resolveOrNull(this);
  }
}
