import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../responsive/extensions.dart';
import '../../responsive/window_size_class.dart';
import '../../utils/assets/asset_utils.dart';

/// Platform identifier for asset variant resolution.
///
/// Web is a first-class platform — `kIsWeb` is checked before falling
/// through to the host's [TargetPlatform], because Flutter web reports
/// itself as android/ios/macos under the hood.
enum AppPlatform {
  ios,
  android,
  macos,
  windows,
  linux,
  fuchsia,
  web,
}

/// Composite key for [AssetRef.byCombo]. Any field may be `null` to mean
/// "any value on this axis", letting callers target a specific
/// (theme, size, platform) cell without enumerating every triple.
@immutable
class AssetVariantKey {
  const AssetVariantKey({this.theme, this.size, this.platform});

  final Brightness? theme;
  final WindowSizeClass? size;
  final AppPlatform? platform;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetVariantKey &&
          other.theme == theme &&
          other.size == size &&
          other.platform == platform;

  @override
  int get hashCode => Object.hash(theme, size, platform);
}

/// Asset reference with optional theme / size / platform variants.
///
/// Resolution priority (first match wins):
///   1. `byCombo[(theme, size, platform)]` — exact 3-axis
///   2. `byCombo[(theme, size, null)]`     — theme + size
///   3. `byCombo[(theme, null, platform)]` — theme + platform
///   4. `byCombo[(null, size, platform)]`  — size + platform
///   5. `byTheme[theme]`
///   6. `bySize[size]`
///   7. `byPlatform[platform]`
///   8. `defaultPath`
///
/// Theme outranks size and platform among single axes: a dark-mode asset
/// rendered against a dark background is the most expensive mismatch
/// (potentially invisible), where a wrong size is just a resolution miss.
@immutable
class AssetRef {
  const AssetRef(
    this.defaultPath, {
    this.byTheme,
    this.bySize,
    this.byPlatform,
    this.byCombo,
  });

  final String defaultPath;
  final Map<Brightness, String>? byTheme;
  final Map<WindowSizeClass, String>? bySize;
  final Map<AppPlatform, String>? byPlatform;
  final Map<AssetVariantKey, String>? byCombo;

  /// Pick the asset path for the current context.
  String resolve(BuildContext context) {
    final theme = Theme.of(context).brightness;
    final size =
        context.maybeBreakpoints?.windowSize ??
        WindowSizeClass.fromWidth(MediaQuery.sizeOf(context).width);
    final platform = _detectPlatform(context);

    final combo = byCombo;
    if (combo != null && combo.isNotEmpty) {
      final hit =
          combo[AssetVariantKey(
            theme: theme,
            size: size,
            platform: platform,
          )] ??
          combo[AssetVariantKey(theme: theme, size: size)] ??
          combo[AssetVariantKey(theme: theme, platform: platform)] ??
          combo[AssetVariantKey(size: size, platform: platform)];
      if (hit != null) return hit;
    }

    return byTheme?[theme] ??
        bySize?[size] ??
        byPlatform?[platform] ??
        defaultPath;
  }

  /// Resolve and warm Flutter's `ImageCache` for this asset.
  Future<void> precacheImage(BuildContext context) =>
      AssetUtils.preloadImages([resolve(context)], context);

  /// Resolve and load this Lottie composition (cached).
  Future<LottieComposition> lottie(BuildContext context) =>
      AssetUtils.loadLottie(resolve(context));
}

AppPlatform _detectPlatform(BuildContext context) {
  if (kIsWeb) return AppPlatform.web;
  switch (Theme.of(context).platform) {
    case TargetPlatform.iOS:
      return AppPlatform.ios;
    case TargetPlatform.android:
      return AppPlatform.android;
    case TargetPlatform.macOS:
      return AppPlatform.macos;
    case TargetPlatform.windows:
      return AppPlatform.windows;
    case TargetPlatform.linux:
      return AppPlatform.linux;
    case TargetPlatform.fuchsia:
      return AppPlatform.fuchsia;
  }
}

/// `context.asset(Assets.logos.main)` — resolve in one call.
extension AssetContextX on BuildContext {
  String asset(AssetRef ref) => ref.resolve(this);
}
