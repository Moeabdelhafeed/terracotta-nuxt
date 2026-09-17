import 'package:flutter/material.dart';

import '../../../../core/localization/strings/misc_field_strings.dart';
import '../../../../core/tokens/extensions.dart';
import '../../../../core/utils/validators/validators.dart';
import '../../../module/text_field/global_text_field.dart';
import 'iban_field.dart';
import 'name_field.dart';
import 'swift_bic_field.dart';

/// The value a [BankAccountForm] emits.
@immutable
class BankAccountData {
  const BankAccountData({
    this.holder = '',
    this.iban = '',
    this.bic,
    required this.isValid,
  });

  /// Trimmed holder name — empty when [BankAccountForm.showHolder] is off.
  final String holder;

  /// Normalized IBAN (uppercase, no spaces).
  final String iban;

  /// Parsed BIC — null when [BankAccountForm.showBic] is off or the
  /// field is empty.
  final SwiftBic? bic;

  /// Holder + IBAN mod-97 + BIC structure + BIC↔IBAN country all pass.
  final bool isValid;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankAccountData &&
          other.holder == holder &&
          other.iban == iban &&
          other.bic == bic &&
          other.isValid == isValid;

  @override
  int get hashCode => Object.hash(holder, iban, bic, isValid);

  @override
  String toString() => 'BankAccountData($iban, valid: $isValid)';
}

/// The bank-account composite — holder + IBAN + SWIFT/BIC with the
/// cross-check wired:
///
///  * Holder is a [NameField] in full-name mode (≥2 parts).
///  * IBAN validates mod-97 on focus loss.
///  * BIC validates ISO 9362 structure AND must match the IBAN's country
///    ([SwiftBicField.mustMatchIban] — pre-linked to the IBAN field).
///  * [bicRequired] false → empty BIC passes (local transfers), a
///    non-empty one still fully validates.
///  * Focus chains holder → IBAN → BIC. One [AutofillGroup]
///    (holder gets the `name` hint; no platform hints exist for
///    IBAN/BIC).
///
/// ```dart
/// BankAccountForm(
///   bicRequired: false,
///   onChanged: (d) => setState(() => account = d),
/// )
/// ```
class BankAccountForm extends StatefulWidget {
  const BankAccountForm({
    super.key,
    this.showHolder = true,
    this.showBic = true,
    this.bicRequired = true,
    this.holderController,
    this.ibanController,
    this.bicController,
    this.onChanged,
    this.onSubmit,
    this.enabled = true,
    this.deferToParentForm = true,
    this.validationMode = ValidationMode.onInteraction,
    this.style,
  });

  final bool showHolder;
  final bool showBic;

  /// Off → an EMPTY BIC passes (domestic transfers often need none);
  /// non-empty still runs structure + country cross-check.
  final bool bicRequired;

  /// Controllers are optional — the form owns them when absent.
  final TextEditingController? holderController;
  final TextEditingController? ibanController;
  final TextEditingController? bicController;

  /// Parsed state on every change.
  final ValueChanged<BankAccountData>? onChanged;

  /// Keyboard done on the LAST field.
  final ValueChanged<BankAccountData>? onSubmit;

  final bool enabled;

  /// Keep `true` inside a `Form`; `false` for standalone screens.
  final bool deferToParentForm;

  final ValidationMode validationMode;

  /// Visual override applied to every field.
  final TextFieldStyle? style;

  @override
  State<BankAccountForm> createState() => _BankAccountFormState();
}

class _BankAccountFormState extends State<BankAccountForm> {
  TextEditingController? _ownedHolder, _ownedIban, _ownedBic;
  final _ibanFocus = FocusNode();
  final _bicFocus = FocusNode();

  SwiftBic? _bic;

  TextEditingController get _holder =>
      widget.holderController ?? (_ownedHolder ??= TextEditingController());
  TextEditingController get _iban =>
      widget.ibanController ?? (_ownedIban ??= TextEditingController());
  TextEditingController get _bicCtrl =>
      widget.bicController ?? (_ownedBic ??= TextEditingController());

  @override
  void dispose() {
    _ownedHolder?.dispose();
    _ownedIban?.dispose();
    _ownedBic?.dispose();
    _ibanFocus.dispose();
    _bicFocus.dispose();
    super.dispose();
  }

  String get _normalizedIban => _iban.text.replaceAll(' ', '').toUpperCase();

  /// BIC country must equal the IBAN's leading alpha-2 (when both known).
  bool get _bicCountryOk {
    final ibanCountry = _normalizedIban.length >= 2
        ? _normalizedIban.substring(0, 2)
        : null;
    final bicCountry = _bic?.country?.code;
    return ibanCountry == null ||
        bicCountry == null ||
        ibanCountry == bicCountry;
  }

  bool get _isValid {
    final holderOk =
        !widget.showHolder || Validators.validateFullName(_holder.text) == null;
    final ibanOk = Validators.validateIban(_iban.text) == null;
    final bicOk =
        !widget.showBic ||
        (_bicCtrl.text.trim().isEmpty
            ? !widget.bicRequired
            : (_bic?.isValid ?? false) && _bicCountryOk);
    return holderOk && ibanOk && bicOk;
  }

  BankAccountData _current() => BankAccountData(
    holder: widget.showHolder ? _holder.text.trim() : '',
    iban: _normalizedIban,
    bic: widget.showBic && _bicCtrl.text.trim().isNotEmpty ? _bic : null,
    isValid: _isValid,
  );

  void _emit() => widget.onChanged?.call(_current());

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: context.spacing.md);
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showHolder) ...[
            NameField(
              controller: _holder,
              mode: NameFieldMode.full,
              required: true,
              identifier: BankFieldStrings.holderLabel,
              hint: BankFieldStrings.holderHint,
              autofillHints: const [AutofillHints.name],
              enabled: widget.enabled,
              deferToParentForm: widget.deferToParentForm,
              validationMode: widget.validationMode,
              style: widget.style,
              onChanged: (_) => _emit(),
              onSubmitted: (_) => _ibanFocus.requestFocus(),
            ),
            gap,
          ],
          IbanField(
            controller: _iban,
            focusNode: _ibanFocus,
            identifier: BankFieldStrings.ibanLabel,
            enabled: widget.enabled,
            deferToParentForm: widget.deferToParentForm,
            textInputAction: widget.showBic
                ? TextInputAction.next
                : TextInputAction.done,
            style: widget.style,
            onChanged: (_) => _emit(),
            onSubmitted: (_) => widget.showBic
                ? _bicFocus.requestFocus()
                : widget.onSubmit?.call(_current()),
          ),
          if (widget.showBic) ...[
            gap,
            SwiftBicField(
              controller: _bicCtrl,
              focusNode: _bicFocus,
              identifier: BankFieldStrings.swiftBicLabel,
              required: widget.bicRequired,
              mustMatchIban: _iban,
              enabled: widget.enabled,
              deferToParentForm: widget.deferToParentForm,
              textInputAction: TextInputAction.done,
              style: widget.style,
              onBicChanged: (b) {
                _bic = b;
                _emit();
              },
              onSubmitted: (_) => widget.onSubmit?.call(_current()),
            ),
          ],
        ],
      ),
    );
  }
}
