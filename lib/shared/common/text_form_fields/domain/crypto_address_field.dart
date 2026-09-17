import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/misc_field_strings.dart';
import '../../../module/text_field/global_text_field.dart';

/// Supported wallet-address shapes.
enum CryptoNetwork {
  bitcoin('Bitcoin'),
  ethereum('Ethereum'),
  tron('TRON'),
  generic('Crypto');

  const CryptoNetwork(this.label);
  final String label;
}

/// The parsed value a [CryptoAddressField] emits.
@immutable
class CryptoAddress {
  const CryptoAddress({
    required this.raw,
    required this.network,
    required this.isValid,
  });

  final String raw;

  /// Detected (or pinned) network.
  final CryptoNetwork network;

  final bool isValid;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CryptoAddress &&
          other.raw == raw &&
          other.network == network &&
          other.isValid == isValid;

  @override
  int get hashCode => Object.hash(raw, network, isValid);

  @override
  String toString() => 'CryptoAddress(${network.name}: $raw, valid: $isValid)';
}

/// Crypto wallet-address input â auto-DETECTS the network from the
/// prefix (`0xâ¦` Ethereum, `bc1â¦`/`1â¦`/`3â¦` Bitcoin, `Tâ¦` TRON) or pins
/// one via [network]. STRUCTURE validation only (length + base58/bech32/
/// hex charsets) â deliberately no checksum math: ETH's EIP-55 needs
/// keccak and BTC's base58check needs double-SHA; a wrong-checksum
/// address still fails at the node, and structure catches the
/// truncated-paste / wrong-network mistakes that actually happen.
/// A valid address grows an info row naming the detected network.
///
/// ```dart
/// CryptoAddressField(
///   controller: wallet,
///   network: CryptoNetwork.ethereum,
///   onAddressChanged: (a) => cubit.setWallet(a),
/// )
/// ```
class CryptoAddressField extends StatefulWidget {
  const CryptoAddressField({
    super.key,
    required this.controller,
    this.network,
    this.onAddressChanged,
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
    this.focusNode,
    this.textInputAction = TextInputAction.done,
    this.validationMode = ValidationMode.onFocusLoss,
    this.deferToParentForm = true,
    this.messages = const [],
    this.showSuccess = false,
    this.showPrefixIcon = true,
    this.suffix,
    this.showNetworkInfo = true,
    this.style,
    this.sizing,
  });

  static final _eth = RegExp(r'^0x[a-fA-F0-9]{40}$');
  static final _btcLegacy = RegExp(r'^[13][a-km-zA-HJ-NP-Z1-9]{24,33}$');
  static final _btcBech32 = RegExp(r'^bc1[02-9ac-hj-np-z]{11,71}$');
  static final _trx = RegExp(r'^T[a-km-zA-HJ-NP-Z1-9]{33}$');

  final TextEditingController controller;

  /// Pin one network â addresses of any other shape fail. Null â
  /// auto-detect.
  final CryptoNetwork? network;

  /// Parsed value on every change.
  final ValueChanged<CryptoAddress>? onAddressChanged;

  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final String? label;
  final String? identifier;
  final bool required;
  final String? hint;
  final bool enabled;
  final bool readOnly;
  final String? errorText;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final ValidationMode validationMode;
  final bool deferToParentForm;
  final List<FieldMessage> messages;
  final bool showSuccess;
  final bool showPrefixIcon;

  /// Trailing slot — e.g. a QR/barcode scan button
  /// (`TextFieldSuffix.icon(Icons.qr_code_scanner, onTap: ...)`).
  final TextFieldSuffix? suffix;

  /// Info row naming the detected network under a valid address.
  final bool showNetworkInfo;

  final TextFieldStyle? style;
  final TextFieldSizing? sizing;

  /// Which network [text] structurally matches, if any.
  static CryptoNetwork? detect(String text) {
    if (_eth.hasMatch(text)) return CryptoNetwork.ethereum;
    if (_btcBech32.hasMatch(text) || _btcLegacy.hasMatch(text)) {
      return CryptoNetwork.bitcoin;
    }
    if (_trx.hasMatch(text)) return CryptoNetwork.tron;
    return null;
  }

  @override
  State<CryptoAddressField> createState() => _CryptoAddressFieldState();
}

class _CryptoAddressFieldState extends State<CryptoAddressField> {
  String? _defaultValidator(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return CryptoFieldStrings.required;
    }
    final detected = CryptoAddressField.detect(text);
    final pinned = widget.network;
    final ok = pinned == null ? detected != null : detected == pinned;
    if (!ok) {
      return CryptoFieldStrings.invalid(
        (pinned ?? CryptoNetwork.generic).label,
      );
    }
    return null;
  }

  void _notify(String value) {
    final cb = widget.onAddressChanged;
    if (cb == null) return;
    final text = value.trim();
    final effective = widget.validator ?? _defaultValidator;
    cb(
      CryptoAddress(
        raw: text,
        network:
            CryptoAddressField.detect(text) ??
            widget.network ??
            CryptoNetwork.generic,
        isValid: effective(value) == null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detected = CryptoAddressField.detect(widget.controller.text.trim());
    return GlobalTextFormField(
      controller: widget.controller,
      label: widget.label,
      identifier: widget.identifier,
      required: widget.required,
      hint: widget.hint ?? CryptoFieldStrings.hint,
      focusNode: widget.focusNode,
      style: widget.style ?? const TextFieldStyle(),
      sizing: widget.sizing ?? const TextFieldSizing(),
      messages: [
        ...widget.messages,
        if (widget.showNetworkInfo &&
            detected != null &&
            (widget.validator ?? _defaultValidator)(widget.controller.text) ==
                null)
          FieldMessage.info(detected.label, icon: Icons.currency_bitcoin),
      ],
      behavior: TextFieldBehavior(
        keyboardType: TextInputType.visiblePassword,
        textInputAction: widget.textInputAction,
        inputFormatters: [
          // Addresses are case-SENSITIVE (base58) â only strip
          // whitespace noise from pastes.
          FilteringTextInputFormatter.deny(RegExp(r'\s')),
          LengthLimitingTextInputFormatter(90),
        ],
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        autoDetectDirection: false,
      ),
      validation: TextFieldValidation(
        validator: widget.validator ?? _defaultValidator,
        errorText: widget.errorText,
        mode: widget.validationMode,
        deferToParentForm: widget.deferToParentForm,
        revalidateKey: widget.network,
      ),
      features: TextFieldFeatures(showSuccess: widget.showSuccess),
      slots: TextFieldSlots(
        prefixIcon: widget.showPrefixIcon
            ? Padding(
                padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: context.iconColors.primary,
                ),
              )
            : null,
        suffix: widget.suffix,
      ),
      callbacks: TextFieldCallbacks(
        onChanged: (value) {
          widget.onChanged?.call(value);
          // Network info row tracks the live text.
          setState(() {});
          _notify(value);
        },
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}
