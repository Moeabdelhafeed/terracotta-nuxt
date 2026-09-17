import 'package:flutter/material.dart';

import '../../../../shared/module/popup/popup.dart';
import '../../chip/global_chip.dart';
import 'text_field_defaults.dart';
import 'text_field_messages.dart';

// ---------------------------------------------------------------------------
// Suggestions config
// ---------------------------------------------------------------------------

@immutable
class SuggestionsConfig {
  const SuggestionsConfig({
    this.items,
    this.async,
    this.asyncDebounce = TextFieldDefaults.suggestionsDebounce,
    this.onAsyncError,
    this.recent,
    this.onRecentDeleted,
    this.onRecentCleared,
    this.maxItems = TextFieldDefaults.suggestionsMaxItems,
    this.inline = false,
    this.showInlineCompletion = false,
    this.completion,
    this.onSelected,
    this.itemBuilder,
    this.suggestionIcon,
    this.recentIcon = Icons.access_time,
    this.trailingBuilder,
    this.groupBy,
    this.isFullScreenWidth = false,
    this.horizontalPadding = 20,
    this.overlayOptions = const GlobalPopupOptions(),
  });

  /// Behavior + animation for the overlay (when [inline] is false). Controls
  /// entrance animation, close-on-scroll, keyboard-aware resize, etc.
  final GlobalPopupOptions overlayOptions;

  /// Static (synchronous) candidates.
  final List<String>? items;

  /// Async lookup — fired on text change, debounced by [asyncDebounce].
  /// Results are merged with [items], so the two are a union of result sets,
  /// not a priority chain.
  final Future<List<String>> Function(String query)? async;

  final Duration asyncDebounce;
  final ValueChanged<String>? onAsyncError;

  /// Recent searches shown at the top of the suggestions overlay.
  final List<String>? recent;
  final ValueChanged<String>? onRecentDeleted;
  final VoidCallback? onRecentCleared;

  final int maxItems;

  /// Render suggestions inline (under the field) instead of in an overlay.
  final bool inline;

  /// Ghost-text completion in-line with the input (Tab / Arrow-right accepts).
  final bool showInlineCompletion;

  /// Dynamic completion provider — given the live text, return the ghost
  /// remainder to append (or null for none). Overrides the list-based
  /// candidate match, for completions DERIVED from the text rather than
  /// picked from [items] (e.g. email-domain ghosting: `john` → `@gmail.com`).
  /// Requires [showInlineCompletion] to be `true`.
  final String? Function(String text)? completion;

  final ValueChanged<String>? onSelected;

  /// Custom item renderer. `isSelected` is provided.
  final Widget Function(
    BuildContext context,
    String suggestion,
    bool isSelected,
  )?
  itemBuilder;

  /// Leading icon on each SUGGESTION row (recents have [recentIcon]).
  /// Null → no leading icon. For a fully custom row use [itemBuilder].
  final IconData? suggestionIcon;

  /// Leading icon on each RECENT row. Defaults to a clock.
  final IconData recentIcon;

  /// Trailing widget per suggestion row (e.g. an insert-arrow / info button).
  /// Rendered after the text; taps inside it don't select the row.
  ///
  /// Use a compact tap surface (`InkResponse` + padded `Icon`) — an
  /// `IconButton` carries Material's 48px tap-target padding and inflates
  /// the row height even with tight `constraints`.
  final Widget Function(BuildContext context, String suggestion)?
  trailingBuilder;

  /// Section label per suggestion — a header row is inserted whenever the
  /// label CHANGES while walking the (order-preserving) result list, so keep
  /// same-group results adjacent. Null (per item or overall) → no header.
  final String? Function(String suggestion)? groupBy;

  /// Suggestions overlay spans full screen width (e.g. global search bars).
  final bool isFullScreenWidth;

  /// Horizontal padding when [isFullScreenWidth] is true.
  final double horizontalPadding;
}

// ---------------------------------------------------------------------------
// Chips config
// ---------------------------------------------------------------------------

// `ChipStyle` used to be declared here too — a six-field copy of the
// chip module's bag, under the SAME name. Importing both was an
// ambiguous-import error, which is the only reason the tags panel had
// to hand-roll an `InputChip` instead of using `GlobalChip`. The one in
// `module/chip/` is the bag now; this file just uses it.

@immutable
class ChipsConfig {
  const ChipsConfig({
    this.initial,
    this.onChanged,
    this.max,
    this.addOnSubmit = false,
    this.separators = const [],
    this.removeLastOnBackspace = false,
    this.beforeAdd,
    this.style,
    this.chipBuilder,
    this.editOnTap = false,
    this.showCounter = false,
  });

  final List<String>? initial;
  final ValueChanged<List<String>>? onChanged;
  final int? max;

  /// Keyboard submit turns the typed text into a chip (editor clears,
  /// focus kept for the next tag) instead of bubbling to `onSubmitted`.
  /// A rejected add ([beforeAdd] veto / duplicate / [max]) keeps the text
  /// so the user sees what didn't land. Empty text submits normally.
  final bool addOnSubmit;

  /// Characters that commit the pending text as a chip mid-typing
  /// (`[',']` — typing a comma chips what's before it). A paste
  /// containing separators explodes into multiple chips; the segment
  /// after the last separator stays in the editor.
  final List<String> separators;

  /// Backspace in an EMPTY editor removes the last chip (Gmail
  /// behavior). Hardware/desktop keyboards always; soft keyboards where
  /// the platform reports the key event.
  final bool removeLastOnBackspace;

  /// Normalize / veto every add path (submit, separator, suggestion
  /// pick): return the cleaned tag, or null to reject. Duplicate + [max]
  /// checks run on the RETURNED value. Tip: map a duplicate to the
  /// EXISTING chip's exact value (instead of rejecting) — the module's
  /// own dup check then pulses the existing chip as feedback.
  final String? Function(String raw)? beforeAdd;

  /// Default-chip visual overrides. Ignored when [chipBuilder] is set.
  final ChipStyle? style;

  /// Full control over one chip. Call [onDeleted] from your delete
  /// affordance; wrap interactive parts in your own Semantics.
  final Widget Function(
    BuildContext context,
    String chip,
    VoidCallback onDeleted,
  )?
  chipBuilder;

  /// Tapping a chip pops it back into the editor as text (focused, caret
  /// at end) for correction — Gmail behavior.
  final bool editOnTap;

  /// Show a `3/5` tag counter row under the field (needs [max]).
  final bool showCounter;
}

// ---------------------------------------------------------------------------
// Voice input config
// ---------------------------------------------------------------------------

/// Speech-to-text adapter. Kept abstract so the widget has no DI dependency.
/// Adopters pass an implementation (typically wrapping `SpeechToTextService`)
/// via [VoiceInputConfig].
abstract class TextFieldSpeechAdapter {
  Future<void> start({
    String? localeId,
    required void Function(String text, bool isFinal) onResult,
    required void Function(String error) onError,
  });
  Future<void> stop();
  void cancel();
}

@immutable
class VoiceInputConfig {
  const VoiceInputConfig({required this.adapter, this.locale});

  /// Built-in path: widget drives [adapter.start] / [adapter.stop].
  final TextFieldSpeechAdapter adapter;

  /// Speech locale (e.g. `en_US`).
  final String? locale;
}

// ---------------------------------------------------------------------------
// Counters config (char + word)
// ---------------------------------------------------------------------------

@immutable
class CountersConfig {
  const CountersConfig({
    this.showCharCount = false,
    this.showWordCount = false,
  });

  /// Show `X/maxLength` (requires [TextFieldBehavior.maxLength]).
  final bool showCharCount;

  /// Show `N words`.
  final bool showWordCount;
}

// ---------------------------------------------------------------------------
// Animations config
// ---------------------------------------------------------------------------

@immutable
class AnimationsConfig {
  const AnimationsConfig({
    this.shakeOnError = false,
    this.pulseOnInput = false,
    this.animateIdentifier = false,
    this.floatingLabel = false,
    this.messageAnimation = FieldMessageAnimation.fade,
    this.messageSlideFrom = FieldMessageSlideFrom.start,
  });

  /// Horizontal shake when an error appears.
  final bool shakeOnError;

  /// Tiny scale pulse on every keystroke.
  final bool pulseOnInput;

  /// Identifier header text grows + tints on focus.
  final bool animateIdentifier;

  /// Material floating label behavior.
  final bool floatingLabel;

  /// Entrance animation for the message rows below the field (validator
  /// error + [FieldMessage]s). Replays when a row's text changes.
  final FieldMessageAnimation messageAnimation;

  /// Edge a [FieldMessageAnimation.slide] row enters from
  /// (start/end are Directionality-aware).
  final FieldMessageSlideFrom messageSlideFrom;
}
