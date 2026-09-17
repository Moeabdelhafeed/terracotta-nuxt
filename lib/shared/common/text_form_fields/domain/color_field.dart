import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/strings/color_field_strings.dart';
import '../../../../core/tokens/extensions.dart';
import '../../../../core/utils/color_codec.dart';
import '../../../../core/utils/css_colors.dart';
import '../../../../core/utils/recent_colors.dart';
import '../../../../core/utils/validators/validators.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../../../module/sheet/global_sheet.dart';
import '../../../module/text_field/global_text_field.dart';
import '../../dropdown_fields/domain/color_format_dropdown_field.dart'
    show ColorFormatDropdownField;
import 'color_picker_panel.dart';
import 'joined_pair_radii.dart';

export '../../../../core/utils/color_codec.dart' show ColorFormat, ColorCodec;

/// The parsed value a [ColorField] emits — the [Color] (null while empty /
/// invalid), the active [format], the raw text, and validity. Matches the
/// `Money` / `Measurement` value-object pattern.
@immutable
class ColorValue {
  const ColorValue({
    required this.color,
    required this.format,
    required this.raw,
    required this.isValid,
  });

  /// Parsed color, or null while the field is empty / mid-entry / invalid.
  final Color? color;

  /// The format the text is currently expressed in.
  final ColorFormat format;

  /// The exact field text.
  final String raw;

  /// Passes the field's sync validator (empty counts as valid unless the
  /// field is `required`).
  final bool isValid;

  /// This color re-expressed in [target] (e.g. read the hex of an rgb entry),
  /// or null when there's no parsed color.
  String? asFormat(ColorFormat target) =>
      color == null ? null : ColorCodec.encode(color!, target);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColorValue &&
          other.color == color &&
          other.format == format &&
          other.raw == raw &&
          other.isValid == isValid;

  @override
  int get hashCode => Object.hash(color, format, raw, isValid);

  @override
  String toString() => 'ColorValue($raw as ${format.label}, valid: $isValid)';
}

/// Color input with a live swatch prefix and a FORMAT picker joined to the
/// end (`HEX` / `RGB` / `HSL` …, mirror of the phone/currency/measurement
/// pairs). Each format brings its own formatter, hint and validator;
/// [convertOnFormatChange] re-expresses the typed color when the format
/// switches (`#FF5733` → `rgb(255, 87, 51)`). [onColorChanged] emits a parsed
/// [ColorValue].
class ColorField extends StatefulWidget {
  const ColorField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onColorChanged,
    this.onFormatChanged,
    this.label,
    this.identifier,
    this.hint,
    this.enabled = true,
    this.readOnly = false,
    this.required = false,
    this.errorText,
    this.validator,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.validationMode = ValidationMode.onInteraction,
    this.deferToParentForm = true,
    this.messages = const [],
    this.initialFormat = ColorFormat.hex,
    this.allowedFormats = ColorFormat.values,
    this.showFormatPicker = true,
    this.convertOnFormatChange = true,
    this.showCopyButton = false,
    this.showPicker = true,
    this.style,
    this.sizing,
  }) : assert(allowedFormats.length > 0, 'Provide at least one format.');

  final TextEditingController controller;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;

  /// Parsed value on every change (typing or format switch).
  final ValueChanged<ColorValue>? onColorChanged;
  final ValueChanged<ColorFormat>? onFormatChanged;

  final String? label;
  final String? identifier;

  /// Placeholder override; null → the active format's example.
  final String? hint;

  final bool enabled;
  final bool readOnly;

  /// Empty input fails validation.
  final bool required;

  final String? errorText;

  /// Sync check. Null → optional + per-format validity ([ColorCodec.isValid]).
  final String? Function(String?)? validator;

  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final ValidationMode validationMode;

  /// Keep `true` inside a `Form`; `false` for standalone fields.
  final bool deferToParentForm;

  final List<FieldMessage> messages;

  /// Format the field starts in.
  final ColorFormat initialFormat;

  /// Formats offered in the picker (one → no picker, static format).
  final List<ColorFormat> allowedFormats;

  /// Show the joined format picker. False → single fixed [initialFormat].
  final bool showFormatPicker;

  /// Re-express the typed color when the format changes (same color, new
  /// notation). Off keeps the raw text as-is.
  final bool convertOnFormatChange;

  /// Show a suffix copy button that copies the current text to the clipboard.
  final bool showCopyButton;

  /// Tapping the swatch opens a visual color picker (bottom sheet) that
  /// live-writes the picked color back in the active format.
  final bool showPicker;

  final TextFieldStyle? style;
  final TextFieldSizing? sizing;

  @override
  State<ColorField> createState() => _ColorFieldState();
}

class _ColorFieldState extends State<ColorField> {
  late ColorFormat _format;

  @override
  void initState() {
    super.initState();
    _format = widget.allowedFormats.contains(widget.initialFormat)
        ? widget.initialFormat
        : widget.allowedFormats.first;
  }

  @override
  void didUpdateWidget(covariant ColorField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.allowedFormats.contains(_format)) {
      _format = widget.allowedFormats.first;
    }
  }

  bool get _hasPicker =>
      widget.showFormatPicker && widget.allowedFormats.length > 1;

  List<TextInputFormatter> get _formatters => switch (_format) {
    ColorFormat.hex => const [ColorHexInputFormatter()],
    ColorFormat.hex8 => const [ColorHexInputFormatter(digits: 8)],
    // rgb / hsl families: keep it to the characters those notations use.
    _ => [FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z(),.%\s]'))],
  };

  int? get _maxLength => switch (_format) {
    ColorFormat.hex => 7,
    ColorFormat.hex8 => 9,
    _ => null,
  };

  String? _defaultValidator(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) {
      return widget.required ? Validators.validateRequired(value) : null;
    }
    return ColorCodec.isValid(v, _format)
        ? null
        : ColorFieldStrings.invalidFormat(_format.hint);
  }

  void _selectFormat(ColorFormat format) {
    final previous = _format;
    setState(() => _format = format);
    // Convert the typed color into the new notation (same color, new text).
    if (widget.convertOnFormatChange) {
      final color = ColorCodec.parse(widget.controller.text, previous);
      if (color != null) {
        final text = ColorCodec.encode(color, format);
        widget.controller.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }
    }
    widget.onFormatChanged?.call(format);
    _emit();
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.controller.text));
  }

  /// Live swatch prefix; tapping it opens the visual picker when [showPicker].
  Widget _swatch() {
    final swatch = TextFieldColorPreview(controller: widget.controller);
    if (!widget.showPicker || widget.readOnly || !widget.enabled) return swatch;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openPicker,
      child: swatch,
    );
  }

  Future<void> _openPicker() async {
    final current =
        ColorCodec.parseAny(widget.controller.text) ?? const Color(0xFFFFFFFF);
    await GlobalBottomSheet.show<void>(
      context: context,
      title: ColorFieldStrings.pickerTitle,
      content: Padding(
        padding: EdgeInsets.all(context.spacing.md),
        child: ColorPickerPanel(
          initialColor: current,
          enableAlpha: _format.hasAlpha,
          onChanged: (c) {
            final text = ColorCodec.encode(c, _format);
            widget.controller.value = TextEditingValue(
              text: text,
              selection: TextSelection.collapsed(offset: text.length),
            );
            _emit();
          },
        ),
      ),
    );
    // Remember the picked color for the picker's "Recent" row.
    final picked = ColorCodec.parseAny(widget.controller.text);
    if (picked != null) RecentColors.add(picked);
  }

  void _emit() {
    final cb = widget.onColorChanged;
    if (cb == null) return;
    final raw = widget.controller.text;
    final color = ColorCodec.parse(raw, _format);
    cb(
      ColorValue(
        color: color,
        format: _format,
        raw: raw,
        isValid: raw.trim().isEmpty ? !widget.required : color != null,
      ),
    );
  }

  /// Canonical format row — shared with the standalone
  /// `ColorFormatDropdownField` so both pickers render identically.
  DropdownItem<ColorFormat> _formatItem(ColorFormat f) =>
      ColorFormatDropdownField.itemFor(f);

  Widget _formatPicker(BorderRadius borderRadius) {
    return GlobalDropdown<ColorFormat>(
      enabled: widget.enabled,
      style: TextFieldStyle(borderRadius: borderRadius),
      // Short fixed labels (HEX / RGBA) — hug them with a stable floor,
      // pinned to the field's box height so the seam lines up.
      sizing: TextFieldSizing(
        fitWidthToContent: true,
        minWidth: 84,
        maxWidth: 120,
        height: widget.sizing?.height ?? kJoinedPairBoxHeight,
      ),
      items: widget.allowedFormats.map(_formatItem).toList(),
      selectedValue: _format,
      onChanged: (f) {
        if (f != null) _selectFormat(f);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final radii = _hasPicker ? joinedPairRadii(context) : null;
    final baseStyle = widget.style ?? const TextFieldStyle();

    final field = GlobalTextFormField(
      controller: widget.controller,
      label: widget.label,
      // Identifier moves to an external header when the picker widens the
      // control so it spans the whole pair.
      identifier: _hasPicker ? null : widget.identifier,
      hint: widget.hint ?? _format.hint,
      focusNode: widget.focusNode,
      style: radii == null
          ? baseStyle
          : baseStyle.copyWith(borderRadius: radii.start),
      sizing: widget.sizing ?? const TextFieldSizing(),
      messages: widget.messages,
      behavior: TextFieldBehavior(
        textInputAction: widget.textInputAction,
        inputFormatters: _formatters,
        maxLength: _maxLength,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        autoDetectDirection: false,
      ),
      validation: TextFieldValidation(
        validator: widget.validator ?? _defaultValidator,
        errorText: widget.errorText,
        mode: widget.validationMode,
        deferToParentForm: widget.deferToParentForm,
        // Re-validate when the format (hence the accepted notation) changes.
        revalidateKey: (_format, widget.required),
      ),
      // In NAME format, autocomplete the 148 CSS names as you type.
      features: _format == ColorFormat.named
          ? TextFieldFeatures(
              suggestions: SuggestionsConfig(
                items: CssColors.names,
                onSelected: (s) {
                  widget.controller.value = TextEditingValue(
                    text: s,
                    selection: TextSelection.collapsed(offset: s.length),
                  );
                  _emit();
                },
              ),
            )
          : const TextFieldFeatures(),
      slots: TextFieldSlots(
        prefixIcon: _swatch(),
        suffix: widget.showCopyButton
            ? TextFieldSuffix.icon(Icons.copy_outlined, onTap: _copy)
            : null,
      ),
      callbacks: TextFieldCallbacks(
        onChanged: (value) {
          widget.onChanged?.call(value);
          _emit();
        },
        onSubmitted: widget.onSubmitted,
      ),
    );

    final core = _hasPicker
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: field),
              _formatPicker(radii!.end),
            ],
          )
        : field;

    if (!_hasPicker || widget.identifier == null) return core;

    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: context.spacing.sm),
          child: Text(
            widget.identifier!,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        core,
      ],
    );
  }
}
