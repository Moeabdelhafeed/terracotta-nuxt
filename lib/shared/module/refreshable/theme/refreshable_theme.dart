import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../refreshable_models.dart';

/// App-wide defaults for [GlobalRefreshable].
///
/// The rebrand hook: set the spinner's colour, its pill and how long it
/// lingers once here, and every pull-to-refresh in the app follows.
@immutable
class GlobalRefreshableTheme extends ThemeExtension<GlobalRefreshableTheme> {
  const GlobalRefreshableTheme({this.style});

  final RefreshableStyle? style;

  static GlobalRefreshableTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalRefreshableTheme>();

  @override
  GlobalRefreshableTheme copyWith({RefreshableStyle? style}) =>
      GlobalRefreshableTheme(style: style ?? this.style);

  @override
  GlobalRefreshableTheme lerp(
    ThemeExtension<GlobalRefreshableTheme>? other,
    double t,
  ) {
    if (other is! GlobalRefreshableTheme) return this;
    return GlobalRefreshableTheme(style: _lerpStyle(style, other.style, t));
  }

  /// Continuous fields interpolate; discrete ones SNAP at the midpoint —
  /// half a Cupertino spinner is not a thing, and neither is half a
  /// haptic.
  static RefreshableStyle? _lerpStyle(
    RefreshableStyle? a,
    RefreshableStyle? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    final pick = t < 0.5 ? a : b;
    return RefreshableStyle(
      color: Color.lerp(a?.color, b?.color, t),
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      displacement: lerpDouble(a?.displacement, b?.displacement, t),
      edgeOffset: lerpDouble(a?.edgeOffset, b?.edgeOffset, t),
      strokeWidth: lerpDouble(a?.strokeWidth, b?.strokeWidth, t),
      hapticThreshold: lerpDouble(a?.hapticThreshold, b?.hapticThreshold, t),
      illustrationOffset: lerpDouble(
        a?.illustrationOffset,
        b?.illustrationOffset,
        t,
      ),
      customTriggerExtent: lerpDouble(
        a?.customTriggerExtent,
        b?.customTriggerExtent,
        t,
      ),
      variant: pick?.variant,
      minShowDuration: pick?.minShowDuration,
      illustrationFade: pick?.illustrationFade,
      customSettle: pick?.customSettle,
      minRefreshInterval: pick?.minRefreshInterval,
      enableHaptic: pick?.enableHaptic,
      respectReducedMotion: pick?.respectReducedMotion,
    );
  }
}

extension RefreshableStyleResolve on RefreshableStyle {
  /// Stacks `caller > GlobalRefreshableTheme.style > defaults`, then
  /// fills the colours from `context.<group>Colors` so the indicator
  /// tracks the active palette, role and brightness.
  ResolvedRefreshableStyle resolve(BuildContext context) {
    final merged = RefreshableStyle.defaults
        .mergedWith(GlobalRefreshableTheme.maybeOf(context)?.style)
        .mergedWith(this);
    const floor = RefreshableStyle.defaults;

    final respect = merged.respectReducedMotion ?? floor.respectReducedMotion!;
    final still = respect && MediaQuery.disableAnimationsOf(context);

    return ResolvedRefreshableStyle(
      variant: _concrete(merged.variant ?? floor.variant!),
      // The PALETTE, not `Theme.of(context).colorScheme` — a rebrand
      // has to move the spinner with everything else.
      color: merged.color ?? context.primaryColors.primary,
      // The pill sits ABOVE the page, so it takes the container colour
      // rather than the background one.
      backgroundColor:
          merged.backgroundColor ?? context.backgroundColors.cardBackground,
      displacement: merged.displacement ?? floor.displacement!,
      edgeOffset: merged.edgeOffset ?? floor.edgeOffset!,
      strokeWidth: merged.strokeWidth ?? floor.strokeWidth!,
      // NOT zeroed by reduced motion. It is a floor on how long the
      // indicator is READABLE, not an animation — a reader who has
      // asked for less motion has not asked to be told less.
      minShowDuration: merged.minShowDuration ?? floor.minShowDuration!,
      hapticThreshold: merged.hapticThreshold ?? floor.hapticThreshold!,
      illustrationOffset:
          merged.illustrationOffset ?? floor.illustrationOffset!,
      illustrationFade: still
          ? Duration.zero
          : (merged.illustrationFade ?? floor.illustrationFade!),
      customSettle: still
          ? Duration.zero
          : (merged.customSettle ?? floor.customSettle!),
      customTriggerExtent:
          merged.customTriggerExtent ?? floor.customTriggerExtent!,
      minRefreshInterval:
          merged.minRefreshInterval ?? floor.minRefreshInterval!,
      enableHaptic: merged.enableHaptic ?? floor.enableHaptic!,
      still: still,
    );
  }

  /// Resolves [RefreshableVariant.adaptive] against the platform, ONCE,
  /// so nothing downstream has to ask again.
  RefreshableVariant _concrete(RefreshableVariant variant) {
    if (variant != RefreshableVariant.adaptive) return variant;
    final platform = defaultTargetPlatform;
    return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS
        ? RefreshableVariant.cupertino
        : RefreshableVariant.material;
  }
}
