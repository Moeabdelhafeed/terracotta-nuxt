import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/enums/app/app_role.dart';
import '../../../../core/constants/enums/app/color_saturation.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../data/blocs/preferences/preferences_cubit.dart';
import '../../../../data/blocs/preferences/preferences_state.dart';
import '../../../../data/models/common/language/language.dart';
import '../../../../data/services/languages_service.dart';
import '../../buttons/global_icon_button.dart';
import '../debug_overlay_models.dart';

/// Quick switch for the most-touched [PreferencesCubit] fields — theme /
/// role / saturation / font / language — plus a LIVE preview of the
/// app's resolved theme (the overlay floats above the app, so
/// `Theme.of` here IS the app theme and repaints on every flip).
class DebugThemeQuickView extends StatelessWidget {
  const DebugThemeQuickView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreferencesCubit, PreferencesState>(
      builder: (context, state) {
        final cubit = context.read<PreferencesCubit>();
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 24),
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 28),
                  foregroundColor: DebugOverlayTheme.textDim,
                ),
                onPressed: () {
                  cubit
                    ..resetDisplayPreferences()
                    ..setAppRole(AppRole.user)
                    ..setLanguage(defaultLanguage);
                },
                icon: const Icon(Icons.restart_alt_rounded, size: 13),
                label: Text(
                  'Reset all',
                  style: DebugOverlayTheme.ui.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            _FlatSection(
              title: 'Theme mode',
              icon: Icons.brightness_6_rounded,
              child: _Segmented<ThemeMode>(
                values: ThemeMode.values,
                current: state.themeMode,
                labelOf: (m) => switch (m) {
                  ThemeMode.system => 'System',
                  ThemeMode.light => 'Light',
                  ThemeMode.dark => 'Dark',
                },
                iconOf: (m) => switch (m) {
                  ThemeMode.system => Icons.brightness_auto_rounded,
                  ThemeMode.light => Icons.light_mode_rounded,
                  ThemeMode.dark => Icons.dark_mode_rounded,
                },
                onSelect: cubit.setThemeMode,
              ),
            ),
            _FlatSection(
              title: 'App role',
              icon: Icons.badge_outlined,
              child: _ChipRow<AppRole>(
                values: AppRole.values,
                current: state.appRole,
                labelOf: (r) => r.label,
                onSelect: cubit.setAppRole,
              ),
            ),
            _FlatSection(
              title: 'Color saturation',
              icon: Icons.color_lens_outlined,
              child: _ChipRow<ColorSaturation>(
                values: ColorSaturation.values,
                current: state.colorSaturation,
                labelOf: (s) => s.label,
                onSelect: cubit.setColorSaturation,
              ),
            ),
            _FlatSection(
              title: 'Font scale',
              icon: Icons.format_size_rounded,
              child: _FontScaleControl(
                value: state.fontScale,
                onChange: cubit.setFontScale,
                onReset: cubit.resetFontScale,
              ),
            ),
            _FlatSection(
              title: 'Language',
              icon: Icons.language_rounded,
              child: _LanguagePicker(
                current: state.language,
                onSelect: cubit.setLanguage,
              ),
            ),
            const _FlatSection(
              title: 'Live preview — resolved app theme',
              icon: Icons.visibility_rounded,
              child: _ThemePreview(),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────

/// Uncarded section: icon + title header, content, hairline divider —
/// matches the flattened permissions/assets/L10n pages.
class _FlatSection extends StatelessWidget {
  const _FlatSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
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
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

/// Equal-width segmented control — for FIXED small option sets (theme
/// mode). Variable sets (roles, languages) stay chips.
class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.values,
    required this.current,
    required this.labelOf,
    required this.onSelect,
    this.iconOf,
  });

  final List<T> values;
  final T current;
  final String Function(T) labelOf;
  final IconData Function(T)? iconOf;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    final accent = DebugOverlayTheme.accent;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: DebugOverlayTheme.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DebugOverlayTheme.border),
      ),
      child: Row(
        children: [
          for (final v in values)
            Expanded(
              child: Material(
                color: v == current
                    ? accent.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  onTap: () => onSelect(v),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 30,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (iconOf != null) ...[
                          Icon(
                            iconOf!(v),
                            size: 12,
                            color: v == current
                                ? accent
                                : DebugOverlayTheme.textDim,
                          ),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          labelOf(v),
                          style: DebugOverlayTheme.ui.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: v == current
                                ? accent
                                : DebugOverlayTheme.textDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _ChipRow<T> extends StatelessWidget {
  const _ChipRow({
    required this.values,
    required this.current,
    required this.labelOf,
    required this.onSelect,
  });

  final List<T> values;
  final T current;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in values)
          _Chip(
            label: labelOf(v),
            selected: v == current,
            onTap: () => onSelect(v),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final accent = DebugOverlayTheme.accent;
    return Material(
      color: selected ? accent.withValues(alpha: 0.18) : DebugOverlayTheme.bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.6)
                  : DebugOverlayTheme.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 6)],
              Text(
                label,
                style: DebugOverlayTheme.mono.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? accent : DebugOverlayTheme.textDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _FontScaleControl extends StatelessWidget {
  const _FontScaleControl({
    required this.value,
    required this.onChange,
    required this.onReset,
  });

  final double value;
  final ValueChanged<double> onChange;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final accent = DebugOverlayTheme.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 7,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                ),
                child: Slider(
                  value: value.clamp(0.8, 1.4),
                  min: 0.8,
                  max: 1.4,
                  divisions: 12,
                  activeColor: accent,
                  inactiveColor: DebugOverlayTheme.border,
                  onChanged: onChange,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: accent.withValues(alpha: 0.4)),
              ),
              child: Text(
                '×${value.toStringAsFixed(2)}',
                style: DebugOverlayTheme.mono.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
            GlobalIconButton(
              enforceMinTouchTarget: false,
              tooltip: 'Reset to 1.00',
              onPressed: onReset,
              iconData: Icons.refresh_rounded,
              iconSize: 14,
              style: const ButtonStateStyle(
                width: 28,
                height: 28,
                foregroundColor: DebugOverlayTheme.textDim,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final t in const ['0.8×', '1.0×', '1.4×'])
                Text(
                  t,
                  style: DebugOverlayTheme.mono.copyWith(
                    fontSize: 9,
                    color: DebugOverlayTheme.textDimmer,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Live sample at the chosen scale (explicit multiply — the
        // overlay's own chrome intentionally ignores the app scale).
        Text(
          'The quick brown fox — نص تجريبي ١٢٣',
          style: DebugOverlayTheme.ui.copyWith(
            fontSize: 13 * value,
            color: DebugOverlayTheme.text,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({required this.current, required this.onSelect});

  final Language current;
  final ValueChanged<Language> onSelect;

  @override
  Widget build(BuildContext context) {
    final svc = getIt.isRegistered<LanguagesService>()
        ? getIt<LanguagesService>()
        : null;
    final languages = svc?.languages ?? const <Language>[];
    if (languages.isEmpty) {
      return Text(
        '<LanguagesService not registered>',
        style: DebugOverlayTheme.ui.copyWith(
          color: DebugOverlayTheme.textDimmer,
          fontSize: 11,
        ),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final lang in languages)
          _Chip(
            // Flag emoji render as tofu in the overlay's mono font —
            // a locale-code badge is glyph-safe everywhere.
            leading: _LocaleBadge(
              code: lang.locale.toUpperCase(),
              selected: lang.locale == current.locale,
            ),
            label: lang.name ?? lang.locale,
            selected: lang.locale == current.locale,
            onTap: () => onSelect(lang),
          ),
      ],
    );
  }
}

class _LocaleBadge extends StatelessWidget {
  const _LocaleBadge({required this.code, required this.selected});

  final String code;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = selected
        ? DebugOverlayTheme.accent
        : DebugOverlayTheme.textDimmer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.withValues(alpha: 0.6)),
      ),
      child: Text(
        code,
        style: DebugOverlayTheme.mono.copyWith(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: c,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

/// The payoff panel: renders swatches + sample components with the
/// APP's ambient theme (the overlay sits inside the app's MaterialApp,
/// so `Theme.of(context)` here resolves the exact theme the knobs
/// above produce — every flip repaints this instantly).
class _ThemePreview extends StatelessWidget {
  const _ThemePreview();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final swatches = <(String, Color, Color)>[
      ('primary', cs.primary, cs.onPrimary),
      ('secondary', cs.secondary, cs.onSecondary),
      ('tertiary', cs.tertiary, cs.onTertiary),
      ('surface', cs.surface, cs.onSurface),
      ('error', cs.error, cs.onError),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final (name, bg, fg) in swatches) ...[
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: DebugOverlayTheme.border),
                      ),
                      child: Text(
                        'Aa',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: fg,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: DebugOverlayTheme.mono.copyWith(
                        fontSize: 8,
                        color: DebugOverlayTheme.textDimmer,
                      ),
                    ),
                  ],
                ),
              ),
              if (name != 'error') const SizedBox(width: 5),
            ],
          ],
        ),
        const SizedBox(height: 10),
        // Mini "app surface" card — real Material widgets picking up the
        // ambient app theme.
        Material(
          color: cs.surface,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Title — resolved textTheme', style: tt.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'Body text at the active font scale and palette.',
                  style: tt.bodySmall,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    FilledButton(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      onPressed: () {},
                      child: const Text('Primary'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      onPressed: () {},
                      child: const Text('Outline'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
