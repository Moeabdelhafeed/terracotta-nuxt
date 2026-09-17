import 'package:flutter/foundation.dart';

import 'list_models.dart';

/// Standalone selection state for a [GlobalList]. Kept separate
/// from [GlobalListController] so paginated lists don't have to
/// carry selection plumbing they don't use, and selection-only
/// lists don't have to instantiate fetch state they don't need.
///
/// Pass the controller to `GlobalList` via the `selection`
/// parameter; the widget will rebuild on selection changes and
/// honour [mode] when an item is tapped (when a tap handler is
/// wired through the item builder).
class ListSelectionController<T> extends ChangeNotifier {
  ListSelectionController({
    this.mode = SelectionMode.multi,
    Iterable<T> initial = const [],
  }) : _selected = {...initial};

  final SelectionMode mode;
  final Set<T> _selected;

  /// All currently-selected items. Returns an unmodifiable view —
  /// mutate via [toggle] / [select] / [deselect] / [clear].
  Set<T> get selected => Set.unmodifiable(_selected);

  bool isSelected(T item) => _selected.contains(item);

  void toggle(T item) {
    if (mode == SelectionMode.none) return;
    if (_selected.contains(item)) {
      _selected.remove(item);
    } else {
      if (mode == SelectionMode.single) _selected.clear();
      _selected.add(item);
    }
    notifyListeners();
  }

  void select(T item) {
    if (mode == SelectionMode.none) return;
    if (mode == SelectionMode.single) _selected.clear();
    if (_selected.add(item)) notifyListeners();
  }

  void deselect(T item) {
    if (_selected.remove(item)) notifyListeners();
  }

  void selectAll(Iterable<T> items) {
    if (mode == SelectionMode.none) return;
    final before = _selected.length;
    if (mode == SelectionMode.single) {
      _selected
        ..clear()
        ..add(items.first);
    } else {
      _selected.addAll(items);
    }
    if (_selected.length != before) notifyListeners();
  }

  void clear() {
    if (_selected.isEmpty) return;
    _selected.clear();
    notifyListeners();
  }

  /// Selects all items in `items[from..=to]` (inclusive). Used to
  /// implement Shift+click range selection on top of the current
  /// anchor. `from` and `to` can be in either order — they are
  /// normalised internally.
  void selectRange(int from, int to, List<T> items) {
    if (mode != SelectionMode.multi) return;
    final lo = from < to ? from : to;
    final hi = from < to ? to : from;
    if (lo < 0 || hi >= items.length) return;
    final before = _selected.length;
    for (var i = lo; i <= hi; i++) {
      _selected.add(items[i]);
    }
    if (_selected.length != before) notifyListeners();
  }
}
