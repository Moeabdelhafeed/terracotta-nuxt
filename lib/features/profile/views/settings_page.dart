import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/flavor/flavor.dart';
import '../../../core/flavor/flavor_config.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/settings_strings.dart';
import '../../../core/notifications/notification_permissions.dart';
import '../../../core/tokens/extensions.dart';
import '../../../core/utils/device/info/app_info_utils.dart';
import '../../../shared/module/buttons/global_outlined_button.dart';
import '../../../shared/module/container/global_container.dart';
import '../../../shared/module/preferences_pickers/preferences_pickers.dart';
import '../../../shared/module/scrollable/global_scrollable.dart';
import '../../_shared/terracotta_page_bar.dart';
import '../../_shared/terracotta_widgets.dart';

/// «الإعدادات» — the handful of things a CUSTOMER sets.
///
/// ## Why this is not the template's settings page
///
/// The template ships one, and it is a showcase: an app-role switch, a
/// colour-saturation ramp, a reveal shape, a reveal direction, a
/// dynamic-colour toggle. Those are controls for the people building
/// the template. Nothing in this app ever linked to that page, which
/// is the honest verdict on whether a customer wanted it.
///
/// This one carries three things: the LANGUAGE, the TEXT SIZE, and
/// whether NOTIFICATIONS are on.
///
/// **The theme switch says where dark came from.** The design is
/// light-only, so dark is the app's own work: a warm-neutral ground
/// with its own elevation ladder, its own inks and its own status
/// hues, every pair measured against 4.5:1
/// (`test/terracotta/dark_palette_test.dart`). The row carries one
/// line saying so rather than pretending the studio drew it.
///
/// **Notifications are READ, not set.** Only the OS can grant the
/// permission and only the reader can tell it, so the row says where
/// it stands and opens the system screen. A toggle that cannot toggle
/// is worse than a sentence.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with WidgetsBindingObserver {
  NotificationPermissionStatus? _notifications;
  String? _version;

  @override
  void initState() {
    super.initState();
    // The reader can change the permission in the OS and come back, so
    // this screen re-reads it on the way back in.
    WidgetsBinding.instance.addObserver(this);
    unawaited(_read());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_read());
  }

  Future<void> _read() async {
    final status = await NotificationPermissions.check();
    final info = await AppInfoUtils.getInfo();
    if (!mounted) return;
    setState(() {
      _notifications = status;
      _version = info.fullVersion;
    });
  }

  bool get _notificationsOn =>
      _notifications == NotificationPermissionStatus.granted ||
      _notifications == NotificationPermissionStatus.provisional;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: context.backgroundColors.scaffoldBackground,
      appBar: TerracottaPageBar(
        title: CommonStrings.settings,
        showShopActions: false,
      ),
      body: GlobalScrollable(
        child: GlobalContainer.shell(
          padding: EdgeInsetsDirectional.fromSTEB(
            spacing.md,
            spacing.md,
            spacing.md,
            spacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Section(
                title: SettingsStrings.language,
                child: const LanguagePicker(),
              ),
              SizedBox(height: spacing.md),
              _Section(
                title: SettingsStrings.textSize,
                child: const FontScaleSlider(),
              ),
              // ── THEME — withdrawn, not deleted ──────────────────
              //
              // The app ships LIGHT ONLY. The dark ramp is built and
              // measured (`test/terracotta/dark_palette_test.dart`)
              // and `AppTheme` still produces both, so bringing this
              // back is uncommenting the block below and restoring
              // `themeMode: prefs.themeMode` in `my_app.dart` — the
              // two have to move together, or the switch moves a
              // value nothing reads.
              //
              // SizedBox(height: spacing.md),
              // _Section(
              //   title: SettingsStrings.theme,
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.stretch,
              //     children: [
              //       const ThemeModePicker(),
              //       SizedBox(height: spacing.sm),
              //       Text(
              //         SettingsStrings.themeNote,
              //         style: context.textTheme.bodySmall?.copyWith(
              //           color: context.textColors.secondary,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              SizedBox(height: spacing.md),
              _Section(
                title: SettingsStrings.notifications,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _notificationsOn
                          ? SettingsStrings.notificationsOn
                          : SettingsStrings.notificationsOff,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: _notificationsOn
                            ? context.statusColors.success
                            : context.textColors.secondary,
                      ),
                    ),
                    // ALWAYS OFFERED, on or off.
                    //
                    // It was shown only when they were off, so a
                    // reader who wanted to turn them OFF had no way to
                    // get there — and turning them off is the reason
                    // most people open a notifications row. Neither
                    // direction is something this app can do itself:
                    // only the OS grants and revokes, so both are the
                    // same button.
                    SizedBox(height: spacing.sm),
                    GlobalOutlinedButton(
                      text: SettingsStrings.openNotificationSettings,
                      icon: Icons.open_in_new_rounded,
                      onPressed: () =>
                          unawaited(NotificationPermissions.openSettings()),
                    ),
                  ],
                ),
              ),
              // WHETHER PUSH ACTUALLY WORKS on this device.
              //
              // Not for a customer, and not shown to one: every way
              // FCM topics fail is silent and they all look the same
              // from outside, and the log lines that would tell them
              // apart are compiled out of the build a tester is
              // holding. Hidden on production — see
              // [PushDiagnosticsPage].
              if (FlavorConfig.instance.flavor != Flavor.prod) ...[
                SizedBox(height: spacing.md),
                GlobalOutlinedButton(
                  text: 'Push diagnostics',
                  icon: Icons.troubleshoot_rounded,
                  onPressed: () => context.pushNamed('push-diagnostics'),
                ),
              ],
              SizedBox(height: spacing.lg),
              if (_version case final version?)
                Text(
                  SettingsStrings.version(version),
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.textColors.secondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One setting, in the card every other list on this tab uses.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return TerracottaCard(
      padding: EdgeInsets.all(spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: context.textTheme.titleSmall?.copyWith(
              color: context.textColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: spacing.sm),
          child,
        ],
      ),
    );
  }
}
