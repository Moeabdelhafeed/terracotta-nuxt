import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/animations/animation_presets.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/color_field_strings.dart';
import '../../../../core/tokens/extensions.dart';
import '../../../../core/utils/color_codec.dart';
import '../../../../core/utils/recent_colors.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../../../module/sheet/global_sheet.dart';
import '../../../module/text_field/global_text_field.dart';
import '../../dropdown_fields/domain/color_format_dropdown_field.dart'
    show ColorFormatDropdownField;
import 'color_field.dart';
import 'color_picker_panel.dart';
import 'joined_pair_radii.dart';

export '../../../../core/utils/color_codec.dart' show ColorFormat, ColorCodec;
export 'color_field.dart' show ColorValue;

/// Segmented color input — one small box PER CHANNEL (R / G / B, or the hex
/// pairs, or H / S / L …), joined into a single control with a format picker
/// on the end (the phone/measurement joined-pair look, extended to N boxes).
///
/// - **Validates as a whole**: the group is valid only when every channel is
///   filled + in range; one error row sits under the row, not per box.
/// - **Paste distribution**: paste a full color (`#FF5733`, `rgb(...)`, …)
///   into ANY box and it's split across all boxes — converted into the active
///   format if it was pasted in another.
/// - **Auto-advance**: focus jumps to the next box as each fills.
/// - **Format switch** converts the current color into the new channel set.
///
/// Emits a parsed [ColorValue] via [onColorChanged].
class SegmentedColorField extends StatefulWidget {
  const SegmentedColorField({
    super.key,
    this.initialColor,
    this.initialFormat = ColorFormat.hex,
    this.allowedFormats = ColorFormat.values,
    this.showFormatPicker = true,
    this.convertOnFormatChange = true,
    this.showPicker = true,
    this.enabled = true,
    this.required = false,
    this.identifier,
    this.onColorChanged,
    this.onFormatChanged,
    this.style,
  }) : assert(allowedFormats.length > 0, 'Provide at least one format.');

  /// Seed color (decomposed into the initial format's channels).
  final Color? initialColor;
  final ColorFormat initialFormat;
  final List<ColorFormat> allowedFormats;
  final bool showFormatPicker;
  final bool convertOnFormatChange;

  /// Tapping the leading swatch opens the visual color picker.
  final bool showPicker;

  final bool enabled;

  /// Any empty channel fails validation.
  final bool required;

  final String? identifier;
  final ValueChanged<ColorValue>? onColorChanged;
  final ValueChanged<ColorFormat>? onFormatChanged;
  final TextFieldStyle? style;

  @override
  State<SegmentedColorField> createState() => _SegmentedColorFieldState();
}

/// Shared height for the channel boxes + the format picker so they line up
/// (the picker's chevron button would otherwise inflate it taller).
const double _kSegmentHeight = 48;

class _SegmentedColorFieldState extends State<SegmentedColorField> {
  late ColorFormat _format;
  List<ColorChannel> _channels = const [];
  List<TextEditingController> _controllers = const [];
  List<FocusNode> _nodes = const [];

  /// Guards the re-entrant write during paste distribution / format convert.
  bool _distributing = false;

  /// Only formats with channels are segmentable — `named` has none, so it's
  /// dropped from the segmented picker.
  List<ColorFormat> get _formats {
    final f = widget.allowedFormats
        .where((x) => x.channels.isNotEmpty)
        .toList();
    return f.isEmpty ? const [ColorFormat.hex] : f;
  }

  @override
  void initState() {
    super.initState();
    _format = _formats.contains(widget.initialFormat)
        ? widget.initialFormat
        : _formats.first;
    _rebuildSegments(seed: widget.initialColor);
  }

  @override
  void dispose() {
    _disposeSegments();
    super.dispose();
  }

  void _disposeSegments() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
  }

  void _rebuildSegments({Color? seed}) {
    _disposeSegments();
    _channels = _format.channels;
    _controllers = List.generate(
      _channels.length,
      (_) => TextEditingController(),
    );
    _nodes = List.generate(_channels.length, (_) => FocusNode());
    if (seed != null) _applyColor(seed);
  }

  bool get _hasPicker => widget.showFormatPicker && _formats.length > 1;

  Color? get _currentColor => ColorCodec.colorFromChannels(
    _format,
    _controllers.map((c) => c.text).toList(),
  );

  bool get _anyFilled => _controllers.any((c) => c.text.trim().isNotEmpty);

  /// Fill every box from [color]'s channels (paste / seed / format convert).
  void _applyColor(Color color) {
    _distributing = true;
    final parts = ColorCodec.channelsOf(_format, color);
    for (var i = 0; i < _controllers.length && i < parts.length; i++) {
      final t = parts[i];
      _controllers[i].value = TextEditingValue(
        text: t,
        selection: TextSelection.collapsed(offset: t.length),
      );
    }
    _distributing = false;
  }

  void _onSegment(int i, String value) {
    if (_distributing) return;
    final ch = _channels[i];
    // Full-color paste into a box → split it across every box (converting to
    // the active format if it was pasted in another notation).
    if (value.length > ch.maxLen) {
      final color = ColorCodec.parseAny(value);
      if (color != null) {
        _applyColor(color);
        _nodes[i].unfocus();
        setState(_emit);
        return;
      }
    }
    // Auto-advance as each box fills.
    if (value.length >= ch.maxLen && i < _channels.length - 1) {
      _nodes[i + 1].requestFocus();
    }
    setState(_emit);
  }

  void _emit() {
    final color = _currentColor;
    final valid = color != null || (!widget.required && !_anyFilled);
    widget.onColorChanged?.call(
      ColorValue(
        color: color,
        format: _format,
        raw: color != null
            ? ColorCodec.encode(color, _format)
            : _controllers.map((c) => c.text).join(', '),
        isValid: valid,
      ),
    );
  }

  void _selectFormat(ColorFormat f) {
    if (f == _format) return;
    final color = widget.convertOnFormatChange ? _currentColor : null;
    setState(() {
      _format = f;
      _rebuildSegments(seed: color);
    });
    widget.onFormatChanged?.call(f);
    _emit();
  }

  Future<void> _openPicker() async {
    final current = _currentColor ?? const Color(0xFFFFFFFF);
    await GlobalBottomSheet.show<void>(
      context: context,
      title: ColorFieldStrings.pickerTitle,
      content: Padding(
        padding: EdgeInsets.all(context.spacing.md),
        child: ColorPickerPanel(
          initialColor: current,
          enableAlpha: _format.hasAlpha,
          onChanged: (c) {
            _applyColor(c);
            setState(_emit);
          },
        ),
      ),
    );
    final picked = _currentColor;
    if (picked != null) RecentColors.add(picked);
  }

  // ── UI ──────────────────────────────────────────────────────────────
  /// Live swatch shown as the LEADING of the first channel box; tapping it
  /// opens the visual picker when [SegmentedColorField.showPicker].
  Widget _leadingSwatch() {
    final outline = context.backgroundColors.outline;
    final swatch = AnimatedContainer(
      duration: AppDurations.quick,
      width: context.iconSizes.sm,
      height: context.iconSizes.sm,
      decoration: BoxDecoration(
        color: _currentColor ?? outline.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(context.radii.xs),
        border: Border.all(color: outline.withValues(alpha: 0.4)),
      ),
    );
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 6, end: 2),
      child: widget.showPicker && widget.enabled
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _openPicker,
              child: swatch,
            )
          : swatch,
    );
  }

  Widget _segment(int i) {
    final ch = _channels[i];
    final base = widget.style ?? const TextFieldStyle();
    final isFirst = i == 0;
    final radii = edgeRadii(
      context,
      roundStart: isFirst,
      roundEnd: !_hasPicker && i == _channels.length - 1,
    );
    // No fixed width — the caller wraps each box in `Expanded` so every
    // channel shares the row width equally and grows with the container.
    return GlobalTextFormField(
      controller: _controllers[i],
      focusNode: _nodes[i],
      hint: ch.label,
      // Pin the height so the boxes line up with the format picker.
      sizing: const TextFieldSizing(height: _kSegmentHeight),
      style: base.copyWith(
        borderRadius: radii,
        // Tight cells — values are 2–4 chars, centred; drop the horizontal
        // inset so boxes hug the digits (vertical fits the pinned height).
        contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 14),
      ),
      slots: isFirst
          ? TextFieldSlots(prefixIcon: _leadingSwatch())
          : const TextFieldSlots(),
      behavior: TextFieldBehavior(
        textAlign: TextAlign.center,
        keyboardType: ch.isHex ? TextInputType.text : TextInputType.number,
        inputFormatters: [
          _ColorSegmentFormatter(maxLen: ch.maxLen, isHex: ch.isHex),
        ],
        enabled: widget.enabled,
        autoDetectDirection: false,
      ),
      callbacks: TextFieldCallbacks(onChanged: (v) => _onSegment(i, v)),
    );
  }

  Widget _formatPicker() {
    return GlobalDropdown<ColorFormat>(
      enabled: widget.enabled,
      style: TextFieldStyle(
        borderRadius: edgeRadii(context, roundStart: false, roundEnd: true),
      ),
      sizing: const TextFieldSizing(
        fitWidthToContent: true,
        minWidth: 84,
        maxWidth: 120,
        // Match the channel boxes — without this the chevron button inflates
        // the trigger taller, leaving a gap below it.
        height: _kSegmentHeight,
      ),
      // Canonical format rows — shared with `ColorFormatDropdownField`.
      items: _formats.map(ColorFormatDropdownField.itemFor).toList(),
      selectedValue: _format,
      onChanged: (f) {
        if (f != null) _selectFormat(f);
      },
    );
  }

  Widget? _statusRow(Color? color) {
    // Whole-group validity: incomplete/invalid while any box is filled, or
    // required + empty.
    final invalid = _anyFilled && color == null;
    final requiredEmpty = widget.required && !_anyFilled;
    if (!invalid && !requiredEmpty) return null;
    final message = requiredEmpty
        ? ColorFieldStrings.required
        : ColorFieldStrings.invalidFormat(_format.hint);
    return Padding(
      padding: EdgeInsets.only(top: context.spacing.xs),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 14,
            color: context.statusColors.error,
          ),
          SizedBox(width: context.spacing.xs),
          Flexible(
            child: Text(
              message,
              style: TextStyle(color: context.statusColors.error, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _currentColor;
    final status = _statusRow(color);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.identifier != null)
          Padding(
            padding: EdgeInsets.only(bottom: context.spacing.sm),
            child: Text(
              widget.identifier!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Every channel box shares the width equally (flex 1); the format
            // picker keeps its own content width at the end.
            for (var i = 0; i < _channels.length; i++)
              Expanded(child: _segment(i)),
            if (_hasPicker) _formatPicker(),
          ],
        ),
        if (status != null) status,
      ],
    );
  }
}

/// Per-box formatter: filters to the channel's charset + clamps length, but
/// lets a FULL-color paste through untouched so the field can split it across
/// all boxes (see `_SegmentedColorFieldState._onSegment`).
class _ColorSegmentFormatter extends TextInputFormatter {
  const _ColorSegmentFormatter({required this.maxLen, required this.isHex});

  final int maxLen;
  final bool isHex;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    // A pasted full color is longer than one channel and parses → pass it
    // through; onChanged distributes then rewrites this box to its channel.
    if (text.length > maxLen && ColorCodec.parseAny(text) != null) {
      return newValue;
    }
    var s = isHex
        ? text.toUpperCase().replaceAll(RegExp(r'[^0-9A-F]'), '')
        : text.replaceAll(RegExp(r'[^0-9.]'), '');
    if (s.length > maxLen) s = s.substring(0, maxLen);
    return TextEditingValue(
      text: s,
      selection: TextSelection.collapsed(offset: s.length),
    );
  }
}
