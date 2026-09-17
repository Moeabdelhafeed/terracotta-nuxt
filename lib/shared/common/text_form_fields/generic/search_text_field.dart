import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/field_strings.dart';
import '../../../../core/tokens/extensions.dart';
import '../../../module/chip/global_chip.dart';
import '../../../module/search/global_search_controller.dart';
import '../../../module/text_field/global_text_field.dart';

export '../../../module/search/global_search_controller.dart'
    show GlobalSearchController;

/// Search text field — search-icon prefix, clear-button suffix, debounced
/// `onChanged`, and:
///
/// * **Suggestions** — static [suggestions] and/or [suggestionsAsync]
///   (debounced, stale results dropped, loading row while in flight);
///   [onSuggestionSelected] on pick.
/// * **Voice** — pass a [speechAdapter] (e.g.
///   `SpeechToTextTextFieldAdapter(getIt<SpeechToTextService>())`) for a mic
///   suffix that dictates the query.
/// * **Persistent recents** — pass a [searchController]
///   (`GlobalSearchController(historyCubit: …)`): input/submit/recents/
///   loading are wired automatically and history survives restarts. The
///   manual [recentSearches] trio is for caller-owned lists.
/// * **Scopes** — [scopes] renders a filter-chip row under the field
///   (All / Cities / …); selection is caller-owned via [selectedScope] +
///   [onScopeChanged].
class SearchTextField extends StatelessWidget {
  const SearchTextField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.label,
    this.identifier,
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
    this.showSearchIcon = true,
    this.suggestionIcon = Icons.search_rounded,
    this.suggestionTrailingBuilder,
    this.suggestionGroupBy,
    this.speechAdapter,
    this.speechLocale,
    this.searchController,
    this.isLoading = false,
    this.scopes,
    this.selectedScope,
    this.onScopeChanged,
    this.style,
    this.sizing,
  });

  final TextEditingController controller;
  final void Function(String) onChanged;
  final String? label;
  final String? identifier;

  /// Null → localized default.
  final String? hint;

  /// Idle period before [onChanged] fires (module `onChangedDelay`).
  final Duration debounce;

  final bool enabled;
  final FocusNode? focusNode;
  final void Function(String)? onSubmitted;

  /// Caller-owned recents (ignored when [searchController] is set).
  final List<String>? recentSearches;
  final ValueChanged<String>? onRecentSearchDeleted;
  final VoidCallback? onRecentSearchesCleared;

  /// Static suggestion pool (filtered as you type).
  final List<String>? suggestions;

  /// Async lookup — debounced by the module, stale responses dropped, a
  /// loading row shows while in flight.
  final Future<List<String>> Function(String query)? suggestionsAsync;

  /// Fired when a suggestion or recent row is tapped (the field text is
  /// already filled by then).
  final ValueChanged<String>? onSuggestionSelected;

  /// Ghost-complete the query inline from recents + static [suggestions]
  /// (Tab / → accepts). On by default.
  final bool showInlineCompletion;

  /// Magnifier inside the field. On by default.
  ///
  /// Turn it off where the surrounding chrome already says "search" —
  /// an app bar in search mode, for one, where the icon just repeats
  /// what the whole bar is for and eats width from the query.
  final bool showSearchIcon;

  /// Leading icon on each suggestion row (null → none). Recents keep their
  /// clock icon.
  final IconData? suggestionIcon;

  /// Trailing widget per suggestion row (e.g. an insert-arrow button) —
  /// its taps don't select the row.
  final Widget Function(BuildContext context, String suggestion)?
  suggestionTrailingBuilder;

  /// Section label per suggestion — inserts a header row whenever the label
  /// changes down the result list (keep same-group results adjacent).
  final String? Function(String suggestion)? suggestionGroupBy;

  /// Mic suffix — dictates into the field. Inject the adapter; no `getIt`
  /// here.
  final TextFieldSpeechAdapter? speechAdapter;

  /// Speech locale for [speechAdapter] (e.g. `ar_JO`).
  final String? speechLocale;

  /// Full search harness: debounce + async results + PERSISTED recents
  /// (`SearchHistoryCubit`). When set, it drives input/submit/recents/
  /// loading and the manual recents params are ignored.
  final GlobalSearchController? searchController;

  /// External loading flag → suffix spinner (the [searchController] path
  /// drives this automatically).
  final bool isLoading;

  /// Per-call visual override (wins over the app-wide theme) — the
  /// standard wrapper-contract escape hatch (drawer/app-bar search
  /// customise fill + radius through this).
  final TextFieldStyle? style;

  /// Box geometry (height / width / density).
  final TextFieldSizing? sizing;

  /// Filter scopes rendered as a chip row under the field.
  final List<String>? scopes;
  final String? selectedScope;
  final ValueChanged<String>? onScopeChanged;

  @override
  Widget build(BuildContext context) {
    final sc = searchController;
    if (sc == null) return _build(context, null);
    return ListenableBuilder(
      listenable: sc,
      builder: (context, _) => _build(context, sc),
    );
  }

  Widget _build(BuildContext context, GlobalSearchController? sc) {
    final recents = sc?.recents ?? recentSearches;
    final hasSuggestions =
        recents != null || suggestions != null || suggestionsAsync != null;

    final field = GlobalTextFormField(
      controller: controller,
      label: label,
      identifier: identifier,
      hint: hint ?? FieldStrings.searchHint,
      focusNode: focusNode,
      style: style ?? const TextFieldStyle(),
      sizing: sizing ?? const TextFieldSizing(),
      behavior: TextFieldBehavior(
        textInputAction: TextInputAction.search,
        onChangedDelay: debounce,
        enabled: enabled,
      ),
      slots: TextFieldSlots(
        prefixIcon: showSearchIcon
            ? Padding(
                padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
                child: Icon(
                  Icons.search_rounded,
                  color: context.textColors.secondary,
                ),
              )
            : null,
      ),
      features: TextFieldFeatures(
        showClearButton: true,
        suffixLoading: sc?.loading ?? isLoading,
        voice: speechAdapter == null
            ? null
            : VoiceInputConfig(adapter: speechAdapter!, locale: speechLocale),
        suggestions: hasSuggestions
            ? SuggestionsConfig(
                items: suggestions ?? const [],
                async: suggestionsAsync,
                // Recents render ON TOP of the suggestion rows (module
                // default) — the standard search-box layout.
                recent: recents,
                onRecentDeleted: sc?.removeRecent ?? onRecentSearchDeleted,
                onRecentCleared: sc?.clearRecents ?? onRecentSearchesCleared,
                // Ghost completion from recents + static items.
                showInlineCompletion: showInlineCompletion,
                suggestionIcon: suggestionIcon,
                trailingBuilder: suggestionTrailingBuilder,
                groupBy: suggestionGroupBy,
                onSelected: (s) {
                  sc?.onRecentTapped(s);
                  onSuggestionSelected?.call(s);
                },
              )
            : null,
      ),
      callbacks: TextFieldCallbacks(
        onChanged: (v) {
          sc?.onInput(v);
          onChanged(v);
        },
        onSubmitted: (v) {
          sc?.submit(v);
          onSubmitted?.call(v);
        },
      ),
    );

    final scopeList = scopes;
    if (scopeList == null || scopeList.isEmpty) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        field,
        SizedBox(height: context.spacing.sm),
        Wrap(
          spacing: context.spacing.xs,
          runSpacing: context.spacing.xs,
          children: [
            for (final scope in scopeList)
              GlobalChip(
                label: scope,
                selected: scope == selectedScope,
                enabled: enabled,
                onSelected: (_) => onScopeChanged?.call(scope),
              ),
          ],
        ),
      ],
    );
  }
}
