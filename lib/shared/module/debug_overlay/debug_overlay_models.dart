import 'package:flutter/material.dart';

import '../../../core/constants/enums/app/log_level.dart';
import '../../../core/flavor/flavor_config.dart';

/// Developer tools exposed by the overlay — each gets a card on the home
/// hub and a dedicated full-panel view when tapped.
/// Bucket a [DevTool] belongs to on the home hub. Lets the list grow
/// past a flat scroll without losing scannability — devs typically know
/// whether they need a *diagnostic* read-out or a *simulator* before
/// they know which exact tool.
enum DevToolCategory {
  diagnostics(label: 'Diagnostics'),
  simulators(label: 'Simulators'),
  actions(label: 'Quick actions');

  const DevToolCategory({required this.label});

  final String label;
}

enum DevTool {
  logs(
    label: 'Logs',
    icon: Icons.terminal_rounded,
    description: 'Live console — filter, search, copy, multi-select',
    category: DevToolCategory.diagnostics,
  ),
  network(
    label: 'Network',
    icon: Icons.swap_vert_rounded,
    description: 'Recent HTTP requests — status, timing, headers, body',
    category: DevToolCategory.diagnostics,
  ),
  env(
    label: 'Environment',
    icon: Icons.dns_rounded,
    description: 'Flavor, .env, Remote Config — resolved values + sources',
    category: DevToolCategory.diagnostics,
  ),
  buildInfo(
    label: 'Build info',
    icon: Icons.info_outline_rounded,
    description: 'Version, platform, dart-defines — copyable bug-report blob',
    category: DevToolCategory.diagnostics,
  ),
  storage(
    label: 'Storage',
    icon: Icons.folder_open_rounded,
    description: 'HydratedBloc cubits + secure storage — read/clear',
    category: DevToolCategory.diagnostics,
  ),
  routeHistory(
    label: 'Route history',
    icon: Icons.route_rounded,
    description: 'Last 50 navigation events — tap to re-go',
    category: DevToolCategory.diagnostics,
  ),
  connectivitySim(
    label: 'Connectivity',
    icon: Icons.network_check_rounded,
    description: 'Force online/offline/VPN states to drive gates + banners',
    category: DevToolCategory.simulators,
  ),
  crashInjector(
    label: 'Crash injector',
    icon: Icons.bug_report_rounded,
    description: 'Fire log levels + throws to verify reporting pipeline',
    category: DevToolCategory.simulators,
  ),
  rcOverrides(
    label: 'RC overrides',
    icon: Icons.toggle_on_rounded,
    description:
        'Override Remote Config keys at runtime — no Firebase round-trip',
    category: DevToolCategory.simulators,
  ),
  updateGateSim(
    label: 'Update gate',
    icon: Icons.system_update_alt_rounded,
    description: 'Force min/latest version to drive the update flows',
    category: DevToolCategory.simulators,
  ),
  themeQuick(
    label: 'Theme & locale',
    icon: Icons.palette_outlined,
    description: 'Theme mode, role, saturation, font scale, language',
    category: DevToolCategory.actions,
  ),
  perf(
    label: 'Performance',
    icon: Icons.speed_rounded,
    description: 'Frame overlay, raster cache checkers, image cache stats',
    category: DevToolCategory.actions,
  ),
  uiLab(
    label: 'UI lab',
    icon: Icons.science_rounded,
    description: 'Fire toasts, snackbars, loading variants for visual QA',
    category: DevToolCategory.actions,
  ),
  deepLinks(
    label: 'Deep links',
    icon: Icons.link_rounded,
    description: 'Paste a URL/path → GoRouter.go, with recent history',
    category: DevToolCategory.actions,
  ),
  // ─── Inspectors (diagnostics) ─────────────────────────────
  auth(
    label: 'Auth',
    icon: Icons.lock_person_rounded,
    description: 'Token, expiry, user — refresh / logout / force 401',
    category: DevToolCategory.diagnostics,
  ),
  blocs(
    label: 'Bloc state',
    icon: Icons.timeline_rounded,
    description: 'Live state + transition history per registered bloc',
    category: DevToolCategory.diagnostics,
  ),
  permissions(
    label: 'Permissions',
    icon: Icons.verified_user_rounded,
    description:
        'Camera, mic, location, notifications — request / open settings',
    category: DevToolCategory.diagnostics,
  ),
  themeTokens(
    label: 'Theme tokens',
    icon: Icons.palette_rounded,
    description: 'Resolved ColorScheme, AppPalette, AppTokens — copy hex',
    category: DevToolCategory.diagnostics,
  ),
  l10n(
    label: 'Localization',
    icon: Icons.translate_rounded,
    description: 'Locale + ARB keys per language — search, missing-key audit',
    category: DevToolCategory.diagnostics,
  ),
  serviceLocator(
    label: 'Service locator',
    icon: Icons.account_tree_rounded,
    description: 'Every getIt registration — type, lazy/eager, resolved',
    category: DevToolCategory.diagnostics,
  ),
  frameTimeline(
    label: 'Frame timeline',
    icon: Icons.timeline_outlined,
    description: 'Last 60 frame timings — sparkline + p95/max',
    category: DevToolCategory.diagnostics,
  ),
  timeline(
    label: 'Session timeline',
    icon: Icons.view_timeline_rounded,
    description: 'Nav + bloc + network + warnings merged chronologically',
    category: DevToolCategory.diagnostics,
  ),
  assets(
    label: 'Assets',
    icon: Icons.collections_rounded,
    description: 'Image / SVG / Lottie / fonts catalog with previews',
    category: DevToolCategory.diagnostics,
  ),
  // ─── Simulators ───────────────────────────────────────────
  mockToggle(
    label: 'Mock mode',
    icon: Icons.cloud_off_rounded,
    description: 'Force ApiService to serve mocks instead of network',
    category: DevToolCategory.simulators,
  ),
  networkSim(
    label: 'Network sim',
    icon: Icons.speed_outlined,
    description: 'Inject latency + force per-Nth request to fail',
    category: DevToolCategory.simulators,
  ),
  maintenanceSim(
    label: 'Maintenance',
    icon: Icons.engineering_rounded,
    description: 'Force the maintenance gate with custom title / ETA / URL',
    category: DevToolCategory.simulators,
  ),
  buildLockBypass(
    label: 'Build-lock bypass',
    icon: Icons.lock_open_rounded,
    description: 'Skip the staging/uat password gate this session',
    category: DevToolCategory.simulators,
  ),
  scenarios(
    label: 'Scenarios',
    icon: Icons.bookmarks_rounded,
    description:
        'Save / apply named sets of overrides — offline QA, demo mode…',
    category: DevToolCategory.simulators,
  ),
  // ─── Quick actions ────────────────────────────────────────
  cacheNuker(
    label: 'Caches',
    icon: Icons.delete_forever_rounded,
    description: 'Wipe Dio / image / hydrated / secure storage in one tap',
    category: DevToolCategory.actions,
  ),
  onboardingReset(
    label: 'Onboarding',
    icon: Icons.restart_alt_rounded,
    description:
        'Force show / skip onboarding, or flip the persisted seen flag',
    category: DevToolCategory.actions,
  ),
  routeJumper(
    label: 'Route jumper',
    icon: Icons.alt_route_rounded,
    description:
        'Pick any defined route, fill path params + JSON extras, choose push mode',
    category: DevToolCategory.actions,
  ),
  splash(
    label: 'Splash',
    icon: Icons.bolt_rounded,
    description: 'Force hold / skip the splash gate without restarting',
    category: DevToolCategory.actions,
  ),
  devicePreview(
    label: 'Device preview',
    icon: Icons.smartphone_rounded,
    description: 'Toggle the DevicePreview wrapper without restarting',
    category: DevToolCategory.actions,
  ),
  clipboard(
    label: 'Clipboard',
    icon: Icons.content_paste_rounded,
    description: 'Inspect, edit or clear the system clipboard',
    category: DevToolCategory.actions,
  ),
  settings(
    label: 'Settings',
    icon: Icons.tune_rounded,
    description: 'Logger & overlay configuration',
    category: DevToolCategory.actions,
  );

  const DevTool({
    required this.label,
    required this.icon,
    required this.description,
    required this.category,
  });

  final String label;
  final IconData icon;
  final String description;
  final DevToolCategory category;
}

/// Visual palette for the debug overlay. Intentionally independent of the
/// app's theme so the tool stays recognizable over any surface.
class DebugOverlayTheme {
  DebugOverlayTheme._();

  // ─── Surfaces ────────────────────────────────────────────────
  static const bg = Color(0xFF0B0B0E);
  static const surface = Color(0xFF15161B);
  static const surfaceHigh = Color(0xFF1E2028);
  static const surfaceHigher = Color(0xFF262932);

  // ─── Accents & text ──────────────────────────────────────────
  /// Fallback when [FlavorConfig] hasn't been set yet (e.g. very early
  /// boot, unit tests). Production paths see flavor color via [accent].
  static const accentDefault = Color(0xFF00E5FF);
  static const accentMuted = Color(0xFF0099B3);
  static const text = Color(0xFFEFEFF2);
  static const textDim = Color(0xFF8A8D96);
  static const textDimmer = Color(0xFF4F525C);
  static const border = Color(0xFF2A2D36);

  /// Active accent — flavor color when bootstrap has run, else the
  /// cyan fallback. Reads through to [FlavorConfig.maybeInstance] so
  /// the overlay reinforces "you are not in prod" inside every view.
  static Color get accent =>
      FlavorConfig.maybeInstance?.flavor.bannerColor ?? accentDefault;

  /// One hue per tool category — home grid + pinned strip scan by color.
  static Color categoryColor(DevToolCategory c) => switch (c) {
    DevToolCategory.diagnostics => const Color(0xFF4FC3F7),
    DevToolCategory.simulators => const Color(0xFFFFA726),
    DevToolCategory.actions => const Color(0xFF66BB6A),
  };

  // ─── Level colors ────────────────────────────────────────────
  static Color levelColor(LogLevel level) => switch (level) {
    LogLevel.trace => const Color(0xFF6B6F79),
    LogLevel.debug => const Color(0xFF4FC3F7),
    LogLevel.info => const Color(0xFF66BB6A),
    LogLevel.warning => const Color(0xFFFFA726),
    LogLevel.error => const Color(0xFFEF5350),
    LogLevel.fatal => const Color(0xFFAB47BC),
  };

  // ─── Typography ──────────────────────────────────────────────
  // The whole overlay is a developer tool, so everything renders in
  // Menlo (with a sensible cross-platform fallback chain). [ui] is the
  // default UI text style, [mono] is the same family at a tighter size
  // for log content and other code-shaped data.
  /// Single source of truth for the overlay's font family. Every
  /// overlay-scoped text widget — including the floating pill — reads
  /// from here so there's no `'monospace'` / `'Menlo'` drift.
  static const kFont = 'Menlo';
  static const kFontFallback = <String>[
    'Monaco',
    'Consolas',
    'Courier',
    'monospace',
  ];

  static const TextStyle ui = TextStyle(
    color: text,
    fontSize: 12.5,
    letterSpacing: -0.1,
    height: 1.3,
    fontFamily: kFont,
    fontFamilyFallback: kFontFallback,
  );

  static const TextStyle mono = TextStyle(
    color: text,
    fontSize: 11.5,
    fontFamily: kFont,
    fontFamilyFallback: kFontFallback,
    height: 1.35,
  );
}

/// FAB dimensions & panel geometry.
const double kDebugFabSize = 48;
const double kDebugPanelHeightRatio = 0.85;
