import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/booking_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../_shared/filter_chip_rail.dart';
import 'my_workshops_list.dart';

/// One status the list actually contains, and how many are in it.
@immutable
class BookingStatusCount {
  const BookingStatusCount({required this.status, required this.count});

  /// The wire value — `confirmed`, `cancelled`, `completed`.
  final String status;
  final int count;
}

/// «الكل · مؤكد ٢ · ملغاة ١» — the statuses «ورشاتي» is currently
/// showing, as a strip of chips.
///
/// ## Built from the list, not from the vocabulary
///
/// The backend has seven booking statuses and four delivery ones. A
/// strip of eleven chips, most of them empty, is a worse thing to read
/// than no strip at all — it asks the customer to work out which of
/// them apply to the three bookings they have.
///
/// So the chips are derived from what is on screen: a status appears
/// only if a booking has it, in the order the statuses first appear,
/// with its count beside it. One status means one chip and nothing to
/// choose between, so the whole strip hides.
///
/// The count is the point of the chip as much as the label — «ملغاة ١»
/// answers "how many did I cancel?" without the reader filtering at
/// all.
class BookingStatusFilter extends StatelessWidget {
  const BookingStatusFilter({
    required this.counts,
    required this.total,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<BookingStatusCount> counts;

  /// «الكل»'s number — see [totalFor]. Passed in rather than summed
  /// here, because the server's `all` counts statuses the strip drops.
  final int total;

  /// The wire value being filtered to, or null for all of them.
  final String? selected;
  final ValueChanged<String?> onChanged;

  /// The strip's chips: the SERVER's tally when it sent one, the rows
  /// on screen otherwise.
  ///
  /// `GET /api/workshops/bookings` answers with `meta.status_counts`,
  /// a tally of the customer's whole history that does not move when
  /// the list is filtered or paginated — so «ملغاة ٣» stays 3 after
  /// «ملغاة» is chosen, instead of collapsing to whatever the filter
  /// left on screen. Its key order is the backend's own status
  /// vocabulary, which reads from "not paid yet" through to
  /// "cancelled", and the strip follows it.
  ///
  /// `all` is dropped — «الكل» is the strip's own first chip and takes
  /// its number from the total — and so is any status the customer has
  /// none of: a chip for an empty status asks the reader to work out
  /// which ones apply to them.
  ///
  /// The FALLBACK counts [entries] in the order they first appear. It
  /// is right for exactly the case that produces it — an older server,
  /// or a payload with no `meta` — because this call is unpaginated
  /// and every row is therefore present.
  static List<BookingStatusCount> countsFor(
    List<MyWorkshopEntry> entries, {
    Map<String, int> serverCounts = const {},
  }) {
    if (serverCounts.isNotEmpty) {
      return [
        for (final row in serverCounts.entries)
          if (row.key != 'all' && row.value > 0)
            BookingStatusCount(status: row.key, count: row.value),
      ];
    }

    final tally = <String, int>{};
    for (final entry in entries) {
      tally[entry.status] = (tally[entry.status] ?? 0) + 1;
    }
    return [
      for (final row in tally.entries)
        BookingStatusCount(status: row.key, count: row.value),
    ];
  }

  /// «الكل»'s own number.
  ///
  /// The server's `all` when it sent one — it counts the whole history
  /// including any status the strip dropped — and the sum of the chips
  /// otherwise.
  static int totalFor(
    List<BookingStatusCount> counts, {
    Map<String, int> serverCounts = const {},
  }) => serverCounts['all'] ?? counts.fold(0, (sum, row) => sum + row.count);

  @override
  Widget build(BuildContext context) {
    // Nothing to choose between. One status is the list itself, and a
    // lone chip that cannot be turned off is decoration.
    if (counts.length < 2) return const SizedBox.shrink();

    return FilterChipRail(
      // The page wraps everything in `GlobalContainer.shell`, which
      // pads both sides by `spacing.md` — the rail reaches back out
      // through it and puts the inset back on its own content. See
      // [FilterChipRail].
      escape: context.spacing.md,
      chips: [
        FilterChipSpec(
          label: BookingStrings.filterAll,
          count: total,
          selected: selected == null,
          onTap: () => onChanged(null),
        ),
        for (final row in counts)
          FilterChipSpec(
            // The status's own words, from the same lookup the card's
            // badge uses — so a chip and the cards it filters to
            // never disagree.
            label: BookingStrings.status(row.status) ?? row.status,
            count: row.count,
            selected: selected == row.status,
            tint: _tintFor(context, row.status),
            onTap: () => onChanged(selected == row.status ? null : row.status),
          ),
      ],
    );
  }

  /// The same colour the card's own badge reads in.
  static Color _tintFor(
    BuildContext context,
    String status,
  ) => switch (status) {
    'confirmed' || 'attending' || 'completed' => context.statusColors.success,
    'absent' || 'awaiting_pickup' => context.statusColors.warning,
    // `preparing` is AMBER, matching the card's own badge — see
    // `BookingCard._colorFor`.
    'preparing' => context.statusColors.warning,
    'getting_ready' || 'on_the_way' => context.statusColors.info,
    'cancelled' => context.statusColors.error,
    _ => context.statusColors.warning,
  };
}
