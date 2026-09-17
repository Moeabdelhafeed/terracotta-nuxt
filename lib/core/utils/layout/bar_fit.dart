/// Which control GROUPS fit on a bar, and which move to its overflow
/// menu.
///
/// A toolbar that hides buttons one at a time produces broken controls:
/// the PDF viewer's zoom pair lost its plus and kept its minus, which
/// is worse than losing both. So the unit is a GROUP — controls that
/// only make sense together — and a group is shown whole or not at all.
///
/// Nothing is ever hidden, only MOVED. The caller puts what does not
/// fit into a menu, which is the deal that makes dropping a group
/// acceptable in the first place.
///
/// Lives in core because two modules follow this rule — the PDF
/// viewer's bottom bar and the video player's control bar — and the
/// alternative was the same ten lines drifting apart in two places.
library;

/// The indices of [slots] that fit inside [budget].
///
/// [slots] is how many button-widths each group needs, in the order
/// they should be offered; [unit] is one button-width.
///
/// Later groups are still considered after an earlier one is dropped: a
/// wide group failing must not strand the narrow ones behind it. That
/// reorders nothing — the survivors keep their original order — it only
/// means the bar fills rather than truncating at the first refusal.
///
/// [budget] must ALREADY have the overflow button's own width taken out
/// where one is needed. Dropping a control to make room for the button
/// that holds it would be the wrong way round.
List<int> barFit({
  required double budget,
  required List<int> slots,
  required double unit,
}) {
  final shown = <int>[];
  var left = budget;
  for (var i = 0; i < slots.length; i++) {
    final width = slots[i] * unit;
    if (width > left) continue;
    left -= width;
    shown.add(i);
  }
  return shown;
}
