import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/colors/workshop_family_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/booking_strings.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/booking/booking_piece.dart';
import '../../../data/models/terracotta/booking/painting_session.dart';
import '../../../data/models/terracotta/core/api_image.dart';
import '../../../shared/module/list/global_list.dart';
import '../../../shared/module/media_picker/media_picker_models.dart';
import '../../../shared/module/media_picker/picker_lightbox.dart';
import '../../_shared/shared_hero.dart';
import '../../_shared/terracotta_image.dart';
import '../../_shared/terracotta_widgets.dart';
import 'clock_time.dart';

/// «قطعك» — what has been photographed so far, grouped by piece.
///
/// ## Why this replaces the well rather than sitting under it
///
/// The well says "add photos". Once there are photos, the thing the
/// reader wants is to SEE them — whether the one they just took came
/// out, whether they have covered every piece. So the pieces take the
/// space and adding more becomes a small action beside them.
///
/// ## A piece is its photographs
///
/// The server groups by the label typed at upload, so a piece is not a
/// row anyone created — it is a name with pictures under it. Two
/// consequences the UI has to be honest about:
///
///   * Removing a piece's LAST photograph removes the piece.
///   * **There is no replace.** The API has one create and two
///     deletes; swapping a picture means deleting it and uploading
///     again. The confirmation says so rather than letting the reader
///     discover it.
class PieceGallery extends StatelessWidget {
  const PieceGallery({
    required this.pieces,
    this.onAddTo,
    this.onRename,
    this.onRemovePhoto,
    this.onRemovePiece,
    this.canEdit = true,
    this.photosLeft = 0,
    this.family = WorkshopFamily.makeYourPiece,
    this.wireColor,
    super.key,
  });

  final List<BookingPiece> pieces;

  /// ANOTHER ANGLE ON THIS PIECE — opens the photos sheet on it,
  /// rather than on a page asking for a new person.
  final void Function(BookingPiece)? onAddTo;

  /// Changes this piece's NAME and nothing else. See
  /// [PieceRenameSheet].
  final void Function(BookingPiece)? onRename;

  /// `(pieceId, imageId)`. Null while the session is not running.
  final void Function(int pieceId, int imageId)? onRemovePhoto;
  final void Function(int pieceId)? onRemovePiece;

  /// `(pieceId, imageId)`. Null while the session is not running.

  /// Whether the studio still allows changes — `attending` only. After
  /// that the pictures stay and the controls go.
  final bool canEdit;

  /// What is left of the four-per-person allowance.
  final int photosLeft;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final piece in pieces) ...[
          _PieceCard(
            piece: piece,
            tint: fam.primary,
            canEdit: canEdit,
            // WHOSE NAME the pencil edits. A label is a PERSON on
            // «صمم قطعتك» and the OBJECT on the catalogue types.
            renameLabel: family == WorkshopFamily.makeYourPiece
                ? BookingStrings.editPersonName
                : BookingStrings.editPieceName,
            // ROOM ON THIS PIECE. Two ceilings and the lower wins: the
            // booking's remaining allowance, and four on any one
            // label. Out of room hides the add and leaves the other
            // two, rather than greying a control nobody can use.
            onAddPhoto:
                onAddTo == null ||
                    photosLeft <= 0 ||
                    piece.images.length >= kMaxPhotosPerPiece
                ? null
                : () => onAddTo!(piece),
            onRename: onRename == null ? null : () => onRename!(piece),
            onRemove: onRemovePiece == null
                ? null
                : () => onRemovePiece!(piece.id),
            onRemovePhoto: onRemovePhoto == null
                ? null
                : (imageId) => onRemovePhoto!(piece.id, imageId),
          ),
          SizedBox(height: spacing.sm),
        ],
      ],
    );
  }
}

/// `MAX_IMAGES_PER_PERSON` on the server — one label's ceiling,
/// whatever the booking's whole allowance is.
const int kMaxPhotosPerPiece = 4;

/// One piece: its name, how many pictures it has, and the pictures.
class _PieceCard extends StatelessWidget {
  const _PieceCard({
    required this.piece,
    required this.tint,
    required this.canEdit,
    required this.renameLabel,
    this.onAddPhoto,
    this.onRename,
    this.onRemove,
    this.onRemovePhoto,
  });

  final BookingPiece piece;
  final Color tint;
  final bool canEdit;

  /// What the pencil is called out loud.
  final String renameLabel;

  /// Another photograph of THIS piece. Null when there is no room
  /// left, or once the studio has closed the booking to changes.
  final VoidCallback? onAddPhoto;

  /// Its name, on its own.
  final VoidCallback? onRename;

  /// The whole piece, every photograph of it with it.
  final VoidCallback? onRemove;

  /// One photograph. `imageId`.
  final void Function(int imageId)? onRemovePhoto;

  /// Opens the full-screen viewer the media picker already owns —
  /// swipeable pages, pinch-zoom, drag to dismiss.
  ///
  /// The pages are THIS piece's photographs, not the whole booking's:
  /// swiping is how a customer compares two shots of one cup, and
  /// sliding into a different piece's pictures is not what the tap
  /// meant.
  void _open(BuildContext context, BookingPiece piece, int index) {
    final viewable = piece.images
        .where((i) => i.display.isNotEmpty)
        .toList(growable: false);
    if (viewable.isEmpty) return;

    unawaited(
      showPickerLightbox(
        context: context,
        items: [for (final i in viewable) PickerItem.url(i.display)],
        kinds: List.filled(viewable.length, AttachmentKind.image),
        initialIndex: index.clamp(0, viewable.length - 1),
        // NO NAME over the picture. The url is a storage slug and says
        // nothing; the piece's own name is on the card behind it.
        showTitle: false,
        // The tapped photograph FLIES up into the viewer rather than
        // being replaced by it.
        heroTag: HeroTag.photo(
          viewable[index.clamp(0, viewable.length - 1)].display,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final label = (piece.label ?? '').trim().isEmpty
        ? BookingStrings.pieceUntitled
        : piece.label!.trim();

    return TerracottaCard(
      padding: EdgeInsets.all(spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.textColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      BookingStrings.piecePhotoCount(piece.images.length),
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.textColors.secondary,
                      ),
                    ),
                    if (piece.paintingSession case final session?) ...[
                      SizedBox(height: spacing.xs),
                      _PaintingNote(session: session),
                    ],
                  ],
                ),
              ),
              // THE THREE THINGS THAT CAN BE DONE TO A PIECE, on the
              // piece. Glyphs, not words: three labelled buttons beside
              // a name that is already truncating leaves nothing for
              // the name, and each of these is a shape people read
              // without reading — a camera, a pencil, a bin.
              //
              // ORDER IS DELIBERATE. The destructive one sits at the
              // far end, furthest from the two that are pressed often,
              // and it asks before it does anything.
              if (canEdit) ...[
                if (onAddPhoto case final add?)
                  _PieceAction(
                    icon: Icons.add_a_photo_outlined,
                    tooltip: BookingStrings.addMorePhotos,
                    tint: tint,
                    onPressed: add,
                  ),
                if (onRename case final rename?)
                  _PieceAction(
                    icon: Icons.edit_outlined,
                    tooltip: renameLabel,
                    tint: tint,
                    onPressed: rename,
                  ),
                if (onRemove case final remove?)
                  _PieceAction(
                    icon: Icons.delete_outline_rounded,
                    tooltip: CommonStrings.remove,
                    tint: context.statusColors.error,
                    onPressed: remove,
                  ),
              ],
            ],
          ),
          SizedBox(height: spacing.xs),
          SizedBox(
            height: 96,
            child: GlobalList<ApiImage>.static(
              items: piece.images,
              scrollDirection: Axis.horizontal,
              // FADED WHERE THERE IS MORE, which is the list's own
              // `smart` band: two photographs fit and are cut
              // square, five run past the card and the end softens.
              // Drawn by hand first, unconditionally — which put a
              // fade on rows that were not scrolling and said "there
              // is more" where there was not.
              edgeFade: const EdgeFadeStyle(
                mode: EdgeFadeMode.shader,
                size: 20,
              ),
              separatorBuilder: (_, _) => SizedBox(width: spacing.xs),
              itemBuilder: (context, image, index) => Stack(
                children: [
                  // TAPPABLE. A photograph the customer took of their
                  // own piece, at 96 points, is a thumbnail of
                  // something they want to look at.
                  GestureDetector(
                    onTap: () => _open(context, piece, index),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(context.radii.sm),
                      child: SizedBox.square(
                        dimension: 96,
                        // Through the app's own wrapper, which carries
                        // the BLURHASH and the url rule — a picture
                        // drawn straight from the module has to
                        // remember both on its own.
                        child: SharedHero(
                          tag: HeroTag.photo(image.display),
                          child: TerracottaImage(image: image),
                        ),
                      ),
                    ),
                  ),
                  // ONE PHOTOGRAPH, on the photograph. There is no
                  // replace in the API — a shot that came out badly is
                  // deleted and taken again — so this has to be
                  // reachable from where the reader is looking at it.
                  if (canEdit && onRemovePhoto != null)
                    PositionedDirectional(
                      top: 2,
                      end: 2,
                      child: _RemoveDot(
                        onTap: () => onRemovePhoto!(image.id),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One glyph on the piece's card.
///
/// A FULL 44-POINT TARGET with a 24-point glyph. The first draw of
/// these was a 16-point icon in an 8-point pad — small enough that
/// three of them read as decoration on the card rather than as the
/// three things that can be done to it, and small enough to miss.
/// The name beside them truncates instead; a name has an ellipsis to
/// fall back on and a control does not.
class _PieceAction extends StatelessWidget {
  const _PieceAction({
    required this.icon,
    required this.tooltip,
    required this.tint,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color tint;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: tooltip,
    excludeSemantics: true,
    child: Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onPressed,
        radius: 24,
        child: SizedBox.square(
          dimension: 44,
          child: Icon(icon, size: context.iconSizes.md, color: tint),
        ),
      ),
    ),
  );
}

/// The close dot on a photograph.
class _RemoveDot extends StatelessWidget {
  const _RemoveDot({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: CommonStrings.remove,
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          // SCRIM, not the error red. The dot sits ON a photograph
          // whose colours are not ours, and a red disc over a
          // customer's own picture reads as damage to the picture.
          color: context.overlayColors.scrim.withValues(alpha: 0.55),
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Icon(
            Icons.close_rounded,
            size: context.iconSizes.xs,
            color: context.textColors.onPrimary,
          ),
        ),
      ),
    ),
  );
}

/// «محجوزة للتلوين · لوّن كوبك، ٢٠ سبتمبر».
///
/// The piece is booked into a paint session, which is the whole reason
/// the collection countdown has gone quiet — the studio is holding it
/// for that day. Without this line the deadline simply disappears and
/// the reader has nothing to attach that to.
class _PaintingNote extends StatelessWidget {
  const _PaintingNote({required this.session});

  final PaintingSession session;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final locale = Localizations.localeOf(context).toString();
    final upcoming = session.isUpcoming;
    final tint = upcoming
        ? context.primaryColors.accent
        : context.textColors.secondary;
    final workshop = (session.workshopTitle ?? '').trim();
    final date = session.date;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          upcoming ? Icons.event_available_rounded : Icons.brush_rounded,
          size: context.iconSizes.xs,
          color: tint,
        ),
        SizedBox(width: spacing.xs),
        Flexible(
          child: Text(
            upcoming && date != null
                // Asia/Riyadh as the server wrote it — printed, never
                // re-zoned.
                ? BookingStrings.piecePaintingOn(
                    workshop,
                    formatBookingDate(date, locale),
                  )
                : BookingStrings.piecePaintedAt(workshop),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelSmall?.copyWith(color: tint),
          ),
        ),
      ],
    );
  }
}
