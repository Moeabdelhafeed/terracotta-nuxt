import 'package:flutter/material.dart';

import 'update_state.dart';
import 'update_strings.dart';

/// Variants for how the soft (non-blocking) update prompt appears.
/// Default [none] keeps soft updates dormant — the gate only
/// activates the hard, blocking screen.
enum SoftUpdateMode {
  /// Don't surface anything when an update is available but not
  /// required.
  none,

  /// Persistent banner at top of screen until dismissed for the
  /// session.
  banner,

  /// Modal bottom sheet shown once per cold-start session (or after
  /// remind-later cooldown).
  sheet,
}

/// App-level configuration for the update gate.
///
/// All opt-in features are off by default — the only thing the gate
/// does without configuration is render the hard screen when the RC
/// `min_app_version_*` exceeds the current version.
@immutable
class UpdateOptions {
  const UpdateOptions({
    this.enabled = true,
    this.softMode = SoftUpdateMode.none,
    this.allowSkipVersion = false,
    this.allowRemindLater = true,
    this.remindLaterCooldown = const Duration(hours: 24),
    this.bootGracePeriod = const Duration(milliseconds: 800),
    this.dismissOnTapOutside = false,
    this.barrierColor,
    this.strings = const UpdateStrings(),
    this.illustrationBuilder,
    this.hardScreenBuilder,
    this.softBannerBuilder,
    this.softSheetBuilder,
    this.openStore,
  });

  /// Master switch. Set false to bypass the gate entirely (e.g. in
  /// tests, web, or staging where you want unblocked installs).
  final bool enabled;

  /// What the gate does when the running version is between min and
  /// latest. [SoftUpdateMode.none] = nothing.
  final SoftUpdateMode softMode;

  /// Show a "Skip this version" button on the soft prompt. Tapping
  /// stores the version in the cubit so the user isn't asked again
  /// for that release.
  final bool allowSkipVersion;

  /// Show "Maybe later" on the soft prompt. After tap, the prompt
  /// hides for [remindLaterCooldown].
  final bool allowRemindLater;
  final Duration remindLaterCooldown;

  /// Time after boot before the gate is allowed to render. Avoids
  /// a flash during cold-start RC fetch.
  final Duration bootGracePeriod;

  /// Whether tapping outside the soft sheet dismisses it. Hard gate
  /// is never dismissible.
  final bool dismissOnTapOutside;

  /// Backdrop color override for the hard gate. Null = pulled from
  /// theme.
  final Color? barrierColor;

  final UpdateStrings strings;

  /// Replace the icon/illustration in the default screen. Receives
  /// `BuildContext` so the implementation can read theme. Common
  /// uses: `Lottie.asset(...)`, custom branded artwork.
  final WidgetBuilder? illustrationBuilder;

  /// Total override for the hard fullscreen UI. Receives the
  /// resolved [UpdateState] so the caller can inspect versions,
  /// strings, and trigger `cubit.openStore()`. When null, the
  /// default themed screen is rendered.
  final Widget Function(BuildContext context, UpdateState state)?
  hardScreenBuilder;

  /// Total override for the soft banner widget. Same contract as
  /// [hardScreenBuilder].
  final Widget Function(BuildContext context, UpdateState state)?
  softBannerBuilder;

  /// Total override for the soft bottom sheet. Same contract.
  final Widget Function(BuildContext context, UpdateState state)?
  softSheetBuilder;

  /// Override the store-open behaviour. Default opens
  /// `RemoteConfigService.currentStoreUrl` via `url_launcher`. Use
  /// this to plug in deep-link interception, in-app review prompts,
  /// or analytics wrapping.
  final Future<void> Function(BuildContext context, String url)? openStore;

  UpdateOptions copyWith({
    bool? enabled,
    SoftUpdateMode? softMode,
    bool? allowSkipVersion,
    bool? allowRemindLater,
    Duration? remindLaterCooldown,
    Duration? bootGracePeriod,
    bool? dismissOnTapOutside,
    Color? barrierColor,
    UpdateStrings? strings,
    WidgetBuilder? illustrationBuilder,
    Widget Function(BuildContext, UpdateState)? hardScreenBuilder,
    Widget Function(BuildContext, UpdateState)? softBannerBuilder,
    Widget Function(BuildContext, UpdateState)? softSheetBuilder,
    Future<void> Function(BuildContext, String)? openStore,
  }) {
    return UpdateOptions(
      enabled: enabled ?? this.enabled,
      softMode: softMode ?? this.softMode,
      allowSkipVersion: allowSkipVersion ?? this.allowSkipVersion,
      allowRemindLater: allowRemindLater ?? this.allowRemindLater,
      remindLaterCooldown: remindLaterCooldown ?? this.remindLaterCooldown,
      bootGracePeriod: bootGracePeriod ?? this.bootGracePeriod,
      dismissOnTapOutside: dismissOnTapOutside ?? this.dismissOnTapOutside,
      barrierColor: barrierColor ?? this.barrierColor,
      strings: strings ?? this.strings,
      illustrationBuilder: illustrationBuilder ?? this.illustrationBuilder,
      hardScreenBuilder: hardScreenBuilder ?? this.hardScreenBuilder,
      softBannerBuilder: softBannerBuilder ?? this.softBannerBuilder,
      softSheetBuilder: softSheetBuilder ?? this.softSheetBuilder,
      openStore: openStore ?? this.openStore,
    );
  }
}
