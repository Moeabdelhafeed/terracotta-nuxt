import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/env/env.dart';
import '../../../../core/flavor/flavor.dart';
import '../../../../core/flavor/flavor_config.dart';
import '../../../../data/services/remote_config_service.dart';
import '../../toast/global_toast.dart';
import '../global_debug_overlay.dart';

/// Environment diagnostics — flavor / .env / Remote Config snapshot.
///
/// Tap any row to copy the RAW value (masked secrets copy the real
/// thing). RC rows show a layer chip for the source that supplied the
/// value; values are read BEFORE the source snapshot so the chips
/// reflect this very render, and the view re-renders live when
/// overrides change.
class DebugEnvView extends StatefulWidget {
  const DebugEnvView({super.key});

  @override
  State<DebugEnvView> createState() => _DebugEnvViewState();
}

class _DebugEnvViewState extends State<DebugEnvView> {
  StreamSubscription<void>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = RemoteConfigService.overrideChanges.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = FlavorConfig.maybeInstance;
    final flavor = config?.flavor;

    final flavorRows = <_RowData>[
      if (config != null && flavor != null) ...[
        _RowData('flavor', flavor.name),
        _RowData('displayName', flavor.displayName),
        _RowData(
          'apiBaseUrl',
          config.apiBaseUrl.isEmpty ? '<unset>' : config.apiBaseUrl,
        ),
        _RowData('apiTimeoutSeconds', '${config.apiTimeoutSeconds}'),
        _RowData('enableLogs', '${config.enableLogs}'),
        _RowData('useRemoteTranslations', '${config.useRemoteTranslations}'),
        _RowData('requiresBuildLock', '${flavor.requiresBuildLock}'),
        _RowData(
          'buildLockHash',
          _mask(config.buildLockHash),
          copyValue: config.buildLockHash,
        ),
        _RowData(
          'missingFields',
          config.missingRequiredFields.isEmpty
              ? '<none>'
              : config.missingRequiredFields.join(', '),
          warn: config.missingRequiredFields.isNotEmpty,
        ),
      ] else
        const _RowData('flavor', '<not initialized>'),
    ];

    final envRows = <_RowData>[
      _RowData(
        'API_BASE_URL',
        Env.apiBaseUrl.isEmpty ? '<unset>' : Env.apiBaseUrl,
      ),
      _RowData('API_X_TOKEN', _mask(Env.apiXToken), copyValue: Env.apiXToken),
      _RowData(
        'MAPS_HTTP_API_KEY',
        _mask(Env.mapsHttpApiKey),
        copyValue: Env.mapsHttpApiKey,
      ),
      _RowData(
        'MAPS_NATIVE_API_KEY',
        _mask(Env.mapsNativeApiKey),
        copyValue: Env.mapsNativeApiKey,
      ),
      _RowData(
        'SUPPORT_EMAIL',
        Env.supportEmail.isEmpty ? '<unset>' : Env.supportEmail,
      ),
      _RowData(
        'WEBSITE_URL',
        Env.websiteUrl.isEmpty ? '<unset>' : Env.websiteUrl,
      ),
      _RowData(
        'FEEDBACK_ENDPOINT',
        Env.feedbackEndpoint.isEmpty ? '<unset>' : Env.feedbackEndpoint,
      ),
      _RowData(
        'FCM_VAPID_KEY',
        _mask(Env.fcmVapidKey),
        copyValue: Env.fcmVapidKey,
      ),
    ];

    // Read every RC value FIRST — the resolvers record their winning
    // layer lazily, so snapshotting sources before the reads shows
    // last render's chips (or none on first open).
    final rcValues = <(String, String, String?)>[
      (
        'x_api_token',
        _mask(RemoteConfigService.apiToken),
        RemoteConfigService.apiToken,
      ),
      (
        'base_url',
        RemoteConfigService.baseUrl.isEmpty
            ? '<unset>'
            : RemoteConfigService.baseUrl,
        null,
      ),
      (
        'maps_http_api_key',
        _mask(RemoteConfigService.mapsHttpApiKey),
        RemoteConfigService.mapsHttpApiKey,
      ),
      (
        'feedback_endpoint',
        RemoteConfigService.feedbackEndpoint.isEmpty
            ? '<unset>'
            : RemoteConfigService.feedbackEndpoint,
        null,
      ),
      (
        'feedback_support_email',
        RemoteConfigService.feedbackSupportEmail.isEmpty
            ? '<unset>'
            : RemoteConfigService.feedbackSupportEmail,
        null,
      ),
      ('feedback_enabled', '${RemoteConfigService.feedbackEnabled}', null),
      ('onboarding_enabled', '${RemoteConfigService.onboardingEnabled}', null),
      ('maintenance_mode', '${RemoteConfigService.maintenanceMode}', null),
      ('legal_source_mode', RemoteConfigService.legalSourceMode, null),
      (
        'connectivity_probe_url',
        RemoteConfigService.connectivityProbeUrl,
        null,
      ),
    ];
    final sources = RemoteConfigService.lastSourceSnapshot;
    final rcRows = <_RowData>[
      for (final (key, display, copy) in rcValues)
        _RowData(key, display, copyValue: copy, source: sources[key]),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      children: [
        if (flavor != null) _FlavorHero(flavor: flavor, config: config!),
        const SizedBox(height: 14),
        _Section(
          title: 'Flavor',
          icon: Icons.flag_rounded,
          color: const Color(0xFFFFA726),
          rows: flavorRows,
        ),
        _Section(
          title: '.env (compile-time)',
          icon: Icons.lock_rounded,
          color: const Color(0xFF81C784),
          rows: envRows,
        ),
        _Section(
          title: 'Remote Config (runtime)',
          icon: Icons.cloud_rounded,
          color: const Color(0xFF64B5F6),
          rows: rcRows,
        ),
        // Editing lives in the RC overrides tool.
        Material(
          color: DebugOverlayTheme.surface,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () => DebugOverlayController.openTool(DevTool.rcOverrides),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: DebugOverlayTheme.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: DebugOverlayTheme.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      size: 14,
                      color: DebugOverlayTheme.accentDefault,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Override a value',
                          style: DebugOverlayTheme.ui.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'RC overrides tool — flip any key at runtime',
                          style: DebugOverlayTheme.ui.copyWith(
                            fontSize: 10,
                            color: DebugOverlayTheme.textDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 15,
                    color: DebugOverlayTheme.textDimmer,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _mask(String value) {
    if (value.isEmpty) return '<unset>';
    if (value.length <= 8) return '••••';
    return '${value.substring(0, 4)}•••${value.substring(value.length - 4)}';
  }
}

// ─────────────────────────────────────────────────────────────

class _RowData {
  const _RowData(
    this.label,
    this.value, {
    this.copyValue,
    this.source,
    this.warn = false,
  });

  final String label;
  final String value;

  /// Raw value copied on tap — display may be masked.
  final String? copyValue;
  final EnvSource? source;
  final bool warn;
}

class _FlavorHero extends StatelessWidget {
  const _FlavorHero({required this.flavor, required this.config});

  final Flavor flavor;
  final FlavorConfig config;

  @override
  Widget build(BuildContext context) {
    final color = flavor.bannerColor;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.flag_rounded, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  flavor.displayName.toUpperCase(),
                  style: DebugOverlayTheme.mono.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  config.apiBaseUrl.isEmpty
                      ? 'No API base URL configured.'
                      : config.apiBaseUrl,
                  overflow: TextOverflow.ellipsis,
                  style: DebugOverlayTheme.mono.copyWith(
                    fontSize: 10.5,
                    color: DebugOverlayTheme.textDim,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.color,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<_RowData> rows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 12, color: color),
              ),
              const SizedBox(width: 7),
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
          Container(
            decoration: BoxDecoration(
              color: DebugOverlayTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: DebugOverlayTheme.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0)
                    Container(
                      height: 1,
                      color: DebugOverlayTheme.border.withValues(alpha: 0.5),
                    ),
                  _KvRow(data: rows[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KvRow extends StatelessWidget {
  const _KvRow({required this.data});

  final _RowData data;

  @override
  Widget build(BuildContext context) {
    final dim = data.value.startsWith('<') && data.value.endsWith('>');
    final copyable = data.copyValue ?? (dim ? '' : data.value);
    return InkWell(
      onTap: copyable.isEmpty
          ? null
          : () {
              Clipboard.setData(ClipboardData(text: copyable));
              GlobalToast.info('${data.label} copied');
            },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(
                data.label,
                style: DebugOverlayTheme.mono.copyWith(
                  fontSize: 11,
                  color: DebugOverlayTheme.textDim,
                ),
              ),
            ),
            Expanded(
              child: Text(
                data.value,
                style: DebugOverlayTheme.mono.copyWith(
                  fontSize: 11,
                  fontWeight: data.warn ? FontWeight.w700 : FontWeight.w400,
                  color: data.warn
                      ? const Color(0xFFFFA726)
                      : dim
                      ? DebugOverlayTheme.textDimmer
                      : DebugOverlayTheme.text,
                ),
              ),
            ),
            if (data.source != null) ...[
              const SizedBox(width: 8),
              _SourceChip(source: data.source!),
            ],
            if (copyable.isNotEmpty) ...[
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.copy_rounded,
                  size: 11,
                  color: DebugOverlayTheme.textDimmer,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.source});

  final EnvSource source;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (source) {
      EnvSource.override => ('OVR', const Color(0xFFE57373)),
      EnvSource.remoteConfig => ('RC', const Color(0xFF64B5F6)),
      EnvSource.flavorConfig => ('flavor', const Color(0xFF9575CD)),
      EnvSource.dotenv => ('.env', const Color(0xFF81C784)),
      EnvSource.hardcoded => ('hard', const Color(0xFFFFB74D)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontFamily: DebugOverlayTheme.kFont,
          fontFamilyFallback: DebugOverlayTheme.kFontFallback,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
