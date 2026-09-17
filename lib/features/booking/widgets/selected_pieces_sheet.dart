import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/booking_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../core/utils/money_minor_units.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/terracotta_widgets.dart';
import '../cubits/piece_selection_cubit.dart';
import '../cubits/piece_selection_state.dart';
import '../data/picked_piece.dart';
import '../views/piece_selection_page.dart' show madeOnLabel;
import 'piece_card.dart';
import 'sheet_shell.dart';

/// «القطع المختارة» — the running selection.
///
/// A sheet over the catalogue, not a route: the customer is mid-pick
/// and losing the grid behind them would lose their place.
///
/// It holds the SAME cubit the grid does, so the steppers here are the
/// real ones — a piece chosen three categories ago can be dropped
/// without going back to find its tab — and the count on the button
/// that opened this follows along underneath.
class SelectedPiecesSheet extends StatelessWidget {
  const SelectedPiecesSheet({
    required this.pieces,
    required this.tint,
    super.key,
  }) : lines = null;

  /// The same sheet with nothing to press.
  ///
  /// The checkout shows it: the basket is settled by then and the price
  /// is the server's, so a stepper here would change a total the
  /// customer is already being asked to pay. Going back is the way to
  /// change the pieces.
  const SelectedPiecesSheet.settled({
    required List<PickedPiece> this.lines,
    required this.tint,
    super.key,
  }) : pieces = null;

  final PieceSelectionCubit? pieces;

  /// Set only on the settled sheet.
  final List<PickedPiece>? lines;

  final Color tint;

  /// What was picked, resolved back to rows.
  ///
  /// The selection holds IDs, not rows — the row belongs to the
  /// catalogue, and copying it in would leave two versions of one
  /// product to keep in step. See `PieceSelectionState.resolve`.
  static List<PickedPiece> linesOf(
    PieceSelectionState state, {
    String? locale,
  }) => state.resolve(
    untitled: BookingStrings.pieceUntitled,
    madeOn: (piece) => madeOnLabel(piece.madeOn, locale ?? 'en'),
  );

  void _more(PickedPiece piece) => piece.isOwn
      ? pieces?.toggleOwn(piece.ownPieceId!)
      : pieces?.add(piece.productId!);

  void _fewer(PickedPiece piece) => piece.isOwn
      ? pieces?.toggleOwn(piece.ownPieceId!)
      : pieces?.remove(piece.productId!);

  @override
  Widget build(BuildContext context) {
    final cubit = pieces;
    if (cubit == null) {
      return _panel(context, lines: lines!, canAdd: false, editable: false);
    }
    return BlocBuilder<PieceSelectionCubit, PieceSelectionState>(
      bloc: cubit,
      builder: (context, state) => _panel(
        context,
        lines: linesOf(
          state,
          locale: Localizations.localeOf(context).toString(),
        ),
        canAdd: state.canAddMore,
        editable: true,
      ),
    );
  }

  Widget _panel(
    BuildContext context, {
    required List<PickedPiece> lines,
    required bool canAdd,
    required bool editable,
  }) {
    final total = lines.fold(0, (sum, l) => sum + l.quantity);
    return SheetShell(
      title: BookingStrings.selectedPieces(total),
      centerTitle: true,
      // Grows with the selection instead of taking a fixed slab of
      // screen: one piece opens a short panel, and a long basket
      // scrolls rather than pushing the total off the bottom.
      heightFactor: null,
      maxHeightFactor: 0.85,
      children: [
        for (final piece in lines) ...[
          PieceCard(
            title: piece.title,
            subtitle: piece.subtitle,
            price: piece.price,
            image: piece.image,
            quantity: piece.quantity,
            canAdd: canAdd,
            oneOnly: piece.isOwn,
            tint: tint,
            editable: editable,
            onAdd: () => _more(piece),
            onRemove: () => _fewer(piece),
          ),
          SizedBox(height: context.spacing.sm),
        ],
        SizedBox(height: context.spacing.sm),
        _Total(
          // Money stays a decimal STRING: the sum is taken in integer
          // minor units, never through a double.
          amount: MinorUnits.sumLines([
            for (final piece in lines) (piece.price, piece.quantity),
          ]),
        ),
        SizedBox(height: context.spacing.md),
        GlobalFilledButton(
          text: BookingStrings.close,
          onPressed: () => Navigator.of(context).pop(),
          style: terracottaCtaStyle(
            showArrow: false,
          ).copyWith(backgroundColor: tint),
        ),
      ],
    );
  }
}

/// «الاجمالي» — what the pieces come to.
///
/// The PIECES only. The celebration fee, the wallet and any discount
/// are applied server-side in a specific order, so the number the
/// customer pays is quoted at the checkout and never computed here.
class _Total extends StatelessWidget {
  const _Total({required this.amount});

  final String amount;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        BookingStrings.piecesTotal,
        style: context.textTheme.titleMedium?.copyWith(
          color: context.textColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
      const Spacer(),
      PriceText(amount: amount),
    ],
  );
}

/// Opens [SelectedPiecesSheet] over the catalogue.
Future<void> showSelectedPiecesSheet(
  BuildContext context, {
  required PieceSelectionCubit pieces,
  required Color tint,
}) => showTerracottaSheet<void>(
  context,
  builder: (_) => SelectedPiecesSheet(pieces: pieces, tint: tint),
);

/// Opens the SETTLED sheet — what was picked, with nothing to press.
Future<void> showSettledPiecesSheet(
  BuildContext context, {
  required List<PickedPiece> lines,
  required Color tint,
}) => showTerracottaSheet<void>(
  context,
  builder: (_) => SelectedPiecesSheet.settled(lines: lines, tint: tint),
);
