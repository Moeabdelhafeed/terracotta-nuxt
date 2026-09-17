import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/core/api_image.dart';
import '../../../shared/module/media_picker/media_picker_models.dart';
import '../../../shared/module/media_picker/picker_lightbox.dart';
import '../../_shared/terracotta_image.dart';

/// The photographs above an expanded workshop.
///
/// DYNAMIC, because the catalogue is: the live server returns
/// `gallery: []` on every workshop today, and the CMS can put any
/// number in it. So this draws what it is given —
///
///   * none  → nothing at all, not an empty frame
///   * one   → one wide photograph
///   * two   → two side by side
///   * three → two above one wide, as the design draws it
///   * more  → the same three, and the third carries a `+N` badge
///
/// The badge is the gallery tab's idiom: a blurred, dimmed band over
/// the picture with the count in white.
class WorkshopGalleryStrip extends StatelessWidget {
  const WorkshopGalleryStrip({required this.images, super.key});

  final List<ApiImage> images;

  /// The design's proportions for the top row.
  static const _leadFlex = 185;
  static const _trailFlex = 158;
  static const _rowHeight = 132.0;

  /// How many are drawn at most. Everything beyond is counted into the
  /// badge on the last one.
  static const maxTiles = 3;

  /// Opens the full-screen viewer the media picker already uses —
  /// swipeable pages, pinch-zoom, drag to dismiss. Every page is an
  /// IMAGE: a workshop gallery has no video on the wire.
  void _open(BuildContext context, int index) {
    final viewable = images.where((i) => i.display.isNotEmpty).toList();
    if (viewable.isEmpty) return;

    unawaited(
      showPickerLightbox(
        context: context,
        items: [for (final i in viewable) PickerItem.url(i.display)],
        kinds: List.filled(viewable.length, AttachmentKind.image),
        initialIndex: index.clamp(0, viewable.length - 1),
        // NO NAME over the picture. `serving-plates-1-1-6.jpg` is the
        // CMS's upload slug — it says nothing to a customer and sits
        // on the photograph they opened it to look at. The counter
        // stays: which of two it is, is worth knowing.
        showTitle: false,
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    int index, {
    double? width,
    int? overflow,
  }) => Expanded(
    flex: width == null ? 1 : 0,
    child: GestureDetector(
      onTap: () => _open(context, index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.radii.xs),
        child: SizedBox(
          height: _rowHeight,
          width: width,
          child: Stack(
            fit: StackFit.expand,
            children: [
              TerracottaImage(image: images[index]),
              if (overflow != null && overflow > 0)
                _OverflowBadge(count: overflow),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    // NOTHING, not an empty frame. A placeholder box where photographs
    // go reads as a picture that failed to load.
    if (images.isEmpty) return const SizedBox.shrink();

    final spacing = context.spacing;
    final shown = images.length.clamp(0, maxTiles);
    final overflow = images.length - maxTiles;

    if (shown == 1) {
      return Row(children: [_tile(context, 0)]);
    }
    if (shown == 2) {
      return Row(
        children: [
          _tile(context, 0),
          SizedBox(width: spacing.xs),
          _tile(context, 1),
        ],
      );
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: _leadFlex,
              child: Row(children: [_tile(context, 0)]),
            ),
            SizedBox(width: spacing.xs),
            Expanded(
              flex: _trailFlex,
              child: Row(children: [_tile(context, 1)]),
            ),
          ],
        ),
        SizedBox(height: spacing.xs),
        Row(children: [_tile(context, 2, overflow: overflow)]),
      ],
    );
  }
}

/// «+٤» over the last tile, in the album grid's idiom.
class _OverflowBadge extends StatelessWidget {
  const _OverflowBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => ColoredBox(
    // A flat scrim rather than a blur: this band is small and sits on
    // a thumbnail, and a `BackdropFilter` costs a saveLayer and a
    // backdrop read per tile.
    color: context.overlayColors.scrim.withValues(alpha: 0.55),
    child: Center(
      child: Text(
        // Localized, so it reads «+٤» in Arabic — plain `ar` formats
        // in WESTERN digits.
        '+${AppNumbers.localizeDigits('$count')}',
        style: context.textTheme.titleLarge?.copyWith(
          color: context.textColors.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
