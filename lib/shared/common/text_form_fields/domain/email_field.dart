import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/field_strings.dart';
import '../../../../core/localization/strings/text_field_strings.dart';
import '../../../../core/utils/validators/validators.dart';
import '../../../../data/services/email_domain_verifier.dart';
import '../../../module/text_field/global_text_field.dart';

/// Common consumer providers, used by [EmailField.suggestDomains] when no
/// [EmailField.allowedDomains] restriction is set.
const kCommonEmailDomains = [
  'gmail.com',
  'outlook.com',
  'hotmail.com',
  'yahoo.com',
  'icloud.com',
];

/// Email input — the full-featured domain wrapper (the template for the
/// other domain fields).
///
/// Presets: email keyboard, `Validators.validateEmail`, LTR-only content,
/// `AutofillHints.email`, trim-on-submit, mail prefix icon.
///
/// On top of the standard wrapper contract it exposes the module's newer
/// capabilities:
///  * [asyncValidator] — server-side check ("already registered?"), gated
///    by the sync validator, debounced, spinner while in flight.
///  * [messages] / [showSuccess] / [successText] — status rows below the
///    field (sorted error → success → warning → info).
///  * [errorIcon] / [errorBuilder] — customize the error row.
///  * [style] / [sizing] — visual + box-geometry overrides.
///  * [lowercaseInput] — normalize as the user types.
///  * [deferToParentForm] — set `false` for standalone (non-Form) usage.
class EmailField extends StatelessWidget {
  const EmailField({
    super.key,
    this.fieldKey,
    required this.controller,
    this.onChanged,
    this.onSubmitted,
    this.label,
    this.identifier,
    this.required = true,
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
    this.prefixIcon,
    this.suffix,
    this.style,
    this.sizing,
    this.trimOnSubmit = true,
    this.lowercaseInput = false,
    this.autofillHints = const [AutofillHints.email],
    this.allowedDomains,
    this.suggestDomains = false,
    this.verifyDomain = false,
  });

  /// Key for the inner [GlobalTextFormField]. Pass a `GlobalKey` to keep
  /// the editor's element (focus, keyboard connection, undo stack) alive
  /// when a composite reparents it — `EmailOrPhoneField`'s face swap.
  final Key? fieldKey;

  final TextEditingController controller;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final String? label;
  final String? identifier;

  /// Default true (an email field is usually mandatory): shows the `*`
  /// marker and keeps empty-fails validation. `false` → optional: empty
  /// passes, a non-empty value still needs the full format.
  final bool required;

  /// Null → localized default.
  final String? hint;
  final bool enabled;
  final bool readOnly;
  final String? errorText;

  /// Sync format check. Defaults to [Validators.validateEmail].
  final String? Function(String?)? validator;

  /// Server-side check (e.g. "is this email already registered?"). Runs only
  /// after the sync [validator] passes; debounced by [asyncDebounce].
  final Future<String?> Function(String value)? asyncValidator;

  /// Defaults to [TextFieldDefaults.asyncValidatorDebounce].
  final Duration? asyncDebounce;

  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final ValidationMode validationMode;

  /// Keep `true` inside a `Form`; set `false` for standalone fields so the
  /// internal triggers (focus loss / submit / live) drive validation.
  final bool deferToParentForm;

  /// Icon shown before the error message row. See
  /// [TextFieldValidation.errorIcon].
  final IconData? errorIcon;

  /// Full control over the error row. See [TextFieldValidation.errorBuilder].
  final Widget Function(BuildContext context, String message)? errorBuilder;

  /// Status rows below the field (sorted by severity).
  final List<FieldMessage> messages;

  /// Show a success row when the field is valid (with optional [successText]).
  final bool showSuccess;
  final String? successText;

  final bool showPrefixIcon;

  /// Leading icon override (defaults to the mail icon) — composites like
  /// `EmailOrPhoneField` show a neutral identifier icon instead.
  final IconData? prefixIcon;

  /// Trailing slot — e.g. `TextFieldSuffix.icon(...)` / `.loading()`.
  final TextFieldSuffix? suffix;

  /// Per-call visual override (wins over the app-wide theme).
  final TextFieldStyle? style;

  /// Box geometry (height / width / fit-to-content / density).
  final TextFieldSizing? sizing;

  /// Strip surrounding whitespace on submit — pasted emails routinely carry
  /// a trailing space. Default `true`.
  final bool trimOnSubmit;

  /// Lower-case as the user types (emails are case-insensitive in practice).
  final bool lowercaseInput;

  /// Platform autofill. Defaults to `[AutofillHints.email]`; pass `null`
  /// to disable.
  final List<String>? autofillHints;

  /// Restrict to these domains (case-insensitive, e.g. `['gmail.com']` or
  /// `['company.com']` for org-internal apps). Runs AFTER the format check;
  /// a mismatch fails validation with a translated message. Public apps
  /// usually prefer [suggestDomains] without a restriction.
  final List<String>? allowedDomains;

  /// Ghost-complete the domain while typing (Tab / → accepts): `john` →
  /// ghost `@gmail.com` when a single domain is known; after `@`, completes
  /// the first matching domain. Uses [allowedDomains] if set, else
  /// [kCommonEmailDomains].
  final bool suggestDomains;

  /// Async-check that the domain can actually receive mail (DNS MX/A lookup
  /// via [EmailDomainVerifier] — catches dead domains + typos, no backend).
  /// Runs after the sync validator passes, BEFORE any caller
  /// [asyncValidator]. Fail-open on network errors. Domain deliverability
  /// only — mailbox existence needs a confirmation email.
  final bool verifyDomain;

  List<String> get _domains => allowedDomains ?? kCommonEmailDomains;

  String? _effectiveValidator(String? value) {
    if (!required && (value == null || value.trim().isEmpty)) return null;
    final base = (validator ?? Validators.validateEmail)(value);
    if (base != null) return base;
    final domains = allowedDomains;
    if (domains == null || domains.isEmpty) return null;
    final domain = value!.trim().toLowerCase().split('@').last;
    final ok = domains.any((d) => d.toLowerCase() == domain);
    if (ok) return null;
    return TextFieldStrings.emailDomainNotAllowed(domains.join(', '));
  }

  /// Chained async check: domain deliverability (when [verifyDomain]) gates
  /// the caller's [asyncValidator].
  Future<String?> _effectiveAsyncValidator(String value) async {
    if (verifyDomain) {
      final err = await EmailDomainVerifier.instance.validateEmailDomain(value);
      if (err != null) return err;
    }
    return asyncValidator?.call(value);
  }

  /// Ghost remainder for the current [text] — see [suggestDomains].
  String? _domainCompletion(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    final at = t.indexOf('@');
    if (at < 0) {
      // No @ yet: only unambiguous when a single domain is known.
      return _domains.length == 1 ? '@${_domains.first}' : null;
    }
    if (at == 0) return null; // no local part yet
    final typed = t.substring(at + 1).toLowerCase();
    for (final d in _domains) {
      final dl = d.toLowerCase();
      if (dl == typed) return null; // already complete
      if (dl.startsWith(typed)) return d.substring(typed.length);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GlobalTextFormField(
      key: fieldKey,
      controller: controller,
      label: label,
      identifier: identifier,
      required: required,
      hint: hint ?? FieldStrings.emailHint,
      focusNode: focusNode,
      style: style ?? const TextFieldStyle(),
      sizing: sizing ?? const TextFieldSizing(),
      messages: messages,
      behavior: TextFieldBehavior(
        keyboardType: TextInputType.emailAddress,
        textInputAction: textInputAction,
        enabled: enabled,
        readOnly: readOnly,
        autoDetectDirection: false,
        trimOnSubmit: trimOnSubmit,
        autofillHints: autofillHints,
        inputFormatters: lowercaseInput ? [LowerCaseInputFormatter()] : null,
      ),
      validation: TextFieldValidation(
        validator: _effectiveValidator,
        asyncValidator: (verifyDomain || asyncValidator != null)
            ? _effectiveAsyncValidator
            : null,
        asyncDebounce:
            asyncDebounce ?? TextFieldDefaults.asyncValidatorDebounce,
        errorText: errorText,
        mode: validationMode,
        deferToParentForm: deferToParentForm,
        errorIcon: errorIcon,
        errorBuilder: errorBuilder,
      ),
      features: TextFieldFeatures(
        showSuccess: showSuccess,
        successText: successText,
        suggestions: suggestDomains
            ? SuggestionsConfig(
                showInlineCompletion: true,
                completion: _domainCompletion,
              )
            : null,
      ),
      slots: TextFieldSlots(
        prefixIcon: showPrefixIcon
            ? Padding(
                padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
                child: Icon(
                  prefixIcon ?? Icons.email_outlined,
                  color: context.iconColors.primary,
                ),
              )
            : null,
        suffix: suffix,
      ),
      callbacks: TextFieldCallbacks(
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      ),
    );
  }
}
