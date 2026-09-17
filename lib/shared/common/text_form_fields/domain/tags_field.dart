import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/tags_field_strings.dart';
import '../../../module/chip/global_chip.dart';
import '../../../module/text_field/global_text_field.dart';

/// Tags / chips input — free-text entry that commits on submit or
/// separator, suggestion pick-to-add, Gmail-style backspace-pop. For
/// interests, skills, filters.
///
/// Entry paths (all funneled through one normalize/veto pipeline):
///  * TYPE + submit (keyboard done/enter) — text becomes a chip, editor
///    clears, focus stays for the next tag.
///  * [separators] (default comma) commit mid-typing; a pasted
///    `"flutter, dart, bloc"` explodes into three chips.
///  * Pick from the suggestions overlay ([suggestions] /
///    [asyncSuggestions]).
///  * Backspace in an empty editor pops the last chip.
///
/// Normalization before every add: trim + inner-space collapse, optional
/// [lowercase], case-insensitive dedupe, [maxTagLength], [tagValidator],
/// and — when [allowCustomTags] is false — membership in [suggestions]
/// (canonical casing taken from the list). Rejections surface as an error
/// row; duplicates drop silently.
///
/// Emits the tag list via [onTagsChanged]. [minTags] / [maxTags] bound it
/// ([minTags] validates with a localized message, [maxTags] hard-caps).
///
/// ```dart
/// TagsField(
///   identifier: 'Interests',
///   suggestions: kInterests,
///   maxTags: 5,
///   onTagsChanged: (tags) => cubit.setInterests(tags),
/// )
/// ```
class TagsField extends StatefulWidget {
  const TagsField({
    super.key,
    this.controller,
    this.initialTags = const [],
    this.onTagsChanged,
    this.onSubmitted,
    this.label,
    this.identifier,
    this.hint,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.focusNode,
    this.textInputAction = TextInputAction.done,
    this.validationMode = ValidationMode.onInteraction,
    this.deferToParentForm = true,
    this.messages = const [],
    this.showSuccess = false,
    this.minTags = 0,
    this.maxTags,
    this.suggestions,
    this.asyncSuggestions,
    this.allowCustomTags = true,
    this.lowercase = false,
    this.maxTagLength,
    this.tagValidator,
    this.separators = const [','],
    this.showPrefixIcon = true,
    this.chipStyle,
    this.chipBuilder,
    this.editChipOnTap = true,
    this.showTagCounter = true,
    this.style,
    this.sizing,
  }) : assert(
         allowCustomTags || suggestions != null,
         'allowCustomTags: false needs a suggestions list to pick from.',
       );

  /// Editor controller for the PENDING tag text (transient — committed
  /// tags live in the chip list). Null → internal.
  final TextEditingController? controller;

  /// Seed chips. Changing the list CONTENT resets the field's chips.
  final List<String> initialTags;

  /// The committed tag list on every change (add, remove, pop).
  final ValueChanged<List<String>>? onTagsChanged;

  /// Fires only for an EMPTY-editor submit (non-empty submits become
  /// chips) — "user is done with the field".
  final void Function(String)? onSubmitted;

  final String? label;
  final String? identifier;

  /// Null → localized "Add a tag…".
  final String? hint;

  final bool enabled;
  final bool readOnly;
  final String? errorText;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final ValidationMode validationMode;

  /// Keep `true` inside a `Form`; `false` for standalone fields.
  final bool deferToParentForm;

  /// Status rows below the field (sorted by severity).
  final List<FieldMessage> messages;

  /// Show a success row when the field is valid.
  final bool showSuccess;

  /// Fewer tags fail validation with a localized "Add at least N" row.
  final int minTags;

  /// Hard cap — further adds are ignored.
  final int? maxTags;

  /// Static suggestion candidates (overlay pick-to-add).
  final List<String>? suggestions;

  /// Async lookup, merged with [suggestions].
  final Future<List<String>> Function(String query)? asyncSuggestions;

  /// `false` → only tags present in [suggestions] land (controlled
  /// vocabulary: skills taxonomy, category filters).
  final bool allowCustomTags;

  /// Lower-case every tag on add.
  final bool lowercase;

  /// Longer tags are rejected with a localized message.
  final int? maxTagLength;

  /// Domain check on the NORMALIZED tag — return an error message to
  /// reject (shown as an error row), null to accept.
  final String? Function(String tag)? tagValidator;

  /// Characters that commit the pending text mid-typing. Default comma.
  final List<String> separators;

  final bool showPrefixIcon;

  /// Default-chip visual overrides (colors, radius, border, label style).
  final ChipStyle? chipStyle;

  /// Full control over one chip (category colors, avatars). Call the
  /// given `onDeleted` from your delete affordance.
  final Widget Function(
    BuildContext context,
    String chip,
    VoidCallback onDeleted,
  )?
  chipBuilder;

  /// Tap a chip to pop it back into the editor for correction (Gmail
  /// behavior). Default on.
  final bool editChipOnTap;

  /// `3/5` counter row under the field when [maxTags] is set. Runs
  /// warning-colored at the cap. Default on.
  final bool showTagCounter;

  /// Per-call visual override (wins over the app-wide theme).
  final TextFieldStyle? style;

  /// Box geometry (height / width / fit-to-content / density).
  final TextFieldSizing? sizing;

  @override
  State<TagsField> createState() => _TagsFieldState();
}

class _TagsFieldState extends State<TagsField> {
  TextEditingController? _internalController;
  late List<String> _tags = List.of(widget.initialTags);

  /// Why the last add was rejected — error row until the next edit.
  String? _rejectMessage;

  static final _innerSpace = RegExp(r'\s+');

  TextEditingController get _controller =>
      widget.controller ?? (_internalController ??= TextEditingController());

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  void _reject(String message) {
    if (_rejectMessage != message) setState(() => _rejectMessage = message);
  }

  void _clearReject() {
    if (_rejectMessage != null) setState(() => _rejectMessage = null);
  }

  /// The module's `beforeAdd` hook — every add path lands here.
  String? _normalize(String raw) {
    var tag = raw.trim().replaceAll(_innerSpace, ' ');
    if (widget.lowercase) tag = tag.toLowerCase();
    if (tag.isEmpty) return null;
    final maxLen = widget.maxTagLength;
    if (maxLen != null && tag.length > maxLen) {
      _reject(TagsFieldStrings.tooLong(maxLen));
      return null;
    }
    if (!widget.allowCustomTags) {
      final pool = widget.suggestions!;
      final lower = tag.toLowerCase();
      final match = pool.where((s) => s.toLowerCase() == lower).firstOrNull;
      if (match == null) {
        _reject(TagsFieldStrings.notAllowed);
        return null;
      }
      tag = match; // canonical casing from the vocabulary
    }
    final domainError = widget.tagValidator?.call(tag);
    if (domainError != null) {
      _reject(domainError);
      return null;
    }
    // Case-insensitive dedupe: map to the EXISTING chip's exact value —
    // the module's own dup check then pulses that chip as feedback
    // (returning null here would read as a silent veto instead).
    final lower = tag.toLowerCase();
    final existing = _tags.where((e) => e.toLowerCase() == lower).firstOrNull;
    if (existing != null) {
      _clearReject();
      return existing;
    }
    _clearReject();
    return tag;
  }

  void _onChipsChanged(List<String> tags) {
    setState(() => _tags = tags);
    widget.onTagsChanged?.call(tags);
  }

  String? _validator(String? _) {
    if (_tags.length < widget.minTags) {
      return TagsFieldStrings.min(widget.minTags);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hasSuggestions =
        widget.suggestions != null || widget.asyncSuggestions != null;
    return GlobalTextFormField(
      controller: _controller,
      label: widget.label,
      identifier: widget.identifier,
      hint: widget.hint ?? TagsFieldStrings.hint,
      focusNode: widget.focusNode,
      style: widget.style ?? const TextFieldStyle(),
      sizing: widget.sizing ?? const TextFieldSizing(),
      messages: [
        ...widget.messages,
        if (_rejectMessage != null) FieldMessage.error(_rejectMessage!),
        // At the cap further adds are ignored — say so instead of letting
        // the field feel broken.
        if (widget.maxTags != null && _tags.length >= widget.maxTags!)
          FieldMessage.info(TagsFieldStrings.maxReached(widget.maxTags!)),
      ],
      behavior: TextFieldBehavior(
        textInputAction: widget.textInputAction,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
      ),
      validation: TextFieldValidation(
        validator: _validator,
        errorText: widget.errorText,
        mode: widget.validationMode,
        deferToParentForm: widget.deferToParentForm,
        // Count changes must re-check an already-visible min-count error.
        revalidateKey: _tags.length,
      ),
      features: TextFieldFeatures(
        showSuccess: widget.showSuccess,
        chips: ChipsConfig(
          initial: widget.initialTags,
          max: widget.maxTags,
          addOnSubmit: true,
          separators: widget.separators,
          removeLastOnBackspace: true,
          beforeAdd: _normalize,
          onChanged: _onChipsChanged,
          style: widget.chipStyle,
          chipBuilder: widget.chipBuilder,
          editOnTap: widget.editChipOnTap,
          showCounter: widget.showTagCounter,
        ),
        suggestions: hasSuggestions
            ? SuggestionsConfig(
                items: widget.suggestions,
                async: widget.asyncSuggestions,
              )
            : null,
      ),
      slots: TextFieldSlots(
        prefixIcon: widget.showPrefixIcon
            ? Padding(
                padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
                child: Icon(
                  Icons.sell_outlined,
                  color: context.iconColors.primary,
                ),
              )
            : null,
      ),
      callbacks: TextFieldCallbacks(
        onChanged: (_) => _clearReject(),
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}
