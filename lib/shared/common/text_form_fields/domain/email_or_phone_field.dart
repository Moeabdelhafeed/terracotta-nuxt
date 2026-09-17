import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/animations/animation_presets.dart';
import '../../../../core/constants/country_codes.dart';
import '../../../../core/localization/strings/misc_field_strings.dart';
import '../../../../core/utils/validators/validators.dart';
import '../../../../data/models/common/country_code/country_code.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../../../module/text_field/global_text_field.dart';
import 'email_field.dart';
import 'joined_pair_radii.dart';
import 'phone_number_field.dart';

/// What an [EmailOrPhoneField] parsed out of the input — pattern-match to
/// route the sign-in call:
///
/// ```dart
/// switch (identifier) {
///   EmailLoginIdentifier(:final email) => auth.signInWithEmail(email),
///   PhoneLoginIdentifier(:final phone) => auth.signInWithPhone(phone.e164),
/// }
/// ```
sealed class LoginIdentifier {
  const LoginIdentifier();

  /// Sync-validity snapshot at emit time (format / length rules).
  bool get isValid;
}

/// The input reads as an email address.
final class EmailLoginIdentifier extends LoginIdentifier {
  const EmailLoginIdentifier({required this.email, required this.isValid});

  /// Trimmed input as typed.
  final String email;

  @override
  final bool isValid;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmailLoginIdentifier &&
          other.email == email &&
          other.isValid == isValid;

  @override
  int get hashCode => Object.hash(email, isValid);

  @override
  String toString() => 'EmailLoginIdentifier($email, valid: $isValid)';
}

/// The input reads as a phone number — [phone] carries country / national
/// digits / wire-ready `e164`.
final class PhoneLoginIdentifier extends LoginIdentifier {
  const PhoneLoginIdentifier({required this.phone});

  final PhoneNumber phone;

  @override
  bool get isValid => phone.isValid;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhoneLoginIdentifier && other.phone == phone;

  @override
  int get hashCode => phone.hashCode;

  @override
  String toString() => 'PhoneLoginIdentifier(${phone.e164}, valid: $isValid)';
}

/// Login-identifier field — ONE input that morphs between [EmailField] and
/// [PhoneNumberField] as the user types. Standard MENA sign-in ("email or
/// phone").
///
/// Detection, both directions, live:
///  * Digits only (`+` / `00` / separators / Eastern-Arabic digits
///    tolerated) — typed OR pasted — flips to the PHONE face: country
///    picker appears, digits regroup, phone keyboard. A pasted
///    international number (`+962 79…`) also selects its country.
///  * Any letter / `@` while on the phone face flips straight back to the
///    EMAIL face (picker gone, grouping spaces dropped, the letter kept) —
///    emails like `90smusic@…` survive a digit-y start.
///  * Clearing the phone face resets to the neutral email face.
///
/// Both faces share [controller] and focus, so the swap is seamless.
/// Consume via [onIdentifierChanged] — a sealed [LoginIdentifier]
/// (`EmailLoginIdentifier` / `PhoneLoginIdentifier`, `null` when empty).
///
/// ```dart
/// EmailOrPhoneField(
///   controller: login,
///   allowedCountries: const ['JO', 'SA', 'EG'],
///   onIdentifierChanged: (id) => cubit.setIdentifier(id),
/// )
/// ```
class EmailOrPhoneField extends StatefulWidget {
  const EmailOrPhoneField({
    super.key,
    required this.controller,
    this.onIdentifierChanged,
    this.onChanged,
    this.onSubmitted,
    this.label,
    this.identifier,
    this.hint,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.emailValidator,
    this.focusNode,
    this.textInputAction = TextInputAction.done,
    this.validationMode = ValidationMode.onInteraction,
    this.deferToParentForm = true,
    this.messages = const [],
    this.showSuccess = false,
    this.suggestDomains = true,
    this.allowedCountries,
    this.preferredCountries = const [],
    this.allowLandline = true,
    this.style,
    this.sizing,
  });

  final TextEditingController controller;

  /// Parsed identifier on every change — `null` when the field is empty.
  final ValueChanged<LoginIdentifier?>? onIdentifierChanged;

  /// Raw text as displayed (phone face: grouped national digits).
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final String? label;
  final String? identifier;

  /// Null → localized "Email or phone number".
  final String? hint;

  final bool enabled;
  final bool readOnly;
  final String? errorText;

  /// Email-face format check. Null → [Validators.validateEmail]. The phone
  /// face keeps [PhoneNumberField]'s per-country length rules.
  final String? Function(String?)? emailValidator;

  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final ValidationMode validationMode;

  /// Keep `true` inside a `Form`; `false` for standalone fields.
  final bool deferToParentForm;

  /// Status rows below the field (sorted by severity).
  final List<FieldMessage> messages;

  /// Show a success row when the field is valid.
  final bool showSuccess;

  /// Email face: ghost-complete common providers (`@gmail.com` …).
  final bool suggestDomains;

  /// Phone face: ISO whitelist for the picker + all detection layers.
  final List<String>? allowedCountries;

  /// Phone face: ISO codes pinned in a "Preferred" picker group.
  final List<String> preferredCountries;

  /// Phone face: `false` → mobile-only length rules.
  final bool allowLandline;

  /// Per-call visual override (wins over the app-wide theme).
  final TextFieldStyle? style;

  /// Box geometry (height / width / fit-to-content / density).
  final TextFieldSizing? sizing;

  @override
  State<EmailOrPhoneField> createState() => _EmailOrPhoneFieldState();
}

class _EmailOrPhoneFieldState extends State<EmailOrPhoneField> {
  bool _phoneMode = false;

  /// Country a mode-entering international paste detected — seeds the
  /// remounted [PhoneNumberField]. Null → its own SIM/locale chain.
  CountryCode? _seedCountry;

  /// Bumped on every phone-face entry so the [PhoneNumberField] remounts
  /// and re-runs its country seeding against the fresh [_seedCountry].
  int _phoneGeneration = 0;

  /// Bumped on every return to the email face so its entrance replays.
  int _emailGeneration = 0;

  /// The initial mount renders statically — the entrance morph plays only
  /// on actual face swaps.
  bool _hasMorphed = false;

  /// Picker width measured just before a phone → email swap — drives the
  /// reverse width morph (email field growing back over the vacated slot).
  double? _collapsePickerWidth;

  /// Owned only when the caller didn't pass a node — the face swap needs
  /// ONE stable node so focus (and the open keyboard) survives.
  FocusNode? _internalFocus;

  /// Shared by BOTH faces' inner editors — GlobalKey reparenting keeps
  /// the editor's element (and with it the EditableText state, focus and
  /// the live keyboard connection) alive across the swap. The keyboard
  /// TYPE then updates in place instead of the connection dying with the
  /// old subtree.
  final GlobalKey _editorKey = GlobalKey(debugLabel: 'email-or-phone-editor');

  /// Paste-noise tolerated inside a phone number.
  static final _phoneNoise = RegExp(r'[\s\-.()]');

  /// Digits with an optional `+` — what qualifies as "typing a phone".
  static final _phoneShape = RegExp(r'^\+?\d+$');

  /// Any char a phone number can never contain (letters, `@`, …) —
  /// Eastern-Arabic/Persian digits are phone chars, not letters.
  static final _nonPhoneChar = RegExp(r'[^\d\s\-.()+٠-٩۰-۹]');

  FocusNode get _focus => widget.focusNode ?? (_internalFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    // Pre-filled controller (saved login) — classify before first build.
    final text = widget.controller.text.trim();
    if (text.isNotEmpty && _looksLikePhone(text)) {
      _phoneMode = true;
      final parsed = _parseInternational(text);
      _seedCountry = parsed?.country;
      if (parsed != null) {
        // Dial code moves into the picker; the editor keeps the grouped
        // national number.
        final groups = parsed.country.groupSizes;
        widget.controller.text = groups != null
            ? PhoneGroupingInputFormatter.group(parsed.national, groups: groups)
            : parsed.national;
      }
    }
  }

  @override
  void dispose() {
    _internalFocus?.dispose();
    super.dispose();
  }

  bool _isAllowed(CountryCode c) {
    final allowed = widget.allowedCountries;
    if (allowed == null || allowed.isEmpty) return true;
    return allowed.any((iso) => iso.toUpperCase() == c.code);
  }

  bool _looksLikePhone(String text) {
    final cleaned = DateInputFormatter.normalizeDigits(
      text,
    ).replaceAll(_phoneNoise, '');
    return _phoneShape.hasMatch(cleaned);
  }

  /// `+962…` / `00962…` → country + national digits, when the country is
  /// known and allowed.
  ({CountryCode country, String national})? _parseInternational(String text) {
    final cleaned = DateInputFormatter.normalizeDigits(
      text,
    ).replaceAll(_phoneNoise, '');
    if (!cleaned.startsWith('+') && !cleaned.startsWith('00')) return null;
    final parsed = CountryCodes.parseInternational(cleaned);
    if (parsed == null || !_isAllowed(parsed.country)) return null;
    return parsed;
  }

  /// Rendered width of the phone face's country picker — measured by
  /// walking our element subtree while the phone face is STILL mounted
  /// (call before the swap's setState). Null when not found / not laid
  /// out.
  double? _measurePickerWidth() {
    double? width;
    void visit(Element el) {
      if (width != null) return;
      if (el.widget is GlobalDropdown<CountryCode>) {
        final ro = el.renderObject;
        if (ro is RenderBox && ro.hasSize) width = ro.size.width;
        return;
      }
      el.visitChildElements(visit);
    }

    if (mounted) context.visitChildElements(visit);
    return width;
  }

  /// The new face's WRITABLE editor state (the picker trigger is a
  /// read-only EditableText — skipped).
  EditableTextState? _findEditableState() {
    EditableTextState? result;
    void visit(Element el) {
      if (result != null) return;
      if (el is StatefulElement && el.state is EditableTextState) {
        final st = el.state as EditableTextState;
        if (!st.widget.readOnly) result = st;
        return;
      }
      el.visitChildElements(visit);
    }

    if (mounted) context.visitChildElements(visit);
    return result;
  }

  /// Re-arm typing after a face swap. The shared node never LOSES focus
  /// across the swap, so the fresh editor's focus-gained hook — the thing
  /// that opens the keyboard connection (with the new keyboard type) —
  /// never fires and a bare `requestFocus` is a no-op. Ask the new editor
  /// to open the connection directly: focus itself never drops, so the
  /// focused border / cursor can't blink (an unfocus → refocus bounce
  /// reads as a flash). Bounce only as a fallback when the editor can't
  /// be found.
  void _refocus() {
    if (!widget.enabled || widget.readOnly) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_focus.hasFocus) {
        _focus.requestFocus();
        return;
      }
      final editable = _findEditableState();
      if (editable != null) {
        editable.requestKeyboard();
        return;
      }
      _focus.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    });
  }

  // ── email face ──────────────────────────────────────────────────────

  void _onEmailChanged(String text) {
    widget.onChanged?.call(text);
    final t = text.trim();
    if (t.isEmpty) {
      widget.onIdentifierChanged?.call(null);
      return;
    }
    if (_looksLikePhone(t)) {
      _enterPhoneMode(t);
      return;
    }
    _emitEmail(t);
  }

  void _emitEmail(String value) {
    final validator = widget.emailValidator ?? Validators.validateEmail;
    widget.onIdentifierChanged?.call(
      EmailLoginIdentifier(email: value, isValid: validator(value) == null),
    );
  }

  void _enterPhoneMode(String text) {
    final cleaned = DateInputFormatter.normalizeDigits(
      text,
    ).replaceAll(_phoneNoise, '');
    final parsed = _parseInternational(cleaned);
    // Unparsed international input degrades to bare digits — the user
    // keeps typing, the picker keeps its own detection.
    var national =
        parsed?.national ?? cleaned.replaceAll(RegExp(r'^(\+|00)'), '');
    final groups = parsed?.country.groupSizes;
    if (groups != null) {
      national = PhoneGroupingInputFormatter.group(national, groups: groups);
    }
    setState(() {
      _phoneMode = true;
      _seedCountry = parsed?.country;
      _phoneGeneration++;
      _hasMorphed = true;
    });
    widget.controller.value = TextEditingValue(
      text: national,
      selection: TextSelection.collapsed(offset: national.length),
    );
    _refocus();
    // The remounted PhoneNumberField emits the initial PhoneNumber
    // snapshot itself (pre-filled-controller notify in its initState).
  }

  // ── phone face ──────────────────────────────────────────────────────

  void _onPhoneNumber(PhoneNumber number) {
    if (widget.controller.text.trim().isEmpty) return;
    widget.onIdentifierChanged?.call(PhoneLoginIdentifier(phone: number));
  }

  void _onPhoneText(String text) {
    widget.onChanged?.call(text);
    // Backspaced to empty — reset to the neutral (email) face so the
    // picker disappears and the keyboard offers letters again.
    if (text.trim().isEmpty) _exitPhoneMode();
  }

  void _exitPhoneMode() {
    _collapsePickerWidth = _measurePickerWidth();
    setState(() {
      _phoneMode = false;
      _seedCountry = null;
      _emailGeneration++;
      _hasMorphed = true;
    });
    widget.onIdentifierChanged?.call(null);
    _refocus();
  }

  /// Runs BEFORE the phone chain (which strips non-digits) — a letter or
  /// `@` means "this is an email after all": swallow the edit this frame,
  /// then morph back with the full text (grouping spaces dropped, the
  /// typed char kept) and the caret at the end.
  TextEditingValue _interceptNonPhone(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!_nonPhoneChar.hasMatch(newValue.text)) return newValue;
    final email = newValue.text.replaceAll(' ', '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _collapsePickerWidth = _measurePickerWidth();
      setState(() {
        _phoneMode = false;
        _seedCountry = null;
        _emailGeneration++;
        _hasMorphed = true;
      });
      widget.controller.value = TextEditingValue(
        text: email,
        selection: TextSelection.collapsed(offset: email.length),
      );
      widget.onChanged?.call(email);
      _emitEmail(email.trim());
      _refocus();
    });
    return oldValue;
  }

  // ── build ───────────────────────────────────────────────────────────

  String get _hint => widget.hint ?? LoginFieldStrings.hint;

  /// One sizing for BOTH faces: equal heights kill the swap jump, and —
  /// load-bearing — the identical box wrapper keeps the reparented
  /// editor's inner subtree structure the same on both faces, so the
  /// GlobalKey move preserves the EditableText state (keyboard
  /// connection). The phone face pins its editor to the joined-pair
  /// height anyway; the email face must match it.
  TextFieldSizing get _sizing =>
      widget.sizing ?? const TextFieldSizing(height: kJoinedPairBoxHeight);

  @override
  Widget build(BuildContext context) {
    final face = _buildFace(context);
    // The swap animates by WIDTH only — no fade/scale (a whole-field
    // opacity dip reads as a flash). Email → phone: the picker grows in
    // inside PhoneNumberField (animatePickerEntrance) and the editor
    // reflows. Phone → email: reverse morph below — the email field
    // starts behind a leading gap the size the picker actually had
    // (measured pre-swap) and grows back over it.
    if (_phoneMode) return face;
    final fromWidth = _collapsePickerWidth;
    if (!_hasMorphed ||
        fromWidth == null ||
        MediaQuery.disableAnimationsOf(context)) {
      return face;
    }
    return TweenAnimationBuilder<double>(
      key: ValueKey('email-face-$_emailGeneration'),
      tween: Tween(begin: 1, end: 0),
      duration: AppDurations.fast,
      curve: Curves.easeOutCubic,
      child: face,
      builder: (context, t, child) => Row(
        children: [
          SizedBox(width: fromWidth * t),
          Expanded(child: child!),
        ],
      ),
    );
  }

  Widget _buildFace(BuildContext context) {
    if (_phoneMode) {
      return PhoneNumberField(
        key: ValueKey('email-or-phone-$_phoneGeneration'),
        fieldKey: _editorKey,
        controller: widget.controller,
        focusNode: _focus,
        initialCountry: _seedCountry,
        label: widget.label,
        identifier: widget.identifier,
        hint: _hint,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        errorText: widget.errorText,
        messages: widget.messages,
        showSuccess: widget.showSuccess,
        allowedCountries: widget.allowedCountries,
        preferredCountries: widget.preferredCountries,
        allowLandline: widget.allowLandline,
        textInputAction: widget.textInputAction,
        validationMode: widget.validationMode,
        deferToParentForm: widget.deferToParentForm,
        style: widget.style,
        sizing: _sizing,
        leadingFormatters: [
          TextInputFormatter.withFunction(_interceptNonPhone),
        ],
        // Width morph: picker grows in, the editor reflows. Only on real
        // swaps — a pre-filled mount renders settled.
        animatePickerEntrance: _hasMorphed,
        onNumberChanged: _onPhoneNumber,
        onChanged: _onPhoneText,
        onSubmitted: widget.onSubmitted,
      );
    }
    return EmailField(
      fieldKey: _editorKey,
      controller: widget.controller,
      focusNode: _focus,
      label: widget.label,
      identifier: widget.identifier,
      hint: _hint,
      // Neutral identifier icon — a mail icon would read "email only".
      prefixIcon: Icons.alternate_email,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      errorText: widget.errorText,
      messages: widget.messages,
      showSuccess: widget.showSuccess,
      validator: widget.emailValidator,
      suggestDomains: widget.suggestDomains,
      textInputAction: widget.textInputAction,
      validationMode: widget.validationMode,
      deferToParentForm: widget.deferToParentForm,
      style: widget.style,
      sizing: _sizing,
      autofillHints: const [AutofillHints.username, AutofillHints.email],
      onChanged: _onEmailChanged,
      onSubmitted: widget.onSubmitted,
    );
  }
}
