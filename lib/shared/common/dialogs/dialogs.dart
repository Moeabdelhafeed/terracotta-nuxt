/// App-owned dialog wrappers — purpose-shaped `show*` helpers over
/// `GlobalDialog`, localized en+ar, returning typed Futures. The
/// deliberate surface-twin of `shared/common/sheets/`: same names,
/// same contracts, same `SheetStrings` copy — pick the sheet on
/// phones, the dialog on desktop-sized windows.
/// Catalog page: /common-dialogs-showcase (Common Hub).
///
/// - [showActionListDialog] — tappable rows, returns picked value.
/// - [showConfirmDialog] — confirm/cancel → `bool` (dismiss = false);
///   presets [showDeleteConfirmDialog], [showLogoutConfirmDialog],
///   [showDiscardChangesDialog].
/// - [showSelectionDialog] — single-select list + optional search.
/// - [showMultiSelectDialog] — checkbox list + Apply/Reset →
///   `List<T>?` (null = dismissed).
/// - [showInputDialog] — one text field + submit → `String?` (the
///   validated replacement for `GlobalDialog.input`).
/// - [showInfoDialog] — read-only explainer with "Got it".
/// - [showFilterDialog] — Filters chrome + Reset/Apply →
///   [FilterSheetResult].
///
/// Item/action types are shared with the sheets ([SheetAction],
/// [SelectionSheetItem]) so call sites can swap surface per bucket
/// without remapping data.
library;

export '../../module/dialog/global_dialog.dart';
export 'action_list_dialog.dart';
export 'confirm_dialog.dart';
export 'filter_dialog.dart';
export 'info_dialog.dart';
export 'input_dialog.dart';
export 'multi_select_dialog.dart';
export 'selection_dialog.dart';
