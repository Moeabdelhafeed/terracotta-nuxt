import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/colors/workshop_family_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/localization/strings/booking_strings.dart';
import '../../../core/localization/strings/checkout_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/empty_state/global_empty_state.dart';
import '../../../shared/module/list/global_list.dart';
import '../../../shared/module/scrollable/global_scrollable.dart';
import '../../_shared/category_chips.dart';
import '../../_shared/screen_entrance.dart';
import '../../_shared/shared_hero.dart';
import '../../_shared/skeleton_block.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/terracotta_page_bar.dart';
import '../../checkout/views/booking_checkout_page.dart';
import '../cubits/piece_selection_cubit.dart';
import '../cubits/piece_selection_state.dart';
import '../widgets/piece_card.dart';
import '../widgets/selected_pieces_sheet.dart';

/// «اختيار القطع» — the catalogue step.
///
/// Only for `paint_your_piece` and `make_your_candle`: their price
/// comes from the pieces picked, while `make_your_piece` is a flat rate
/// per person and skips this screen entirely. The schedule screen
/// decides which of the two roads it is on and lands here or on the
/// checkout.
///
/// The catalogue is nested INSIDE the workshop payload
/// (`GET /api/workshops/{id}` → categories → sub-categories →
/// products), not fetched from the shop endpoints — one request holds
/// the products AND the per-person bounds they are counted against.
class PieceSelectionPage extends StatefulWidget {
  const PieceSelectionPage({
    this.args,
    this.workshopId,
    this.family = WorkshopFamily.paintYourPiece,
    this.wireColor,
    this.cubit,
    super.key,
  });

  /// Everything the schedule screen settled — workshop, party size,
  /// date and session. This screen adds the pieces and hands the whole
  /// bag on, so the checkout asks for none of it again. Null after a
  /// hot restart, where a route extra does not survive.
  final BookingCheckoutArgs? args;

  /// The id off the PATH, which survives a hot restart when the extra
  /// does not. Without it the catalogue would be asked for workshop
  /// zero and the screen would sit empty for the rest of the session.
  final int? workshopId;

  final WorkshopFamily family;
  final String? wireColor;

  /// A cubit to use instead of making one — the seam a widget test
  /// needs, since the page loads on mount. Null in the app.
  final PieceSelectionCubit? cubit;

  /// The family this screen paints in: the one it was handed, else the
  /// default.
  WorkshopFamily get effectiveFamily => args?.family ?? family;

  /// The workshop to ask for: the one the schedule screen named, else
  /// the one in the path.
  int get effectiveWorkshopId => args?.workshopId ?? workshopId ?? 0;
  String? get effectiveWireColor => args?.wireColor ?? wireColor;

  @override
  State<PieceSelectionPage> createState() => _PieceSelectionPageState();
}

class _PieceSelectionPageState extends State<PieceSelectionPage> {
  late final _pieces =
      (widget.cubit ??
            PieceSelectionCubit(
              workshopId: '${widget.effectiveWorkshopId}',
              people: widget.args?.people ?? 1,
            ))
        ..load();

  @override
  void dispose() {
    // Only what this page MADE. An injected one belongs to its test.
    if (widget.cubit == null) unawaited(_pieces.close());
    super.dispose();
  }

  /// On to payment, carrying both what the schedule settled and what
  /// was picked here. The lines are what turn a flat quote into a
  /// catalogue one — without them the checkout prices the seat, which
  /// on these workshops is `"0.00"`.
  void _continue(PieceSelectionState state) => context.pushNamed(
    'booking-checkout',
    // The ROWS, not the ids: the checkout lists what was picked and
    // derives the wire lines from the same rows.
    extra: _args.withPieces(SelectedPiecesSheet.linesOf(state)),
  );

  /// What the schedule screen settled, or an empty bag after a hot
  /// restart — the checkout falls back to its own defaults there, the
  /// same way this screen does.
  BookingCheckoutArgs get _args =>
      widget.args ??
      const BookingCheckoutArgs(workshopId: 0, title: '', people: 1);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PieceSelectionCubit, PieceSelectionState>(
      bloc: _pieces,
      builder: (context, state) {
        // The WORKSHOP's own type wins once the payload has landed —
        // the extra that would otherwise say so does not survive a hot
        // restart, and a candle workshop in the paint family's hue is
        // the wrong screen.
        final fam = WorkshopFamilyColors.resolve(
          family: state.family ?? widget.effectiveFamily,
          isDark: context.isDarkMode,
          wireColor: widget.effectiveWireColor,
        );

        return Scaffold(
          backgroundColor: context.backgroundColors.scaffoldBackground,
          appBar: TerracottaPageBar(title: BookingStrings.pickPieces),
          body: GlobalScrollable(
            // The CALLER has to ask, or a page shorter than the viewport
            // drops the drag recogniser.
            physics: const AlwaysScrollableScrollPhysics(),
            child: _Body(state: state, tint: fam.primary, pieces: _pieces),
          ),
          // PINNED. The catalogue is as long as the studio's shelf, and
          // the running count is the thing the customer checks WHILE
          // picking — at the foot of the list it is a thing to go looking
          // for.
          bottomNavigationBar: _Footer(
            state: state,
            tint: fam.primary,
            wash: fam.container,
            onOpenSelection: () => showSelectedPiecesSheet(
              context,
              pieces: _pieces,
              tint: fam.primary,
            ),
            onContinue: () => _continue(state),
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.tint, required this.pieces});

  final PieceSelectionState state;
  final Color tint;
  final PieceSelectionCubit pieces;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    if (state.loading) {
      return Padding(
        padding: EdgeInsetsDirectional.all(spacing.md),
        child: const _PieceSkeleton(),
      );
    }

    if (state.error != null || state.categories.isEmpty) {
      return Padding(
        padding: EdgeInsetsDirectional.all(spacing.md),
        child: GlobalEmptyState(
          icon: state.error != null
              ? Icons.wifi_off_rounded
              : Icons.local_cafe_rounded,
          title: state.error != null
              ? AuthStrings.errorGeneric
              : BookingStrings.piecesEmpty,
          variant: EmptyStateVariant.compact,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: spacing.sm),
        // The SHOP's rails, in the workshop's colour — the design draws
        // one way of choosing a category and the customer has already
        // used it to browse the shop. The rails inset their OWN
        // contents, so a tile can scroll to the screen edge instead of
        // being clipped mid-way with nowhere to scroll into.
        SizedBox(
          // Shorter than the shop's rail: these tiles carry a word and
          // no artwork — the workshop's own categories have no image —
          // so the shop's 104 was mostly empty tile. Not much shorter,
          // though: cut to the words' own height the tile stopped
          // reading as a card at all.
          height: 84,
          child: GlobalList.static(
            // The customer's OWN pieces lead, when they have any: what
            // they already made is the reason they came back, and the
            // studio's shelf is the alternative.
            items: [
              if (state.showsOwnPieces)
                (PieceSelectionState.ownTab, BookingStrings.ownPieces),
              for (final category in state.categories)
                (category.id, category.title),
            ],
            scrollDirection: Axis.horizontal,
            style: ListStyle(
              padding: EdgeInsets.symmetric(horizontal: spacing.md),
            ),
            separatorBuilder: (_, _) => SizedBox(width: spacing.sm),
            itemBuilder: (context, tab, index) => CategoryChip(
              label: tab.$2,
              selected: tab.$1 == state.categoryId,
              tint: tint,
              onTap: () => pieces.selectCategory(tab.$1),
            ),
          ),
        ),
        if (state.subCategories.length > 1) ...[
          SizedBox(height: spacing.sm),
          SizedBox(
            // Two lines of label. The chip has no vertical padding of
            // its own — it fills this and centres the words in it.
            height: 52,
            child: GlobalList.static(
              items: state.subCategories,
              scrollDirection: Axis.horizontal,
              style: ListStyle(
                padding: EdgeInsets.symmetric(horizontal: spacing.md),
              ),
              separatorBuilder: (_, _) => SizedBox(width: spacing.sm),
              itemBuilder: (context, sub, index) => SubCategoryChip(
                label: sub.title,
                selected: sub.id == state.subCategoryId,
                tint: tint,
                // No clearing here, unlike the shop: a group always
                // holds the products, so "no group" would be a blank
                // screen rather than "everything in this category".
                onTap: () => pieces.selectSubCategory(sub.id),
              ),
            ),
          ),
        ],
        SizedBox(height: spacing.lg),
        Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: spacing.md),
          child: state.categoryId == PieceSelectionState.ownTab
              ? _OwnPieces(state: state, tint: tint, pieces: pieces)
              : _Products(state: state, tint: tint, pieces: pieces),
        ),
        SizedBox(height: spacing.xl),
      ],
    );
  }
}

/// The studio's shelf.
class _Products extends StatelessWidget {
  const _Products({
    required this.state,
    required this.tint,
    required this.pieces,
  });

  final PieceSelectionState state;
  final Color tint;
  final PieceSelectionCubit pieces;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      // STAGGERED as the catalogue lands — the pieces arrive one
      // after another rather than the whole grid appearing at once.
      children: ScreenEntrance.stage([
        for (final product in state.products) ...[
          PieceCard.product(
            product: product,
            quantity: state.quantityOf(product.id),
            // Disabled AT the ceiling on every row, not only the one
            // being pressed: the limit is on the booking, so the whole
            // list has to stop offering more.
            canAdd: state.canAddMore,
            tint: tint,
            onAdd: () => pieces.add(product.id),
            onRemove: () => pieces.remove(product.id),
          ),
          SizedBox(height: spacing.sm),
        ],
        if (state.products.isEmpty)
          GlobalEmptyState(
            icon: Icons.local_cafe_rounded,
            title: BookingStrings.piecesEmpty,
            variant: EmptyStateVariant.compact,
          ),
      ]),
    );
  }
}

/// «قطعي» — what the customer made in an earlier workshop, offered back
/// to be painted at the workshop's flat `own_pieces.price`.
///
/// A piece already painted somewhere else is never drawn: the server
/// refuses it with `api.workshop_piece_unavailable`, so offering one
/// would be offering a 422.
class _OwnPieces extends StatelessWidget {
  const _OwnPieces({
    required this.state,
    required this.tint,
    required this.pieces,
  });

  final PieceSelectionState state;
  final Color tint;
  final PieceSelectionCubit pieces;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final locale = Localizations.localeOf(context).toString();
    final price = state.ownPieces?.price ?? '0.00';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          BookingStrings.ownPiecesHint,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.textColors.secondary,
          ),
        ),
        SizedBox(height: spacing.md),
        for (final piece in state.availableOwn) ...[
          PieceCard(
            title: piece.label ?? BookingStrings.pieceUntitled,
            subtitle: madeOnLabel(piece.madeOn, locale),
            price: price,
            image: piece.primaryImage,
            quantity: state.holdsOwn(piece.id) ? 1 : 0,
            canAdd: state.canAddMore,
            // A specific object is one or none.
            oneOnly: true,
            tint: tint,
            onAdd: () => pieces.toggleOwn(piece.id),
            onRemove: () => pieces.toggleOwn(piece.id),
          ),
          SizedBox(height: spacing.sm),
        ],
      ],
    );
  }
}

/// «صنعتها ٤ يوليو» — the day, which is what tells two similar cups
/// apart. The wire sends `Y-m-d`; anything else is passed through
/// rather than guessed at.
String? madeOnLabel(String? day, String locale) {
  if (day == null || day.isEmpty) return null;
  final parsed = DateTime.tryParse(day);
  return BookingStrings.ownPieceMadeOn(
    parsed == null ? day : DateFormat.MMMMd(locale).format(parsed),
  );
}

/// The running count, the rule it is measured against, and the way out.
class _Footer extends StatelessWidget {
  const _Footer({
    required this.state,
    required this.tint,
    required this.wash,
    required this.onOpenSelection,
    required this.onContinue,
  });

  final PieceSelectionState state;
  final Color tint;

  /// The family hue at 9% — the design's pale bar, which is how the
  /// selection button reads as secondary to the brown one under it.
  final Color wash;

  final VoidCallback onOpenSelection;
  final VoidCallback onContinue;

  /// The rule in the customer's words, and only while it is unmet — a
  /// standing instruction under a satisfied basket is noise.
  String? get _rule {
    if (state.canContinue) return null;
    final min = state.minPerPerson;
    if (min == null) return null;
    final max = state.maxPerPerson;
    if (max == null) return BookingStrings.piecesMinOnly(state.minTotal);
    // A range of one is not a range.
    return state.minTotal == state.maxTotal
        ? BookingStrings.piecesExact(state.minTotal)
        : BookingStrings.piecesRange(state.minTotal, state.maxTotal);
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final rule = _rule;

    return Material(
      color: context.backgroundColors.scaffoldBackground,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            spacing.md,
            spacing.sm,
            spacing.md,
            spacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (rule != null) ...[
                Text(
                  rule,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.textColors.secondary,
                  ),
                ),
                SizedBox(height: spacing.sm),
              ],
              // The count OPENS the selection — it is the only way back
              // to a product picked three categories ago. Drawn as the
              // CTA's twin in the pale wash, which is the design's way
              // of saying "second, not other".
              GlobalFilledButton(
                text: BookingStrings.selectedPieces(state.total),
                enabled: state.total > 0,
                onPressed: onOpenSelection,
                style: terracottaCtaStyle(showArrow: false).copyWith(
                  backgroundColor: wash,
                  textStyle: TextStyle(
                    fontSize: kTerracottaCtaLabelSize,
                    color: tint,
                  ),
                ),
              ),
              SizedBox(height: spacing.sm),
              SharedHero(
                tag: HeroTag.bookingCta,
                exitsWithRoute: true,
                child: GlobalFilledButton(
                  text: CheckoutStrings.title,
                  enabled: state.canContinue,
                  onPressed: onContinue,
                  style: terracottaCtaStyle().copyWith(backgroundColor: tint),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Four product-shaped boxes while the catalogue arrives.
class _PieceSkeleton extends StatelessWidget {
  const _PieceSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < 4; i++) ...[
          const SizedBox(
            height: 96,
            child: SkeletonBlock(),
          ),
          SizedBox(height: context.spacing.sm),
        ],
      ],
    );
  }
}
