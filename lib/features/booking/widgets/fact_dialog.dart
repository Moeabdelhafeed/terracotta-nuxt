import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../_shared/terracotta_cta_style.dart';

/// One fact from the grid, at full length.
///
/// ## Why a dialog and not a longer chip
///
/// The chips are a GRID, and a grid is a shape: six tiles the same
/// size, their glyphs on one line and their labels on another. A label
/// that grows breaks that — two lines made every tile in the row as
/// tall as the longest one in it, so a row of three short facts sat in
/// boxes sized for a fact that was not there.
///
/// The label is cut with an ellipsis instead, and this is where the
/// rest of it lives. It used to be a marquee: only moving when the
/// text actually overflowed, which sounds free and is not — six chips
/// with two of them sliding is a page that will not sit still, and a
/// reader has to WAIT for the end of a sentence rather than reach it.
///
/// ## It wears the chip it came from
///
/// Same glyph, same tint, same corner. A dialog in the app's neutral
/// grey would be a different object arriving; this reads as the tile
/// the reader just touched, opened.
class FactDialog extends StatelessWidget {
  const FactDialog({
    required this.label,
    required this.icon,
    required this.tint,
    this.iconAsset,
    this.title,
    super.key,
  });

  /// The fact, whole — this is the thing the chip could not fit.
  final String label;

  final IconData icon;

  /// The design's own glyph, when the app ships one.
  final String? iconAsset;

  final Color tint;

  /// What the fact IS — «الموعد», «الحضور». Optional: several of these
  /// facts are self-describing and a heading over them would be
  /// repetition.
  final String? title;

  static const _iconSize = 34.0;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final radius = BorderRadius.circular(context.radii.lg);

    return Dialog(
      backgroundColor: context.backgroundColors.surface,
      shape: RoundedRectangleBorder(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // THE CHIP'S OWN PLATE, at the size the chip draws it —
            // the tinted wash and the glyph on it, so the thing that
            // opened is recognisably the thing that was tapped.
            Align(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(context.radii.md),
                ),
                child: Padding(
                  padding: EdgeInsets.all(spacing.md),
                  child: iconAsset != null
                      ? SvgPicture.asset(
                          iconAsset!,
                          width: _iconSize,
                          height: _iconSize,
                          colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
                        )
                      : Icon(icon, size: _iconSize, color: tint),
                ),
              ),
            ),
            if (title case final heading?) ...[
              SizedBox(height: spacing.md),
              Text(
                heading,
                textAlign: TextAlign.center,
                style: context.textTheme.labelMedium?.copyWith(
                  color: context.textColors.secondary,
                ),
              ),
            ],
            SizedBox(height: spacing.sm),
            // NO `maxLines`. The whole point of this screen is the
            // part the chip had to cut.
            SelectableText(
              label,
              textAlign: TextAlign.center,
              style: context.textTheme.titleMedium?.copyWith(
                color: context.textColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: spacing.lg),
            GlobalFilledButton(
              text: CommonStrings.close,
              style: terracottaCtaStyle(
                showArrow: false,
              ).copyWith(backgroundColor: tint),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens [FactDialog] over the booking.
Future<void> showFactDialog(
  BuildContext context, {
  required String label,
  required IconData icon,
  required Color tint,
  String? iconAsset,
  String? title,
}) => showDialog<void>(
  context: context,
  builder: (_) => FactDialog(
    label: label,
    icon: icon,
    tint: tint,
    iconAsset: iconAsset,
    title: title,
  ),
);
