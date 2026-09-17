/// Barrel for the pre-built selection-control wrappers — the
/// checkbox/switch counterpart of `text_form_fields/` and
/// `dropdown_fields/`. App-owned, purpose-shaped, localized.
/// Strict 1:1 module mapping via subdirs: `checkbox/` wraps
/// `module/checkbox`, `switch/` wraps `module/switch`, `slider/` wraps
/// `module/slider`.
///
/// Validated (Form-integrated, must-accept):
///  - [ConsentCheckboxField] — Terms / Privacy / both, tappable links.
///  - [AgeConfirmationCheckbox] — "I confirm I am {age} or older".
///  - [AcknowledgementCheckbox] — caller-supplied sentence (NDA,
///    disclaimers), localized default error.
///
/// Plain labeled (localized en + ar):
///  - [RememberMeCheckbox], [MarketingOptInCheckbox],
///    [DontShowAgainCheckbox], [SaveCardCheckbox],
///    [DefaultAddressCheckbox], [SameAsBillingCheckbox].
///
/// Radio:
///  - [YesNoRadioGroup] — localized Yes/No single-select.
///  - [GenderRadioGroup] — the gender picker's radio face (same enum +
///    strings as the dropdown).
///  - [AddressTypeRadioGroup] — Home/Work/Other tag picker (same enum
///    as `AddressForm`).
///
/// Segmented (single-select):
///  - [ViewModeSegmented] — list/grid toggle.
///  - [MapListSegmented] — list/map toggle for location screens.
///  - [ChartPeriodSegmented] — D/W/M/Y period picker.
///  - [ThemeModeSegmented] — system/light/dark (shares
///    ThemeModeStrings with the dropdown).
///  - [StatusFilterSegmented] — all/active/archived list filter.
///  - [TimeFormatSegmented] — 12h/24h clock preference.
///
/// Toggle group:
///  - [SortDirectionToggle] — asc/desc icon pair.
///  - [WeekdaysToggleGroup] — multi-select weekdays (recurrence /
///    business hours), locale-ordered.
///  - [PriceTierToggle] — $…$$$$ tier filter, multi-select.
///  - [TextFormatToggle] — B/I/U/S editor flags, icon multi-select.
///  - [TextAlignToggle] — start/center/end/justify, RTL-aware icons.
///  - [NotificationChannelsToggle] — push/email/SMS multi-select.
///  - [DayPartToggle] — morning/afternoon/evening/night windows.
///  - [SizeFilterToggle] — XS–XXL tokens, multi-select.
///  - [CountFilterToggle] — Any/1/2/3/4+ minimum-count filter.
///  - [StarRatingToggle] — 1★–5★ class filter, multi-select.
///
/// Switch:
///  - [SettingsSwitchRow] — settings-page row with trailing
///    `GlobalSwitch` (the switch module ships no tile of its own),
///    plus localized presets: [DarkModeSwitchRow],
///    [NotificationsSwitchRow], [BiometricSwitchRow],
///    [AnalyticsSwitchRow], [CrashReportsSwitchRow],
///    [HapticsSwitchRow].
///
/// Slider:
///  - [SettingsSliderRow] — settings-page row with a leading icon, a
///    description line and a bare `GlobalSlider` under them (the
///    slider module draws its own card, which a settings LIST already
///    is). [SettingsRangeRow] is its two-thumbed twin — a separate
///    widget rather than a flag, because the value type changes.
///  - [SliderFormField] — `FormField<double>` with the same error row
///    the text fields draw. Every other selection control here had one
///    and the slider did not, so a "budget must be at least 100" rule
///    lived in the submit handler.
///  - Localized presets: [VolumeSlider] (icon follows the level, zero
///    says "Muted"), [BrightnessSlider], [TextScaleSlider] (bounded by
///    `AppTypographyScale`, not by a guess), [PlaybackSpeedSlider]
///    (seven rungs, evenly spaced on the TRACK rather than in value),
///    [QualitySlider] (four `stepLabels`, which is also what a screen
///    reader announces), [PriceRangeSlider], [AgeRangeSlider],
///    [DistanceRadiusSlider], [RatingFilterSlider] (zero is "Any", not
///    zero stars).
///
/// Anything else is a ten-liner over `GlobalCheckbox` /
/// `GlobalCheckboxFormField` — copy a pattern above.
///
/// Locale note: every wrapper registers a locale dependency in build
/// (`Localizations.maybeLocaleOf`) — Tr/S reads are static, so without
/// it a const-constructed instance would freeze its language until hot
/// reload. The FormField wrappers additionally re-validate a SHOWING
/// error on a language flip (the error string is cached in
/// FormFieldState). Copy both behaviors into new wrappers.
library;

export '../../module/checkbox/global_checkbox.dart';
export '../../module/radio/global_radio.dart';
export '../../module/segmented_control/global_segmented_control.dart';
export '../../module/slider/global_slider.dart';
export '../../module/toggle_group/global_toggle_group.dart';
export 'checkbox/acknowledgement_checkbox.dart';
export 'checkbox/age_confirmation_checkbox.dart';
export 'checkbox/consent_checkbox_field.dart';
export 'checkbox/default_address_checkbox.dart';
export 'checkbox/dont_show_again_checkbox.dart';
export 'checkbox/marketing_opt_in_checkbox.dart';
export 'checkbox/remember_me_checkbox.dart';
export 'checkbox/same_as_billing_checkbox.dart';
export 'checkbox/save_card_checkbox.dart';
export 'radio/address_type_radio_group.dart';
export 'radio/gender_radio_group.dart';
export 'radio/yes_no_radio_group.dart';
export 'segmented/chart_period_segmented.dart';
export 'segmented/map_list_segmented.dart';
export 'segmented/status_filter_segmented.dart';
export 'segmented/theme_mode_segmented.dart';
export 'segmented/time_format_segmented.dart';
export 'segmented/view_mode_segmented.dart';
export 'slider/age_range_slider.dart';
export 'slider/brightness_slider.dart';
export 'slider/distance_radius_slider.dart';
export 'slider/playback_speed_slider.dart';
export 'slider/price_range_slider.dart';
export 'slider/quality_slider.dart';
export 'slider/rating_filter_slider.dart';
export 'slider/settings_range_row.dart';
export 'slider/settings_slider_row.dart';
export 'slider/slider_form_field.dart';
export 'slider/text_scale_slider.dart';
export 'slider/volume_slider.dart';
export 'switch/analytics_switch_row.dart';
export 'switch/biometric_switch_row.dart';
export 'switch/crash_reports_switch_row.dart';
export 'switch/dark_mode_switch_row.dart';
export 'switch/haptics_switch_row.dart';
export 'switch/notifications_switch_row.dart';
export 'switch/settings_switch_row.dart';
export 'toggle_group/count_filter_toggle.dart';
export 'toggle_group/day_part_toggle.dart';
export 'toggle_group/notification_channels_toggle.dart';
export 'toggle_group/price_tier_toggle.dart';
export 'toggle_group/size_filter_toggle.dart';
export 'toggle_group/sort_direction_toggle.dart';
export 'toggle_group/star_rating_toggle.dart';
export 'toggle_group/text_align_toggle.dart';
export 'toggle_group/text_format_toggle.dart';
export 'toggle_group/weekdays_toggle_group.dart';
