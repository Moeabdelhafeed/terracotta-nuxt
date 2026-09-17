import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/localization/strings/home_strings.dart';
import '../../../core/localization/strings/piece_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/workshop/workshop_own_pieces.dart';
import '../../../shared/module/container/global_container.dart';
import '../../../shared/module/empty_state/global_empty_state.dart';
import '../../../shared/module/refreshable/global_refreshable.dart';
import '../../../shared/module/scrollable/global_scrollable.dart';
import '../../_shared/account_refresh.dart';
import '../../_shared/screen_entrance.dart';
import '../../_shared/terracotta_image.dart';
import '../../_shared/terracotta_page_bar.dart';
import '../../_shared/terracotta_widgets.dart';
import '../cubits/my_pieces_cubit.dart';

/// «قطعي» — everything the customer has made at the studio.
///
/// **There is no endpoint for this.** The pieces are readable only as
/// `own_pieces` on a `paint_your_piece` workshop's detail, so
/// [MyPiecesCubit] finds that workshop first and then asks it. When the
/// studio lists no such workshop the screen says the source is gone,
/// not that the customer owns nothing.
///
/// A piece exists because of `piece_labels` on the booking's photo
/// upload — three angles of one mug are ONE piece, which is why each
/// row here has a name and a first photo rather than being a photo.
///
/// Pieces already painted elsewhere still show. This is the collection,
/// not the picker — the picker is the booking flow, and it is the one
/// that has to drop them.
class MyPiecesPage extends StatefulWidget {
  const MyPiecesPage({this.cubit, super.key});

  /// A cubit to use instead of making one — the seam a widget test
  /// needs, since the page loads on mount. Null in the app.
  final MyPiecesCubit? cubit;

  @override
  State<MyPiecesPage> createState() => _MyPiecesPageState();
}

class _MyPiecesPageState extends State<MyPiecesPage> {
  late final _pieces = (widget.cubit ?? MyPiecesCubit())..load();

  @override
  void dispose() {
    // Only what this page MADE.
    if (widget.cubit == null) unawaited(_pieces.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: context.backgroundColors.scaffoldBackground,
      appBar: TerracottaPageBar(title: PieceStrings.title),
      body: BlocBuilder<MyPiecesCubit, MyPiecesState>(
        bloc: _pieces,
        builder: (context, state) => GlobalRefreshable(
          onRefresh: () async {
            // AND WHO THEY ARE. A pull on a page about the customer
            // is a person asking whether the app is still right about
            // them — see [AccountRefresh].
            await Future.wait([
              AccountRefresh.user(context),
              _pieces.refresh(),
            ]);
          },
          child: GlobalScrollable(
            // The CALLER has to ask, or a page shorter than the
            // viewport drops the drag recogniser.
            physics: const AlwaysScrollableScrollPhysics(),
            child: GlobalContainer.shell(
              padding: EdgeInsetsDirectional.fromSTEB(
                spacing.md,
                spacing.md,
                spacing.md,
                spacing.xxl,
              ),
              child: _Body(state: state),
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final MyPiecesState state;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    if (state.loading && !state.hasData) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 120),
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    if (!state.hasData) {
      // A HEIGHT, and centred in it — dropped straight into a stretched
      // column an empty state sits at the top and reads as a page that
      // failed to draw.
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 360),
        child: Center(child: _Nothing(state: state)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      // STAGGERED. The page slides in as one; its cards arrive one
      // after another behind it — the same treatment the auth flow
      // carries, and it skips any element that FLEW here rather than
      // replaying an arrival that already happened.
      children: ScreenEntrance.stage([
        // What it would cost to bring one back — the flat own-piece
        // rate, as money rather than the wire's `"60.00"`.
        if (state.price case final price?) ...[
          Text(
            PieceStrings.paintPrice(
              '${PriceText.format(price)} ${HomeStrings.currency}',
            ),
            style: context.textTheme.bodySmall?.copyWith(
              color: context.textColors.secondary,
            ),
          ),
          SizedBox(height: spacing.md),
        ],
        for (final piece in state.pieces) ...[
          _PieceCard(piece: piece),
          SizedBox(height: spacing.sm),
        ],
      ]),
    );
  }
}

/// The three ways this screen can have nothing to show, which are three
/// different sentences.
class _Nothing extends StatelessWidget {
  const _Nothing({required this.state});

  final MyPiecesState state;

  @override
  Widget build(BuildContext context) {
    if (state.error != null) {
      return GlobalEmptyState(
        icon: Icons.wifi_off_rounded,
        title: AuthStrings.errorGeneric,
      );
    }

    // The studio takes no pieces back at the moment, so there is
    // nowhere to read them from. Saying "you have made nothing" here
    // would be a lie told to someone with a shelf of cups.
    if (state.noSource) {
      return GlobalEmptyState(
        icon: Icons.storefront_outlined,
        title: PieceStrings.noSource,
        subtitle: PieceStrings.noSourceBody,
      );
    }

    return GlobalEmptyState(
      icon: Icons.coffee_outlined,
      title: PieceStrings.empty,
      subtitle: PieceStrings.emptyBody,
    );
  }
}

/// One thing the customer made.
class _PieceCard extends StatelessWidget {
  const _PieceCard({required this.piece});

  final WorkshopOwnPiece piece;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final radii = context.radii;
    final locale = Localizations.localeOf(context).toString();
    final label = (piece.label ?? '').trim();

    return TerracottaCard(
      child: Row(
        // START, never stretch: a stretched row inside an unbounded
        // column resolves to an infinite height.
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The FIRST photo of it. A piece is a group of photos sharing
          // one label, so this is the piece's face, not its only image.
          SizedBox(
            width: 72,
            height: 72,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radii.md),
              child: TerracottaImage(image: piece.primaryImage),
            ),
          ),
          SizedBox(width: spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // The label is what GROUPS the photos, and an older
                  // row may have none.
                  label.isEmpty ? PieceStrings.untitled : label,
                  style: context.textTheme.titleMedium?.copyWith(
                    color: context.textColors.primary,
                  ),
                ),
                if (piece.madeOn case final made?) ...[
                  SizedBox(height: spacing.xs),
                  Text(
                    PieceStrings.madeOn(
                      DateFormat.yMMMd(locale).format(DateTime.parse(made)),
                    ),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.textColors.secondary,
                    ),
                  ),
                ],
                SizedBox(height: spacing.sm),
                StatusChip(
                  label: piece.isAvailableToPaint
                      ? PieceStrings.available
                      : PieceStrings.painted,
                  // Already painted is DONE, not broken — the studio's
                  // mint, the same one every finished thing wears.
                  color: piece.isAvailableToPaint
                      ? context.primaryColors.primary
                      : context.statusColors.success,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
