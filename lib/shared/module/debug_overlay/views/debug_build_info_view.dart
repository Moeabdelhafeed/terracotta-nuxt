import 'dart:io' as io;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/devtools/network_capture.dart';
import '../../../../core/flavor/flavor_config.dart';
import '../../../../core/utils/loggers/log_buffer.dart';
import '../../../../data/services/remote_config_service.dart';
import '../../toast/global_toast.dart';
import '../debug_overlay_models.dart';
import '../dev_tool_status.dart';

/// One-screen reference: app + flavor + device + platform + runtime.
/// Tap any row to copy its value; "copy all" renders a markdown blob
/// for bug reports / chat threads / issue tickets.
class DebugBuildInfoView extends StatefulWidget {
  const DebugBuildInfoView({super.key});

  @override
  State<DebugBuildInfoView> createState() => _DebugBuildInfoViewState();
}

class _DebugBuildInfoViewState extends State<DebugBuildInfoView> {
  PackageInfo? _packageInfo;
  List<(String, String)> _deviceRows = const [('device', '<loading…>')];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _packageInfo = info);
    } catch (_) {
      // Tests / non-platform contexts — skip silently.
    }
    try {
      final rows = await _loadDeviceRows();
      if (mounted) setState(() => _deviceRows = rows);
    } catch (_) {
      if (mounted) {
        setState(() => _deviceRows = const [('device', '<unavailable>')]);
      }
    }
  }

  static Future<List<(String, String)>> _loadDeviceRows() async {
    final plugin = DeviceInfoPlugin();
    if (kIsWeb) {
      final w = await plugin.webBrowserInfo;
      return [
        ('browser', w.browserName.name),
        ('userAgent', w.userAgent ?? '<unknown>'),
      ];
    }
    if (io.Platform.isIOS) {
      final i = await plugin.iosInfo;
      return [
        ('model', i.utsname.machine),
        ('name', i.name),
        ('system', '${i.systemName} ${i.systemVersion}'),
        ('physicalDevice', '${i.isPhysicalDevice}'),
      ];
    }
    if (io.Platform.isAndroid) {
      final a = await plugin.androidInfo;
      return [
        ('model', '${a.manufacturer} ${a.model}'),
        ('android', '${a.version.release} (SDK ${a.version.sdkInt})'),
        ('board', a.board),
        ('physicalDevice', '${a.isPhysicalDevice}'),
      ];
    }
    if (io.Platform.isMacOS) {
      final m = await plugin.macOsInfo;
      return [
        ('model', m.model),
        ('macOS', m.osRelease),
        ('arch', m.arch),
      ];
    }
    return [('platform', io.Platform.operatingSystem)];
  }

  @override
  Widget build(BuildContext context) {
    final flavor = FlavorConfig.maybeInstance?.flavor;
    final config = FlavorConfig.maybeInstance;
    final p = _packageInfo;

    final appRows = <(String, String)>[
      if (p != null) ...[
        ('appName', p.appName),
        ('package', p.packageName),
        ('version', '${p.version}+${p.buildNumber}'),
        if (p.buildSignature.isNotEmpty) ('buildSignature', p.buildSignature),
        if (p.installerStore != null) ('installerStore', p.installerStore!),
      ] else
        ('packageInfo', '<loading…>'),
    ];

    final missing = config?.missingRequiredFields ?? const [];
    final flavorRows = <(String, String)>[
      if (flavor != null && config != null) ...[
        ('flavor', flavor.name),
        ('displayName', flavor.displayName),
        (
          'apiBaseUrl',
          config.apiBaseUrl.isEmpty ? '<unset>' : config.apiBaseUrl,
        ),
        ('apiTimeoutSeconds', '${config.apiTimeoutSeconds}'),
        ('enableLogs', '${config.enableLogs}'),
        ('useRemoteTranslations', '${config.useRemoteTranslations}'),
        ('requiresBuildLock', '${flavor.requiresBuildLock}'),
        ('missingFields', missing.isEmpty ? '<none>' : missing.join(', ')),
      ] else
        ('flavor', '<not initialized>'),
    ];

    final mq = MediaQuery.of(context);
    final platformRows = <(String, String)>[
      ('platform', defaultTargetPlatform.name),
      ('isWeb', '$kIsWeb'),
      if (!kIsWeb) ...[
        ('os', io.Platform.operatingSystem),
        ('osVersion', io.Platform.operatingSystemVersion),
        ('locale', io.Platform.localeName),
        ('cores', '${io.Platform.numberOfProcessors}'),
      ],
      (
        'screenSize',
        '${mq.size.width.toStringAsFixed(0)} × '
            '${mq.size.height.toStringAsFixed(0)} '
            '@${mq.devicePixelRatio}x',
      ),
      (
        'safeArea',
        'top=${mq.padding.top.toStringAsFixed(0)} '
            'bottom=${mq.padding.bottom.toStringAsFixed(0)}',
      ),
      ('textScale', mq.textScaler.scale(1.0).toStringAsFixed(2)),
      ('orientation', mq.orientation.name),
      ('platformBrightness', mq.platformBrightness.name),
    ];

    final runtimeRows = <(String, String)>[
      ('flutterMode', _flutterMode),
      ('dartVersion', _dartVersionLine),
    ];

    final sections = <(String, IconData, Color, List<(String, String)>)>[
      ('App', Icons.apps_rounded, const Color(0xFF66BB6A), appRows),
      ('Flavor', Icons.flag_rounded, const Color(0xFFFFA726), flavorRows),
      (
        'Device',
        Icons.smartphone_rounded,
        const Color(0xFF4FC3F7),
        _deviceRows,
      ),
      (
        'Platform',
        Icons.devices_rounded,
        const Color(0xFF64B5F6),
        platformRows,
      ),
      ('Runtime', Icons.memory_rounded, const Color(0xFFBA68C8), runtimeRows),
    ];

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 80),
          children: [
            for (final (title, icon, color, rows) in sections)
              _Section(
                title: title,
                icon: icon,
                color: color,
                rows: rows,
                warnValues: title == 'Flavor' && missing.isNotEmpty
                    ? {missing.join(', ')}
                    : const {},
              ),
          ],
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.copy_rounded,
                  label: 'Copy markdown',
                  onTap: () {
                    final blob = _buildMarkdownBlob(sections);
                    Clipboard.setData(ClipboardData(text: blob));
                    GlobalToast.info('Build info copied as markdown');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.medical_services_rounded,
                  label: 'Share diagnostics',
                  onTap: () => _shareDiagnostics(sections),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Constant runtime info ─────────────────────────────────

  static String get _flutterMode {
    if (kReleaseMode) return 'release';
    if (kProfileMode) return 'profile';
    return 'debug';
  }

  /// `Platform.version` returns a verbose string like
  /// "3.5.0 (stable) (Mon Jul 29 ...) ...". We grab the first segment.
  static String get _dartVersionLine {
    if (kIsWeb) return '<web>';
    final v = io.Platform.version;
    final paren = v.indexOf(' ');
    return paren < 0 ? v : v.substring(0, paren);
  }

  static String _buildMarkdownBlob(
    List<(String, IconData, Color, List<(String, String)>)> sections,
  ) {
    final buf = StringBuffer('# Build info\n\n');
    for (final (title, _, _, rows) in sections) {
      buf.writeln('## $title\n');
      for (final (label, value) in rows) {
        buf.writeln('- **$label**: $value');
      }
      buf.writeln();
    }
    return buf.toString().trimRight();
  }

  /// Full bug-report bundle: build info + active overrides + recent
  /// logs + network summary, written to a temp .md and pushed through
  /// the share sheet — one attachment for a ticket or chat thread.
  static Future<void> _shareDiagnostics(
    List<(String, IconData, Color, List<(String, String)>)> sections,
  ) async {
    try {
      final buf = StringBuffer(_buildMarkdownBlob(sections))..writeln('\n');

      buf.writeln('## Active overrides\n');
      final active = DevToolStatus.active();
      if (active.isEmpty) {
        buf.writeln('- none');
      } else {
        for (final t in active) {
          buf.writeln('- ${t.label}');
        }
      }
      final overrides = RemoteConfigService.overrides;
      if (overrides.isNotEmpty) {
        buf.writeln('\n### RC overrides\n');
        for (final e in overrides.entries) {
          buf.writeln('- `${e.key}` = `${e.value}`');
        }
      }

      buf.writeln('\n## Network (last 20)\n');
      final captures = NetworkCapture.entries.take(20).toList();
      if (captures.isEmpty) {
        buf.writeln('- none captured');
      } else {
        for (final e in captures) {
          final status = e.statusCode?.toString() ?? e.errorType ?? '…';
          final ms = e.duration?.inMilliseconds;
          buf.writeln(
            '- `${e.method}` ${e.url} → $status${ms == null ? '' : ' (${ms}ms)'}',
          );
        }
      }

      buf.writeln('\n## Logs (last 200)\n\n```');
      buf.writeln(LogBuffer.recentPlain(count: 200));
      buf.writeln('```');

      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final file = io.File('${dir.path}/diagnostics-$stamp.md');
      await file.writeAsString(buf.toString());
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } catch (e) {
      GlobalToast.error('Diagnostics export failed', description: '$e');
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Section + row widgets
// ─────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.color,
    required this.rows,
    this.warnValues = const {},
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<(String, String)> rows;

  /// Values rendered amber (e.g. missing required flavor fields).
  final Set<String> warnValues;

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
                  _KvRow(
                    label: rows[i].$1,
                    value: rows[i].$2,
                    warn: warnValues.contains(rows[i].$2),
                  ),
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
  const _KvRow({
    required this.label,
    required this.value,
    this.warn = false,
  });

  final String label;
  final String value;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final dim = value.startsWith('<') && value.endsWith('>');
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        GlobalToast.info('$label copied');
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(
                label,
                style: DebugOverlayTheme.mono.copyWith(
                  fontSize: 11,
                  color: DebugOverlayTheme.textDim,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: DebugOverlayTheme.mono.copyWith(
                  fontSize: 11,
                  color: warn
                      ? const Color(0xFFFFA726)
                      : dim
                      ? DebugOverlayTheme.textDimmer
                      : DebugOverlayTheme.text,
                  fontWeight: warn ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
            const Icon(
              Icons.copy_rounded,
              size: 11,
              color: DebugOverlayTheme.textDimmer,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DebugOverlayTheme.accent,
      borderRadius: BorderRadius.circular(10),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: Colors.black87),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                    fontFamily: DebugOverlayTheme.kFont,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
