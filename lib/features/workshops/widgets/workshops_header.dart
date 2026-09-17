import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/workshop_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../shared/module/segmented_control/global_segmented_control.dart';
import '../../_shared/localized_rebuild.dart';
import '../../_shared/screen_entrance.dart';
import '../../gift/widgets/wallet_gift_row.dart';
import '../workshops_tab.dart';

/// The controls under the drawn intro: the book-a-workshop /
/// my-workshops segmented control, and the gift + wallet pair.
///
/// The TITLE is not here — `_WorkshopsIntro` on the page carries it,
/// over the line art, which is where the design puts it. Drawing it
/// again here was the same words twice, one above the other.
class WorkshopsHeader extends StatelessWidget {
  const WorkshopsHeader({
    required this.tab,
    required this.onTabChanged,
    this.onGiftTap,
    this.onOpenWallet,
    this.bookingCount = 0,
    // Zero until `GET /api/wallet` is bound. Printed with the
    // currency, not left blank — see `_WalletCard.balance`.
    this.walletBalance = '0',
    this.entrance = false,
    super.key,
  });

  /// Whether the control and the two cards arrive one after another
  /// rather than all at once. Once per launch — see [TabEntrance].
  ///
  /// The three are the page's whole header, and they were staged by the
  /// page as ONE child: the control, the balance and the gift tile
  /// appeared together, which is the thing a stagger exists not to do.
  final bool entrance;

  /// Which side of the control is selected. Owned by the page, because
  /// the page is what will swap the content under it.
  final WorkshopsTab tab;
  final ValueChanged<WorkshopsTab> onTabChanged;

  /// Opens the gift flow. Null leaves the tile inert.
  final VoidCallback? onGiftTap;

  /// «عرض المعاملات» — into the ledger behind the balance.
  final VoidCallback? onOpenWallet;

  final int bookingCount;

  /// Decimal string, printed as received.
  final String walletBalance;

  /// The header's own stagger, or the header exactly as it was.
  List<Widget> _stage(List<Widget> children, {int from = 0}) =>
      entrance ? ScreenEntrance.stage(children, from: from) : children;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _stage([
        _Segmented(
          tab: tab,
          bookingCount: bookingCount,
          onChanged: onTabChanged,
        ),
        // THE CATALOGUE TAB ONLY.
        //
        // The balance and the gift tile are for BUYING a workshop, and
        // «ورشاتي» is the list of ones already bought. On that tab
        // they pushed the reader's own bookings most of a screen down
        // to offer something they had just finished doing.
        //
        // The number is not lost: the profile tab shows the same
        // balance, and the ledger is one tap from there.
        if (tab == WorkshopsTab.book) ...[
          SizedBox(height: spacing.md),
          // WRAPPED before staging, because `stage` passes a bare
          // `SizedBox` through as a spacer — and this one is a height,
          // not a gap. Left bare the cards would be the one part of the
          // header that never arrived.
          // THE SHARED PAIR — the shop tab carries the same one. See
          // [WalletGiftRow].
          ScreenEntrance(
            child: WalletGiftRow(
              balance: walletBalance,
              onOpenWallet: onOpenWallet ?? () {},
              onGiftTap: onGiftTap ?? () {},
            ),
          ),
        ],
      ]),
    );
  }
}

/// «حجز ورشة» / «ورشاتي», as a real segmented control.
///
/// BOOK comes first. It is the tab the reader lands on and the one the
/// design draws selected; putting "my workshops" first opened the
/// screen on the tab nobody asked for.
///
/// The module owns the sliding indicator, the keyboard traversal and
/// the semantics. This used to be two `DecoratedBox`es and a hardcoded
/// bool — it looked right and could not be operated.
class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.tab,
    required this.bookingCount,
    required this.onChanged,
  });

  final WorkshopsTab tab;
  final int bookingCount;
  final ValueChanged<WorkshopsTab> onChanged;

  @override
  Widget build(BuildContext context) {
    // The labels are read HERE — see `dependOnLanguage`.
    dependOnLanguage(context);

    return GlobalSegmentedControl<WorkshopsTab>(
      value: tab,
      onChanged: onChanged,
      style: SegmentedStyle(
        // Both halves the same width, as drawn.
        expandEqual: true,
        // TALLER than the module's default, and the words larger with
        // it: the control is one of two things on this screen the
        // reader is meant to hit, and the design draws it as a bar
        // rather than a chip.
        height: 56,
        segmentPadding: EdgeInsets.symmetric(vertical: context.spacing.sm),
        selectedTextStyle: context.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedTextStyle: context.textTheme.titleMedium,
        backgroundColor: context.buttonsColors.disabled,
        selectedColor: context.primaryColors.primary,
        selectedForegroundColor: context.textColors.onPrimary,
        unselectedForegroundColor: context.textColors.disabled,
        borderRadius: BorderRadius.circular(context.radii.md),
        // The design's own number: a 5pt gutter between the pill and
        // the track it slides in.
        indicatorPadding: 5,
      ),
      segments: [
        SegmentItem(value: WorkshopsTab.book, label: WorkshopStrings.tabBook),
        SegmentItem(
          value: WorkshopsTab.mine,
          label: WorkshopStrings.tabMine,
          // AFTER the words, which in Arabic is their left — a count
          // belongs behind the thing it counts, and the leading icon
          // slot would put it on the wrong end.
          trailing: bookingCount > 0 ? _CountBadge(count: bookingCount) : null,
        ),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.textColors.disabled,
      borderRadius: BorderRadius.circular(context.radii.xs),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      child: Text(
        '$count',
        style: context.textTheme.labelSmall?.copyWith(
          color: context.textColors.onPrimary,
        ),
      ),
    ),
  );
}

/// The coral gift tile.
///
/// The design draws a drawn LOOP behind the glyph — the same line art
/// that backs the other coral surfaces, in white at low alpha and
/// larger than the tile, so only a sweep of it shows.
