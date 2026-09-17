import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lottie/lottie.dart';

/// Asset preloading + Lottie composition cache.
///
/// Flutter already caches images ([ImageCache]), parsed SVGs (via
/// `flutter_svg`), and bundle loads ([rootBundle]). This service only
/// exists for the two things Flutter does **not** give you:
///
/// 1. **Startup preloading** — warm [ImageCache] and parse Lotties before
///    first paint so animations/images don't stutter in.
/// 2. **Lottie composition cache** — the `lottie` package re-parses JSON
///    on every `Lottie.asset(...)` call; caching the parsed
///    [LottieComposition] makes reuse instant.
///
/// Per-asset accessors live on [AssetRef] — `Assets.images.foo.precacheImage(ctx)`
/// and `Assets.lotties.bar.lottie(ctx)`.
class AssetUtils {
  AssetUtils._();

  static final Map<String, LottieComposition> _lottieCache = {};

  /// Warm Flutter's [ImageCache] for a list of asset paths. Needs a
  /// valid [BuildContext] — call from your root widget's first-frame
  /// callback, not from `main()`.
  static Future<void> preloadImages(
    List<String> paths,
    BuildContext context,
  ) async {
    await Future.wait(
      paths.map((p) => precacheImage(AssetImage(p), context)),
    );
  }

  /// Parse and cache Lottie compositions. Safe to call from `main()` —
  /// no [BuildContext] required.
  static Future<void> preloadLotties(List<String> paths) async {
    await Future.wait(paths.map(loadLottie));
  }

  /// Load a Lottie composition, caching the parsed result for future calls.
  static Future<LottieComposition> loadLottie(String path) async {
    final cached = _lottieCache[path];
    if (cached != null) return cached;
    try {
      final data = await rootBundle.load(path);
      final composition = await LottieComposition.fromByteData(data);
      _lottieCache[path] = composition;
      return composition;
    } catch (e) {
      debugPrint('AssetUtils: loadLottie failed for $path: $e');
      rethrow;
    }
  }

  /// Drop all cached Lottie compositions.
  static void clearLottieCache() => _lottieCache.clear();

  /// Number of Lottie compositions currently cached.
  static int get cachedLottieCount => _lottieCache.length;
}
