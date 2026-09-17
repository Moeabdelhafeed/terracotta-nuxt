import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/text_field_strings.dart';
import '../../../../core/localization/strings/validator_strings.dart';
import '../../../../core/tokens/extensions.dart';
import '../../../../core/utils/card_brand.dart';
import '../../../../core/utils/validators/validators.dart';
import '../../../../data/services/screen_capture_service.dart';
import '../../../module/text_field/global_text_field.dart';

/// Mirrors the caller's controller and renders all but the last 4 digits
/// as bullets while [masked] — `•••• •••• •••• 4242` for saved-card
/// (card-on-file) display. Same-length mapping (digit → `•`, spaces
/// kept), so layout and selection stay exact.
class _MaskedCardTextController extends TextEditingController {
  _MaskedCardTextController({required this.source})
    : super.fromValue(source.value) {
    source.addListener(_fromSource);
    addListener(_toSource);
  }

  final TextEditingController source;
  bool masked = false;
  bool _syncing = false;

  void _fromSource() {
    if (_syncing) return;
    _syncing = true;
    value = source.value;
    _syncing = false;
  }

  void _toSource() {
    if (_syncing) return;
    _syncing = true;
    source.value = value;
    _syncing = false;
  }

  @override
  void dispose() {
    source.removeListener(_fromSource);
    super.dispose();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (!masked) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }
    final chars = text.split('');
    var digitsLeft = chars.where((c) => c != ' ').length - 4;
    final buffer = StringBuffer();
    for (final c in chars) {
      if (c != ' ' && digitsLeft > 0) {
        buffer.write('•');
        digitsLeft--;
      } else {
        buffer.write(c);
      }
    }
    return TextSpan(style: style, text: buffer.toString());
  }
}

/// Credit-card number field — network-aware:
///
/// * **Brand detection** ([CardBrand.detect]) from the IIN prefix — a
///   label chip appears in the suffix as soon as the network is known,
///   and [onBrandChanged] reports it (e.g. to size a CVV field:
///   `brand.cvvLength`).
/// * **Brand-true formatting** — Amex groups `4-6-5`, Diners `4-6-4`,
///   everything else every 4; the digit cap follows the network's real
///   lengths (19-digit Visa/UnionPay accepted).
/// * **Brand-true validation** — length must match the network
///   (a 14-digit Visa fails even if Luhn passes) + the Luhn checksum.
class CreditCardField extends StatefulWidget {
  const CreditCardField({
    super.key,
    required this.controller,
    this.onBrandChanged,
    this.brandDetector,
    this.showBrandChip = true,
    this.onCompleted,
    this.obscure = false,
    this.detectScreenCapture = false,
    this.obscureWhenUnfocused = false,
    this.onChanged,
    this.onSubmitted,
    this.label,
    this.identifier,
    this.hint = '0000 0000 0000 0000',
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
    this.autofillHints = const [AutofillHints.creditCardNumber],
  });

  final TextEditingController controller;

  /// Fires when the detected network changes ([CardBrand.unknown] when
  /// the prefix no longer matches anything).
  final ValueChanged<CardBrand>? onBrandChanged;

  /// Override network detection with a market-specific BIN table
  /// (domestic schemes — mada, RuPay, Elo — live INSIDE the global
  /// Visa/MC ranges, so prefix rules can't tell them apart; classify
  /// your acquirer's BIN list here and fall back to
  /// [CardBrand.detect]). Drives grouping, length cap, validation and
  /// the chip. For a custom chip LABEL (e.g. "mada"), pass [suffix].
  final CardBrand Function(String digits)? brandDetector;

  /// Detected-network label in the suffix ("Visa", "Amex", …). A custom
  /// [suffix] wins.
  final bool showBrandChip;

  /// Fires when the number reaches a valid length FOR ITS NETWORK and
  /// passes Luhn — e.g. `(_) => expiryFocus.requestFocus()`.
  final ValueChanged<String>? onCompleted;

  /// Bullets + the module's visibility toggle (shoulder-surfing
  /// protection while typing).
  final bool obscure;

  /// While the screen is recorded / shared ([ScreenCaptureService]) the
  /// digits obscure INSTANTLY (no last-char peek), a warning row shows,
  /// and the reveal toggle asks for confirmation — same treatment as
  /// `PasswordField`.
  final bool detectScreenCapture;

  /// Card-on-file display: when the field loses focus, all but the last
  /// 4 digits render as bullets (`•••• •••• •••• 4242`); tapping in
  /// reveals the full number for editing.
  final bool obscureWhenUnfocused;

  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final String? label;
  final String? identifier;
  final String hint;
  final bool enabled;
  final bool readOnly;
  final String? errorText;

  /// Sync check. Null → brand-aware length + Luhn.
  final String? Function(String?)? validator;

  /// Server-side check (e.g. BIN lookup). Runs after the sync validator
  /// passes.
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

  /// Trailing slot — replaces the brand chip.
  final TextFieldSuffix? suffix;

  /// Per-call visual override (wins over the app-wide theme).
  final TextFieldStyle? style;

  /// Box geometry (height / width / fit-to-content / density).
  final TextFieldSizing? sizing;

  /// Platform autofill. Defaults to `[AutofillHints.creditCardNumber]`;
  /// pass `null` to disable.
  final List<String>? autofillHints;

  @override
  State<CreditCardField> createState() => _CreditCardFieldState();
}

class _CreditCardFieldState extends State<CreditCardField> {
  static final _nonDigit = RegExp(r'\D');

  CardBrand _brand = CardBrand.unknown;

  /// Owned only for [CreditCardField.obscureWhenUnfocused] — masking
  /// follows the focus state.
  _MaskedCardTextController? _maskedCtrl;
  FocusNode? _internalFocus;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_detectBrand);
    _brand = _detect(_digits);
    if (widget.obscureWhenUnfocused) {
      _maskedCtrl = _MaskedCardTextController(source: widget.controller);
      _focus.addListener(_syncMask);
      _syncMask();
    }
  }

  FocusNode get _focus => widget.focusNode ?? (_internalFocus ??= FocusNode());

  void _syncMask() {
    final ctrl = _maskedCtrl;
    if (ctrl == null) return;
    final masked = !_focus.hasFocus && ctrl.text.isNotEmpty;
    if (masked != ctrl.masked) {
      setState(() => ctrl.masked = masked);
    }
  }

  @override
  void didUpdateWidget(covariant CreditCardField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_detectBrand);
      widget.controller.addListener(_detectBrand);
      if (_maskedCtrl != null) {
        _maskedCtrl!.dispose();
        _maskedCtrl = _MaskedCardTextController(source: widget.controller);
      }
      _detectBrand();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_detectBrand);
    _maskedCtrl?.dispose();
    _internalFocus?.dispose();
    super.dispose();
  }

  String get _digits => widget.controller.text.replaceAll(_nonDigit, '');

  CardBrand _detect(String digits) =>
      (widget.brandDetector ?? CardBrand.detect)(digits);

  void _detectBrand() {
    final brand = _detect(_digits);
    if (brand == _brand) return;
    setState(() => _brand = brand);
    widget.onBrandChanged?.call(brand);
  }

  /// Brand-aware default: the length must be valid FOR THE NETWORK
  /// (unknown networks fall back to the generic 13–19) + Luhn. Brand is
  /// derived from the VALUE being validated, not widget state — Form
  /// validation can run with any text.
  String? _brandValidator(String? value) {
    if (value == null || value.isEmpty) {
      return ValidatorStrings.cardNumberCannotBeEmpty;
    }
    final digits = value.replaceAll(_nonDigit, '');
    if (!_detect(digits).lengths.contains(digits.length)) {
      return ValidatorStrings.cardNumberMustBeValid;
    }
    return Validators.validateCardNumber(digits);
  }

  TextFieldSuffix? get _brandChip {
    if (!widget.showBrandChip || _brand == CardBrand.unknown) return null;
    return TextFieldSuffix.widget(
      Padding(
        padding: EdgeInsetsDirectional.only(end: context.spacing.md),
        child: Text(
          _brand.label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: context.textColors.secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Capture protection rebuilds live when recording starts/stops.
    if (!widget.detectScreenCapture) return _buildField(context, false);
    return ListenableBuilder(
      listenable: ScreenCaptureService.instance,
      builder: (context, _) =>
          _buildField(context, ScreenCaptureService.instance.isCaptured),
    );
  }

  Widget _buildField(BuildContext context, bool captured) {
    return GlobalTextFormField(
      controller: _maskedCtrl ?? widget.controller,
      label: widget.label,
      identifier: widget.identifier,
      hint: widget.hint,
      focusNode: widget.obscureWhenUnfocused ? _focus : widget.focusNode,
      style: widget.style ?? const TextFieldStyle(),
      sizing: widget.sizing ?? const TextFieldSizing(),
      messages: [
        if (captured)
          FieldMessage.warning(
            TextFieldStrings.screenCaptureWarning,
            icon: Icons.screen_share_outlined,
          ),
        ...widget.messages,
      ],
      behavior: TextFieldBehavior(
        keyboardType: TextInputType.number,
        textInputAction: widget.textInputAction,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          CreditCardInputFormatter(detector: widget.brandDetector),
        ],
        // Bullets while explicitly obscured OR while the screen is being
        // captured; capture also kills the last-char peek and gates the
        // reveal toggle behind a confirm dialog (module behavior).
        obscureText: widget.obscure || captured,
        instantObscure: captured,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        autoDetectDirection: false,
        autofillHints: widget.autofillHints,
      ),
      validation: TextFieldValidation(
        validator: widget.validator ?? _brandValidator,
        asyncValidator: widget.asyncValidator,
        asyncDebounce:
            widget.asyncDebounce ?? TextFieldDefaults.asyncValidatorDebounce,
        errorText: widget.errorText,
        mode: widget.validationMode,
        deferToParentForm: widget.deferToParentForm,
        errorIcon: widget.errorIcon,
        errorBuilder: widget.errorBuilder,
      ),
      features: TextFieldFeatures(
        showSuccess: widget.showSuccess,
        successText: widget.successText,
      ),
      slots: TextFieldSlots(
        prefixIcon: widget.showPrefixIcon
            ? Padding(
                padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
                child: Icon(
                  Icons.credit_card,
                  color: context.iconColors.primary,
                ),
              )
            : null,
        // While obscured (explicit or capture-forced) the slot must stay
        // free for the module's visibility toggle — an explicit suffix
        // replaces it, and losing the eye during a recording would lock
        // the user out of revealing. The chip returns once un-obscured.
        suffix:
            widget.suffix ?? (widget.obscure || captured ? null : _brandChip),
      ),
      callbacks: TextFieldCallbacks(
        onChanged: (value) {
          widget.onChanged?.call(value);
          final digits = value.replaceAll(_nonDigit, '');
          if (_detect(digits).lengths.contains(digits.length) &&
              Validators.isValidCardNumber(digits)) {
            widget.onCompleted?.call(digits);
          }
        },
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}
