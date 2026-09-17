import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/ip_field_strings.dart';
import '../../../module/text_field/global_text_field.dart';

/// What an [IpHostField]'s input turned out to be.
enum IpHostKind { ipv4, ipv6, hostname }

/// What the field accepts.
enum IpHostMode { any, ipOnly, hostOnly }

/// The parsed value an [IpHostField] emits.
@immutable
class IpHost {
  const IpHost({
    required this.raw,
    required this.host,
    required this.kind,
    required this.isValid,
    this.port,
  });

  /// Full input as typed (may include the port).
  final String raw;

  /// Address / hostname without the port (IPv6 without brackets).
  final String host;

  final IpHostKind? kind;

  /// Parsed `:port` â null when absent.
  final int? port;

  final bool isValid;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IpHost &&
          other.raw == raw &&
          other.host == host &&
          other.kind == kind &&
          other.port == port &&
          other.isValid == isValid;

  @override
  int get hashCode => Object.hash(raw, host, kind, port, isValid);

  @override
  String toString() =>
      'IpHost(${kind?.name}: $host${port == null ? '' : ':$port'}, valid: $isValid)';
}

/// IP-address / hostname input â auto-detects IPv4, IPv6 and hostnames
/// (server settings, self-hosted endpoints). Validation uses Dart's own
/// `Uri.parseIPv4Address` / `parseIPv6Address` (web-safe, no `dart:io`),
/// plus RFC-shaped hostname labels. [allowPort] accepts `host:8080` and
/// bracketed `[::1]:8080`; the port range-checks 1â65535.
///
/// ```dart
/// IpHostField(
///   controller: server,
///   allowPort: true,
///   onHostChanged: (h) => cubit.setEndpoint(h),
/// )
/// ```
class IpHostField extends StatelessWidget {
  const IpHostField({
    super.key,
    required this.controller,
    this.mode = IpHostMode.any,
    this.allowPort = false,
    this.onHostChanged,
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
    this.style,
    this.sizing,
  });

  static final _hostLabel = RegExp(
    r'^(?=.{1,253}$)([a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)*([a-zA-Z]{2,}|[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)$',
  );

  final TextEditingController controller;

  /// What's acceptable â IPs, hostnames, or either (default).
  final IpHostMode mode;

  /// Accept a trailing `:port` (`api.example.com:8080`, `[::1]:8080`).
  final bool allowPort;

  /// Parsed value on every change.
  final ValueChanged<IpHost>? onHostChanged;

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
  final TextFieldStyle? style;
  final TextFieldSizing? sizing;

  static bool _isIpv4(String s) {
    try {
      Uri.parseIPv4Address(s);
      return true;
    } on FormatException {
      return false;
    }
  }

  static bool _isIpv6(String s) {
    try {
      Uri.parseIPv6Address(s);
      return true;
    } on FormatException {
      return false;
    }
  }

  /// Split `host[:port]` (incl. `[v6]:port`), classify the host.
  /// `port == -1` marks a malformed port.
  static ({String host, IpHostKind? kind, int? port}) parse(
    String raw, {
    required bool allowPort,
  }) {
    var host = raw.trim();
    int? port;

    if (allowPort) {
      final bracket = RegExp(r'^\[(.+)\]:(\d+)$').firstMatch(host);
      if (bracket != null) {
        host = bracket.group(1)!;
        port = int.tryParse(bracket.group(2)!) ?? -1;
      } else {
        // A single trailing :port â an unbracketed IPv6 has 2+ colons and
        // keeps them all.
        final colonCount = ':'.allMatches(host).length;
        final lastColon = host.lastIndexOf(':');
        if (colonCount == 1 && lastColon > 0) {
          final candidate = host.substring(lastColon + 1);
          port = int.tryParse(candidate) ?? -1;
          host = host.substring(0, lastColon);
        }
      }
      if (port != null && (port < 1 || port > 65535)) port = -1;
    }

    final kind = _isIpv4(host)
        ? IpHostKind.ipv4
        : _isIpv6(host)
        ? IpHostKind.ipv6
        : _hostLabel.hasMatch(host)
        ? IpHostKind.hostname
        : null;
    return (host: host, kind: kind, port: port);
  }

  String? _defaultValidator(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return IpFieldStrings.required;
    }
    final parsed = parse(text, allowPort: allowPort);
    if (parsed.port == -1) {
      return IpFieldStrings.invalidPort;
    }
    final kind = parsed.kind;
    final ok = switch (mode) {
      IpHostMode.any => kind != null,
      IpHostMode.ipOnly => kind == IpHostKind.ipv4 || kind == IpHostKind.ipv6,
      IpHostMode.hostOnly => kind == IpHostKind.hostname,
    };
    if (!ok) {
      return mode == IpHostMode.hostOnly
          ? IpFieldStrings.invalidHost
          : IpFieldStrings.invalidIp;
    }
    return null;
  }

  void _notify(String value) {
    final cb = onHostChanged;
    if (cb == null) return;
    final text = value.trim();
    final parsed = parse(text, allowPort: allowPort);
    final effective = validator ?? _defaultValidator;
    cb(
      IpHost(
        raw: text,
        host: parsed.host,
        kind: parsed.kind,
        port: parsed.port == -1 ? null : parsed.port,
        isValid: effective(value) == null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlobalTextFormField(
      controller: controller,
      label: label,
      identifier: identifier,
      required: required,
      hint: hint ?? IpFieldStrings.hint,
      focusNode: focusNode,
      style: style ?? const TextFieldStyle(),
      sizing: sizing ?? const TextFieldSizing(),
      messages: messages,
      behavior: TextFieldBehavior(
        keyboardType: TextInputType.url,
        textInputAction: textInputAction,
        inputFormatters: [
          FilteringTextInputFormatter.deny(RegExp(r'\s')),
          LengthLimitingTextInputFormatter(260),
        ],
        enabled: enabled,
        readOnly: readOnly,
        autoDetectDirection: false,
      ),
      validation: TextFieldValidation(
        validator: validator ?? _defaultValidator,
        errorText: errorText,
        mode: validationMode,
        deferToParentForm: deferToParentForm,
        revalidateKey: (mode, allowPort),
      ),
      features: TextFieldFeatures(showSuccess: showSuccess),
      slots: TextFieldSlots(
        prefixIcon: showPrefixIcon
            ? Padding(
                padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
                child: Icon(
                  Icons.dns_outlined,
                  color: context.iconColors.primary,
                ),
              )
            : null,
        suffix: suffix,
      ),
      callbacks: TextFieldCallbacks(
        onChanged: (value) {
          onChanged?.call(value);
          _notify(value);
        },
        onSubmitted: onSubmitted,
      ),
    );
  }
}
