import 'package:flutter/material.dart';

import '../sheet/global_sheet.dart';

/// Visual variant for the preference pickers. Each picker honors
/// these — they all render the same options + bind to the same cubit
/// setter, just with different chrome.
///
/// - [pillRow]   horizontal scrollable strip of chips. Compact.
///   Drop into drawer footers, profile rows, onboarding strips.
/// - [list]      tappable rows with icon + label + radio. Settings page.
/// - [segmented] iOS-style segmented control. 2–4 options only.
/// - [dropdown]  collapsed menu. Forms with limited vertical space.
/// - [sheet]     opens a modal bottom sheet on tap. Use when picker
///   itself is shown as a single tappable summary tile.
/// - [dialog]    opens an `AlertDialog`. Same idea as sheet but
///   modal-blocking. Better for short option lists on desktop / web.
enum PickerVariant { pillRow, list, segmented, dropdown, sheet, dialog }

/// Per-instance config shared by all preference pickers.
@immutable
class PickerOptions {
  const PickerOptions({
    this.variant = PickerVariant.list,
    this.title,
    this.subtitle,
    this.icon,
    this.dense = false,
    this.showIcons = true,
    this.padding,
    this.trailing,
    this.searchThreshold = 8,
    this.sheetStyle = const SheetStyle(
      floating: true,
      // The sheet pads its content by 20 on every side, which is
      // right for a form and wrong for a list of ROWS: each row
      // already carries its own vertical padding, so the two stacked.
      // Twelve a side holds the rows off the card's rounded corners —
      // a row that runs into the curve reads as clipped — and eight at
      // the top keeps them off the heading. NOTHING at the bottom: the
      // sheet already pads the home indicator's inset in there, and
      // anything of ours lands on top of it as a visible band under
      // the last option.
      contentPadding: EdgeInsets.only(top: 8, left: 12, right: 12),
    ),
  });

  final PickerVariant variant;

  /// Section heading. Pickers in [PickerVariant.pillRow] / [segmented]
  /// hide the title block; [list] / [sheet] / [dialog] surface it.
  final String? title;
  final String? subtitle;

  /// Leading icon shown next to the title.
  final IconData? icon;

  /// Tighter spacing — used in dense settings or sidebars.
  final bool dense;

  /// Show per-option icons (e.g. light/dark/auto on theme picker).
  final bool showIcons;

  final EdgeInsetsGeometry? padding;

  /// Optional trailing widget on the title row (e.g. a "Reset" button).
  final Widget? trailing;

  /// How many options a sheet or dialog may show before it offers a
  /// filter.
  ///
  /// Eight. Below that the list is shorter than the search field is
  /// worth; past it — a language catalogue, a currency list — scanning
  /// an unfiltered column is the slowest way to answer a question the
  /// reader already knows the answer to. The commons' selection sheet
  /// draws the same line with its own `enableSearch`.
  final int searchThreshold;

  /// The surface [PickerVariant.sheet] opens on.
  ///
  /// FLOATING by default, which is what the app's other pick-one-of-a-
  /// few sheets look like — the media source sheet is the one to
  /// compare against. It used to take the sheet module's plain
  /// default, so the picker's sheet was the odd one out on a screen
  /// beside any of them, AND it wore the sheet's form-shaped content
  /// padding around a list of rows that already had their own.
  ///
  /// It lives here rather than on `PickerStyle` deliberately: it is
  /// another module's bag, and the picker's own must not re-state one.
  final SheetStyle sheetStyle;

  /// This bag's answers laid over [base].
  ///
  /// Every picker ships a localized title, subtitle and icon in its
  /// own defaults, and a caller who wants nothing but a different
  /// VARIANT should keep them. It used to be `options ?? _defaults` —
  /// either all of a caller's or all of the picker's — so
  /// `PickerOptions(variant: sheet)` silently threw the heading away,
  /// and the sheet and the dialog it opened had nothing at the top but
  /// a close button.
  PickerOptions mergedOver(PickerOptions base) => PickerOptions(
    variant: variant,
    title: title ?? base.title,
    subtitle: subtitle ?? base.subtitle,
    icon: icon ?? base.icon,
    dense: dense,
    showIcons: showIcons,
    padding: padding ?? base.padding,
    trailing: trailing ?? base.trailing,
    searchThreshold: searchThreshold,
    sheetStyle: sheetStyle,
  );

  PickerOptions copyWith({
    PickerVariant? variant,
    String? title,
    String? subtitle,
    IconData? icon,
    bool? dense,
    bool? showIcons,
    EdgeInsetsGeometry? padding,
    Widget? trailing,
    int? searchThreshold,
    SheetStyle? sheetStyle,
  }) {
    return PickerOptions(
      variant: variant ?? this.variant,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      dense: dense ?? this.dense,
      showIcons: showIcons ?? this.showIcons,
      padding: padding ?? this.padding,
      trailing: trailing ?? this.trailing,
      searchThreshold: searchThreshold ?? this.searchThreshold,
      sheetStyle: sheetStyle ?? this.sheetStyle,
    );
  }
}
