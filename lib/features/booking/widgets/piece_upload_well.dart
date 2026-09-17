import 'package:flutter/material.dart';

import '../../../core/constants/colors/workshop_family_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/booking_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../_shared/terracotta_widgets.dart';

/// «ارفع صور قطعك» — the way into the photo sheet, on a booking that is
/// happening right now.
///
/// Only ever shown while the customer is AT the wheel: a photograph of
/// the piece is something they take during the session, and offering it
/// before or after offers a thing they cannot do.
///
/// ## Why this is a doorway and not the picker
///
/// It WAS the picker: one photograph, no name, and nothing uploaded.
/// The endpoint takes `images[]` and `piece_labels[]` in step and
/// groups the photographs into pieces by that label, so every picture
/// needs a name beside it and the booking has two caps to state before
/// anything is chosen. That is a sheet's worth of screen — see
/// [PiecePhotosSheet] — and this is the tap that opens it.
class PieceUploadWell extends StatelessWidget {
  const PieceUploadWell({
    required this.onAdd,
    this.text,
    this.family = WorkshopFamily.makeYourPiece,
    this.wireColor,
    super.key,
  });

  final VoidCallback onAdd;

  /// What it asks for. Defaults to «ارفع صورة قطعتك» — the first
  /// step, for a booking with nothing on it yet. A booking that is
  /// only SHORT a piece passes the remaining-photos wording instead.
  final String? text;

  final WorkshopFamily family;
  final String? wireColor;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final fam = WorkshopFamilyColors.resolve(
      family: family,
      isDark: context.isDarkMode,
      wireColor: wireColor,
    );

    return TerracottaCard(
      dashed: true,
      onTap: onAdd,
      borderColor: fam.primary,
      color: fam.primary.withValues(alpha: 0.06),
      padding: EdgeInsets.symmetric(
        vertical: spacing.lg,
        horizontal: spacing.md,
      ),
      child: Column(
        children: [
          Icon(
            Icons.add_a_photo_outlined,
            size: context.iconSizes.lg,
            color: fam.primary,
          ),
          SizedBox(height: spacing.xs),
          Text(
            text ?? BookingStrings.uploadPiece,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.textColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
