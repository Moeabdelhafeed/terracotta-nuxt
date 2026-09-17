import 'package:flutter/material.dart';

import '../../module/app_bar/global_app_bar.dart';
import '../../module/text_field/text_field.dart';
import '../text_form_fields/generic/search_text_field.dart';

/// A [GlobalAppBar] in search mode whose field is the app's own
/// [SearchTextField] — debounce, recent searches, suggestions, scope
/// chips, voice input and a loading spinner.
///
/// ## Why this is not inside the app bar module
///
/// `app_bar` is a PRIMITIVE module, and primitives may not import
/// `shared/common/` (see `lib/shared/module/CLAUDE.md`). The dependency
/// runs one way: commons compose primitives, never the reverse, so a
/// commons wrapper that used an app bar would otherwise close a cycle.
///
/// So the module keeps a deliberately bare search field and exposes a
/// `searchField` slot; this wrapper fills it. Everything the search
/// field can do is reachable here, and nothing had to move layers.
///
/// ```dart
/// Scaffold(
///   appBar: SearchAppBar(
///     controller: _query,
///     onChanged: _search,
///     recentSearches: _recents,
///     suggestionsAsync: api.suggest,
///   ),
/// )
/// ```
class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SearchAppBar({
    required this.controller,
    required this.onChanged,
    super.key,
    this.hint,
    this.debounce = const Duration(milliseconds: 250),
    this.enabled = true,
    this.focusNode,
    this.onSubmitted,
    this.recentSearches,
    this.onRecentSearchDeleted,
    this.onRecentSearchesCleared,
    this.suggestions,
    this.suggestionsAsync,
    this.onSuggestionSelected,
    this.showInlineCompletion = true,
    this.searchController,
    this.isLoading = false,
    this.scopes,
    this.selectedScope,
    this.onScopeChanged,
    this.fieldStyle,
    this.actions,
    this.showBack = true,
    this.onBack,
    this.style = const AppBarStyle(),
  });

  // ─── Field ─────────────────────────────────────────────────
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? hint;
  final Duration debounce;
  final bool enabled;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final List<String>? recentSearches;
  final ValueChanged<String>? onRecentSearchDeleted;
  final VoidCallback? onRecentSearchesCleared;
  final List<String>? suggestions;
  final Future<List<String>> Function(String)? suggestionsAsync;
  final ValueChanged<String>? onSuggestionSelected;
  final bool showInlineCompletion;
  final GlobalSearchController? searchController;
  final bool isLoading;
  final List<String>? scopes;
  final String? selectedScope;
  final ValueChanged<String>? onScopeChanged;

  /// Overrides for the field's own visual bag, merged OVER
  /// [blendIntoBar].
  final TextFieldStyle? fieldStyle;

  /// Makes the field read as part of the bar rather than as a control
  /// sitting on it.
  ///
  /// A search field in an app bar is the bar's whole content, so the
  /// usual affordances work against it: a fill colour paints a second
  /// surface on top of the bar's own, and a focus border draws a box
  /// around text the user is already obviously editing. Both go.
  ///
  /// Setting `base` is NOT enough: `TextFieldStyle.defaults` and the
  /// app-wide theme both set `focused` explicitly, and a state-specific
  /// side always overlays `base` — so the focus ring survived at
  /// `focusedBorderWidth` in a transparent colour. `focused` has to be
  /// zeroed by name. `error` is deliberately left alone: an app-bar
  /// search has no validator, so it cannot fire, and silently killing
  /// error styling would be worse than dead config.
  /// The horizontal inset goes too. With no fill and no border there is
  /// no box for it to sit inside — it only pushes the query away from
  /// the bar's own start edge, out of line with the title of every
  /// other screen. Vertical padding stays: it is what centres the text
  /// in the toolbar.
  static const TextFieldStyle blendIntoBar = TextFieldStyle(
    fillColor: Colors.transparent,
    border: TextFieldBorderStyle(
      base: TextFieldBorderSide(color: Colors.transparent, width: 0),
      focused: TextFieldBorderSide(color: Colors.transparent, width: 0),
    ),
    contentPadding: EdgeInsets.symmetric(
      vertical: AppBarDefaults.searchFieldPadding,
    ),
  );

  // ─── Bar ───────────────────────────────────────────────────
  final List<Widget>? actions;
  final bool showBack;
  final VoidCallback? onBack;
  final AppBarStyle style;

  @override
  Size get preferredSize => Size.fromHeight(style.preferredToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return GlobalAppBar(
      searchMode: true,
      showBack: showBack,
      onBack: onBack,
      actions: actions,
      style: style,
      searchField: SearchTextField(
        controller: controller,
        onChanged: onChanged,
        hint: hint,
        debounce: debounce,
        enabled: enabled,
        focusNode: focusNode,
        onSubmitted: onSubmitted,
        recentSearches: recentSearches,
        onRecentSearchDeleted: onRecentSearchDeleted,
        onRecentSearchesCleared: onRecentSearchesCleared,
        suggestions: suggestions,
        suggestionsAsync: suggestionsAsync,
        onSuggestionSelected: onSuggestionSelected,
        showInlineCompletion: showInlineCompletion,
        // The bar IS the search affordance — a magnifier inside it just
        // repeats that and takes width from the query.
        showSearchIcon: false,
        searchController: searchController,
        isLoading: isLoading,
        scopes: scopes,
        selectedScope: selectedScope,
        onScopeChanged: onScopeChanged,
        style: blendIntoBar.mergedWith(fieldStyle),
      ),
    );
  }
}
