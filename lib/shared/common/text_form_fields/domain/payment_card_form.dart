import 'package:flutter/material.dart';

import '../../../../core/localization/strings/field_strings.dart';
import '../../../../core/localization/strings/misc_field_strings.dart';
import '../../../../core/tokens/extensions.dart';
import '../../../../core/utils/card_brand.dart';
import '../../../../core/utils/validators/validators.dart';
import '../../../module/text_field/global_text_field.dart';
import '../../selection_fields/checkbox/save_card_checkbox.dart';
import 'cardholder_name_field.dart';
import 'credit_card_field.dart';
import 'cvv_field.dart';
import 'date_field.dart';

/// The parsed value a [PaymentCardForm] emits on every change — wire-ready
/// pieces plus the validity snapshot, so consumers never re-parse.
@immutable
class PaymentCard {
  const PaymentCard({
    required this.number,
    required this.expiry,
    required this.cvv,
    required this.brand,
    required this.isValid,
    this.holderName = '',
    this.saveCard = false,
  });

  static final _mmYy = RegExp(r'^(\d{2})/(\d{2})$');

  /// Digits only, no separators.
  final String number;

  /// `MM/YY` as displayed.
  final String expiry;

  final String cvv;
  final CardBrand brand;

  /// Name on card — empty unless [PaymentCardForm.showCardholder].
  final String holderName;

  /// The save-card checkbox — always false when
  /// [PaymentCardForm.showSaveCard] is off.
  final bool saveCard;

  /// All shown fields pass their sync validators.
  final bool isValid;

  /// [expiry] parsed to the card's last valid moment (end of the expiry
  /// month). Null while the entry is incomplete or nonsensical.
  DateTime? get expiryDate {
    final m = _mmYy.firstMatch(expiry);
    if (m == null) return null;
    final month = int.parse(m.group(1)!);
    if (month < 1 || month > 12) return null;
    final year = 2000 + int.parse(m.group(2)!);
    return DateTime(year, month + 1, 0, 23, 59, 59);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentCard &&
          other.number == number &&
          other.expiry == expiry &&
          other.cvv == cvv &&
          other.brand == brand &&
          other.holderName == holderName &&
          other.saveCard == saveCard &&
          other.isValid == isValid;

  @override
  int get hashCode =>
      Object.hash(number, expiry, cvv, brand, holderName, saveCard, isValid);

  @override
  String toString() => 'PaymentCard(${brand.label} ****, valid: $isValid)';
}

/// The checkout trio wired the right way — one widget:
///
/// * Focus chain: card complete → expiry → CVV.
/// * The CVV length follows the detected network (Amex = 4).
/// * One [onCardChanged] with a parsed [PaymentCard].
/// * [detectScreenCapture] arms the password-grade protection on the
///   number and CVV (instant bullets + warning + reveal confirm).
///
/// Wrapped in an [AutofillGroup] — the OS fills number/expiry/CVV as one
/// set (the fields carry the `creditCard*` hints).
class PaymentCardForm extends StatefulWidget {
  const PaymentCardForm({
    super.key,
    this.cardController,
    this.expiryController,
    this.cvvController,
    this.cardholderController,
    this.onCardChanged,
    this.showCardholder = false,
    this.showSaveCard = false,
    this.initialSaveCard = false,
    this.cardIdentifier,
    this.expiryIdentifier,
    this.cvvIdentifier,
    this.cardholderIdentifier,
    this.enabled = true,
    this.deferToParentForm = true,
    this.validationMode = ValidationMode.onInteraction,
    this.detectScreenCapture = false,
    this.obscureCvv = true,
    this.showSuccess = false,
    this.brandDetector,
    this.style,
  });

  /// Controllers are optional — the form owns them when absent.
  final TextEditingController? cardController;
  final TextEditingController? expiryController;
  final TextEditingController? cvvController;
  final TextEditingController? cardholderController;

  /// Parsed card on every change to any of the fields.
  final ValueChanged<PaymentCard>? onCardChanged;

  /// Name-on-card row above the number ([CardholderNameField] — Latin
  /// only, `creditCardName` autofill). Feeds [PaymentCard.holderName]
  /// and the validity snapshot.
  final bool showCardholder;

  /// Localized `SaveCardCheckbox` under the CVV row — never gates
  /// validity; rides [PaymentCard.saveCard].
  final bool showSaveCard;
  final bool initialSaveCard;

  final String? cardIdentifier;
  final String? expiryIdentifier;
  final String? cvvIdentifier;
  final String? cardholderIdentifier;
  final bool enabled;

  /// Keep `true` inside a `Form`; `false` for standalone checkouts.
  final bool deferToParentForm;

  final ValidationMode validationMode;

  /// Password-grade capture protection on the number + CVV.
  final bool detectScreenCapture;

  /// Bullets + eye on the CVV (default).
  final bool obscureCvv;

  /// Success rows on the individual fields.
  final bool showSuccess;

  /// Market BIN-table override — see `CreditCardField.brandDetector`.
  final CardBrand Function(String digits)? brandDetector;

  /// Visual override applied to all three fields.
  final TextFieldStyle? style;

  @override
  State<PaymentCardForm> createState() => _PaymentCardFormState();
}

class _PaymentCardFormState extends State<PaymentCardForm> {
  static final _nonDigit = RegExp(r'\D');

  TextEditingController? _ownedCard;
  TextEditingController? _ownedExpiry;
  TextEditingController? _ownedCvv;
  TextEditingController? _ownedCardholder;
  final _expiryFocus = FocusNode();
  final _cvvFocus = FocusNode();
  CardBrand _brand = CardBrand.unknown;
  late bool _saveCard = widget.initialSaveCard;

  TextEditingController get _card =>
      widget.cardController ?? (_ownedCard ??= TextEditingController());
  TextEditingController get _expiry =>
      widget.expiryController ?? (_ownedExpiry ??= TextEditingController());
  TextEditingController get _cvv =>
      widget.cvvController ?? (_ownedCvv ??= TextEditingController());
  TextEditingController get _cardholder =>
      widget.cardholderController ??
      (_ownedCardholder ??= TextEditingController());

  @override
  void dispose() {
    _ownedCard?.dispose();
    _ownedExpiry?.dispose();
    _ownedCvv?.dispose();
    _ownedCardholder?.dispose();
    _expiryFocus.dispose();
    _cvvFocus.dispose();
    super.dispose();
  }

  void _emit() {
    final cb = widget.onCardChanged;
    if (cb == null) return;
    final number = _card.text.replaceAll(_nonDigit, '');
    final expiry = _expiry.text;
    final cvv = _cvv.text;
    final holder = widget.showCardholder ? _cardholder.text : '';
    final cardValid =
        _brand.lengths.contains(number.length) &&
        Validators.isValidCardNumber(number);
    final expiryValid = Validators.isValidCardExpiry(expiry);
    final cvvValid =
        cvv.length == _brand.cvvLength && Validators.digitsOnly.hasMatch(cvv);
    final holderValid =
        !widget.showCardholder || Validators.validateFullName(holder) == null;
    cb(
      PaymentCard(
        number: number,
        expiry: expiry,
        cvv: cvv,
        brand: _brand,
        holderName: holder,
        saveCard: widget.showSaveCard && _saveCard,
        isValid: cardValid && expiryValid && cvvValid && holderValid,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // One autofill context for the whole card set — the OS fills
    // number/expiry/CVV together (the fields carry the creditCard hints).
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showCardholder) ...[
            CardholderNameField(
              controller: _cardholder,
              identifier:
                  widget.cardholderIdentifier ?? FieldStrings.cardholderHint,
              enabled: widget.enabled,
              deferToParentForm: widget.deferToParentForm,
              validationMode: widget.validationMode,
              style: widget.style,
              onChanged: (_) => _emit(),
            ),
            SizedBox(height: context.spacing.md),
          ],
          CreditCardField(
            controller: _card,
            identifier: widget.cardIdentifier ?? CardFieldStrings.numberLabel,
            enabled: widget.enabled,
            deferToParentForm: widget.deferToParentForm,
            validationMode: widget.validationMode,
            detectScreenCapture: widget.detectScreenCapture,
            brandDetector: widget.brandDetector,
            showSuccess: widget.showSuccess,
            style: widget.style,
            onBrandChanged: (b) {
              setState(() => _brand = b);
              _emit();
            },
            onCompleted: (_) => _expiryFocus.requestFocus(),
            onChanged: (_) => _emit(),
          ),
          SizedBox(height: context.spacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DateField.cardExpiry(
                  controller: _expiry,
                  focusNode: _expiryFocus,
                  identifier:
                      widget.expiryIdentifier ?? CardFieldStrings.expiryLabel,
                  enabled: widget.enabled,
                  deferToParentForm: widget.deferToParentForm,
                  validationMode: widget.validationMode,
                  showSuccess: widget.showSuccess,
                  style: widget.style,
                  onCompleted: (_) => _cvvFocus.requestFocus(),
                  onChanged: (_) => _emit(),
                ),
              ),
              SizedBox(width: context.spacing.md),
              Expanded(
                child: CvvField(
                  controller: _cvv,
                  focusNode: _cvvFocus,
                  identifier: widget.cvvIdentifier ?? CardFieldStrings.cvvLabel,
                  length: _brand.cvvLength,
                  obscure: widget.obscureCvv,
                  detectScreenCapture: widget.detectScreenCapture,
                  enabled: widget.enabled,
                  deferToParentForm: widget.deferToParentForm,
                  validationMode: widget.validationMode,
                  showSuccess: widget.showSuccess,
                  style: widget.style,
                  onChanged: (_) => _emit(),
                ),
              ),
            ],
          ),
          if (widget.showSaveCard) ...[
            SizedBox(height: context.spacing.md),
            SaveCardCheckbox(
              value: _saveCard,
              enabled: widget.enabled,
              onChanged: (v) {
                setState(() => _saveCard = v);
                _emit();
              },
            ),
          ],
        ],
      ),
    );
  }
}
