import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../../data/services/media/dynamic_assets.dart';
import '../../shared/module/image/global_image.dart';
import 'dynamic_asset_slots.dart';
import 'terracotta_image.dart';

/// One drawing, from the STUDIO if they have set one and from the
/// bundle if they have not.
///
/// ```dart
/// DynamicAssetImage(
///   section: 'onboarding',
///   assetKey: 'onboarding_1',
///   fallback: 'assets/images/onboarding-1.png',
/// )
/// ```
///
/// ## What happens on a miss
///
/// The bundled drawing is shown — immediately, with no spinner and no
/// wait — and the same file is uploaded into the empty key so the
/// studio has something to replace next time they open the CMS. See
/// [DynamicAssets] for why that can never overwrite their own work.
///
/// ## There is never a loading state
///
/// Two ways this could have shown one, and both are closed:
///
///   * **before the manifest lands** every lookup is null, so the
///     bundled drawing is simply what is drawn;
///   * **while the studio's file downloads** the bundled drawing is
///     the network image's own `placeholder`, so it stays on screen
///     until the remote one has decoded and then swaps. It goes out
///     through [TerracottaImage] like every other API picture, so the
///     blurhash and the url rule come along with it.
///
/// Either way the reader is looking at a finished picture the whole
/// time. A shimmer here would be a grey box standing in for an image
/// the app already has in its hand — which is how this first shipped,
/// and it read as the screen failing to load.
///
/// [DynamicAssets.precache] then warms the remote files after the
/// first frame, so on most screens the swap has already happened
/// before anything is shown.
class DynamicAssetImage extends StatefulWidget {
  const DynamicAssetImage({
    required this.section,
    required this.assetKey,
    required this.fallback,
    this.fit = BoxFit.contain,
    this.seed = true,
    super.key,
  });

  /// The CMS `sub_group` — `onboarding`, `auth`, `workshops`.
  final String section;

  /// The CMS `key`. Slug-shaped: `^[a-z0-9]([a-z0-9_-]*[a-z0-9])?$`.
  final String assetKey;

  /// The bundled asset shown when the CMS has nothing, and uploaded
  /// into the key when [seed] is on.
  final String fallback;

  final BoxFit fit;

  /// Whether a miss puts the bundled file into the empty key.
  ///
  /// Off for a drawing the studio should never be offered — a brand
  /// mark, a piece of chrome — where the CMS having it would only be a
  /// way to break the app's own identity.
  final bool seed;

  /// The dynamic version of [assetPath] when the studio may replace
  /// it, and the plain bundled asset when they may not.
  ///
  /// This is what makes adoption a one-line swap: a caller names the
  /// asset it always named, and [dynamicAssetSlots] decides whether
  /// there is a CMS slot behind it.
  static Widget forAsset(String assetPath, {BoxFit fit = BoxFit.contain}) {
    final slot = slotForAsset(assetPath);
    if (slot == null) {
      return GlobalImage.a(
        assetPath,
        placeholder: const SizedBox.shrink(),
        style: ImageStyle(fit: fit, borderRadius: BorderRadius.zero),
      );
    }
    return DynamicAssetImage(
      section: slot.section,
      assetKey: slot.key,
      fallback: assetPath,
      fit: fit,
    );
  }

  @override
  State<DynamicAssetImage> createState() => _DynamicAssetImageState();
}

class _DynamicAssetImageState extends State<DynamicAssetImage> {
  DynamicAssets? get _assets =>
      getIt.isRegistered<DynamicAssets>() ? getIt<DynamicAssets>() : null;

  @override
  void initState() {
    super.initState();
    if (!widget.seed) return;
    // AFTER the first frame: the reader is looking at the bundled
    // drawing already and nothing about this should delay it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        _assets?.seed(
          section: widget.section,
          key: widget.assetKey,
          assetPath: widget.fallback,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bundled = GlobalImage.a(
      widget.fallback,
      placeholder: const SizedBox.shrink(),
      style: ImageStyle(fit: widget.fit, borderRadius: BorderRadius.zero),
    );

    return TerracottaImage(
      image: _assets?.imageFor(widget.section, widget.assetKey),
      fit: widget.fit,
      // THE BUNDLED DRAWING IS THE PLACEHOLDER — not a shimmer. It is
      // the same picture, already decoded, and holding it until the
      // studio's version arrives means there is no moment where this
      // widget shows nothing. It is also what a missing slot draws.
      placeholder: bundled,
    );
  }
}
