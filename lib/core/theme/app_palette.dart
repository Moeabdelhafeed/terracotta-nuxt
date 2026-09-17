import 'package:flutter/material.dart';

import '../constants/colors/background_colors.dart';
import '../constants/colors/buttons_colors.dart';
import '../constants/colors/icon_colors.dart';
import '../constants/colors/overlay_colors.dart';
import '../constants/colors/primary_colors.dart';
import '../constants/colors/shimmer_colors.dart';
import '../constants/colors/status_colors.dart';
import '../constants/colors/text_colors.dart';
import '../constants/enums/app/app_role.dart';
import '../extensions/color_extensions.dart';

/// `ThemeExtension` bundle of every role-aware color class — built once
/// per theme and registered into `ThemeData.extensions`. Saturation is
/// applied here so that:
///
///   - `Theme.of(c).colorScheme.X` (Material widgets read this)
///   - `context.primaryColors.X` / `context.textColors.X` etc. (custom code)
///
/// resolve to the *same* color, regardless of which path the caller
/// takes. Lerps automatically when the theme animates between
/// light/dark, role, or saturation values.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.primary,
    required this.background,
    required this.text,
    required this.buttons,
    required this.status,
    required this.icon,
    required this.shimmer,
    required this.overlay,
  });

  final PrimaryColors primary;
  final BackgroundColors background;
  final TextColors text;
  final ButtonsColors buttons;
  final StatusColors status;
  final IconColors icon;
  final ShimmerColors shimmer;
  final OverlayColors overlay;

  /// Build the palette for `(appRole, isDark, saturation)`. Applies the
  /// saturation multiplier across every adjustable color (skipping
  /// neutral / `onX` colors that should remain pure black/white, and
  /// the `overlay` bucket which holds barriers/scrims).
  factory AppPalette.build({
    required AppRole appRole,
    required bool isDark,
    required double saturation,
  }) {
    final p = PrimaryColors.getColors(appRole: appRole, isDark: isDark);
    final bg = BackgroundColors.getColors(appRole: appRole, isDark: isDark);
    final t = TextColors.getColors(appRole: appRole, isDark: isDark);
    final btn = ButtonsColors.getColors(appRole: appRole, isDark: isDark);
    final s = StatusColors.getColors(appRole: appRole, isDark: isDark);
    final i = IconColors.getColors(appRole: appRole, isDark: isDark);
    final sh = ShimmerColors.getColors(appRole: appRole, isDark: isDark);
    final o = OverlayColors.getColors(appRole: appRole, isDark: isDark);

    if (saturation == 1.0) {
      return AppPalette(
        primary: p,
        background: bg,
        text: t,
        buttons: btn,
        status: s,
        icon: i,
        shimmer: sh,
        overlay: o,
      );
    }

    return AppPalette(
      primary: PrimaryColors(
        primary: p.primary.scaleSaturation(saturation),
        secondary: p.secondary.scaleSaturation(saturation),
        accent: p.accent.scaleSaturation(saturation),
        primaryHighContrast: p.primaryHighContrast.scaleSaturation(saturation),
        border: p.border.scaleSaturation(saturation),
      ),
      background: BackgroundColors(
        background: bg.background.scaleSaturation(saturation),
        surface: bg.surface.scaleSaturation(saturation),
        scaffoldBackground: bg.scaffoldBackground.scaleSaturation(saturation),
        container: bg.container.scaleSaturation(saturation),
        cardBackground: bg.cardBackground.scaleSaturation(saturation),
        inputBackground: bg.inputBackground.scaleSaturation(saturation),
        outline: bg.outline.scaleSaturation(saturation),
        outlineVariant: bg.outlineVariant.scaleSaturation(saturation),
      ),
      text: TextColors(
        primary: t.primary.scaleSaturation(saturation),
        secondary: t.secondary.scaleSaturation(saturation),
        disabled: t.disabled.scaleSaturation(saturation),
        onPrimary: t.onPrimary,
        onAccent: t.onAccent,
        link: t.link.scaleSaturation(saturation),
        primaryHighContrast: t.primaryHighContrast.scaleSaturation(saturation),
      ),
      buttons: ButtonsColors(
        primary: btn.primary.scaleSaturation(saturation),
        secondary: btn.secondary.scaleSaturation(saturation),
        disabled: btn.disabled.scaleSaturation(saturation),
        outline: btn.outline.scaleSaturation(saturation),
      ),
      status: StatusColors(
        success: s.success.scaleSaturation(saturation),
        warning: s.warning.scaleSaturation(saturation),
        error: s.error.scaleSaturation(saturation),
        info: s.info.scaleSaturation(saturation),
      ),
      icon: IconColors(
        primary: i.primary.scaleSaturation(saturation),
        secondary: i.secondary.scaleSaturation(saturation),
        onPrimary: i.onPrimary,
      ),
      shimmer: ShimmerColors(
        baseColor: sh.baseColor.scaleSaturation(saturation),
        highlight: sh.highlight.scaleSaturation(saturation),
        containerBackground: sh.containerBackground.scaleSaturation(saturation),
      ),
      overlay: o,
    );
  }

  @override
  AppPalette copyWith({
    PrimaryColors? primary,
    BackgroundColors? background,
    TextColors? text,
    ButtonsColors? buttons,
    StatusColors? status,
    IconColors? icon,
    ShimmerColors? shimmer,
    OverlayColors? overlay,
  }) {
    return AppPalette(
      primary: primary ?? this.primary,
      background: background ?? this.background,
      text: text ?? this.text,
      buttons: buttons ?? this.buttons,
      status: status ?? this.status,
      icon: icon ?? this.icon,
      shimmer: shimmer ?? this.shimmer,
      overlay: overlay ?? this.overlay,
    );
  }

  /// Field-by-field [Color.lerp] for smooth palette transitions during
  /// theme switches.
  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return AppPalette(
      primary: PrimaryColors(
        primary: l(primary.primary, other.primary.primary),
        secondary: l(primary.secondary, other.primary.secondary),
        accent: l(primary.accent, other.primary.accent),
        primaryHighContrast: l(
          primary.primaryHighContrast,
          other.primary.primaryHighContrast,
        ),
        border: l(primary.border, other.primary.border),
      ),
      background: BackgroundColors(
        background: l(background.background, other.background.background),
        surface: l(background.surface, other.background.surface),
        scaffoldBackground: l(
          background.scaffoldBackground,
          other.background.scaffoldBackground,
        ),
        container: l(background.container, other.background.container),
        cardBackground: l(
          background.cardBackground,
          other.background.cardBackground,
        ),
        inputBackground: l(
          background.inputBackground,
          other.background.inputBackground,
        ),
        outline: l(background.outline, other.background.outline),
        outlineVariant: l(
          background.outlineVariant,
          other.background.outlineVariant,
        ),
      ),
      text: TextColors(
        primary: l(text.primary, other.text.primary),
        secondary: l(text.secondary, other.text.secondary),
        disabled: l(text.disabled, other.text.disabled),
        onPrimary: l(text.onPrimary, other.text.onPrimary),
        onAccent: l(text.onAccent, other.text.onAccent),
        link: l(text.link, other.text.link),
        primaryHighContrast: l(
          text.primaryHighContrast,
          other.text.primaryHighContrast,
        ),
      ),
      buttons: ButtonsColors(
        primary: l(buttons.primary, other.buttons.primary),
        secondary: l(buttons.secondary, other.buttons.secondary),
        disabled: l(buttons.disabled, other.buttons.disabled),
        outline: l(buttons.outline, other.buttons.outline),
      ),
      status: StatusColors(
        success: l(status.success, other.status.success),
        warning: l(status.warning, other.status.warning),
        error: l(status.error, other.status.error),
        info: l(status.info, other.status.info),
      ),
      icon: IconColors(
        primary: l(icon.primary, other.icon.primary),
        secondary: l(icon.secondary, other.icon.secondary),
        onPrimary: l(icon.onPrimary, other.icon.onPrimary),
      ),
      shimmer: ShimmerColors(
        baseColor: l(shimmer.baseColor, other.shimmer.baseColor),
        highlight: l(shimmer.highlight, other.shimmer.highlight),
        containerBackground: l(
          shimmer.containerBackground,
          other.shimmer.containerBackground,
        ),
      ),
      overlay: OverlayColors(
        barrier: l(overlay.barrier, other.overlay.barrier),
        scrim: l(overlay.scrim, other.overlay.scrim),
        modalBackground: l(
          overlay.modalBackground,
          other.overlay.modalBackground,
        ),
      ),
    );
  }
}
