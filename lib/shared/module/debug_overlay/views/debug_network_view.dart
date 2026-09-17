import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/devtools/network_capture.dart';
import '../../buttons/global_icon_button.dart';
import '../../toast/global_toast.dart';
import '../debug_overlay_models.dart';
import '../widgets/debug_search_field.dart';

/// Network inspector — list of recent HTTP calls captured by
/// [NetworkCapture]. Tap a row to drill into request/response detail
/// with copy-as-curl. Search filters by method or path. Pull or tap
/// the trash to clear the buffer.
class DebugNetworkView extends StatefulWidget {
  const DebugNetworkView({super.key});

  @override
  State<DebugNetworkView> createState() => _DebugNetworkViewState();
}

class _DebugNetworkViewState extends State<DebugNetworkView> {
  StreamSubscription<void>? _sub;
  String _query = '';
  StatusBucket? _bucketFilter;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sub = NetworkCapture.changes.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  static const _bucketMeta = <StatusBucket, (String, Color)>{
    StatusBucket.success: ('2xx', Color(0xFF66BB6A)),
    StatusBucket.redirect: ('3xx', Color(0xFF4FC3F7)),
    StatusBucket.clientError: ('4xx', Color(0xFFFFA726)),
    StatusBucket.error: ('err', Color(0xFFEF5350)),
    StatusBucket.pending: ('pending', DebugOverlayTheme.textDim),
  };

  @override
  Widget build(BuildContext context) {
    final all = NetworkCapture.entries;
    final q = _query.toLowerCase();
    final filtered = [
      for (final e in all)
        if ((q.isEmpty ||
                e.method.toLowerCase().contains(q) ||
                e.url.toLowerCase().contains(q)) &&
            (_bucketFilter == null || e.bucket == _bucketFilter))
          e,
    ];
    final bucketCounts = <StatusBucket, int>{};
    for (final e in all) {
      bucketCounts[e.bucket] = (bucketCounts[e.bucket] ?? 0) + 1;
    }

    return Column(
      children: [
        _Toolbar(
          searchCtrl: _searchCtrl,
          onSearch: (q) => setState(() => _query = q),
          onClear: () {
            NetworkCapture.clear();
            GlobalToast.info('Capture buffer cleared');
          },
          captureEnabled: NetworkCapture.enabled,
          onToggleCapture: () {
            setState(() => NetworkCapture.enabled = !NetworkCapture.enabled);
          },
          shownCount: filtered.length,
          totalCount: all.length,
          filtering: q.isNotEmpty || _bucketFilter != null,
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
          decoration: const BoxDecoration(
            color: DebugOverlayTheme.surface,
            border: Border(bottom: BorderSide(color: DebugOverlayTheme.border)),
          ),
          child: SizedBox(
            height: 26,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _BucketChip(
                  label: 'all',
                  count: all.length,
                  color: DebugOverlayTheme.accent,
                  selected: _bucketFilter == null,
                  onTap: () => setState(() => _bucketFilter = null),
                ),
                for (final MapEntry(key: bucket, value: (label, color))
                    in _bucketMeta.entries) ...[
                  const SizedBox(width: 6),
                  _BucketChip(
                    label: label,
                    count: bucketCounts[bucket] ?? 0,
                    color: color,
                    selected: _bucketFilter == bucket,
                    onTap: () => setState(
                      () => _bucketFilter = _bucketFilter == bucket
                          ? null
                          : bucket,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (!NetworkCapture.enabled)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: const Color(0xFFFFA726).withValues(alpha: 0.12),
            child: Text(
              'CAPTURE PAUSED — new requests are NOT recorded',
              style: DebugOverlayTheme.mono.copyWith(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFFA726),
                letterSpacing: 0.4,
              ),
            ),
          ),
        Expanded(
          child: filtered.isEmpty
              ? _EmptyState(filtered: all.isNotEmpty)
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => Container(
                    height: 1,
                    color: DebugOverlayTheme.border.withValues(alpha: 0.5),
                  ),
                  itemBuilder: (_, i) {
                    final entry = filtered[i];
                    return _Row(
                      entry: entry,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _DetailPage(entry: entry),
                          fullscreenDialog: false,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _BucketChip extends StatelessWidget {
  const _BucketChip({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: 0.18) : DebugOverlayTheme.bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.6)
                  : DebugOverlayTheme.border,
            ),
          ),
          child: Text(
            '$label $count',
            style: DebugOverlayTheme.mono.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: selected ? color : DebugOverlayTheme.textDim,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Toolbar
// ─────────────────────────────────────────────────────────────

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.searchCtrl,
    required this.onSearch,
    required this.onClear,
    required this.captureEnabled,
    required this.onToggleCapture,
    required this.shownCount,
    required this.totalCount,
    required this.filtering,
  });

  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch;
  final VoidCallback onClear;
  final bool captureEnabled;
  final VoidCallback onToggleCapture;
  final int shownCount;
  final int totalCount;
  final bool filtering;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      decoration: const BoxDecoration(
        color: DebugOverlayTheme.surface,
        border: Border(bottom: BorderSide(color: DebugOverlayTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: DebugSearchField(
              controller: searchCtrl,
              hintText: 'Filter by method or path',
              onChanged: onSearch,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            filtering ? '$shownCount/$totalCount' : '$totalCount',
            style: DebugOverlayTheme.mono.copyWith(
              fontSize: 10,
              color: DebugOverlayTheme.textDim,
            ),
          ),
          GlobalIconButton(
            tooltip: captureEnabled ? 'Pause capture' : 'Resume capture',
            enforceMinTouchTarget: false,
            iconData: captureEnabled
                ? Icons.pause_circle_outline_rounded
                : Icons.play_circle_outline_rounded,
            onPressed: onToggleCapture,
            iconSize: 16,
            style: ButtonStateStyle(
              width: 28,
              height: 28,
              foregroundColor: captureEnabled
                  ? DebugOverlayTheme.accent
                  : DebugOverlayTheme.textDim,
            ),
          ),
          const GlobalIconButton(
            tooltip: 'Export HAR',
            enforceMinTouchTarget: false,
            iconData: Icons.ios_share_rounded,
            onPressed: _exportHar,
            iconSize: 16,
            style: ButtonStateStyle(
              width: 28,
              height: 28,
              foregroundColor: DebugOverlayTheme.textDim,
            ),
          ),
          GlobalIconButton(
            tooltip: 'Clear',
            enforceMinTouchTarget: false,
            iconData: Icons.delete_sweep_rounded,
            onPressed: onClear,
            iconSize: 16,
            style: const ButtonStateStyle(
              width: 28,
              height: 28,
              foregroundColor: DebugOverlayTheme.textDim,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// List row
// ─────────────────────────────────────────────────────────────

class _Row extends StatelessWidget {
  const _Row({required this.entry, required this.onTap});

  final NetworkCaptureEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _bucketColor(entry.bucket);
    final path = _pathOnly(entry.url);
    final ms = entry.duration?.inMilliseconds;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusChip(entry: entry, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        entry.method,
                        style: DebugOverlayTheme.mono.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _methodColor(entry.method),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          path,
                          style: DebugOverlayTheme.mono.copyWith(fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        _hms(entry.startedAt),
                        style: DebugOverlayTheme.mono.copyWith(
                          fontSize: 10,
                          color: DebugOverlayTheme.textDim,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (ms != null)
                        Text(
                          '${ms}ms',
                          style: DebugOverlayTheme.mono.copyWith(
                            fontSize: 10,
                            color: DebugOverlayTheme.textDim,
                          ),
                        )
                      else
                        Text(
                          'pending',
                          style: DebugOverlayTheme.mono.copyWith(
                            fontSize: 10,
                            color: DebugOverlayTheme.textDimmer,
                          ),
                        ),
                      if (entry.errorType != null) ...[
                        const SizedBox(width: 10),
                        Icon(
                          Icons.error_outline_rounded,
                          size: 11,
                          color: color,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          entry.errorType!,
                          style: DebugOverlayTheme.mono.copyWith(
                            fontSize: 10,
                            color: color,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.entry, required this.color});
  final NetworkCaptureEntry entry;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final code = entry.statusCode;
    final label = code != null
        ? '$code'
        : (entry.errorType != null ? 'ERR' : '...');
    return Container(
      width: 38,
      padding: const EdgeInsets.symmetric(vertical: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: DebugOverlayTheme.mono.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filtered});

  /// True when the buffer has entries but the active filter hides all.
  final bool filtered;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            filtered ? Icons.filter_alt_off_rounded : Icons.swap_vert_rounded,
            size: 32,
            color: DebugOverlayTheme.textDimmer,
          ),
          const SizedBox(height: 8),
          Text(
            filtered ? 'Nothing matches the filter' : 'No captures yet',
            style: DebugOverlayTheme.ui.copyWith(
              color: DebugOverlayTheme.textDim,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            filtered
                ? 'Clear the search or status chip.'
                : 'Fire a request to see it land here.',
            style: DebugOverlayTheme.ui.copyWith(
              fontSize: 11,
              color: DebugOverlayTheme.textDimmer,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Detail page — request / response / curl tabs
// ─────────────────────────────────────────────────────────────

class _DetailPage extends StatelessWidget {
  const _DetailPage({required this.entry});

  final NetworkCaptureEntry entry;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          _DetailHeader(entry: entry),
          TabBar(
            indicatorColor: DebugOverlayTheme.accent,
            labelColor: DebugOverlayTheme.text,
            unselectedLabelColor: DebugOverlayTheme.textDim,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: DebugOverlayTheme.kFont,
            ),
            tabs: const [
              Tab(text: 'Request', height: 32),
              Tab(text: 'Response', height: 32),
              Tab(text: 'cURL', height: 32),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _RequestTab(entry: entry),
                _ResponseTab(entry: entry),
                _CurlTab(entry: entry),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.entry});
  final NetworkCaptureEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = _bucketColor(entry.bucket);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(
        color: DebugOverlayTheme.surface,
        border: Border(bottom: BorderSide(color: DebugOverlayTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusChip(entry: entry, color: color),
              const SizedBox(width: 10),
              Text(
                entry.method,
                style: DebugOverlayTheme.mono.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _methodColor(entry.method),
                ),
              ),
              const Spacer(),
              Text(
                [
                  _hmsMs(entry.startedAt),
                  if (entry.duration != null)
                    '${entry.duration!.inMilliseconds}ms',
                  if (entry.responseBody != null)
                    _approxSize(entry.responseBody),
                ].join(' · '),
                style: DebugOverlayTheme.mono.copyWith(
                  fontSize: 10.5,
                  color: DebugOverlayTheme.textDim,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(
            entry.url,
            style: DebugOverlayTheme.mono.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _RequestTab extends StatelessWidget {
  const _RequestTab({required this.entry});
  final NetworkCaptureEntry entry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _KvBlock(title: 'Headers', map: entry.requestHeaders),
        if (entry.requestQuery != null) ...[
          const SizedBox(height: 12),
          _KvBlock(title: 'Query', map: entry.requestQuery!),
        ],
        if (entry.requestBody != null) ...[
          const SizedBox(height: 12),
          _BodyBlock(title: 'Body', body: entry.requestBody),
        ],
      ],
    );
  }
}

class _ResponseTab extends StatelessWidget {
  const _ResponseTab({required this.entry});
  final NetworkCaptureEntry entry;

  @override
  Widget build(BuildContext context) {
    if (!entry.hasResponse) {
      return const Center(
        child: Text(
          'In-flight…',
          style: TextStyle(color: DebugOverlayTheme.textDim),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (entry.errorMessage != null)
          _BodyBlock(title: 'Error', body: entry.errorMessage),
        if (entry.responseHeaders != null) ...[
          if (entry.errorMessage != null) const SizedBox(height: 12),
          _KvBlock(title: 'Headers', map: entry.responseHeaders!),
        ],
        if (entry.responseBody != null) ...[
          const SizedBox(height: 12),
          _BodyBlock(title: 'Body', body: entry.responseBody),
        ],
      ],
    );
  }
}

class _CurlTab extends StatelessWidget {
  const _CurlTab({required this.entry});
  final NetworkCaptureEntry entry;

  @override
  Widget build(BuildContext context) {
    final cmd = _toCurl(entry);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Reproduce in shell',
                style: DebugOverlayTheme.ui.copyWith(
                  fontSize: 11,
                  color: DebugOverlayTheme.textDim,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              GlobalIconButton(
                tooltip: 'Copy',
                enforceMinTouchTarget: false,
                iconData: Icons.copy_rounded,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: cmd));
                  GlobalToast.info('cURL copied');
                },
                iconSize: 16,
                style: const ButtonStateStyle(
                  width: 24,
                  height: 24,
                  foregroundColor: DebugOverlayTheme.textDim,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: DebugOverlayTheme.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DebugOverlayTheme.border),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  cmd,
                  style: DebugOverlayTheme.mono.copyWith(fontSize: 11),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Reusable detail blocks
// ─────────────────────────────────────────────────────────────

class _KvBlock extends StatelessWidget {
  const _KvBlock({required this.title, required this.map});

  final String title;
  final Map<String, dynamic> map;

  @override
  Widget build(BuildContext context) {
    if (map.isEmpty) {
      return _Block(
        title: title,
        child: Text(
          '<empty>',
          style: DebugOverlayTheme.mono.copyWith(
            fontSize: 11,
            color: DebugOverlayTheme.textDimmer,
          ),
        ),
      );
    }
    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return _Block(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      e.key,
                      style: DebugOverlayTheme.mono.copyWith(
                        fontSize: 11,
                        color: DebugOverlayTheme.textDim,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SelectableText(
                      '${e.value}',
                      style: DebugOverlayTheme.mono.copyWith(fontSize: 11),
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

class _BodyBlock extends StatelessWidget {
  const _BodyBlock({required this.title, required this.body});
  final String title;
  final Object? body;

  @override
  Widget build(BuildContext context) {
    final pretty = _prettyJson(body);
    return _Block(
      title: title,
      action: GlobalIconButton(
        tooltip: 'Copy',
        enforceMinTouchTarget: false,
        iconData: Icons.copy_rounded,
        onPressed: () {
          Clipboard.setData(ClipboardData(text: pretty));
          GlobalToast.info('$title copied');
        },
        iconSize: 14,
        style: const ButtonStateStyle(
          width: 24,
          height: 24,
          foregroundColor: DebugOverlayTheme.textDim,
        ),
      ),
      child: SelectableText.rich(
        TextSpan(
          style: DebugOverlayTheme.mono.copyWith(
            fontSize: 11,
            height: 1.45,
            color: DebugOverlayTheme.text,
          ),
          children: _jsonSpans(pretty),
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 10),
      decoration: BoxDecoration(
        color: DebugOverlayTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DebugOverlayTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                title,
                style: DebugOverlayTheme.ui.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: DebugOverlayTheme.textDim,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────

/// Export the capture buffer as HAR 1.2 — opens in Chrome DevTools,
/// Charles, Proxyman, etc. Only completed requests are exportable.
Future<void> _exportHar() async {
  final entries = NetworkCapture.entries.where((e) => e.hasResponse).toList();
  if (entries.isEmpty) {
    GlobalToast.warning(
      'Nothing to export',
      description: 'No completed requests in the buffer',
    );
    return;
  }
  try {
    final har = {
      'log': {
        'version': '1.2',
        'creator': {'name': 'terracotta debug overlay', 'version': '1'},
        'entries': [
          for (final e in entries)
            {
              'startedDateTime': e.startedAt.toUtc().toIso8601String(),
              'time': e.duration?.inMilliseconds ?? 0,
              'request': {
                'method': e.method,
                'url': e.url,
                'httpVersion': 'HTTP/1.1',
                'headers': [
                  for (final h in e.requestHeaders.entries)
                    {'name': h.key, 'value': '${h.value}'},
                ],
                'queryString': [
                  for (final q in (e.requestQuery ?? const {}).entries)
                    {'name': q.key, 'value': '${q.value}'},
                ],
                'cookies': const [],
                'headersSize': -1,
                'bodySize': -1,
                if (e.requestBody != null)
                  'postData': {
                    'mimeType': 'application/json',
                    'text': _prettyJson(e.requestBody),
                  },
              },
              'response': {
                'status': e.statusCode ?? 0,
                'statusText': e.statusMessage ?? e.errorType ?? '',
                'httpVersion': 'HTTP/1.1',
                'headers': [
                  for (final h in (e.responseHeaders ?? const {}).entries)
                    {'name': h.key, 'value': '${h.value}'},
                ],
                'cookies': const [],
                'content': {
                  'size': -1,
                  'mimeType': 'application/json',
                  'text': e.responseBody == null
                      ? ''
                      : _prettyJson(e.responseBody),
                },
                'redirectURL': '',
                'headersSize': -1,
                'bodySize': -1,
              },
              'cache': const <String, Object?>{},
              'timings': {
                'send': 0,
                'wait': e.duration?.inMilliseconds ?? 0,
                'receive': 0,
              },
            },
        ],
      },
    };
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = io.File('${dir.path}/capture-$stamp.har');
    await file.writeAsString(jsonEncode(har));
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  } catch (e) {
    GlobalToast.error('HAR export failed', description: '$e');
  }
}

Color _bucketColor(StatusBucket b) => switch (b) {
  StatusBucket.success => const Color(0xFF66BB6A),
  StatusBucket.redirect => const Color(0xFF4FC3F7),
  StatusBucket.clientError => const Color(0xFFFFA726),
  StatusBucket.error => const Color(0xFFEF5350),
  StatusBucket.pending => DebugOverlayTheme.textDim,
};

Color _methodColor(String method) => switch (method.toUpperCase()) {
  'GET' => const Color(0xFF66BB6A),
  'POST' => const Color(0xFF64B5F6),
  'PUT' || 'PATCH' => const Color(0xFFFFA726),
  'DELETE' => const Color(0xFFEF5350),
  _ => DebugOverlayTheme.text,
};

String _hmsMs(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  final s = dt.second.toString().padLeft(2, '0');
  final ms = dt.millisecond.toString().padLeft(3, '0');
  return '$h:$m:$s.$ms';
}

/// Rough response weight from the pretty-printed body — good enough
/// to spot a 2 MB payload on a list endpoint.
String _approxSize(Object? body) {
  final n = _prettyJson(body).length;
  if (n < 1024) return '$n B';
  if (n < 1024 * 1024) return '${(n / 1024).toStringAsFixed(1)} KB';
  return '${(n / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Regex JSON tokenizer for colored bodies — same palette as the
/// route jumper's extras editor. Keys blue, strings green, numbers
/// amber, keywords purple, punctuation dim.
List<TextSpan> _jsonSpans(String src) {
  final re = RegExp(
    r'"(?:\\.|[^"\\])*"|\b(?:true|false|null)\b|'
    r'-?\d+\.?\d*(?:[eE][+-]?\d+)?|[{}\[\],:]',
  );
  final spans = <TextSpan>[];
  var last = 0;
  for (final m in re.allMatches(src)) {
    if (m.start > last) {
      spans.add(TextSpan(text: src.substring(last, m.start)));
    }
    final t = m.group(0)!;
    final Color color;
    if (t.startsWith('"')) {
      // Key when the next non-space char is a colon.
      var i = m.end;
      while (i < src.length && (src[i] == ' ' || src[i] == '\n')) {
        i++;
      }
      final isKey = i < src.length && src[i] == ':';
      color = isKey ? const Color(0xFF64B5F6) : const Color(0xFF66BB6A);
    } else if (t == 'true' || t == 'false' || t == 'null') {
      color = const Color(0xFFBA68C8);
    } else if (RegExp(r'^-?\d').hasMatch(t)) {
      color = const Color(0xFFFFA726);
    } else {
      color = DebugOverlayTheme.textDim;
    }
    spans.add(
      TextSpan(
        text: t,
        style: TextStyle(color: color),
      ),
    );
    last = m.end;
  }
  if (last < src.length) {
    spans.add(TextSpan(text: src.substring(last)));
  }
  return spans;
}

String _pathOnly(String url) {
  final i = url.indexOf('://');
  if (i < 0) return url;
  final after = url.substring(i + 3);
  final slash = after.indexOf('/');
  return slash < 0 ? '/' : after.substring(slash);
}

String _hms(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  final s = dt.second.toString().padLeft(2, '0');
  return '$h:$m:$s';
}

String _prettyJson(Object? body) {
  if (body == null) return '<empty>';
  if (body is String) {
    // Try parsing in case it's a JSON string
    try {
      final decoded = jsonDecode(body);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return body;
    }
  }
  try {
    return const JsonEncoder.withIndent('  ').convert(body);
  } catch (_) {
    return body.toString();
  }
}

String _toCurl(NetworkCaptureEntry entry) {
  final buf = StringBuffer('curl -X ${entry.method} \\\n');
  final url = entry.requestQuery == null || entry.requestQuery!.isEmpty
      ? entry.url
      : '${entry.url}?${entry.requestQuery!.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent('${e.value}')}').join('&')}';
  buf.writeln("  '$url' \\");
  for (final h in entry.requestHeaders.entries) {
    buf.writeln("  -H '${h.key}: ${h.value}' \\");
  }
  if (entry.requestBody != null) {
    final body = entry.requestBody is String
        ? entry.requestBody as String
        : jsonEncode(entry.requestBody);
    buf.writeln("  -d '${body.replaceAll("'", r"\'")}' \\");
  }
  // Trim trailing backslash + newline.
  final out = buf.toString().trimRight();
  return out.endsWith(r'\')
      ? out.substring(0, out.length - 1).trimRight()
      : out;
}
