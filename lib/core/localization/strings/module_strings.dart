import '../../../generated/l10n.dart';
import '../tr.dart';

/// Strings for the `badge_` key prefix family — semantic labels of
/// `GlobalBadge` variants.
class BadgeStrings {
  BadgeStrings._();

  static String countNotifications(String count) => Tr.t(
    'badge.count_notifications',
    S.current.badge_count_notifications(count),
  );

  static String get newNotification =>
      Tr.t('badge.new_notification', S.current.badge_new_notification);
}

/// Strings for the `text_` key prefix family — `GlobalExpandableText`
/// toggle labels.
class TextStrings {
  TextStrings._();

  static String get readMore =>
      Tr.t('text.read_more', S.current.text_read_more);
  static String get readLess =>
      Tr.t('text.read_less', S.current.text_read_less);
}

/// Strings for the `checkbox_` key prefix family.
class CheckboxStrings {
  CheckboxStrings._();

  static String get selectAll =>
      Tr.t('checkbox.select_all', S.current.checkbox_select_all);
  static String get semanticLabel =>
      Tr.t('checkbox.semantic_label', S.current.checkbox_semantic_label);

  // ─── Common-wrapper labels (shared/common/selection_fields) ───

  /// Parameterized — rides [Tr.plural] so a remote ICU template still
  /// interpolates `{age}` (flat Tr.t returns overrides verbatim).
  static String ageConfirm(int age) => Tr.plural(
    'checkbox.age_confirm',
    age,
    S.current.checkbox_age_confirm(age),
    args: {'age': age},
  );
  static String get ageRequired =>
      Tr.t('checkbox.age_required', S.current.checkbox_age_required);
  static String get acknowledgeRequired => Tr.t(
    'checkbox.acknowledge_required',
    S.current.checkbox_acknowledge_required,
  );
  static String get marketingOptIn =>
      Tr.t('checkbox.marketing_opt_in', S.current.checkbox_marketing_opt_in);
  static String get dontShowAgain =>
      Tr.t('checkbox.dont_show_again', S.current.checkbox_dont_show_again);
  static String get saveCard =>
      Tr.t('checkbox.save_card', S.current.checkbox_save_card);
  static String get defaultAddress =>
      Tr.t('checkbox.default_address', S.current.checkbox_default_address);
  static String get sameAsBilling =>
      Tr.t('checkbox.same_as_billing', S.current.checkbox_same_as_billing);
}

/// Strings for the `switch_` key prefix family — the on/off state the
/// switch announces to screen readers.
class SwitchStrings {
  SwitchStrings._();

  static String get on => Tr.t('switch.on', S.current.switch_on);
  static String get off => Tr.t('switch.off', S.current.switch_off);

  // ─── Common-wrapper labels (shared/common/selection_fields) ───

  static String get darkMode =>
      Tr.t('switch.dark_mode', S.current.switch_dark_mode);
  static String get notifications =>
      Tr.t('switch.notifications', S.current.switch_notifications);
  static String get biometric =>
      Tr.t('switch.biometric', S.current.switch_biometric);
  static String get biometricDesc =>
      Tr.t('switch.biometric_desc', S.current.switch_biometric_desc);
  static String get analytics =>
      Tr.t('switch.analytics', S.current.switch_analytics);
  static String get analyticsDesc =>
      Tr.t('switch.analytics_desc', S.current.switch_analytics_desc);
  static String get crashReports =>
      Tr.t('switch.crash_reports', S.current.switch_crash_reports);
  static String get haptics => Tr.t('switch.haptics', S.current.switch_haptics);
}

/// Strings for the `slider_` key prefix family — the labels the
/// pre-built sliders under `shared/common/selection_fields/slider/`
/// wear.
///
/// The MODULE ships none of these: `GlobalSlider` takes whatever label
/// it is handed. A settings page that writes "Volume" in English is a
/// settings page that writes "Volume" in Arabic too, which is the
/// whole reason the commons exist.
class SliderStrings {
  SliderStrings._();

  static String get volume => Tr.t('slider.volume', S.current.slider_volume);
  static String get muted => Tr.t('slider.muted', S.current.slider_muted);
  static String get brightness =>
      Tr.t('slider.brightness', S.current.slider_brightness);
  static String get textSize =>
      Tr.t('slider.text_size', S.current.slider_text_size);
  static String get playbackSpeed =>
      Tr.t('slider.playback_speed', S.current.slider_playback_speed);

  static String get quality => Tr.t('slider.quality', S.current.slider_quality);
  static String get qualityLow =>
      Tr.t('slider.quality_low', S.current.slider_quality_low);
  static String get qualityMedium =>
      Tr.t('slider.quality_medium', S.current.slider_quality_medium);
  static String get qualityHigh =>
      Tr.t('slider.quality_high', S.current.slider_quality_high);
  static String get qualityUltra =>
      Tr.t('slider.quality_ultra', S.current.slider_quality_ultra);

  static String get priceRange =>
      Tr.t('slider.price_range', S.current.slider_price_range);
  static String get ageRange =>
      Tr.t('slider.age_range', S.current.slider_age_range);
  static String get years => Tr.t('slider.years', S.current.slider_years);
  static String get distance =>
      Tr.t('slider.distance', S.current.slider_distance);
  static String get km => Tr.t('slider.unit_km', S.current.slider_unit_km);
  static String get mi => Tr.t('slider.unit_mi', S.current.slider_unit_mi);
  static String get minRating =>
      Tr.t('slider.min_rating', S.current.slider_min_rating);
  static String get any => Tr.t('slider.any', S.current.slider_any);
}

/// Strings for the `indicator_` key prefix family — what a screen
/// reader hears from a page indicator or a story bar.
class IndicatorStrings {
  IndicatorStrings._();

  static String pageOf(int index, int total) =>
      Tr.t('indicator.page_of', S.current.indicator_page_of(index, total));

  static String goToPage(int index) =>
      Tr.t('indicator.go_to_page', S.current.indicator_go_to_page(index));

  static String storySegment(int index, int total) => Tr.t(
    'indicator.story_segment',
    S.current.indicator_story_segment(index, total),
  );

  static String get playing =>
      Tr.t('indicator.story_playing', S.current.indicator_story_playing);
  static String get paused =>
      Tr.t('indicator.story_paused', S.current.indicator_story_paused);
}

/// Strings for the `empty_` key prefix family — the copy the commons
/// empty-state wrappers ship with.
class EmptyStateStrings {
  EmptyStateStrings._();

  static String noResultsTitle(String query) =>
      Tr.t('empty.no_results_title', S.current.empty_no_results_title(query));
  static String get noResultsSubtitle =>
      Tr.t('empty.no_results_subtitle', S.current.empty_no_results_subtitle);
  static String get clearSearch =>
      Tr.t('empty.clear_search', S.current.empty_clear_search);

  static String get offlineTitle =>
      Tr.t('empty.offline_title', S.current.empty_offline_title);
  static String get offlineSubtitle =>
      Tr.t('empty.offline_subtitle', S.current.empty_offline_subtitle);

  static String get failedTitle =>
      Tr.t('empty.failed_title', S.current.empty_failed_title);
  static String get failedSubtitle =>
      Tr.t('empty.failed_subtitle', S.current.empty_failed_subtitle);

  static String get retry => Tr.t('empty.retry', S.current.empty_retry);
}

/// Strings for the `avatar_` key prefix family — what the overflow chip
/// of a `GlobalAvatarGroup` announces.
class AvatarStrings {
  AvatarStrings._();

  static String moreCount(int count) => Tr.plural(
    'avatar.more_count',
    count,
    S.current.avatar_more_count(count),
    args: {'count': count},
  );
}

/// Strings for the `rating_` key prefix family — the slider label and
/// value `GlobalRating` announces.
class RatingStrings {
  RatingStrings._();

  static String get semanticLabel =>
      Tr.t('rating.semantic_label', S.current.rating_semantic_label);

  /// "4 out of 5". [value] is pre-formatted so a whole rating reads as
  /// "4" rather than "4.0", which a screen reader spells out.
  static String valueOutOf(String value, int count) =>
      Tr.t('rating.value_out_of', S.current.rating_value_out_of(value, count));
}

/// Strings for the `radio_` key prefix family — semantic fallback +
/// the yes/no wrapper labels.
class RadioStrings {
  RadioStrings._();

  static String get semanticLabel =>
      Tr.t('radio.semantic_label', S.current.radio_semantic_label);
  static String get yes => Tr.t('radio.yes', S.current.radio_yes);
  static String get no => Tr.t('radio.no', S.current.radio_no);
}

/// Strings for the `toggle_group_` key prefix family.
class ToggleGroupStrings {
  ToggleGroupStrings._();

  static String get semanticLabel => Tr.t(
    'toggle_group.semantic_label',
    S.current.toggle_group_semantic_label,
  );

  /// The tooltip on the "+N" button a collapsed group shows.
  static String get overflowTooltip => Tr.t(
    'toggle_group.overflow_tooltip',
    S.current.toggle_group_overflow_tooltip,
  );

  /// What a reader HEARS on that button — "+3" is a glyph, not a
  /// sentence.
  static String overflowSemanticLabel(int count) => Tr.t(
    'toggle_group.overflow_label',
    S.current.toggle_group_overflow_label(count),
  );

  static String get sortAsc =>
      Tr.t('toggle_group.sort_asc', S.current.toggle_group_sort_asc);
  static String get sortDesc =>
      Tr.t('toggle_group.sort_desc', S.current.toggle_group_sort_desc);
  static String get formatBold =>
      Tr.t('toggle_group.format_bold', S.current.toggle_group_format_bold);
  static String get formatItalic =>
      Tr.t('toggle_group.format_italic', S.current.toggle_group_format_italic);
  static String get formatUnderline => Tr.t(
    'toggle_group.format_underline',
    S.current.toggle_group_format_underline,
  );
  static String get formatStrikethrough => Tr.t(
    'toggle_group.format_strikethrough',
    S.current.toggle_group_format_strikethrough,
  );
  static String get alignStart =>
      Tr.t('toggle_group.align_start', S.current.toggle_group_align_start);
  static String get alignCenter =>
      Tr.t('toggle_group.align_center', S.current.toggle_group_align_center);
  static String get alignEnd =>
      Tr.t('toggle_group.align_end', S.current.toggle_group_align_end);
  static String get alignJustify =>
      Tr.t('toggle_group.align_justify', S.current.toggle_group_align_justify);
  static String get channelPush =>
      Tr.t('toggle_group.channel_push', S.current.toggle_group_channel_push);
  static String get channelEmail =>
      Tr.t('toggle_group.channel_email', S.current.toggle_group_channel_email);
  static String get channelSms =>
      Tr.t('toggle_group.channel_sms', S.current.toggle_group_channel_sms);
  static String get daypartMorning => Tr.t(
    'toggle_group.daypart_morning',
    S.current.toggle_group_daypart_morning,
  );
  static String get daypartAfternoon => Tr.t(
    'toggle_group.daypart_afternoon',
    S.current.toggle_group_daypart_afternoon,
  );
  static String get daypartEvening => Tr.t(
    'toggle_group.daypart_evening',
    S.current.toggle_group_daypart_evening,
  );
  static String get daypartNight =>
      Tr.t('toggle_group.daypart_night', S.current.toggle_group_daypart_night);
  static String get countAny =>
      Tr.t('toggle_group.count_any', S.current.toggle_group_count_any);
}

/// Strings for the `segmented_control_` key prefix family.
class SegmentedControlStrings {
  SegmentedControlStrings._();

  static String get semanticLabel => Tr.t(
    'segmented_control.semantic_label',
    S.current.segmented_control_semantic_label,
  );
  static String get viewList => Tr.t(
    'segmented_control.view_list',
    S.current.segmented_control_view_list,
  );
  static String get viewGrid => Tr.t(
    'segmented_control.view_grid',
    S.current.segmented_control_view_grid,
  );
  static String get periodDay => Tr.t(
    'segmented_control.period_day',
    S.current.segmented_control_period_day,
  );
  static String get periodWeek => Tr.t(
    'segmented_control.period_week',
    S.current.segmented_control_period_week,
  );
  static String get periodMonth => Tr.t(
    'segmented_control.period_month',
    S.current.segmented_control_period_month,
  );
  static String get periodYear => Tr.t(
    'segmented_control.period_year',
    S.current.segmented_control_period_year,
  );
  static String get viewMap =>
      Tr.t('segmented_control.view_map', S.current.segmented_control_view_map);
  static String get time12h =>
      Tr.t('segmented_control.time_12h', S.current.segmented_control_time_12h);
  static String get time24h =>
      Tr.t('segmented_control.time_24h', S.current.segmented_control_time_24h);
  static String get statusAll => Tr.t(
    'segmented_control.status_all',
    S.current.segmented_control_status_all,
  );
  static String get statusActive => Tr.t(
    'segmented_control.status_active',
    S.current.segmented_control_status_active,
  );
  static String get statusArchived => Tr.t(
    'segmented_control.status_archived',
    S.current.segmented_control_status_archived,
  );
}

/// Strings for the `sheet_` key prefix family — the common sheet
/// wrappers in `lib/shared/common/sheets/`.
class SheetStrings {
  SheetStrings._();

  static String get confirmTitle =>
      Tr.t('sheet.confirm_title', S.current.sheet_confirm_title);
  static String get confirm => Tr.t('sheet.confirm', S.current.sheet_confirm);
  static String get deleteTitle =>
      Tr.t('sheet.delete_title', S.current.sheet_delete_title);
  static String get deleteMessage =>
      Tr.t('sheet.delete_message', S.current.sheet_delete_message);
  static String get logoutTitle =>
      Tr.t('sheet.logout_title', S.current.sheet_logout_title);
  static String get logoutMessage =>
      Tr.t('sheet.logout_message', S.current.sheet_logout_message);
  static String get logoutConfirm =>
      Tr.t('sheet.logout_confirm', S.current.sheet_logout_confirm);
  static String get discardTitle =>
      Tr.t('sheet.discard_title', S.current.sheet_discard_title);
  static String get discardMessage =>
      Tr.t('sheet.discard_message', S.current.sheet_discard_message);
  static String get discardConfirm =>
      Tr.t('sheet.discard_confirm', S.current.sheet_discard_confirm);
  static String get gotIt => Tr.t('sheet.got_it', S.current.sheet_got_it);
  static String get filters => Tr.t('sheet.filters', S.current.sheet_filters);
  static String get apply => Tr.t('sheet.apply', S.current.sheet_apply);
  static String get reset => Tr.t('sheet.reset', S.current.sheet_reset);
}

/// Strings for the `popup_` key prefix family — a11y announcements of
/// `GlobalPopup`.
class PopupStrings {
  PopupStrings._();

  static String get openedSemantic =>
      Tr.t('popup.opened_semantic', S.current.popup_opened_semantic);

  static String get closedSemantic =>
      Tr.t('popup.closed_semantic', S.current.popup_closed_semantic);
}

/// Strings for the `dialog_` key prefix family — `GlobalDialog` quick
/// helper defaults.
class DialogStrings {
  DialogStrings._();

  static String get confirm => Tr.t('dialog.confirm', S.current.dialog_confirm);

  static String get enterTextHint =>
      Tr.t('dialog.enter_text_hint', S.current.dialog_enter_text_hint);

  /// Parameterized — rides [Tr.plural] so a remote ICU template still
  /// interpolates `{seconds}` (flat Tr.t returns overrides verbatim).
  static String closingIn(int seconds) => Tr.plural(
    'dialog.closing_in',
    seconds,
    S.current.dialog_closing_in(seconds),
    args: {'seconds': seconds},
  );
}

/// Strings for the `drawer_` key prefix family — `GlobalDrawer` search
/// empty state.
class DrawerStrings {
  DrawerStrings._();

  static String get expand => Tr.t('drawer.expand', S.current.drawer_expand);

  static String get noResults =>
      Tr.t('drawer.no_results', S.current.drawer_no_results);

  static String noItemsMatch(String query) =>
      Tr.t('drawer.no_items_match', S.current.drawer_no_items_match(query));
}

/// Strings for the `video_` key prefix family — `GlobalVideo` player.
/// What a screen reader hears on the audio player.
///
/// Every control is a bare glyph with no text beside it, so one that
/// forgot to name itself would announce nothing at all — the module
/// had no labels of any kind before this.
class AudioStrings {
  const AudioStrings._();

  static String get play => Tr.t('audio.play', S.current.audio_play);
  static String get pause => Tr.t('audio.pause', S.current.audio_pause);
  static String get loading => Tr.t('audio.loading', S.current.audio_loading);
  static String get error => Tr.t('audio.error', S.current.audio_error);
  static String get retry => Tr.t('audio.retry', S.current.audio_retry);

  static String get next => Tr.t('audio.next', S.current.audio_next);

  static String get previous =>
      Tr.t('audio.previous', S.current.audio_previous);

  static String get sleep => Tr.t('audio.sleep', S.current.audio_sleep);

  static String get sleepOff =>
      Tr.t('audio.sleep.off', S.current.audio_sleep_off);

  static String get sleepEndOfTrack =>
      Tr.t('audio.sleep.end', S.current.audio_sleep_end);

  static String sleepMinutes(int minutes) => Tr.t(
    'audio.sleep.minutes',
    S.current.audio_sleep_minutes(minutes),
  );

  /// The chip's own text — it sits beside two others and has a glyph
  /// of its own, so it says the VALUE and leaves the name to the
  /// semantic label.
  static String sleepShortMinutes(int minutes) => Tr.t(
    'audio.sleep.short.minutes',
    S.current.audio_sleep_short_minutes(minutes),
  );

  static String get sleepShortEnd =>
      Tr.t('audio.sleep.short.end', S.current.audio_sleep_short_end);
  static String skipBack(int seconds) =>
      Tr.t('audio.skip_back', S.current.audio_skip_back(seconds));
  static String skipForward(int seconds) =>
      Tr.t('audio.skip_forward', S.current.audio_skip_forward(seconds));
  static String get speed => Tr.t('audio.speed', S.current.audio_speed);
  static String get loop => Tr.t('audio.loop', S.current.audio_loop);
  static String get timeline =>
      Tr.t('audio.timeline', S.current.audio_timeline);
  static String get waveform =>
      Tr.t('audio.waveform', S.current.audio_waveform);
}

class VideoStrings {
  VideoStrings._();

  static String get loadFailed =>
      Tr.t('video.load_failed', S.current.video_load_failed);

  /// What the whole player announces itself as, when nothing named it.
  static String get player => Tr.t('video.player', S.current.video_player);

  // ─── Controls ─────────────────────────────────────────────
  static String get play => Tr.t('video.play', S.current.video_play);
  static String get pause => Tr.t('video.pause', S.current.video_pause);
  static String get replay => Tr.t('video.replay', S.current.video_replay);
  static String get mute => Tr.t('video.mute', S.current.video_mute);
  static String get unmute => Tr.t('video.unmute', S.current.video_unmute);
  static String get enterFullscreen =>
      Tr.t('video.enter_fullscreen', S.current.video_enter_fullscreen);
  static String get exitFullscreen =>
      Tr.t('video.exit_fullscreen', S.current.video_exit_fullscreen);
  static String get settings =>
      Tr.t('video.settings', S.current.video_settings);
  static String get screenshot =>
      Tr.t('video.screenshot', S.current.video_screenshot);
  static String get next => Tr.t('video.next', S.current.video_next);
  static String get previous =>
      Tr.t('video.previous', S.current.video_previous);
  static String get seek => Tr.t('video.seek', S.current.video_seek);
  static String get playbackSpeed =>
      Tr.t('video.playback_speed', S.current.video_playback_speed);
  static String get subtitles =>
      Tr.t('video.subtitles', S.current.video_subtitles);
  static String get audioTrack =>
      Tr.t('video.audio_track', S.current.video_audio_track);
  static String get quality => Tr.t('video.quality', S.current.video_quality);
  static String get off => Tr.t('video.off', S.current.video_off);

  /// Fullscreen only: freezes the whole control layer so a thumb, a
  /// lap or a pocket cannot seek or exit.
  static String get lockScreen =>
      Tr.t('video.lock_screen', S.current.video_lock_screen);
  static String get unlockScreen =>
      Tr.t('video.unlock_screen', S.current.video_unlock_screen);

  /// The card that plays the next item in a playlist by itself.
  static String get upNext => Tr.t('video.up_next', S.current.video_up_next);
  static String get cancelAutoplay =>
      Tr.t('video.cancel_autoplay', S.current.video_cancel_autoplay);

  /// Extra controls an app can offer.
  static String subtitlesToggle({required bool on}) => on
      ? Tr.t('video.subtitles_on', S.current.video_subtitles_on)
      : Tr.t('video.subtitles_off', S.current.video_subtitles_off);
  static String get chapters =>
      Tr.t('video.chapters', S.current.video_chapters);
  static String get replayFromStart =>
      Tr.t('video.replay_start', S.current.video_replay_start);
  static String zoomToggle({required bool filling}) => filling
      ? Tr.t('video.zoom_fit', S.current.video_zoom_fit)
      : Tr.t('video.zoom_fill', S.current.video_zoom_fill);
  static String get sleepTimer =>
      Tr.t('video.sleep_timer', S.current.video_sleep_timer);
  static String get sleepOff =>
      Tr.t('video.sleep_off', S.current.video_sleep_off);
  static String sleepMinutes(int count) =>
      Tr.t('video.sleep_minutes', S.current.video_sleep_minutes(count));
  static String get sleepAtEnd =>
      Tr.t('video.sleep_end', S.current.video_sleep_end);
  static String get loopSetA =>
      Tr.t('video.loop_set_a', S.current.video_loop_set_a);
  static String get loopSetB =>
      Tr.t('video.loop_set_b', S.current.video_loop_set_b);
  static String get loopClear =>
      Tr.t('video.loop_clear', S.current.video_loop_clear);
  static String get subtitleDelay =>
      Tr.t('video.subtitle_delay', S.current.video_subtitle_delay);
  static String get subtitleEarlier =>
      Tr.t('video.subtitle_earlier', S.current.video_subtitle_earlier);
  static String get subtitleLater =>
      Tr.t('video.subtitle_later', S.current.video_subtitle_later);
  static String get subtitleSize =>
      Tr.t('video.subtitle_size', S.current.video_subtitle_size);
  static String get subtitleSmaller =>
      Tr.t('video.subtitle_smaller', S.current.video_subtitle_smaller);
  static String get subtitleLarger =>
      Tr.t('video.subtitle_larger', S.current.video_subtitle_larger);
  static String get subtitleNormalSize =>
      Tr.t('video.subtitle_normal', S.current.video_subtitle_normal);
  static String get subtitleInSync =>
      Tr.t('video.subtitle_reset', S.current.video_subtitle_reset);
  static String get castToScreen => Tr.t('video.cast', S.current.video_cast);

  static String get playNow => Tr.t('video.play_now', S.current.video_play_now);

  /// The device has no audio OUTPUT — the film still plays.
  static String get noAudioDevice =>
      Tr.t('video.no_audio_device', S.current.video_no_audio_device);

  static String seekForward(int seconds) => Tr.t(
    'video.seek_forward',
    S.current.video_seek_forward(seconds),
  );

  static String seekBack(int seconds) =>
      Tr.t('video.seek_back', S.current.video_seek_back(seconds));
}

class AnimationStrings {
  AnimationStrings._();

  static String get loadFailed =>
      Tr.t('animation.load_failed', S.current.animation_load_failed);
  static String get notFound =>
      Tr.t('animation.not_found', S.current.animation_not_found);
  static String get accessDenied =>
      Tr.t('animation.access_denied', S.current.animation_access_denied);
  static String get networkError =>
      Tr.t('animation.network_error', S.current.animation_network_error);
  static String get invalidFile =>
      Tr.t('animation.invalid_file', S.current.animation_invalid_file);

  static String get play => Tr.t('animation.play', S.current.animation_play);
  static String get pause => Tr.t('animation.pause', S.current.animation_pause);
  static String get replay =>
      Tr.t('animation.replay', S.current.animation_replay);

  /// The seek bar's NAME. Its value is the percentage — a slider that
  /// announces "34%" and nothing else says what is 34% of what.
  static String get seek => Tr.t('animation.seek', S.current.animation_seek);

  static String percentPlayed(int percent) => Tr.t(
    'animation.percent_played',
    S.current.animation_percent_played(percent),
  );

  static String get playbackSpeed =>
      Tr.t('animation.playback_speed', S.current.animation_playback_speed);

  /// "1x". A multiplier is not a plural and does not inflect, but it
  /// goes through the same path as everything else so a locale that
  /// writes it differently can.
  static String speedMultiplier(String rate) => Tr.t(
    'animation.speed_multiplier',
    S.current.animation_speed_multiplier(rate),
  );

  static String get pausedReducedMotion => Tr.t(
    'animation.paused_reduced_motion',
    S.current.animation_paused_reduced_motion,
  );
}
