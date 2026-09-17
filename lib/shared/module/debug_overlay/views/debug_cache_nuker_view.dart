import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../data/api/api_service.dart';
import '../../../../data/stores/debug_overlay_prefs.dart';
import '../../buttons/global_icon_button.dart';
import '../../toast/global_toast.dart';
import '../debug_overlay_models.dart';
import '../widgets/debug_surfaces.dart';

/// Per-store wipes with LIVE contents stats (entry counts / sizes), so
/// a wipe is verifiable — the number drops to zero. Each row confirms
/// before destroying state; "nuke everything" stays red.
class DebugCacheNukerView extends StatefulWidget {
  const DebugCacheNukerView({super.key});

  @override
  State<DebugCacheNukerView> createState() => _DebugCacheNukerViewState();
}

class _DebugCacheNukerViewState extends State<DebugCacheNukerView> {
  /// Mirror of [DebugStorageView]'s manifest — keep in sync.
  static const _kHydratedTokens = <String>[
    'PreferencesCubit',
    'MaintenanceCubit',
    'UpdateCubit',
  ];

  int? _hydratedCount;
  int? _secureCount;
  int? _diskBytes;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    // Hydrated tokens that actually have persisted state.
    var hydrated = 0;
    for (final t in _kHydratedTokens) {
      try {
        if (HydratedBloc.storage.read(t) != null) hydrated++;
      } catch (_) {}
    }
    // Secure storage key count.
    int? secure;
    if (!kIsWeb) {
      try {
        secure = (await const FlutterSecureStorage().readAll()).length;
      } catch (_) {}
    }
    // Disk temp + cache dirs.
    int? disk;
    if (!kIsWeb) {
      try {
        disk = 0;
        for (final dir in await _diskDirs()) {
          disk = disk! + await _dirSize(dir);
        }
      } catch (_) {
        disk = null;
      }
    }
    if (!mounted) return;
    setState(() {
      _hydratedCount = hydrated;
      _secureCount = secure;
      _diskBytes = disk;
    });
  }

  static Future<List<io.Directory>> _diskDirs() async {
    final dirs = <io.Directory>[await getTemporaryDirectory()];
    try {
      dirs.add(await getApplicationCacheDirectory());
    } catch (_) {}
    return dirs;
  }

  static Future<int> _dirSize(io.Directory dir) async {
    var total = 0;
    if (!dir.existsSync()) return 0;
    await for (final e in dir.list(recursive: true, followLinks: false)) {
      if (e is io.File) {
        try {
          total += await e.length();
        } catch (_) {}
      }
    }
    return total;
  }

  static Future<void> _wipeDiskDirs() async {
    for (final dir in await _diskDirs()) {
      if (!dir.existsSync()) continue;
      await for (final e in dir.list(followLinks: false)) {
        try {
          await e.delete(recursive: true);
        } catch (_) {}
      }
    }
  }

  static String _fmtBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final imageCache = PaintingBinding.instance.imageCache;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      children: [
        _FlatSection(
          title: 'Per-store',
          icon: Icons.layers_rounded,
          trailing: GlobalIconButton(
            tooltip: 'Refresh stats',
            enforceMinTouchTarget: false,
            iconData: Icons.refresh_rounded,
            onPressed: _loadStats,
            iconSize: 14,
            style: const ButtonStateStyle(
              width: 28,
              height: 28,
              foregroundColor: DebugOverlayTheme.textDim,
            ),
          ),
          child: _TileGroup(
            children: [
              _Tile(
                icon: Icons.swap_vert_rounded,
                color: const Color(0xFF64B5F6),
                label: 'Dio response cache',
                description: 'In-memory ApiService.cache',
                stat: '${ApiService().cacheEntryCount} entries',
                onTap: () => _confirm(
                  context,
                  title: 'Clear Dio cache?',
                  onConfirm: () async {
                    ApiService().clearCache();
                    GlobalToast.info('Dio cache cleared');
                  },
                ),
              ),
              _Tile(
                icon: Icons.image_rounded,
                color: const Color(0xFF81C784),
                label: 'Image cache',
                description: 'PaintingBinding.imageCache + live images',
                stat:
                    '${imageCache.currentSize} imgs · ${_fmtBytes(imageCache.currentSizeBytes)}',
                onTap: () => _confirm(
                  context,
                  title: 'Clear image cache?',
                  onConfirm: () async {
                    PaintingBinding.instance.imageCache
                      ..clear()
                      ..clearLiveImages();
                    GlobalToast.info('Image cache cleared');
                  },
                ),
              ),
              _Tile(
                icon: Icons.folder_delete_rounded,
                color: const Color(0xFF4FC3F7),
                label: 'Disk temp + cache dirs',
                description: 'tmp/ + app cache directory contents',
                stat: _diskBytes == null ? '…' : _fmtBytes(_diskBytes!),
                onTap: () => _confirm(
                  context,
                  title: 'Wipe disk caches?',
                  body:
                      'Deletes everything under the temp and app-cache '
                      'directories (disk-cached images, staged files).',
                  onConfirm: () async {
                    await _wipeDiskDirs();
                    GlobalToast.info('Disk caches wiped');
                  },
                ),
              ),
              _Tile(
                icon: Icons.storage_rounded,
                color: const Color(0xFFFFA726),
                label: 'HydratedBloc',
                description: 'Wipes every cubit\'s persisted state',
                stat: _hydratedCount == null
                    ? '…'
                    : '$_hydratedCount/${_kHydratedTokens.length} stored',
                onTap: () => _confirm(
                  context,
                  title: 'Wipe HydratedBloc state?',
                  body: 'Every cubit re-hydrates from defaults on next read.',
                  onConfirm: () async {
                    for (final t in _kHydratedTokens) {
                      await HydratedBloc.storage.delete(t);
                    }
                    GlobalToast.warning(
                      'HydratedBloc wiped',
                      description: 'Hot-restart for full effect',
                    );
                  },
                ),
              ),
              _Tile(
                icon: Icons.lock_rounded,
                color: const Color(0xFFEF5350),
                label: 'Secure storage',
                description: 'Auth tokens / encrypted prefs',
                stat: _secureCount == null ? '…' : '$_secureCount keys',
                onTap: () => _confirm(
                  context,
                  title: 'Wipe secure storage?',
                  body: 'Logs the user out next request. Continue?',
                  onConfirm: () async {
                    await const FlutterSecureStorage().deleteAll();
                    GlobalToast.warning('Secure storage wiped');
                  },
                ),
              ),
              _Tile(
                icon: Icons.bug_report_rounded,
                color: DebugOverlayTheme.accent,
                label: 'Debug overlay prefs',
                description: 'Pill/window geometry, pins, recents, sim toggles',
                stat: null,
                onTap: () => _confirm(
                  context,
                  title: 'Reset overlay prefs?',
                  body:
                      'Pill position, pinned tools, recents, density and '
                      'the network/mock sim toggles go back to defaults.',
                  onConfirm: () async {
                    DebugOverlayPrefs.reset();
                    GlobalToast.info('Overlay prefs reset');
                  },
                ),
              ),
            ],
          ),
        ),
        _FlatSection(
          title: 'Nuclear',
          icon: Icons.local_fire_department_rounded,
          child: _TileGroup(
            children: [
              _Tile(
                icon: Icons.delete_forever_rounded,
                color: const Color(0xFFEF5350),
                label: 'Wipe everything',
                description: 'Dio + image + disk + hydrated + secure in one go',
                stat: null,
                onTap: () => _confirm(
                  context,
                  title: 'Wipe ALL caches?',
                  body:
                      'Logs out, clears images + disk caches, resets '
                      'hydrated state. Hot-restart strongly recommended after.',
                  destructive: true,
                  onConfirm: () async {
                    ApiService().clearCache();
                    PaintingBinding.instance.imageCache
                      ..clear()
                      ..clearLiveImages();
                    await _wipeDiskDirs();
                    for (final t in _kHydratedTokens) {
                      await HydratedBloc.storage.delete(t);
                    }
                    await const FlutterSecureStorage().deleteAll();
                    GlobalToast.error(
                      'All caches wiped',
                      description: 'Hot-restart for clean state',
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirm(
    BuildContext context, {
    required String title,
    String? body,
    bool destructive = false,
    required Future<void> Function() onConfirm,
  }) async {
    final ok = await debugConfirmDialog(
      context,
      title: title,
      body: body,
      confirmLabel: 'Wipe',
      destructive: destructive,
    );
    if (ok) {
      await onConfirm();
      // Stats verify the wipe — the numbers drop where it landed.
      await _loadStats();
      if (mounted) setState(() {});
    }
  }
}

// ─────────────────────────────────────────────────────────────

class _FlatSection extends StatelessWidget {
  const _FlatSection({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: DebugOverlayTheme.textDim),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: DebugOverlayTheme.ui.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: DebugOverlayTheme.textDim,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _TileGroup extends StatelessWidget {
  const _TileGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DebugOverlayTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DebugOverlayTheme.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Container(
                height: 1,
                color: DebugOverlayTheme.border.withValues(alpha: 0.5),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.color,
    required this.label,
    required this.description,
    required this.stat,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String description;

  /// Live contents summary — null hides the badge.
  final String? stat;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: DebugOverlayTheme.ui.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      description,
                      style: DebugOverlayTheme.ui.copyWith(
                        fontSize: 10,
                        color: DebugOverlayTheme.textDim,
                      ),
                    ),
                  ],
                ),
              ),
              if (stat != null) ...[
                const SizedBox(width: 8),
                Text(
                  stat!,
                  style: DebugOverlayTheme.mono.copyWith(
                    fontSize: 10,
                    color: DebugOverlayTheme.textDimmer,
                  ),
                ),
              ],
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 15,
                color: DebugOverlayTheme.textDimmer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
