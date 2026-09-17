/// App-owned sheet wrappers — purpose-shaped `show*` helpers over
/// `GlobalBottomSheet`, localized en+ar, returning typed Futures.
/// Catalog page: /common-sheets-showcase (Common Hub).
///
/// - [showActionListSheet] — tappable rows, returns picked value.
/// - [showConfirmSheet] — confirm/cancel → `bool` (dismiss = false);
///   presets [showDeleteConfirmSheet], [showLogoutConfirmSheet],
///   [showDiscardChangesSheet].
/// - [showSelectionSheet] — single-select list + optional search.
/// - [showMultiSelectSheet] — checkbox list + Apply/Reset →
///   `List<T>?` (null = dismissed).
/// - [showInputSheet] — one text field + submit → `String?`,
///   keyboard-inset aware.
/// - [showInfoSheet] — read-only explainer with "Got it".
/// - [showFilterSheet] — Filters chrome + Reset/Apply, caller owns
///   the state → [FilterSheetResult].
///
/// Sheets are transient modals: labels evaluate at show-time, so a
/// language flip while one is open keeps the old strings until it is
/// reopened — that's accepted (unlike the persistent selection_fields
/// wrappers, which register locale dependencies).
library;

export '../../module/sheet/global_sheet.dart';
export 'action_list_sheet.dart';
export 'confirm_sheet.dart';
export 'filter_sheet.dart';
export 'info_sheet.dart';
export 'input_sheet.dart';
export 'multi_select_sheet.dart';
export 'selection_sheet.dart';
