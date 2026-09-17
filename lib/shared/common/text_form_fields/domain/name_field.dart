import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/auth_strings.dart';
import '../../../../core/localization/strings/text_field_strings.dart';
import '../../../../core/localization/strings/validator_strings.dart';
import '../../../../core/localization/tr.dart';
import '../../../../core/utils/validators/validators.dart';
import '../../../../data/services/profanity_filter_service.dart';
import '../../../../generated/l10n.dart';
import '../../../module/text_field/global_text_field.dart';

export '../../../../data/services/profanity_filter_service.dart'
    show ProfanityCheck;

/// What a [NameField] collects — drives the default hint, validator,
/// autofill hint and prefix icon.
enum NameFieldMode {
  /// Given name (autofill: `givenName`).
  first,

  /// Family name (autofill: `familyName`).
  last,

  /// Middle name (autofill: `middleName`).
  middle,

  /// Father's name — common in MENA registration forms. No platform
  /// autofill hint exists.
  father,

  /// The whole name in one input (autofill: `name`). Requires at least
  /// [NameField.minParts] parts — `minParts: 4` for quadruple-name
  /// markets (first / father / grandfather / family).
  full,
}

/// Which script a [NameField] accepts — KYC / government forms collect
/// the name "in Arabic" and "in English" as separate inputs.
enum NameScript {
  /// Any letters (the default).
  any,

  /// Arabic letters only — wrong-script input is blocked at the keyboard
  /// AND fails validation ("Name must use Arabic letters").
  arabic,

  /// Latin letters only.
  latin,
}

/// The parsed value a [NameField] emits on every change — the name split
/// into whitespace parts plus the sync-validity snapshot, so consumers
/// never re-split strings.
@immutable
class FullName {
  const FullName({required this.parts, required this.isValid});

  /// Whitespace-separated parts, in typed order.
  final List<String> parts;

  /// Result of the field's SYNC validator at emit time.
  final bool isValid;

  String get first => parts.isEmpty ? '' : parts.first;

  String get last => parts.length < 2 ? '' : parts.last;

  /// Everything between [first] and [last] (`''` for 1–2 parts).
  String get middle =>
      parts.length <= 2 ? '' : parts.sublist(1, parts.length - 1).join(' ');

  /// The parts re-joined with single spaces.
  String get display => parts.join(' ');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FullName &&
          other.isValid == isValid &&
          listEquals(other.parts, parts);

  @override
  int get hashCode => Object.hash(Object.hashAll(parts), isValid);

  @override
  String toString() => 'FullName($display, valid: $isValid)';
}

/// One name field, five shapes — replaces the old FirstNameField /
/// LastNameField / FullNameField triplet.
///
/// Per-mode defaults: localized hint, mode-specific validator (so a last
/// name never complains about "first name"), platform autofill hint and
/// icon. Input is hardened at the keyboard: only name characters get in
/// ([script]-aware), words are title-cased live ([capitalizeWords] —
/// covers paste and hardware keyboards, no-op on Arabic), and input is
/// trimmed on submit. Full mode shows a parts-progress note
/// ([showPartsProgress]) and emits a parsed [FullName] via
/// [onNameChanged].
///
/// ```dart
/// NameField(controller: first)                                  // given name
/// NameField(controller: family, mode: NameFieldMode.last)
/// NameField(controller: full, mode: NameFieldMode.full)         // ≥2 parts
/// NameField(                                                    // gov form
///   controller: arabicName,
///   mode: NameFieldMode.full,
///   minParts: 4,
///   script: NameScript.arabic,
///   onNameChanged: (n) => cubit.setName(n.first, n.last),
/// )
/// ```
class NameField extends StatefulWidget {
  const NameField({
    super.key,
    required this.controller,
    this.mode = NameFieldMode.first,
    this.minParts = 2,
    this.script = NameScript.any,
    this.profanityCheck = ProfanityCheck.off,
    this.onNameChanged,
    this.showPartsProgress = true,
    this.capitalizeWords = true,
    this.onChanged,
    this.onSubmitted,
    this.label,
    this.identifier,
    this.required = false,
    this.hint,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.validator,
    this.asyncValidator,
    this.asyncDebounce,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.validationMode = ValidationMode.onInteraction,
    this.deferToParentForm = true,
    this.errorIcon,
    this.errorBuilder,
    this.messages = const [],
    this.showSuccess = false,
    this.successText,
    this.showPrefixIcon = true,
    this.suffix,
    this.style,
    this.sizing,
    this.trimOnSubmit = true,
    this.autofillHints,
  }) : assert(
         minParts >= 2,
         'minParts is the FULL-name part floor — 2 or more.',
       );

  final TextEditingController controller;

  /// Appends a `*` to the identifier (or hint) — see
  /// [GlobalTextFormField.required].
  final bool required;

  /// Which name this field collects — see [NameFieldMode].
  final NameFieldMode mode;

  /// Minimum whitespace-separated parts for [NameFieldMode.full]
  /// (each ≥ 2 letters). Ignored by the single-part modes.
  final int minParts;

  /// Restrict accepted letters to one script — blocks wrong-script
  /// KEYSTROKES and fails validation on wrong-script text that gets in
  /// another way (prefill). See [NameScript].
  final NameScript script;

  /// Flagged-word reaction ([ProfanityFilterService] — local lists,
  /// word-boundary aware). `warn` shows an orange note the user can
  /// ignore — the right setting for REAL names, where word lists collide
  /// with legitimate ones; `block` fails validation — for usernames /
  /// display names.
  final ProfanityCheck profanityCheck;

  /// Parsed name on every change — see [FullName] (`parts` / `first` /
  /// `last` / `middle` / `isValid`). Fires for every mode (single-part
  /// modes emit one part).
  final ValueChanged<FullName>? onNameChanged;

  /// Full mode only: an info row counting parts while the name is
  /// incomplete (`2 of 4 name parts`). Hidden when empty or complete.
  final bool showPartsProgress;

  /// Title-case each word live (typing AND paste — the keyboard's own
  /// `TextCapitalization.words` is advisory only). Never lowercases what
  /// the user typed (`McDonald` survives); no-op on caseless scripts.
  final bool capitalizeWords;

  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final String? label;
  final String? identifier;

  /// Null → the mode's localized hint.
  final String? hint;

  final bool enabled;
  final bool readOnly;
  final String? errorText;

  /// Sync check. Null → the mode's validator
  /// (`Validators.validateFirstName` … `validateFullName(minParts:)`),
  /// followed by the [script] check.
  final String? Function(String?)? validator;

  /// Server-side check (e.g. display-name moderation). Runs after the
  /// sync validator passes; spinner in the suffix while in flight.
  final Future<String?> Function(String value)? asyncValidator;

  /// Defaults to [TextFieldDefaults.asyncValidatorDebounce].
  final Duration? asyncDebounce;

  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final ValidationMode validationMode;

  /// Keep `true` inside a `Form`; `false` for standalone fields.
  final bool deferToParentForm;

  /// Icon shown before the error message row.
  final IconData? errorIcon;

  /// Full control over the error row.
  final Widget Function(BuildContext context, String message)? errorBuilder;

  /// Status rows below the field (sorted by severity).
  final List<FieldMessage> messages;

  /// Show a success row when the field is valid (with optional [successText]).
  final bool showSuccess;
  final String? successText;

  final bool showPrefixIcon;

  /// Trailing slot.
  final TextFieldSuffix? suffix;

  /// Per-call visual override (wins over the app-wide theme).
  final TextFieldStyle? style;

  /// Box geometry (height / width / fit-to-content / density).
  final TextFieldSizing? sizing;

  /// Strip surrounding whitespace on keyboard submit.
  final bool trimOnSubmit;

  /// Platform autofill. Null → the mode's hint (`givenName` /
  /// `familyName` / `middleName` / `name`; father has none). Pass
  /// `const []` to disable.
  final List<String>? autofillHints;

  @override
  State<NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<NameField> {
  static final _whitespace = RegExp(r'\s+');

  /// Keystroke filter per script — name characters only (letters, marks,
  /// whitespace, apostrophe, hyphen, dot). Doubles as feature "no digits
  /// or symbols ever enter the field".
  static final _allowAny = RegExp(r"[\p{L}\p{M}\s'\-.]", unicode: true);
  static final _allowArabic = RegExp(
    r"[\p{Script=Arabic}\p{M}\s'\-.]",
    unicode: true,
  );
  static final _allowLatin = RegExp(
    r"[\p{Script=Latin}\p{M}\s'\-.]",
    unicode: true,
  );

  /// A letter OUTSIDE the restricted script (marks/punct excluded) —
  /// validation-side complement of the keystroke filter, for text that
  /// arrives another way (controller prefill).
  static final _violatesArabic = RegExp(
    r'(?![\p{Script=Arabic}])\p{L}',
    unicode: true,
  );
  static final _violatesLatin = RegExp(
    r'(?![\p{Script=Latin}])\p{L}',
    unicode: true,
  );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
  }

  @override
  void didUpdateWidget(covariant NameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onText);
      widget.controller.addListener(_onText);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    super.dispose();
  }

  bool _profanityFlagged = false;
  int _profanityReqId = 0;

  /// The parts-progress row + profanity warning derive from the live
  /// text — rebuild / re-check on it.
  void _onText() {
    if (widget.mode == NameFieldMode.full && widget.showPartsProgress) {
      setState(() {});
    }
    _maybeCheckProfanity();
  }

  Future<void> _maybeCheckProfanity() async {
    if (widget.profanityCheck != ProfanityCheck.warn) return;
    final id = ++_profanityReqId;
    final flagged = await ProfanityFilterService.instance.containsProfanity(
      widget.controller.text,
    );
    if (!mounted || id != _profanityReqId) return;
    if (flagged != _profanityFlagged) {
      setState(() => _profanityFlagged = flagged);
    }
  }

  /// Block-mode profanity gate chained before the caller's async check.
  Future<String?> _effectiveAsyncValidator(String value) async {
    if (widget.profanityCheck == ProfanityCheck.block) {
      final err = await ProfanityFilterService.instance.validateClean(value);
      if (err != null) return err;
    }
    return widget.asyncValidator?.call(value);
  }

  List<String> _partsOf(String text) => text
      .trim()
      .split(_whitespace)
      .where((p) => p.isNotEmpty)
      .toList(growable: false);

  /// Parts that count toward [NameField.minParts] (≥ 2 letters — matches
  /// `Validators.validateFullName`).
  int _countedParts(String text) =>
      _partsOf(text).where((p) => p.length >= 2).length;

  String get _defaultHint => switch (widget.mode) {
    NameFieldMode.first => Tr.t(
      'auth.enter_first_name_hint',
      S.current.auth_enter_first_name_hint,
    ),
    NameFieldMode.last => Tr.t(
      'auth.enter_last_name_hint',
      S.current.auth_enter_last_name_hint,
    ),
    NameFieldMode.middle => AuthStrings.enterMiddleNameHint,
    NameFieldMode.father => AuthStrings.enterFatherNameHint,
    NameFieldMode.full => AuthStrings.enterFullNameHint,
  };

  String? Function(String?) get _modeValidator => switch (widget.mode) {
    NameFieldMode.first => Validators.validateFirstName,
    NameFieldMode.last => Validators.validateLastName,
    NameFieldMode.middle => Validators.validateMiddleName,
    NameFieldMode.father => Validators.validateFatherName,
    NameFieldMode.full => (v) => Validators.validateFullName(
      v,
      minParts: widget.minParts,
    ),
  };

  String? _scriptError(String? value) {
    if (value == null || value.isEmpty) return null;
    return switch (widget.script) {
      NameScript.any => null,
      NameScript.arabic =>
        _violatesArabic.hasMatch(value)
            ? ValidatorStrings.nameMustUseArabicLetters
            : null,
      NameScript.latin =>
        _violatesLatin.hasMatch(value)
            ? ValidatorStrings.nameMustUseLatinLetters
            : null,
    };
  }

  String? _effectiveValidator(String? value) {
    final base = (widget.validator ?? _modeValidator)(value);
    if (base != null) return base;
    return _scriptError(value);
  }

  List<String>? get _defaultAutofill => switch (widget.mode) {
    NameFieldMode.first => const [AutofillHints.givenName],
    NameFieldMode.last => const [AutofillHints.familyName],
    NameFieldMode.middle => const [AutofillHints.middleName],
    NameFieldMode.father => null,
    NameFieldMode.full => const [AutofillHints.name],
  };

  IconData get _defaultIcon => switch (widget.mode) {
    NameFieldMode.full => Icons.badge_outlined,
    _ => Icons.person_outline_rounded,
  };

  RegExp get _allowPattern => switch (widget.script) {
    NameScript.any => _allowAny,
    NameScript.arabic => _allowArabic,
    NameScript.latin => _allowLatin,
  };

  /// Full-mode progress note while the name is incomplete.
  FieldMessage? get _partsProgress {
    if (widget.mode != NameFieldMode.full || !widget.showPartsProgress) {
      return null;
    }
    final counted = _countedParts(widget.controller.text);
    if (counted == 0 || counted >= widget.minParts) return null;
    return FieldMessage.info(
      TextFieldStrings.namePartsProgress(counted, widget.minParts),
      icon: Icons.segment,
    );
  }

  void _emitName(String text) {
    final cb = widget.onNameChanged;
    if (cb == null) return;
    cb(
      FullName(
        parts: _partsOf(text),
        isValid: _effectiveValidator(text) == null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _partsProgress;
    return GlobalTextFormField(
      controller: widget.controller,
      label: widget.label,
      identifier: widget.identifier,
      required: widget.required,
      hint: widget.hint ?? _defaultHint,
      focusNode: widget.focusNode,
      style: widget.style ?? const TextFieldStyle(),
      sizing: widget.sizing ?? const TextFieldSizing(),
      messages: [
        if (widget.profanityCheck == ProfanityCheck.warn && _profanityFlagged)
          FieldMessage.warning(
            TextFieldStrings.profanityWarning,
            icon: Icons.report_gmailerrorred_outlined,
          ),
        ...widget.messages,
        if (progress != null) progress,
      ],
      behavior: TextFieldBehavior(
        keyboardType: TextInputType.name,
        textInputAction: widget.textInputAction,
        textCapitalization: TextCapitalization.words,
        trimOnSubmit: widget.trimOnSubmit,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        autofillHints: widget.autofillHints ?? _defaultAutofill,
        inputFormatters: [
          FilteringTextInputFormatter.allow(_allowPattern),
          if (widget.capitalizeWords) NameCaseInputFormatter(),
        ],
      ),
      validation: TextFieldValidation(
        validator: _effectiveValidator,
        asyncValidator:
            widget.profanityCheck == ProfanityCheck.block ||
                widget.asyncValidator != null
            ? _effectiveAsyncValidator
            : null,
        asyncDebounce:
            widget.asyncDebounce ?? TextFieldDefaults.asyncValidatorDebounce,
        errorText: widget.errorText,
        mode: widget.validationMode,
        deferToParentForm: widget.deferToParentForm,
        errorIcon: widget.errorIcon,
        errorBuilder: widget.errorBuilder,
        // Mode / part / script / profanity rules can flip at runtime.
        revalidateKey: (
          widget.mode,
          widget.minParts,
          widget.script,
          widget.profanityCheck,
        ),
      ),
      features: TextFieldFeatures(
        showSuccess: widget.showSuccess,
        successText: widget.successText,
      ),
      slots: TextFieldSlots(
        prefixIcon: widget.showPrefixIcon
            ? Padding(
                padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
                child: Icon(_defaultIcon, color: context.iconColors.primary),
              )
            : null,
        suffix: widget.suffix,
      ),
      callbacks: TextFieldCallbacks(
        onChanged: (value) {
          widget.onChanged?.call(value);
          _emitName(value);
        },
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}
