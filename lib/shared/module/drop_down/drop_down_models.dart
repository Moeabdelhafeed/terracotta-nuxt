import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// DropdownItemOverride
// ---------------------------------------------------------------------------

/// Overrides for how a [DropdownItem] renders inside the overlay dropdown,
/// when you want a different appearance from the trigger display.
@immutable
class DropdownItemOverride {
  final String? label;
  final Widget? leading;
  final Widget? trailing;

  const DropdownItemOverride({this.label, this.leading, this.trailing});
}

// ---------------------------------------------------------------------------
// DropdownItem — with equality for didUpdateWidget comparison
// ---------------------------------------------------------------------------

@immutable
class DropdownItem<T> {
  final T value;
  final String label;
  final Widget? leading;
  final Widget? trailing;

  /// When `false` the row renders at reduced opacity, is not tappable, and
  /// reports `Semantics(enabled: false)`.
  final bool enabled;

  /// Optional overrides for how this item appears inside the dropdown overlay.
  /// When null, the trigger's [label], [leading], and [trailing] are used.
  final DropdownItemOverride? dropdownOverride;

  /// Extra search haystack — matched by the overlay's search field IN
  /// ADDITION to [label]. Use for aliases the label doesn't show (a country
  /// item labeled `+962` passes `'Jordan +962 JO'` so name, dial code and
  /// ISO code all hit).
  final String? searchText;

  const DropdownItem({
    required this.value,
    required this.label,
    this.leading,
    this.trailing,
    this.enabled = true,
    this.dropdownOverride,
    this.searchText,
  });

  /// True when [query] (already lowercased) hits [label] or [searchText].
  bool matchesQuery(String query) =>
      label.toLowerCase().contains(query) ||
      (searchText?.toLowerCase().contains(query) ?? false);

  /// The label shown in the dropdown overlay.
  String get effectiveDropdownLabel => dropdownOverride?.label ?? label;

  /// The leading widget shown in the dropdown overlay.
  Widget? get effectiveDropdownLeading => dropdownOverride?.leading ?? leading;

  /// The trailing widget shown in the dropdown overlay.
  Widget? get effectiveDropdownTrailing =>
      dropdownOverride?.trailing ?? trailing;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DropdownItem<T> &&
          other.value == value &&
          other.label == label &&
          other.enabled == enabled &&
          other.searchText == searchText;

  @override
  int get hashCode => Object.hash(value, label, enabled, searchText);
}

// ---------------------------------------------------------------------------
// DropdownGroup — grouped items
// ---------------------------------------------------------------------------

@immutable
class DropdownGroup<T> {
  final String label;
  final List<DropdownItem<T>> items;

  const DropdownGroup({
    required this.label,
    required this.items,
  });
}

// ---------------------------------------------------------------------------
// GlobalDropdownController — programmatic open/close/clear
// ---------------------------------------------------------------------------

/// Thin adapter over the dropdown's internal popup controller. `open` /
/// `close` / `isOpen` delegate to the owning `GlobalDropdown`'s
/// `GlobalPopupController` (or its inline open state); `clear` fires the
/// widget's clear-selection callback.
///
/// One controller drives exactly ONE dropdown at a time. Attachment is
/// OWNER-AWARE: on a remount (key change, subtree restructure) Flutter
/// runs the new State's `initState` BEFORE the old State's deferred
/// `dispose`, so `attach` replaces the previous owner and the stale
/// owner's `detach` no-ops — the controller keeps working across
/// remounts instead of going inert (the old unconditional detach nulled
/// the fresh attachment).
class GlobalDropdownController {
  Object? _owner;
  VoidCallback? _openCallback;
  VoidCallback? _closeCallback;
  VoidCallback? _clearCallback;
  bool Function()? _isOpenGetter;

  bool get isOpen => _isOpenGetter?.call() ?? false;

  void open() => _openCallback?.call();

  void close() => _closeCallback?.call();

  void clear() => _clearCallback?.call();

  void attach({
    required Object owner,
    required VoidCallback onOpen,
    required VoidCallback onClose,
    required VoidCallback onClear,
    required bool Function() isOpenGetter,
  }) {
    _owner = owner;
    _openCallback = onOpen;
    _closeCallback = onClose;
    _clearCallback = onClear;
    _isOpenGetter = isOpenGetter;
  }

  /// Clears the attachment — but only when [owner] is still the current
  /// owner. A replaced (remounted-away) State's deferred dispose must
  /// not tear down its successor's wiring.
  void detach({required Object owner}) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _openCallback = null;
    _closeCallback = null;
    _clearCallback = null;
    _isOpenGetter = null;
  }
}
