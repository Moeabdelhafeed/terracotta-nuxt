import 'dart:async';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../buttons/global_icon_button.dart';
import '../../dialog/global_dialog.dart';
import '../../toast/global_toast.dart';
import '../debug_overlay_models.dart';
import '../widgets/debug_search_field.dart';
import '../widgets/debug_surfaces.dart';

/// Enumerates every bundled asset via [AssetManifest], segmented into
/// collapsible per-folder sections (the pubspec `assets:` layout maps
/// 1:1 to folders). Kind chips + path search filter across all
/// sections; tap a row to preview (image / SVG / Lottie / file).
class DebugAssetsView extends StatefulWidget {
  const DebugAssetsView({super.key});

  @override
  State<DebugAssetsView> createState() => _DebugAssetsViewState();
}

class _DebugAssetsViewState extends State<DebugAssetsView> {
  List<String> _all = [];
  bool _loading = true;
  String? _filter;
  String _query = '';
  bool _sortBySize = false;
  final _searchCtrl = TextEditingController();
  final Set<String> _collapsed = {};

  /// Logical key → its density variants (1x/2x/3x file entries).
  Map<String, List<AssetMetadata>> _variants = {};

  /// FILE path → byte size, filled progressively after mount (loading
  /// every asset's bytes once — debug-only cost, cached for the session).
  final Map<String, int> _sizes = {};
  bool _sizesReady = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // AssetManifest.json was removed from builds (Flutter 3.10+ ships
      // a binary manifest) — loadString on it throws and the page came
      // up empty. AssetManifest is the supported accessor.
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _all = manifest.listAssets().toList()..sort();
      _variants = {
        for (final key in _all) key: manifest.getAssetVariants(key) ?? const [],
      };
    } catch (_) {
      _all = const [];
      _variants = const {};
    }
    if (!mounted) return;
    setState(() => _loading = false);
    unawaited(_loadSizes());
  }

  /// Every FILE the bundle carries for [key] — the main entry plus its
  /// density variants (deduped: the main asset appears in its own
  /// variant list on some setups).
  Iterable<String> _filesOf(String key) {
    final paths = <String>{
      key,
      for (final v in _variants[key] ?? const <AssetMetadata>[]) v.key,
    };
    return paths;
  }

  Future<void> _loadSizes() async {
    var sinceFlush = 0;
    for (final key in List<String>.from(_all)) {
      if (!mounted) return;
      for (final path in _filesOf(key)) {
        if (_sizes.containsKey(path)) continue;
        try {
          final data = await rootBundle.load(path);
          _sizes[path] = data.lengthInBytes;
        } catch (_) {
          _sizes[path] = 0;
        }
        sinceFlush++;
      }
      if (sinceFlush >= 25) {
        sinceFlush = 0;
        if (mounted) setState(() {});
      }
    }
    if (mounted) setState(() => _sizesReady = true);
  }

  /// Total bundle weight of a logical asset incl. density variants.
  /// Null while its sizes are still loading.
  int? _logicalSize(String key) {
    var total = 0;
    for (final path in _filesOf(key)) {
      final s = _sizes[path];
      if (s == null) return null;
      total += s;
    }
    return total;
  }

  static String _fmtBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(bytes < 10 * 1024 ? 1 : 0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: DebugOverlayTheme.accent,
          ),
        ),
      );
    }

    final kindCounts = <String, int>{};
    for (final p in _all) {
      kindCounts.update(_kind(p), (v) => v + 1, ifAbsent: () => 1);
    }
    final q = _query.trim().toLowerCase();
    // Any active narrowing (text OR kind chip) force-expands sections —
    // a filtered view with collapsed folders reads as "no results".
    final narrowing = q.isNotEmpty || _filter != null;
    final shown = _all.where((p) {
      if (_filter != null && _kind(p) != _filter) return false;
      if (q.isEmpty) return true;
      return p.toLowerCase().contains(q);
    }).toList();

    // Segment by containing folder — mirrors the pubspec assets layout.
    final byFolder = <String, List<String>>{};
    for (final p in shown) {
      byFolder.putIfAbsent(_folderOf(p), () => []).add(p);
    }
    int folderSize(String f) =>
        byFolder[f]!.fold(0, (sum, p) => sum + (_logicalSize(p) ?? 0));
    final folders = byFolder.keys.toList()..sort();
    if (_sortBySize && _sizesReady) {
      folders.sort((a, b) => folderSize(b).compareTo(folderSize(a)));
      for (final f in folders) {
        byFolder[f]!.sort(
          (a, b) => (_logicalSize(b) ?? 0).compareTo(_logicalSize(a) ?? 0),
        );
      }
    }
    final grandTotal = _all.fold<int>(
      0,
      (sum, p) => sum + (_logicalSize(p) ?? 0),
    );

    return Column(
      children: [
        _Header(
          counts: kindCounts,
          selected: _filter,
          onSelect: (k) => setState(() => _filter = _filter == k ? null : k),
        ),
        // Bundle summary + sort-by-size toggle.
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_all.length} assets · ${byFolder.length} folders · '
                  '${_sizesReady ? _fmtBytes(grandTotal) : 'sizing…'}',
                  style: DebugOverlayTheme.ui.copyWith(
                    fontSize: 10.5,
                    color: DebugOverlayTheme.textDim,
                  ),
                ),
              ),
              GlobalIconButton(
                enforceMinTouchTarget: false,
                tooltip: _sortBySize ? 'Sort alphabetically' : 'Sort by size',
                iconData: Icons.swap_vert_rounded,
                onPressed: _sizesReady
                    ? () => setState(() => _sortBySize = !_sortBySize)
                    : null,
                iconSize: 14,
                style: ButtonStateStyle(
                  width: 28,
                  height: 28,
                  foregroundColor: _sortBySize
                      ? DebugOverlayTheme.accent
                      : DebugOverlayTheme.textDim,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: DebugSearchField(
            controller: _searchCtrl,
            hintText: 'Filter path',
            resultCount: q.isNotEmpty ? shown.length : null,
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            itemCount: folders.length,
            itemBuilder: (_, fi) {
              final folder = folders[fi];
              final paths = byFolder[folder]!;
              final isCollapsed = !narrowing && _collapsed.contains(folder);
              return Padding(
                padding: EdgeInsets.only(top: fi == 0 ? 0 : 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FolderHeader(
                      folder: folder,
                      count: paths.length,
                      sizeLabel: _sizesReady
                          ? _fmtBytes(folderSize(folder))
                          : null,
                      collapsed: isCollapsed,
                      collapsible: !narrowing,
                      onTap: () => setState(() {
                        if (!_collapsed.remove(folder)) _collapsed.add(folder);
                      }),
                    ),
                    if (!isCollapsed)
                      for (final p in paths)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: _AssetRow(
                            path: p,
                            sizeLabel: switch (_logicalSize(p)) {
                              final s? => _fmtBytes(s),
                              null => null,
                            },
                            densityCount: _filesOf(p).length,
                          ),
                        ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Containing directory — `assets/logos/foo.png` → `assets/logos`.
  /// Root-level entries (no slash) group under `/`.
  static String _folderOf(String path) {
    final i = path.lastIndexOf('/');
    return i < 0 ? '/' : path.substring(0, i);
  }

  /// Category key: the rich kinds (image/svg/lottie/font) plus one
  /// bucket PER remaining file extension — 'Other 170' told nobody
  /// anything; 'md 12 · json 40 · frag 3' does.
  static String _kind(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.svg')) return 'svg';
    if (lower.endsWith('.json') && lower.contains('lotti')) return 'lottie';
    if (lower.endsWith('.ttf') ||
        lower.endsWith('.otf') ||
        lower.contains('/fonts/')) {
      return 'font';
    }
    if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp')) {
      return 'image';
    }
    final dot = lower.lastIndexOf('.');
    final slash = lower.lastIndexOf('/');
    if (dot > slash && dot < lower.length - 1) return lower.substring(dot + 1);
    return 'misc';
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.counts,
    required this.selected,
    required this.onSelect,
  });

  final Map<String, int> counts;
  final String? selected;
  final ValueChanged<String> onSelect;

  /// Rich kinds first (fixed order), then extension buckets by
  /// descending count.
  static const _kKnownOrder = ['image', 'svg', 'lottie', 'font'];

  @override
  Widget build(BuildContext context) {
    final rest = counts.keys.where((k) => !_kKnownOrder.contains(k)).toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    final kinds = [..._kKnownOrder.where(counts.containsKey), ...rest];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        itemCount: kinds.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final k = kinds[i];
          return _Chip(
            icon: _kindIcon(k),
            label: _kindLabel(k),
            count: counts[k]!,
            color: _kindColor(k),
            selected: selected == k,
            onTap: () => onSelect(k),
          );
        },
      ),
    );
  }

  static String _kindLabel(String k) => switch (k) {
    'image' => 'Images',
    'svg' => 'SVG',
    'lottie' => 'Lottie',
    'font' => 'Fonts',
    'misc' => 'Misc',
    _ => k,
  };

  static IconData _kindIcon(String k) => switch (k) {
    'image' => Icons.image_rounded,
    'svg' => Icons.polyline_rounded,
    'lottie' => Icons.animation_rounded,
    'font' => Icons.text_fields_rounded,
    'md' => Icons.article_rounded,
    'json' => Icons.data_object_rounded,
    'dart' => Icons.code_rounded,
    'frag' || 'glsl' => Icons.gradient_rounded,
    'mp3' || 'wav' || 'ogg' => Icons.audiotrack_rounded,
    'mp4' || 'webm' => Icons.movie_rounded,
    'pdf' => Icons.picture_as_pdf_rounded,
    'env' || 'yaml' || 'yml' => Icons.settings_rounded,
    _ => Icons.insert_drive_file_rounded,
  };

  static Color _kindColor(String k) => switch (k) {
    'image' => const Color(0xFF66BB6A),
    'svg' => const Color(0xFF4FC3F7),
    'lottie' => const Color(0xFFFFA726),
    'font' => const Color(0xFFBA68C8),
    'md' => const Color(0xFF4FC3F7),
    'json' => const Color(0xFFFFA726),
    'dart' => const Color(0xFF29B6F6),
    'pdf' => const Color(0xFFEF5350),
    _ => const Color(0xFF9E9E9E),
  };
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? color : DebugOverlayTheme.textDim;
    return Material(
      color: selected ? color.withValues(alpha: 0.15) : DebugOverlayTheme.bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        splashColor: color.withValues(alpha: 0.15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.6)
                  : DebugOverlayTheme.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 12,
                color: selected ? color : color.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: DebugOverlayTheme.ui.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: DebugOverlayTheme.mono.copyWith(
                  fontSize: 10,
                  color: selected ? color : DebugOverlayTheme.textDimmer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Collapsible folder section header — same language as the grouped
/// lists on the home / L10n / route-jumper pages.
class _FolderHeader extends StatelessWidget {
  const _FolderHeader({
    required this.folder,
    required this.count,
    required this.sizeLabel,
    required this.collapsed,
    required this.collapsible,
    required this.onTap,
  });

  final String folder;
  final int count;

  /// Folder bundle weight — null while sizes still load.
  final String? sizeLabel;

  final bool collapsed;
  final bool collapsible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: collapsible ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 4, 2, 2),
        child: Row(
          children: [
            const Icon(
              Icons.folder_rounded,
              size: 13,
              color: DebugOverlayTheme.textDim,
            ),
            const SizedBox(width: 6),
            // Expanded (not Flexible + Spacer): a loose Flexible shares
            // the free space with the Spacer, so short names left the
            // chevron floating mid-row instead of pinned at the end.
            Expanded(
              child: Text(
                folder,
                overflow: TextOverflow.ellipsis,
                style: DebugOverlayTheme.mono.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: DebugOverlayTheme.textDim,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              sizeLabel == null ? '$count' : '$count · $sizeLabel',
              style: DebugOverlayTheme.mono.copyWith(
                fontSize: 10,
                color: DebugOverlayTheme.textDimmer,
              ),
            ),
            if (collapsible) ...[
              const SizedBox(width: 4),
              AnimatedRotation(
                turns: collapsed ? -0.25 : 0,
                duration: const Duration(milliseconds: 150),
                child: const Icon(
                  Icons.expand_more_rounded,
                  size: 16,
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

class _AssetRow extends StatelessWidget {
  const _AssetRow({
    required this.path,
    required this.sizeLabel,
    required this.densityCount,
  });

  final String path;

  /// Total weight incl. density variants — null while sizes load.
  final String? sizeLabel;

  /// Number of bundled files behind this logical asset (1x/2x/3x).
  final int densityCount;

  String get _basename {
    final i = path.lastIndexOf('/');
    return i < 0 ? path : path.substring(i + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DebugOverlayTheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _showPreview(context, path),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: DebugOverlayTheme.border),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: _Thumbnail(path: path),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // Folder is the section header — the row keeps
                      // just the file name.
                      _basename,
                      style: DebugOverlayTheme.mono.copyWith(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      [
                        sizeLabel ?? '…',
                        if (densityCount > 1) '$densityCount densities',
                      ].join(' · '),
                      style: DebugOverlayTheme.mono.copyWith(
                        fontSize: 9.5,
                        color: DebugOverlayTheme.textDimmer,
                      ),
                    ),
                  ],
                ),
              ),
              GlobalIconButton(
                tooltip: 'Copy full path',
                enforceMinTouchTarget: false,
                iconData: Icons.copy_rounded,
                onPressed: () => Clipboard.setData(ClipboardData(text: path)),
                iconSize: 14,
                style: const ButtonStateStyle(
                  width: 24,
                  height: 24,
                  foregroundColor: DebugOverlayTheme.textDim,
                ),
              ),
              GlobalIconButton(
                tooltip: 'Download / share',
                enforceMinTouchTarget: false,
                iconData: Icons.download_rounded,
                onPressed: () => _download(path),
                iconSize: 14,
                style: const ButtonStateStyle(
                  width: 24,
                  height: 24,
                  foregroundColor: DebugOverlayTheme.textDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Download" on mobile = hand the bytes to the OS share sheet — the
  /// user lands them in Files / Photos / anywhere. Bundled assets have
  /// no real file path, so stage a copy in the temp dir first.
  static Future<void> _download(String path) async {
    if (kIsWeb) {
      GlobalToast.error('Not supported on web');
      return;
    }
    try {
      final data = await rootBundle.load(path);
      final name = path.substring(path.lastIndexOf('/') + 1);
      final dir = await getTemporaryDirectory();
      final file = io.File('${dir.path}/$name');
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } catch (e) {
      GlobalToast.error('Export failed', description: '$e');
    }
  }

  static void _showPreview(BuildContext context, String path) {
    GlobalDialog.show<void>(
      context: context,
      title: path,
      customTitle: SelectableText(
        path,
        style: DebugOverlayTheme.mono.copyWith(
          fontSize: 11,
          color: DebugOverlayTheme.text,
        ),
      ),
      style: debugDialogStyle().copyWith(maxWidth: 480, maxHeight: 480),
      // The dialog chrome scrolls its content — bound the preview so
      // large artwork keeps the old fit-inside-the-box behavior.
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 380),
        child: _Preview(path: path),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.svg')) {
      return SvgPicture.asset(path, fit: BoxFit.contain);
    }
    if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp')) {
      return Image.asset(path, fit: BoxFit.cover, errorBuilder: _err);
    }
    return Container(
      decoration: BoxDecoration(
        color: DebugOverlayTheme.bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: DebugOverlayTheme.border),
      ),
      alignment: Alignment.center,
      child: Icon(_iconFor(lower), size: 16, color: DebugOverlayTheme.textDim),
    );
  }

  static IconData _iconFor(String lower) {
    if (lower.endsWith('.json')) return Icons.movie_rounded;
    if (lower.endsWith('.ttf') || lower.endsWith('.otf')) {
      return Icons.text_fields_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  static Widget _err(BuildContext _, Object _, StackTrace? _) {
    return const Icon(
      Icons.broken_image_rounded,
      size: 14,
      color: DebugOverlayTheme.textDimmer,
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.path});
  final String path;

  static const _kTextExtensions = {
    'dart',
    'md',
    'txt',
    'json',
    'arb',
    'yaml',
    'yml',
    'env',
    'xml',
    'html',
    'css',
    'js',
    'frag',
    'glsl',
    'sksl',
    'csv',
    'log',
    'sh',
    'properties',
    'plist',
    'gradle',
    'kts',
    'lock',
    'gitignore',
  };

  static String _ext(String lower) {
    final dot = lower.lastIndexOf('.');
    final slash = lower.lastIndexOf('/');
    return dot > slash && dot < lower.length - 1
        ? lower.substring(dot + 1)
        : '';
  }

  @override
  Widget build(BuildContext context) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.svg')) {
      return _Checkered(child: SvgPicture.asset(path, fit: BoxFit.contain));
    }
    if (lower.endsWith('.json') && lower.contains('lotti')) {
      return _Checkered(child: Lottie.asset(path));
    }
    if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp')) {
      return _Checkered(child: Image.asset(path, fit: BoxFit.contain));
    }
    if (lower.endsWith('.ttf') || lower.endsWith('.otf')) {
      return _FontPreview(path: path);
    }
    if (_kTextExtensions.contains(_ext(lower))) {
      return _TextPreview(path: path);
    }
    return Center(
      child: Text(
        '<no preview>',
        style: DebugOverlayTheme.ui.copyWith(
          color: DebugOverlayTheme.textDimmer,
        ),
      ),
    );
  }
}

/// Checkerboard backdrop — transparent regions and white-on-white
/// artwork stay visible.
class _Checkered extends StatelessWidget {
  const _Checkered({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CustomPaint(
        painter: _CheckerPainter(),
        child: Padding(padding: const EdgeInsets.all(8), child: child),
      ),
    );
  }
}

class _CheckerPainter extends CustomPainter {
  static const _cell = 8.0;
  static final _light = Paint()..color = const Color(0xFF26282F);
  static final _dark = Paint()..color = const Color(0xFF1B1D23);

  @override
  void paint(Canvas canvas, Size size) {
    for (var y = 0.0; y < size.height; y += _cell) {
      for (var x = 0.0; x < size.width; x += _cell) {
        final even = ((x / _cell).floor() + (y / _cell).floor()).isEven;
        canvas.drawRect(
          Rect.fromLTWH(x, y, _cell, _cell),
          even ? _light : _dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckerPainter oldDelegate) => false;
}

/// Live specimen for bundled .ttf/.otf — loads the face under a
/// preview-only family name (once per session) and renders sample
/// lines. The family name is derived from the path so two fonts never
/// collide.
class _FontPreview extends StatelessWidget {
  const _FontPreview({required this.path});
  final String path;

  static final Set<String> _loaded = {};

  String get _family => 'asset-preview-${path.hashCode.toRadixString(16)}';

  Future<void> _ensureLoaded() async {
    if (_loaded.contains(_family)) return;
    final loader = FontLoader(_family)..addFont(rootBundle.load(path));
    await loader.load();
    _loaded.add(_family);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ensureLoaded(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Text(
              '<failed to load font>',
              style: DebugOverlayTheme.ui.copyWith(
                color: DebugOverlayTheme.textDimmer,
              ),
            ),
          );
        }
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: DebugOverlayTheme.accentDefault,
              ),
            ),
          );
        }
        TextStyle sample(double size, [FontWeight w = FontWeight.w400]) =>
            TextStyle(
              fontFamily: _family,
              fontSize: size,
              fontWeight: w,
              color: DebugOverlayTheme.text,
              decoration: TextDecoration.none,
            );
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The quick brown fox jumps over the lazy dog',
                style: sample(20),
              ),
              const SizedBox(height: 8),
              Text(
                'The quick brown fox — bold',
                style: sample(16, FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text('0123456789 !@#\$%&*()', style: sample(16)),
              const SizedBox(height: 8),
              Text('السلام عليكم — أبجد هوز ٠١٢٣٤٥٦٧٨٩', style: sample(18)),
              const SizedBox(height: 8),
              Text(
                'ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz',
                style: sample(13),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Scrollable plain-text preview for text-like bundled assets (.dart,
/// .md, .json, config files, ...). Capped so a giant file can't choke
/// the dialog.
class _TextPreview extends StatelessWidget {
  const _TextPreview({required this.path});
  final String path;

  static const _kMaxChars = 100 * 1024;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: rootBundle.loadString(path),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Text(
              '<not valid text>',
              style: DebugOverlayTheme.ui.copyWith(
                color: DebugOverlayTheme.textDimmer,
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: DebugOverlayTheme.accentDefault,
              ),
            ),
          );
        }
        final full = snap.data!;
        final truncated = full.length > _kMaxChars;
        final text = truncated
            ? '${full.substring(0, _kMaxChars)}\n…\n<truncated ${full.length - _kMaxChars} chars>'
            : full;
        return Container(
          decoration: BoxDecoration(
            color: DebugOverlayTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: DebugOverlayTheme.border),
          ),
          padding: const EdgeInsets.all(10),
          child: SingleChildScrollView(
            child: SelectableText(
              text,
              style: DebugOverlayTheme.mono.copyWith(
                fontSize: 10.5,
                height: 1.45,
              ),
            ),
          ),
        );
      },
    );
  }
}
