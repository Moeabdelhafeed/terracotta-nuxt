part of 'assets.dart';

class _Logos {
  const _Logos();

  /// App logo with a dark-mode variant.
  ///
  /// Demonstrates the [AssetRef] variant API — `byTheme` swaps in a
  /// dark-mode asset so the logo doesn't disappear on a dark
  /// background. Resolution is automatic at the call site:
  ///
  /// ```dart
  /// Image.asset(Assets.logos.main.resolve(context))
  /// // or
  /// Image.asset(context.asset(Assets.logos.main))
  /// ```
  ///
  /// Add more axes the same way: `bySize` for tablet/desktop logos,
  /// `byPlatform` for iOS-flavored marks, `byCombo` for exact
  /// (theme, size, platform) cells. See [AssetRef] for fallback order.
  AssetRef get main => const AssetRef(
    'assets/logos/logo.png',
    byTheme: {
      Brightness.dark: 'assets/logos/logo_dark.png',
    },
  );

  /// The vessel silhouette on its own, without the wordmark — what the
  /// splash draws. Exported from the design's `splash screen` frame.
  ///
  /// No `byTheme` variant: the design is light-only, and the dark logo
  /// that ships today is a recoloured stand-in rather than a drawn
  /// mark, so pointing at it here would swap in something nobody
  /// approved.
  AssetRef get mark => const AssetRef('assets/logos/logo_mark.png');
}
