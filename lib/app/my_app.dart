import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/devtools/perf_flags.dart';
import '../core/devtools/persistent_widget_inspector.dart';
import '../core/di/service_locator.dart';
import '../core/error/app_remount.dart';
import '../core/error/error_storm.dart';
import '../core/flavor/flavor_config.dart';
import '../core/keyboard/keyboard_scope.dart';
import '../core/loading/loading_overlay.dart';
import '../core/maintenance/maintenance_gate.dart';
import '../core/navigation/go_router_config.dart';
import '../core/responsive/responsive.dart';
import '../core/security/build_lock/build_lock_guard.dart';
import '../core/theme/reveal_theme_switcher.dart';
import '../core/theme/theme.dart';
import '../core/update_gate/update_gate.dart';
import '../core/utils/device/info/notch_side.dart';
import '../data/blocs/preferences/preferences_cubit.dart';
import '../data/blocs/preferences/preferences_state.dart';
import '../data/services/preferences/theme_service.dart';
import '../features/splash/widgets/vessel_reveal_gate.dart';
import '../generated/l10n.dart';
import '../shared/module/connectivity_banner/connectivity_banner.dart';
import '../shared/module/debug_overlay/global_debug_overlay.dart';
import '../shared/module/popup/popup.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void reassemble() {
    super.reassemble();
    // Hot reload only: re-register the route table if routes were
    // added / removed / renamed. Without this, `GoRouterConfig.router`
    // (a static final, never re-initialized by hot reload) keeps the
    // route list captured at first access and a new route 404s until a
    // full restart. No-op when nothing structural changed.
    GoRouterConfig.debugRefreshRoutes();
    // Forget every folded error fingerprint. After an edit you want to
    // see immediately whether the fix took — not wait out the quiet
    // window before the same error is allowed to print again.
    ErrorStorm.reset();
  }

  @override
  Widget build(BuildContext context) {
    // MediaQuery.fromView provides the window size ABOVE MaterialApp
    // WITHOUT a root LayoutBuilder. A LayoutBuilder here rebuilt the
    // whole MaterialApp during the LAYOUT phase on any constraint
    // perturbation — including the one the DevTools inspector overlay
    // introduces — which tore down and re-pushed the entire GoRouter
    // Navigator (page state lost). MediaQuery.sizeOf rebuilds only on a
    // real size change, in the build phase, and doesn't churn the Router.
    return MediaQuery.fromView(
      view: View.of(context),
      child: Builder(
        builder: (context) {
          final windowSize = WindowSizeClass.fromWidth(
            MediaQuery.sizeOf(context).width,
          );
          return BlocBuilder<PreferencesCubit, PreferencesState>(
            builder: (context, prefs) {
              final themeService = getIt<ThemeService>();
              // `DynamicColorBuilder` queries the OS for an accent
              // scheme. Only Android 12+ ships one — every other
              // platform forces a "Dynamic color not detected" log on
              // every boot. Skip the wrap entirely off-Android so the
              // log stays clean.
              final supportsDynamic =
                  !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

              Widget mountApp(
                ColorScheme? lightDynamic,
                ColorScheme? darkDynamic,
              ) {
                final lightSeed = prefs.dynamicColor
                    ? lightDynamic?.primary
                    : null;
                final darkSeed = prefs.dynamicColor
                    ? darkDynamic?.primary
                    : null;
                return ListenableBuilder(
                  listenable: PerfFlags.listenable,
                  builder: (_, _) => MaterialApp.router(
                    debugShowCheckedModeBanner: false,
                    showPerformanceOverlay:
                        PerfFlags.showPerformanceOverlay.value,
                    checkerboardRasterCacheImages:
                        PerfFlags.checkerboardRasterCacheImages.value,
                    checkerboardOffscreenLayers:
                        PerfFlags.checkerboardOffscreenLayers.value,
                    showSemanticsDebugger:
                        PerfFlags.showSemanticsDebugger.value,
                    locale: Locale(prefs.language.locale),
                    localizationsDelegates: const [
                      S.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    supportedLocales: S.delegate.supportedLocales,
                    theme: AppTheme.getTheme(
                      themeMode: ThemeMode.light,
                      appRole: prefs.appRole,
                      windowSize: windowSize,
                      saturation: prefs.colorSaturation,
                      seedColorOverride: lightSeed,
                    ),
                    darkTheme: AppTheme.getTheme(
                      themeMode: ThemeMode.dark,
                      appRole: prefs.appRole,
                      windowSize: windowSize,
                      saturation: prefs.colorSaturation,
                      seedColorOverride: darkSeed,
                    ),
                    // LIGHT, always — the switch is withdrawn.
                    //
                    // Both themes are still BUILT above, and the dark
                    // ramp is real work rather than a derived
                    // fallback: every ground, ink and status hue was
                    // chosen for it and the pairs are measured in
                    // `test/terracotta/dark_palette_test.dart`. What
                    // is not shipped is the CHOICE — the design is
                    // light-only, and the logo's dark variant is still
                    // a recolour.
                    //
                    // Pinned HERE rather than by removing the picker
                    // alone: `prefs.themeMode` defaults to `system`,
                    // so taking the control away without this would
                    // hand every reader on a dark phone a theme they
                    // could no longer turn off.
                    //
                    // To ship it: restore `prefs.themeMode` here AND
                    // uncomment the block in `settings_page.dart`.
                    themeMode: ThemeMode.light,
                    routerDelegate: GoRouterConfig.router.routerDelegate,
                    routeInformationParser:
                        GoRouterConfig.router.routeInformationParser,
                    routeInformationProvider:
                        GoRouterConfig.router.routeInformationProvider,
                    builder: (context, child) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        SystemChrome.setEnabledSystemUIMode(
                          SystemUiMode.edgeToEdge,
                        );
                        SystemChrome.setSystemUIOverlayStyle(
                          SystemUiOverlayStyle(
                            statusBarColor: Colors.transparent,
                            statusBarIconBrightness:
                                themeService.currentBrightnessContrast,
                            systemNavigationBarColor: Colors.black.withValues(
                              alpha: 0.002,
                            ),
                            systemNavigationBarDividerColor: Colors.transparent,
                            systemNavigationBarIconBrightness:
                                themeService.currentBrightnessContrast,
                          ),
                        );
                      });

                      final mq = MediaQuery.of(context);
                      // Top of the builder chain: keeps one WidgetInspector
                      // permanently mounted (debug only) so IDE inspector
                      // toggles can't remount the Router subtree. Pairs with
                      // PersistentWidgetInspector.install() in bootstrap.
                      return PersistentWidgetInspector(
                        // Tap-outside-to-dismiss-focus, app-wide. Without
                        // it a focused field or button keeps focus (and its
                        // keyboard, and its focus ring) until something else
                        // claims it — tapping blank space did nothing.
                        // translucent + a deeper widget winning the arena
                        // means real controls still get their taps; only
                        // taps nothing else wanted land here.
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            final focus = FocusManager.instance.primaryFocus;
                            if (focus?.hasFocus ?? false) focus!.unfocus();
                          },
                          child: MaintenanceGate(
                            child: UpdateGate(
                              child: BuildLockGuard(
                                // Text-scaling MediaQuery sits OUTSIDE the
                                // ConnectivityBanner so that the banner's
                                // status-bar padding override (when active)
                                // doesn't get clobbered by an inner MediaQuery
                                // re-asserting the system padding from a
                                // captured snapshot above the banner.
                                child: ValueListenableBuilder<NotchSide>(
                                  valueListenable: DeviceNotch.sideListenable,
                                  builder: (context, notchSide, banner) =>
                                      MediaQuery(
                                        // Clamp user text scaling so layouts
                                        // can't be pushed past their
                                        // accommodations. Compose the user's
                                        // font-scale preference with the OS
                                        // scaler, then clamp the product.
                                        // 0.8–1.4 covers normal accessibility
                                        // needs; anything beyond breaks rows.
                                        //
                                        // The PADDING is corrected in the same
                                        // place, and once, so that every
                                        // `SafeArea` in the app — ours and an
                                        // adopter's — is handed the truth
                                        // rather than each having to know
                                        // about it. UIKit mirrors the notch
                                        // inset across both landscape edges,
                                        // so the clear side was giving up
                                        // sixty points for a housing that is
                                        // not on it. `DeviceNotch.resolve`
                                        // only ever removes that duplicate,
                                        // and leaves everything alone when it
                                        // does not know which side is which.
                                        data: mq.copyWith(
                                          textScaler: TextScaler.linear(
                                            (mq.textScaler.scale(1.0) *
                                                    prefs.fontScale)
                                                .clamp(0.8, 1.4),
                                          ),
                                          padding: DeviceNotch.resolve(
                                            mq.padding,
                                            notchSide,
                                          ),
                                          viewPadding: DeviceNotch.resolve(
                                            mq.viewPadding,
                                            notchSide,
                                          ),
                                        ),
                                        child: banner!,
                                      ),
                                  child: ConnectivityBanner(
                                    child: BreakpointsProvider(
                                      child: GlobalKeyboardScope(
                                        child: RevealThemeSwitcher(
                                          defaultStrategy:
                                              RevealStrategy.fromKey(
                                                prefs.revealShapeKey,
                                              ),
                                          defaultDirection:
                                              RevealDirection.fromName(
                                                prefs.revealDirectionName,
                                              ),
                                          child: GlobalDebugOverlay(
                                            // NOT `kDebugMode`, which
                                            // is the module's default.
                                            // A tester installs a
                                            // RELEASE apk, and the
                                            // pill is how they read
                                            // the flavor, the host and
                                            // the last request that
                                            // failed. Prod never shows
                                            // it — see
                                            // [Flavor.showDebugOverlay].
                                            enabled: FlavorConfig
                                                .instance
                                                .flavor
                                                .showDebugOverlay,
                                            child: LoadingOverlay(
                                              // ABOVE THE NAVIGATOR —
                                              // the launch reveal's
                                              // second half, which
                                              // opens a transparent
                                              // hole over the real
                                              // destination. The web
                                              // splash is a `z-[100]`
                                              // overlay on an already
                                              // rendered page; this is
                                              // the same position.
                                              // Draws nothing until
                                              // the splash asks. See
                                              // [VesselRevealGate].
                                              child: VesselRevealOverlay(
                                                child: AppRemountScope(
                                                  child:
                                                      child ??
                                                      const SizedBox.shrink(),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }

              return supportsDynamic
                  ? DynamicColorBuilder(builder: mountApp)
                  : mountApp(null, null);
            },
          );
        },
      ),
    );
  }
}
