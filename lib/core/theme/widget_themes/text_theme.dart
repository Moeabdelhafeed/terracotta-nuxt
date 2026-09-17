import 'package:flutter/material.dart';

import '../../constants/colors/text_colors.dart';
import '../../constants/fonts.dart';
import '../../constants/sizes/app_sizes.dart';
import '../../tokens/app_typography_scale.dart';

class MyTextTheme {
  MyTextTheme._();

  static TextTheme build({
    required TextColors text,
    required AppTypographyScale scale,
  }) {
    double s(double base) => scale.scale(base);
    // Font selection is by SCRIPT, not by locale: the Latin face takes
    // the primary slot and every other script's face is a fallback, so
    // Flutter picks the right one PER GLYPH. That is what stops English
    // words rendering in the Arabic face while the app is in Arabic —
    // and it works inside a single mixed string.
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: s(AppSizes.fontDisplayLg),
        fontWeight: FontWeight.bold,
        color: text.primary,
        fontFamily: AppFonts.scriptPrimaryFamily(TextType.display),
        fontFamilyFallback: AppFonts.scriptFallbackFamilies(TextType.display),
        letterSpacing: AppSizes.letterSpacingTight,
        height: AppSizes.lineHeightTight,
      ),
      displayMedium: TextStyle(
        fontSize: s(AppSizes.fontDisplayMd),
        fontWeight: FontWeight.bold,
        color: text.primary,
        fontFamily: AppFonts.scriptPrimaryFamily(TextType.display),
        fontFamilyFallback: AppFonts.scriptFallbackFamilies(TextType.display),
        letterSpacing: AppSizes.letterSpacingDense,
        height: AppSizes.lineHeightDense,
      ),
      displaySmall: TextStyle(
        fontSize: s(AppSizes.fontDisplaySm),
        fontWeight: FontWeight.bold,
        color: text.primary,
        fontFamily: AppFonts.scriptPrimaryFamily(TextType.display),
        fontFamilyFallback: AppFonts.scriptFallbackFamilies(TextType.display),
        height: AppSizes.lineHeightCompact,
      ),
      headlineLarge: TextStyle(
        fontSize: s(AppSizes.fontHeadlineLg),
        fontWeight: FontWeight.bold,
        color: text.primary,
        fontFamily: AppFonts.scriptPrimaryFamily(TextType.headline),
        fontFamilyFallback: AppFonts.scriptFallbackFamilies(TextType.headline),
        height: AppSizes.lineHeightCompact,
      ),
      headlineMedium: TextStyle(
        fontSize: s(AppSizes.fontHeadlineMd),
        fontWeight: FontWeight.w600,
        color: text.primary,
        fontFamily: AppFonts.scriptPrimaryFamily(TextType.headline),
        fontFamilyFallback: AppFonts.scriptFallbackFamilies(TextType.headline),
        height: AppSizes.lineHeightNormal,
      ),
      headlineSmall: TextStyle(
        fontSize: s(AppSizes.fontHeadlineSm),
        fontWeight: FontWeight.w600,
        color: text.primary,
        fontFamily: AppFonts.scriptPrimaryFamily(TextType.headline),
        fontFamilyFallback: AppFonts.scriptFallbackFamilies(TextType.headline),
        letterSpacing: AppSizes.letterSpacingSm,
        height: AppSizes.lineHeightMd,
      ),
      titleLarge: TextStyle(
        fontSize: s(AppSizes.fontTitleLg),
        fontWeight: FontWeight.w600,
        color: text.primary,
        fontFamily: AppFonts.scriptPrimaryFamily(TextType.title),
        fontFamilyFallback: AppFonts.scriptFallbackFamilies(TextType.title),
        letterSpacing: AppSizes.letterSpacingMd,
        height: AppSizes.lineHeightMd,
      ),
      titleMedium: TextStyle(
        fontSize: s(AppSizes.fontTitleMd),
        fontWeight: FontWeight.w500,
        color: text.primary,
        fontFamily: AppFonts.scriptPrimaryFamily(TextType.title),
        fontFamilyFallback: AppFonts.scriptFallbackFamilies(TextType.title),
        letterSpacing: AppSizes.letterSpacingMd,
        height: AppSizes.lineHeightMd,
      ),
      titleSmall: TextStyle(
        fontSize: s(AppSizes.fontTitleSm),
        fontWeight: FontWeight.w500,
        color: text.secondary,
        fontFamily: AppFonts.scriptPrimaryFamily(TextType.title),
        fontFamilyFallback: AppFonts.scriptFallbackFamilies(TextType.title),
        letterSpacing: AppSizes.letterSpacingSm,
        height: AppSizes.lineHeightRelaxed,
      ),
      bodyLarge: TextStyle(
        fontSize: s(AppSizes.fontBodyLg),
        fontWeight: FontWeight.normal,
        color: text.primary,
        fontFamily: AppFonts.scriptPrimaryFamily(TextType.body),
        fontFamilyFallback: AppFonts.scriptFallbackFamilies(TextType.body),
        letterSpacing: AppSizes.letterSpacingWide,
        height: AppSizes.lineHeightLoose,
      ),
      bodyMedium: TextStyle(
        fontSize: s(AppSizes.fontBodyMd),
        fontWeight: FontWeight.normal,
        color: text.primary,
        fontFamily: AppFonts.scriptPrimaryFamily(TextType.body),
        fontFamilyFallback: AppFonts.scriptFallbackFamilies(TextType.body),
        letterSpacing: AppSizes.letterSpacingLg,
        height: AppSizes.lineHeightLoose,
      ),
      bodySmall: TextStyle(
        fontSize: s(AppSizes.fontBodySm),
        fontWeight: FontWeight.normal,
        color: text.secondary,
        fontFamily: AppFonts.scriptPrimaryFamily(TextType.body),
        fontFamilyFallback: AppFonts.scriptFallbackFamilies(TextType.body),
        letterSpacing: AppSizes.letterSpacingXl,
        height: AppSizes.lineHeightRelaxed,
      ),
      labelLarge: TextStyle(
        fontSize: s(AppSizes.fontLabelLg),
        fontWeight: FontWeight.w600,
        color: text.primary,
        fontFamily: AppFonts.scriptPrimaryFamily(TextType.label),
        fontFamilyFallback: AppFonts.scriptFallbackFamilies(TextType.label),
        letterSpacing: AppSizes.letterSpacingXWide,
        height: AppSizes.lineHeightCompact,
      ),
      labelMedium: TextStyle(
        fontSize: s(AppSizes.fontLabelMd),
        fontWeight: FontWeight.w500,
        color: text.secondary,
        fontFamily: AppFonts.scriptPrimaryFamily(TextType.label),
        fontFamilyFallback: AppFonts.scriptFallbackFamilies(TextType.label),
        letterSpacing: AppSizes.letterSpacingWide,
        height: AppSizes.lineHeightMd,
      ),
      labelSmall: TextStyle(
        fontSize: s(AppSizes.fontLabelSm),
        fontWeight: FontWeight.w500,
        color: text.secondary,
        fontFamily: AppFonts.scriptPrimaryFamily(TextType.label),
        fontFamilyFallback: AppFonts.scriptFallbackFamilies(TextType.label),
        letterSpacing: AppSizes.letterSpacingXxWide,
        height: AppSizes.lineHeightCompact,
      ),
    );
  }
}
