import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/tokens/app_tokens.dart';
import '../../toast/global_toast.dart';
import '../debug_overlay_models.dart';
import '../widgets/debug_search_field.dart';

/// Inspector for the resolved theme tree — the full `ColorScheme`, the
/// COMPLETE `AppPalette` (all 8 role groups), `AppTokens` with visual
/// previews (spacing bars, radius corners, icon sizes, elevation
/// shadows), and the live type scale. Tap anything to copy.
class DebugThemeTokensView extends StatefulWidget {
  const DebugThemeTokensView({super.key});

  @override
  State<DebugThemeTokensView> createState() => _DebugThemeTokensViewState();
}

class _DebugThemeTokensViewState extends State<DebugThemeTokensView> {
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final palette = theme.extension<AppPalette>();
    final tokens = theme.extension<AppTokens>();

    final colors = <(String, Color)>[
      ('primary', cs.primary),
      ('onPrimary', cs.onPrimary),
      ('primaryContainer', cs.primaryContainer),
      ('onPrimaryContainer', cs.onPrimaryContainer),
      ('inversePrimary', cs.inversePrimary),
      ('secondary', cs.secondary),
      ('onSecondary', cs.onSecondary),
      ('secondaryContainer', cs.secondaryContainer),
      ('onSecondaryContainer', cs.onSecondaryContainer),
      ('tertiary', cs.tertiary),
      ('onTertiary', cs.onTertiary),
      ('tertiaryContainer', cs.tertiaryContainer),
      ('onTertiaryContainer', cs.onTertiaryContainer),
      ('error', cs.error),
      ('onError', cs.onError),
      ('errorContainer', cs.errorContainer),
      ('onErrorContainer', cs.onErrorContainer),
      ('surface', cs.surface),
      ('onSurface', cs.onSurface),
      ('onSurfaceVariant', cs.onSurfaceVariant),
      ('surfaceContainerLowest', cs.surfaceContainerLowest),
      ('surfaceContainerLow', cs.surfaceContainerLow),
      ('surfaceContainer', cs.surfaceContainer),
      ('surfaceContainerHigh', cs.surfaceContainerHigh),
      ('surfaceContainerHighest', cs.surfaceContainerHighest),
      ('inverseSurface', cs.inverseSurface),
      ('onInverseSurface', cs.onInverseSurface),
      ('outline', cs.outline),
      ('outlineVariant', cs.outlineVariant),
      ('shadow', cs.shadow),
      ('scrim', cs.scrim),
    ];

    final paletteRows = palette == null
        ? const <(String, Color)>[]
        : <(String, Color)>[
            ('primary.primary', palette.primary.primary),
            ('primary.secondary', palette.primary.secondary),
            ('primary.accent', palette.primary.accent),
            (
              'primary.primaryHighContrast',
              palette.primary.primaryHighContrast,
            ),
            ('primary.border', palette.primary.border),
            ('background.background', palette.background.background),
            ('background.surface', palette.background.surface),
            (
              'background.scaffoldBackground',
              palette.background.scaffoldBackground,
            ),
            ('background.container', palette.background.container),
            ('background.cardBackground', palette.background.cardBackground),
            ('background.inputBackground', palette.background.inputBackground),
            ('background.outline', palette.background.outline),
            ('background.outlineVariant', palette.background.outlineVariant),
            ('text.primary', palette.text.primary),
            ('text.secondary', palette.text.secondary),
            ('text.disabled', palette.text.disabled),
            ('text.onPrimary', palette.text.onPrimary),
            ('text.onAccent', palette.text.onAccent),
            ('text.link', palette.text.link),
            ('text.primaryHighContrast', palette.text.primaryHighContrast),
            ('buttons.primary', palette.buttons.primary),
            ('buttons.secondary', palette.buttons.secondary),
            ('buttons.disabled', palette.buttons.disabled),
            ('buttons.outline', palette.buttons.outline),
            ('status.success', palette.status.success),
            ('status.warning', palette.status.warning),
            ('status.error', palette.status.error),
            ('status.info', palette.status.info),
            ('icon.primary', palette.icon.primary),
            ('icon.secondary', palette.icon.secondary),
            ('icon.onPrimary', palette.icon.onPrimary),
            ('shimmer.baseColor', palette.shimmer.baseColor),
            ('shimmer.highlight', palette.shimmer.highlight),
            (
              'shimmer.containerBackground',
              palette.shimmer.containerBackground,
            ),
            ('overlay.barrier', palette.overlay.barrier),
            ('overlay.scrim', palette.overlay.scrim),
            ('overlay.modalBackground', palette.overlay.modalBackground),
          ];

    final spacingRows = tokens == null
        ? const <(String, double)>[]
        : <(String, double)>[
            ('spacing.xs', tokens.spacing.xs),
            ('spacing.sm', tokens.spacing.sm),
            ('spacing.md', tokens.spacing.md),
            ('spacing.lg', tokens.spacing.lg),
            ('spacing.xl', tokens.spacing.xl),
            ('spacing.xxl', tokens.spacing.xxl),
          ];
    final radiiRows = tokens == null
        ? const <(String, double)>[]
        : <(String, double)>[
            ('radii.xs', tokens.radii.xs),
            ('radii.sm', tokens.radii.sm),
            ('radii.md', tokens.radii.md),
            ('radii.lg', tokens.radii.lg),
            ('radii.xl', tokens.radii.xl),
            ('radii.full', tokens.radii.full),
          ];
    final iconRows = tokens == null
        ? const <(String, double)>[]
        : <(String, double)>[
            ('iconSizes.xs', tokens.iconSizes.xs),
            ('iconSizes.sm', tokens.iconSizes.sm),
            ('iconSizes.md', tokens.iconSizes.md),
            ('iconSizes.lg', tokens.iconSizes.lg),
            ('iconSizes.xl', tokens.iconSizes.xl),
            ('iconSizes.xxl', tokens.iconSizes.xxl),
          ];
    final elevationRows = tokens == null
        ? const <(String, double)>[]
        : <(String, double)>[
            ('elevation.flat', tokens.elevation.flat),
            ('elevation.low', tokens.elevation.low),
            ('elevation.medium', tokens.elevation.medium),
            ('elevation.high', tokens.elevation.high),
            ('elevation.max', tokens.elevation.max),
          ];

    final tt = theme.textTheme;
    final typeRows = <(String, TextStyle?)>[
      ('displayLarge', tt.displayLarge),
      ('displayMedium', tt.displayMedium),
      ('displaySmall', tt.displaySmall),
      ('headlineLarge', tt.headlineLarge),
      ('headlineMedium', tt.headlineMedium),
      ('headlineSmall', tt.headlineSmall),
      ('titleLarge', tt.titleLarge),
      ('titleMedium', tt.titleMedium),
      ('titleSmall', tt.titleSmall),
      ('bodyLarge', tt.bodyLarge),
      ('bodyMedium', tt.bodyMedium),
      ('bodySmall', tt.bodySmall),
      ('labelLarge', tt.labelLarge),
      ('labelMedium', tt.labelMedium),
      ('labelSmall', tt.labelSmall),
    ];

    final q = _query.trim().toLowerCase();
    bool match(String name) => q.isEmpty || name.toLowerCase().contains(q);
    final shownColors = colors.where((c) => match(c.$1)).toList();
    final shownPalette = paletteRows.where((c) => match(c.$1)).toList();
    final shownSpacing = spacingRows.where((c) => match(c.$1)).toList();
    final shownRadii = radiiRows.where((c) => match(c.$1)).toList();
    final shownIcons = iconRows.where((c) => match(c.$1)).toList();
    final shownElevation = elevationRows.where((c) => match(c.$1)).toList();
    final shownType = typeRows.where((c) => match(c.$1)).toList();
    final total =
        shownColors.length +
        shownPalette.length +
        shownSpacing.length +
        shownRadii.length +
        shownIcons.length +
        shownElevation.length +
        shownType.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: DebugSearchField(
            controller: _searchCtrl,
            hintText: 'Filter tokens',
            onChanged: (v) => setState(() => _query = v),
            resultCount: q.isEmpty ? null : total,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: _MetaStrip(
            brightness: theme.brightness,
            windowSize: tokens?.windowSize.name,
            typeFactor: tokens?.typography.factor,
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
            children: [
              if (shownColors.isNotEmpty)
                _Section(
                  title: 'ColorScheme',
                  icon: Icons.palette_rounded,
                  count: shownColors.length,
                  child: _Group(
                    children: [
                      for (final r in shownColors)
                        _ColorRow(label: r.$1, color: r.$2),
                    ],
                  ),
                ),
              if (shownPalette.isNotEmpty)
                _Section(
                  title: 'AppPalette',
                  icon: Icons.format_paint_rounded,
                  count: shownPalette.length,
                  child: _Group(
                    children: [
                      for (final r in shownPalette)
                        _ColorRow(label: r.$1, color: r.$2),
                    ],
                  ),
                ),
              if (shownSpacing.isNotEmpty)
                _Section(
                  title: 'Spacing',
                  icon: Icons.space_bar_rounded,
                  count: shownSpacing.length,
                  child: _Group(
                    children: [
                      for (final r in shownSpacing)
                        _ValueRow(
                          label: r.$1,
                          value: r.$2,
                          preview: _SpacingBar(value: r.$2),
                        ),
                    ],
                  ),
                ),
              if (shownRadii.isNotEmpty)
                _Section(
                  title: 'Radii',
                  icon: Icons.rounded_corner_rounded,
                  count: shownRadii.length,
                  child: _Group(
                    children: [
                      for (final r in shownRadii)
                        _ValueRow(
                          label: r.$1,
                          value: r.$2,
                          preview: _RadiusBox(value: r.$2),
                        ),
                    ],
                  ),
                ),
              if (shownIcons.isNotEmpty)
                _Section(
                  title: 'Icon sizes',
                  icon: Icons.emoji_symbols_rounded,
                  count: shownIcons.length,
                  child: _Group(
                    children: [
                      for (final r in shownIcons)
                        _ValueRow(
                          label: r.$1,
                          value: r.$2,
                          preview: Icon(
                            Icons.star_rounded,
                            size: r.$2.clamp(8, 24),
                            color: DebugOverlayTheme.accentDefault,
                          ),
                        ),
                    ],
                  ),
                ),
              if (shownElevation.isNotEmpty)
                _Section(
                  title: 'Elevation',
                  icon: Icons.layers_rounded,
                  count: shownElevation.length,
                  child: _Group(
                    children: [
                      for (final r in shownElevation)
                        _ValueRow(
                          label: r.$1,
                          value: r.$2,
                          preview: _ElevationBox(value: r.$2),
                        ),
                    ],
                  ),
                ),
              if (shownType.isNotEmpty)
                _Section(
                  title: 'Type scale',
                  icon: Icons.text_fields_rounded,
                  count: shownType.length,
                  child: _Group(
                    children: [
                      for (final r in shownType)
                        _TypeRow(label: r.$1, style: r.$2),
                    ],
                  ),
                ),
              if (total == 0)
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Center(
                    child: Text(
                      'No tokens match "$_query"',
                      style: DebugOverlayTheme.ui.copyWith(
                        fontSize: 11,
                        color: DebugOverlayTheme.textDim,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────

/// Which resolved theme these values came from.
class _MetaStrip extends StatelessWidget {
  const _MetaStrip({
    required this.brightness,
    required this.windowSize,
    required this.typeFactor,
  });

  final Brightness brightness;
  final String? windowSize;
  final double? typeFactor;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      brightness == Brightness.dark ? 'dark' : 'light',
      if (windowSize != null) windowSize!,
      if (typeFactor != null) 'type ×$typeFactor',
    ];
    return Row(
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: 12,
          color: DebugOverlayTheme.textDimmer,
        ),
        const SizedBox(width: 6),
        Text(
          'Resolved for: ${parts.join(' · ')}',
          style: DebugOverlayTheme.mono.copyWith(
            fontSize: 10,
            color: DebugOverlayTheme.textDimmer,
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.count,
    required this.child,
  });

  final String title;
  final IconData icon;
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: DebugOverlayTheme.textDim),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: DebugOverlayTheme.ui.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: DebugOverlayTheme.textDim,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: DebugOverlayTheme.mono.copyWith(
                  fontSize: 10,
                  color: DebugOverlayTheme.textDimmer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DebugOverlayTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DebugOverlayTheme.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Container(
                height: 1,
                color: DebugOverlayTheme.border.withValues(alpha: 0.5),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hex = _toHex(color);
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: hex));
        GlobalToast.info('$hex copied');
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        child: Row(
          children: [
            // Checkerboard under the swatch so translucent roles
            // (overlay.*) read as translucent instead of vanishing
            // into the surface.
            SizedBox(
              width: 22,
              height: 22,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: DebugOverlayTheme.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CustomPaint(
                    painter: color.a < 1.0 ? _CheckerPainter() : null,
                    child: ColoredBox(color: color),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: DebugOverlayTheme.mono.copyWith(fontSize: 11),
              ),
            ),
            Text(
              hex,
              style: DebugOverlayTheme.mono.copyWith(
                fontSize: 10.5,
                color: DebugOverlayTheme.textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _toHex(Color c) {
    final r = (c.r * 255).round() & 0xFF;
    final g = (c.g * 255).round() & 0xFF;
    final b = (c.b * 255).round() & 0xFF;
    final a = (c.a * 255).round() & 0xFF;
    String hh(int v) => v.toRadixString(16).padLeft(2, '0').toUpperCase();
    return a == 255
        ? '#${hh(r)}${hh(g)}${hh(b)}'
        : '#${hh(a)}${hh(r)}${hh(g)}${hh(b)}';
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    required this.value,
    required this.preview,
  });

  final String label;
  final double value;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    final text = value == value.roundToDouble() ? '${value.round()}' : '$value';
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: 'context.$label'));
        GlobalToast.info('context.$label copied');
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        child: Row(
          children: [
            SizedBox(
              width: 150,
              child: Text(
                label,
                style: DebugOverlayTheme.mono.copyWith(
                  fontSize: 11,
                  color: DebugOverlayTheme.textDim,
                ),
              ),
            ),
            SizedBox(
              width: 34,
              child: Text(
                text,
                style: DebugOverlayTheme.mono.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: preview,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({required this.label, required this.style});

  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final size = style?.fontSize;
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: 'context.textTheme.$label'));
        GlobalToast.info('context.textTheme.$label copied');
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        child: Row(
          children: [
            SizedBox(
              width: 150,
              child: Text(
                label,
                style: DebugOverlayTheme.mono.copyWith(
                  fontSize: 11,
                  color: DebugOverlayTheme.textDim,
                ),
              ),
            ),
            SizedBox(
              width: 34,
              child: Text(
                size == null ? '—' : '${size.round()}',
                style: DebugOverlayTheme.mono.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Real app font at real weight; size clamped so display
            // styles don't blow the row height.
            Expanded(
              child: Text(
                'Ag',
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: style?.copyWith(
                  fontSize: (size ?? 14).clamp(8, 24),
                  color: DebugOverlayTheme.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Mini previews ───────────────────────────────────────────

class _SpacingBar extends StatelessWidget {
  const _SpacingBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: value.clamp(1, 96),
      height: 8,
      decoration: BoxDecoration(
        color: DebugOverlayTheme.accent.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _RadiusBox extends StatelessWidget {
  const _RadiusBox({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: DebugOverlayTheme.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(value.clamp(0, 11)),
        border: Border.all(
          color: DebugOverlayTheme.accent.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _ElevationBox extends StatelessWidget {
  const _ElevationBox({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: DebugOverlayTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: DebugOverlayTheme.border),
        boxShadow: value <= 0
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: value * 2,
                  offset: Offset(0, value / 2),
                ),
              ],
      ),
    );
  }
}

/// 2×2 light/dark checker behind translucent swatches.
class _CheckerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final light = Paint()..color = const Color(0xFF9E9E9E);
    final dark = Paint()..color = const Color(0xFF616161);
    final half = size.width / 2;
    canvas.drawRect(Rect.fromLTWH(0, 0, half, half), light);
    canvas.drawRect(Rect.fromLTWH(half, 0, half, half), dark);
    canvas.drawRect(Rect.fromLTWH(0, half, half, half), dark);
    canvas.drawRect(Rect.fromLTWH(half, half, half, half), light);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
