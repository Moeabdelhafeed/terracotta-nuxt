import 'dart:ui';

import 'package:flutter/material.dart';

import '../constants/enums/app/app_role.dart';
import '../constants/enums/app/color_saturation.dart';
import '../constants/fonts.dart';
import '../constants/sizes/app_sizes.dart';
import '../responsive/window_size_class.dart';
import '../tokens/app_tokens.dart';
import '../tokens/app_typography_scale.dart';
import 'app_palette.dart';
import 'widget_themes/appbar_theme.dart';
import 'widget_themes/banner_theme.dart';
import 'widget_themes/bottom_sheet_theme.dart';
import 'widget_themes/card_theme.dart';
import 'widget_themes/checkbox_theme.dart';
import 'widget_themes/chip_theme.dart';
import 'widget_themes/date_picker_theme.dart';
import 'widget_themes/dialog_theme.dart';
import 'widget_themes/divider_theme.dart';
import 'widget_themes/drawer_theme.dart';
import 'widget_themes/elevated_button_theme.dart';
import 'widget_themes/expansion_tile_theme.dart';
import 'widget_themes/fab_theme.dart';
import 'widget_themes/filled_button_theme.dart';
import 'widget_themes/global_animation_theme.dart';
import 'widget_themes/global_app_bar_theme.dart';
import 'widget_themes/global_audio_theme.dart';
import 'widget_themes/global_auto_scroller_theme.dart';
import 'widget_themes/global_avatar_theme.dart';
import 'widget_themes/global_badge_theme.dart';
import 'widget_themes/global_banner_theme.dart';
import 'widget_themes/global_bottom_nav_theme.dart';
import 'widget_themes/global_breadcrumbs_theme.dart';
import 'widget_themes/global_buttons_theme.dart';
import 'widget_themes/global_checkbox_theme.dart';
import 'widget_themes/global_chip_theme.dart';
import 'widget_themes/global_collection_theme.dart';
import 'widget_themes/global_container_theme.dart';
import 'widget_themes/global_date_time_picker_theme.dart';
import 'widget_themes/global_dialog_theme.dart';
import 'widget_themes/global_divider_theme.dart';
import 'widget_themes/global_drawer_theme.dart';
import 'widget_themes/global_drop_down_theme.dart';
import 'widget_themes/global_empty_state_theme.dart';
import 'widget_themes/global_feedback_theme.dart';
import 'widget_themes/global_icon_theme.dart';
import 'widget_themes/global_image_theme.dart';
import 'widget_themes/global_in_page_hero_theme.dart';
import 'widget_themes/global_indicator_theme.dart';
import 'widget_themes/global_legal_theme.dart';
import 'widget_themes/global_loading_theme.dart';
import 'widget_themes/global_markdown_theme.dart';
import 'widget_themes/global_marquee_theme.dart';
import 'widget_themes/global_media_picker_theme.dart';
import 'widget_themes/global_nav_animation_theme.dart';
import 'widget_themes/global_page_view_theme.dart';
import 'widget_themes/global_pdf_theme.dart';
import 'widget_themes/global_picker_theme.dart';
import 'widget_themes/global_popup_theme.dart';
import 'widget_themes/global_progress_theme.dart';
import 'widget_themes/global_radio_theme.dart';
import 'widget_themes/global_rating_theme.dart';
import 'widget_themes/global_refreshable_theme.dart';
import 'widget_themes/global_scanner_theme.dart';
import 'widget_themes/global_scrollable_theme.dart';
import 'widget_themes/global_segmented_control_theme.dart';
import 'widget_themes/global_share_theme.dart';
import 'widget_themes/global_sheet_theme.dart';
import 'widget_themes/global_skeleton_theme.dart';
import 'widget_themes/global_slider_theme.dart';
import 'widget_themes/global_stack_theme.dart';
import 'widget_themes/global_stepper_theme.dart';
import 'widget_themes/global_switch_theme.dart';
import 'widget_themes/global_tab_bar_theme.dart';
import 'widget_themes/global_text_field_theme.dart';
import 'widget_themes/global_text_theme.dart';
import 'widget_themes/global_toast_theme.dart';
import 'widget_themes/global_toggle_group_theme.dart';
import 'widget_themes/global_tooltip_theme.dart';
import 'widget_themes/global_transition_theme.dart';
import 'widget_themes/global_video_theme.dart';
import 'widget_themes/global_visualizer_theme.dart';
import 'widget_themes/icon_button_theme.dart';
import 'widget_themes/icon_theme.dart';
import 'widget_themes/list_tile_theme.dart';
import 'widget_themes/menu_theme.dart';
import 'widget_themes/navigation_bar_theme.dart';
import 'widget_themes/outlined_button_theme.dart';
import 'widget_themes/popup_menu_theme.dart';
import 'widget_themes/progress_indicator_theme.dart';
import 'widget_themes/radio_theme.dart';
import 'widget_themes/search_bar_theme.dart';
import 'widget_themes/segmented_button_theme.dart';
import 'widget_themes/slider_theme.dart';
import 'widget_themes/snackbar_theme.dart';
import 'widget_themes/switch_theme.dart';
import 'widget_themes/tab_bar_theme.dart';
import 'widget_themes/text_button_theme.dart';
import 'widget_themes/text_field_theme.dart';
import 'widget_themes/text_theme.dart';
import 'widget_themes/time_picker_theme.dart';
import 'widget_themes/tooltip_theme.dart';

class AppTheme {
  AppTheme._();

  static ThemeData getTheme({
    required ThemeMode themeMode,
    required AppRole appRole,
    WindowSizeClass windowSize = WindowSizeClass.compact,
    ColorSaturation saturation = ColorSaturation.normal,
    Color? seedColorOverride,
  }) {
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            PlatformDispatcher.instance.platformBrightness == Brightness.dark);

    return _buildTheme(
      isDark: isDark,
      appRole: appRole,
      windowSize: windowSize,
      saturation: saturation,
      seedColorOverride: seedColorOverride,
    );
  }

  static ThemeData _buildTheme({
    required bool isDark,
    required AppRole appRole,
    required WindowSizeClass windowSize,
    required ColorSaturation saturation,
    Color? seedColorOverride,
  }) {
    final palette = AppPalette.build(
      appRole: appRole,
      isDark: isDark,
      saturation: saturation.multiplier,
    );
    final primary = palette.primary;
    final bg = palette.background;
    final text = palette.text;
    final status = palette.status;
    final icon = palette.icon;
    final tokens = AppTokens.forBucket(windowSize);
    final typeScale = AppTypographyScale.forBucket(windowSize);

    return ThemeData(
      extensions: [
        tokens,
        palette,
        MyGlobalPopupTheme.build(bg: bg, text: text, tokens: tokens),
        MyGlobalTextFieldTheme.build(tokens: tokens),
        MyGlobalTooltipTheme.build(tokens: tokens),
        MyGlobalTextTheme.build(tokens: tokens),
        MyGlobalMarqueeTheme.build(tokens: tokens),
        MyGlobalDropdownTheme.build(tokens: tokens),
        MyGlobalBreadcrumbsTheme.build(tokens: tokens),
        MyGlobalVideoTheme.build(tokens: tokens),
        MyGlobalAudioTheme.build(tokens: tokens),
        MyGlobalMediaPickerTheme.build(tokens: tokens),
        MyGlobalDateTimePickerTheme.build(tokens: tokens),
        MyGlobalScannerTheme.build(tokens: tokens),
        MyGlobalVisualizerTheme.build(tokens: tokens),
        MyGlobalContainerTheme.build(tokens: tokens),
        MyGlobalDividerTheme.build(tokens: tokens),
        MyGlobalEmptyStateTheme.build(tokens: tokens),
        MyGlobalDrawerTheme.build(tokens: tokens),
        MyGlobalCheckboxTheme.build(tokens: tokens),
        MyGlobalSwitchTheme.build(tokens: tokens),
        MyGlobalRadioTheme.build(tokens: tokens),
        MyGlobalRatingTheme.build(tokens: tokens),
        MyGlobalToggleGroupTheme.build(tokens: tokens),
        MyGlobalSegmentedControlTheme.build(tokens: tokens),
        MyGlobalSheetTheme.build(tokens: tokens),
        MyGlobalDialogTheme.build(tokens: tokens),
        MyGlobalChipTheme.build(tokens: tokens),
        MyGlobalButtonsTheme.build(tokens: tokens),
        MyGlobalBadgeTheme.build(tokens: tokens),
        MyGlobalRefreshableTheme.build(tokens: tokens),
        MyGlobalPageViewTheme.build(tokens: tokens),
        MyGlobalAutoScrollerTheme.build(tokens: tokens),
        MyGlobalStackTheme.build(tokens: tokens),
        MyGlobalPickerTheme.build(tokens: tokens),
        MyGlobalShareTheme.build(tokens: tokens),
        MyGlobalMarkdownTheme.build(tokens: tokens),
        MyGlobalFeedbackTheme.build(tokens: tokens),
        MyGlobalLegalTheme.build(tokens: tokens),
        MyGlobalLoadingTheme.build(tokens: tokens),
        MyGlobalBannerTheme.build(tokens: tokens),
        MyGlobalAvatarTheme.build(tokens: tokens),
        MyGlobalIconTheme.build(tokens: tokens),
        MyGlobalIndicatorTheme.build(tokens: tokens),
        MyGlobalInPageHeroTheme.build(tokens: tokens),
        MyGlobalImageTheme.build(tokens: tokens),
        MyGlobalSkeletonTheme.build(tokens: tokens),
        MyGlobalSliderTheme.build(tokens: tokens),
        MyGlobalStepperTheme.build(tokens: tokens),
        MyGlobalTransitionTheme.build(tokens: tokens),
        MyGlobalNavAnimationTheme.build(tokens: tokens),
        MyGlobalProgressTheme.build(tokens: tokens),
        MyGlobalPdfTheme.build(tokens: tokens),
        MyGlobalAnimationTheme.build(tokens: tokens),
        MyGlobalBottomNavTheme.build(tokens: tokens),
        MyGlobalAppBarTheme.build(
          tokens: tokens,
          // The warm plate is a LIGHT-mode constant; the dark ramp has
          // no equivalent tint, so the container colour stands in.
          buttonPlate: isDark
              ? bg.container
              : MyGlobalAppBarTheme.lightButtonPlate,
          buttonGlyph: primary.primary,
        ),
        MyGlobalTabBarTheme.build(tokens: tokens),
        MyGlobalCollectionTheme.build(tokens: tokens),
        MyGlobalScrollableTheme.build(tokens: tokens),
        MyGlobalToastTheme.build(tokens: tokens),
      ],
      useMaterial3: true,
      // Material auto-densifies on desktop / web — phones stay standard,
      // mouse-driven platforms get tighter hit-targets.
      visualDensity: VisualDensity.adaptivePlatformDensity,
      // The floor under everything the type scale and the widget themes
      // do not cover. Latin primary + the other scripts as fallbacks, so
      // Flutter picks the face PER GLYPH — see AppFonts.
      fontFamily: AppFonts.scriptPrimaryFamily(),
      fontFamilyFallback: AppFonts.scriptFallbackFamilies(),
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: primary.primary,
      scaffoldBackgroundColor: bg.background,
      disabledColor: text.disabled,

      // ─── Color Scheme ───────────────────────────────────────
      // `seedColorOverride` lets a caller (e.g. the dynamic-color
      // picker reading the OS accent on Android 12+) replace the
      // base seed without losing role + saturation tuning.
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColorOverride ?? primary.primary,
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: primary.primary,
        onPrimary: text.onPrimary,
        primaryContainer: primary.primary.withValues(
          alpha: AppSizes.opacityMuted,
        ),
        onPrimaryContainer: primary.primary,
        secondary: primary.secondary,
        onSecondary: text.onPrimary,
        secondaryContainer: primary.secondary.withValues(
          alpha: AppSizes.opacityMuted,
        ),
        onSecondaryContainer: primary.secondary,
        tertiary: primary.accent,
        onTertiary: text.onAccent,
        tertiaryContainer: primary.accent.withValues(
          alpha: AppSizes.opacityMuted,
        ),
        onTertiaryContainer: primary.accent,
        error: status.error,
        onError: text.onPrimary,
        errorContainer: status.error.withValues(alpha: AppSizes.opacityMuted),
        onErrorContainer: status.error,
        surface: bg.background,
        onSurface: text.primary,
        surfaceContainerHighest: bg.container,
        onSurfaceVariant: text.secondary,
        outline: bg.outline,
        outlineVariant: bg.outlineVariant,
      ),

      // ─── Typography ─────────────────────────────────────────
      textTheme: MyTextTheme.build(text: text, scale: typeScale),

      // ─── App Shell ──────────────────────────────────────────
      appBarTheme: MyAppBarTheme.build(
        bg: bg,
        text: text,
        icon: icon,
        tokens: tokens,
      ),
      navigationBarTheme: MyNavigationBarTheme.build(
        primary: primary,
        bg: bg,
        text: text,
        tokens: tokens,
      ),
      tabBarTheme: MyTabBarTheme.build(primary: primary, bg: bg, text: text),
      drawerTheme: MyDrawerTheme.build(bg: bg, tokens: tokens),

      // ─── Buttons ────────────────────────────────────────────
      elevatedButtonTheme: MyElevatedButtonTheme.build(
        primary: primary,
        text: text,
        tokens: tokens,
      ),
      filledButtonTheme: MyFilledButtonTheme.build(
        primary: primary,
        text: text,
        tokens: tokens,
      ),
      outlinedButtonTheme: MyOutlinedButtonTheme.build(
        primary: primary,
        text: text,
        tokens: tokens,
      ),
      textButtonTheme: MyTextButtonTheme.build(
        primary: primary,
        text: text,
        tokens: tokens,
      ),
      floatingActionButtonTheme: MyFabTheme.build(
        primary: primary,
        text: text,
        tokens: tokens,
      ),
      iconButtonTheme: MyIconButtonTheme.build(
        primary: primary,
        icon: icon,
        text: text,
        tokens: tokens,
      ),
      segmentedButtonTheme: MySegmentedButtonTheme.build(
        primary: primary,
        bg: bg,
        text: text,
        tokens: tokens,
      ),
      iconTheme: MyIconTheme.build(icon: icon, tokens: tokens),

      // ─── Inputs ─────────────────────────────────────────────
      inputDecorationTheme: MyTextFormFieldTheme.build(
        primary: primary,
        bg: bg,
        text: text,
        status: status,
        icon: icon,
      ),
      checkboxTheme: MyCheckboxTheme.build(
        primary: primary,
        text: text,
        bg: bg,
        tokens: tokens,
      ),
      switchTheme: MySwitchTheme.build(primary: primary, bg: bg, text: text),
      radioTheme: MyRadioTheme.build(primary: primary, bg: bg, text: text),
      sliderTheme: MySliderTheme.build(primary: primary, bg: bg, text: text),
      chipTheme: MyChipTheme.build(
        primary: primary,
        bg: bg,
        text: text,
        icon: icon,
        isDark: isDark,
        tokens: tokens,
      ),
      searchBarTheme: MySearchBarTheme.build(
        primary: primary,
        bg: bg,
        text: text,
        tokens: tokens,
      ),

      // ─── Surfaces ───────────────────────────────────────────
      cardTheme: MyCardTheme.build(bg: bg, tokens: tokens),
      bottomSheetTheme: MyBottomSheetTheme.build(
        bg: bg,
        text: text,
        tokens: tokens,
      ),
      dialogTheme: MyDialogTheme.build(bg: bg, text: text),
      popupMenuTheme: MyPopupMenuTheme.build(
        bg: bg,
        text: text,
        tokens: tokens,
      ),
      tooltipTheme: MyTooltipTheme.build(
        text: text,
        isDark: isDark,
        tokens: tokens,
      ),
      listTileTheme: MyListTileTheme.build(
        primary: primary,
        bg: bg,
        text: text,
        icon: icon,
        tokens: tokens,
      ),
      expansionTileTheme: MyExpansionTileTheme.build(
        primary: primary,
        bg: bg,
        text: text,
        icon: icon,
        tokens: tokens,
      ),
      menuTheme: MyMenuTheme.buildMenu(bg: bg, tokens: tokens),
      menuBarTheme: MyMenuTheme.buildBar(bg: bg, tokens: tokens),
      menuButtonTheme: MyMenuTheme.buildButton(
        primary: primary,
        text: text,
        tokens: tokens,
      ),

      // ─── Pickers ────────────────────────────────────────────
      datePickerTheme: MyDatePickerTheme.build(
        primary: primary,
        bg: bg,
        text: text,
        tokens: tokens,
      ),
      timePickerTheme: MyTimePickerTheme.build(
        primary: primary,
        bg: bg,
        text: text,
        tokens: tokens,
      ),

      // ─── Feedback ───────────────────────────────────────────
      snackBarTheme: MySnackBarTheme.build(
        bg: bg,
        text: text,
        isDark: isDark,
        tokens: tokens,
      ),
      bannerTheme: MyBannerTheme.build(bg: bg, text: text, tokens: tokens),
      progressIndicatorTheme: MyProgressIndicatorTheme.build(
        primary: primary,
        bg: bg,
      ),
      dividerTheme: MyDividerTheme.build(bg: bg, tokens: tokens),
    );
  }
}
