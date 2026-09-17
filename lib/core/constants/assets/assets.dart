/// Centralized asset references.
///
/// Each accessor returns an [AssetRef] — a path with optional variants
/// for theme (dark/light), window size class (compact … extraLarge),
/// and platform (iOS/Android/macOS/Windows/Linux/Fuchsia/Web). Resolve
/// at the call site:
///
/// ```dart
/// Image.asset(Assets.images.shoppingBags.resolve(context))
/// SvgPicture.asset(context.asset(Assets.svgs.arrowForward))
/// Lottie.asset(Assets.lotties.loading.resolve(context))
/// ```
///
/// Adding variants:
///
/// ```dart
/// AssetRef get logo => const AssetRef(
///       'assets/logos/logo.png',
///       byTheme: {Brightness.dark: 'assets/logos/logo_dark.png'},
///       bySize: {WindowSizeClass.expanded: 'assets/logos/logo_wide.png'},
///       byPlatform: {AppPlatform.ios: 'assets/logos/logo_ios.png'},
///       byCombo: {
///         AssetVariantKey(theme: Brightness.dark, size: WindowSizeClass.expanded,
///             platform: AppPlatform.android): 'assets/logos/logo_tablet_android_dark.png',
///       },
///     );
/// ```
library;

// Imports below are exposed to part files (Brightness, WindowSizeClass)
// so authoring variants in `assets/<category>.dart` doesn't need extra
// imports.
// ignore: unused_import
import 'package:flutter/material.dart';
// ignore: unused_import
import '../../responsive/window_size_class.dart';
import 'asset_ref.dart';

export 'asset_ref.dart';

part 'logos.dart';
part 'images.dart';
part 'icons.dart';
part 'svgs.dart';
part 'lotties.dart';
part 'gifs.dart';
part 'videos.dart';
part 'audios.dart';
part 'fonts.dart';

class Assets {
  const Assets._();

  static const logos = _Logos();
  static const images = _Images();
  static const icons = _Icons();
  static const svgs = _Svgs();
  static const lotties = _Lotties();
  static const gifs = _Gifs();
  static const videos = _Videos();
  static const audios = _Audios();
  static const fonts = _Fonts();
}
