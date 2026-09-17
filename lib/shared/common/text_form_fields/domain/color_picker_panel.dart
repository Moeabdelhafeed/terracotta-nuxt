import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/tokens/extensions.dart';
import '../../../../core/utils/recent_colors.dart';

/// Visual color picker — a saturation/value box + hue slider (+ optional
/// alpha), a preset palette, and a live preview. Emits a [Color] on every
/// drag via [onChanged]. Anchor it in a bottom sheet / popup from a swatch.
class ColorPickerPanel extends StatefulWidget {
  const ColorPickerPanel({
    super.key,
    required this.initialColor,
    required this.onChanged,
    this.enableAlpha = true,
    this.presets = kDefaultColorPresets,
  });

  final Color initialColor;
  final ValueChanged<Color> onChanged;
  final bool enableAlpha;
  final List<Color> presets;

  @override
  State<ColorPickerPanel> createState() => _ColorPickerPanelState();
}

/// A tasteful default palette for the picker's preset row.
const List<Color> kDefaultColorPresets = [
  Color(0xFFF44336),
  Color(0xFFFF9800),
  Color(0xFFFFEB3B),
  Color(0xFF4CAF50),
  Color(0xFF009688),
  Color(0xFF2196F3),
  Color(0xFF3F51B5),
  Color(0xFF9C27B0),
  Color(0xFFE91E63),
  Color(0xFF795548),
  Color(0xFF607D8B),
  Color(0xFF000000),
  Color(0xFF9E9E9E),
  Color(0xFFFFFFFF),
];

class _ColorPickerPanelState extends State<ColorPickerPanel> {
  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initialColor);
  }

  void _update(HSVColor next) {
    setState(() => _hsv = next);
    widget.onChanged(next.toColor());
  }

  @override
  Widget build(BuildContext context) {
    final color = _hsv.toColor();
    final hueColor = HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Saturation / value box ──────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(context.radii.md),
          child: SizedBox(
            height: 160,
            width: double.infinity,
            child: _SvBox(
              hueColor: hueColor,
              saturation: _hsv.saturation,
              value: _hsv.value,
              onChanged: (s, v) => _update(_hsv.withSaturation(s).withValue(v)),
            ),
          ),
        ),
        SizedBox(height: context.spacing.md),
        // ── Hue slider ──────────────────────────────────────────────
        _GradientSlider(
          value: _hsv.hue / 360,
          trackGradient: const LinearGradient(
            colors: [
              Color(0xFFFF0000),
              Color(0xFFFFFF00),
              Color(0xFF00FF00),
              Color(0xFF00FFFF),
              Color(0xFF0000FF),
              Color(0xFFFF00FF),
              Color(0xFFFF0000),
            ],
          ),
          thumbColor: hueColor,
          onChanged: (t) => _update(_hsv.withHue(t * 360)),
        ),
        if (widget.enableAlpha) ...[
          SizedBox(height: context.spacing.sm),
          _GradientSlider(
            value: _hsv.alpha,
            checkered: true,
            trackGradient: LinearGradient(
              colors: [color.withValues(alpha: 0), color.withValues(alpha: 1)],
            ),
            thumbColor: color,
            onChanged: (t) => _update(_hsv.withAlpha(t)),
          ),
        ],
        SizedBox(height: context.spacing.md),
        // ── Preview + hex ───────────────────────────────────────────
        Row(
          children: [
            Container(
              width: context.iconSizes.xl,
              height: context.iconSizes.xl,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(context.radii.sm),
                border: Border.all(
                  color: context.backgroundColors.outline.withValues(
                    alpha: 0.4,
                  ),
                ),
              ),
            ),
            SizedBox(width: context.spacing.md),
            Text(
              '#${color.toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0').substring(2)}',
              style: TextStyle(
                color: context.textColors.secondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        _swatchRow(context, 'Presets', widget.presets),
        if (RecentColors.all.isNotEmpty)
          _swatchRow(context, 'Recent', RecentColors.all),
        _swatchRow(context, 'Harmony', _harmony()),
        _swatchRow(context, 'Shades', _shades()),
      ],
    );
  }

  /// Complementary + analogous + triadic hues from the current color.
  List<Color> _harmony() {
    final h = _hsv.hue;
    Color at(double delta) => _hsv.withHue((h + delta) % 360).toColor();
    return [at(180), at(30), at(-30), at(120), at(240)];
  }

  /// A dark→light value ramp of the current hue/saturation.
  List<Color> _shades() => [
    for (final v in [1.0, 0.8, 0.6, 0.4, 0.2]) _hsv.withValue(v).toColor(),
  ];

  Widget _swatchRow(BuildContext context, String label, List<Color> colors) {
    return Padding(
      padding: EdgeInsets.only(top: context.spacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: context.textColors.secondary),
          ),
          SizedBox(height: context.spacing.xs),
          Wrap(
            spacing: context.spacing.xs,
            runSpacing: context.spacing.xs,
            children: [
              for (final c in colors)
                Semantics(
                  button: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(context.radii.xs),
                    onTap: () => _update(HSVColor.fromColor(c)),
                    child: Container(
                      width: context.iconSizes.md,
                      height: context.iconSizes.md,
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(context.radii.xs),
                        border: Border.all(
                          color: context.backgroundColors.outline.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Saturation/value box: hue base + white→transparent + transparent→black ──
class _SvBox extends StatelessWidget {
  const _SvBox({
    required this.hueColor,
    required this.saturation,
    required this.value,
    required this.onChanged,
  });

  final Color hueColor;
  final double saturation;
  final double value;
  final void Function(double saturation, double value) onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        void handle(Offset local) {
          final s = (local.dx / size.width).clamp(0.0, 1.0);
          final v = 1 - (local.dy / size.height).clamp(0.0, 1.0);
          onChanged(s, v);
        }

        return GestureDetector(
          onPanDown: (d) => handle(d.localPosition),
          onPanUpdate: (d) => handle(d.localPosition),
          child: Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: hueColor)),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white, Colors.transparent],
                    ),
                  ),
                ),
              ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: saturation * size.width - 7,
                top: (1 - value) * size.height - 7,
                child: _Thumb(
                  fill: HSVColor.fromAHSV(1, 0, 0, value).toColor(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Horizontal gradient slider (hue / alpha) ────────────────────────
class _GradientSlider extends StatelessWidget {
  const _GradientSlider({
    required this.value,
    required this.trackGradient,
    required this.thumbColor,
    required this.onChanged,
    this.checkered = false,
  });

  final double value;
  final Gradient trackGradient;
  final Color thumbColor;
  final ValueChanged<double> onChanged;
  final bool checkered;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        void handle(Offset local) =>
            onChanged((local.dx / width).clamp(0.0, 1.0));
        return GestureDetector(
          onPanDown: (d) => handle(d.localPosition),
          onPanUpdate: (d) => handle(d.localPosition),
          child: SizedBox(
            height: 20,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                if (checkered)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CustomPaint(painter: _CheckerPainter()),
                    ),
                  ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: trackGradient,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: context.backgroundColors.outline.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: (value.clamp(0.0, 1.0)) * (width - 14),
                  child: _Thumb(fill: thumbColor),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.fill});
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
      ),
    );
  }
}

class _CheckerPainter extends CustomPainter {
  static const _cell = 6.0;
  @override
  void paint(Canvas canvas, Size size) {
    final light = Paint()..color = const Color(0xFFE0E0E0);
    final dark = Paint()..color = const Color(0xFFB0B0B0);
    for (var y = 0.0; y < size.height; y += _cell) {
      for (var x = 0.0; x < size.width; x += _cell) {
        final even = ((x ~/ _cell) + (y ~/ _cell)).isEven;
        canvas.drawRect(Rect.fromLTWH(x, y, _cell, _cell), even ? light : dark);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
