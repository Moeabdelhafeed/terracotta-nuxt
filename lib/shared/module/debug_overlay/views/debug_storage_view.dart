import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../../../../core/localization/strings/common_strings.dart';
import '../../buttons/global_icon_button.dart';
import '../../toast/global_toast.dart';
import '../debug_overlay_models.dart';
import '../widgets/debug_surfaces.dart';

/// Storage inspector — peeks into [HydratedBloc.storage] (rehydrated
/// cubit blobs) and [FlutterSecureStorage] (token / encrypted prefs).
///
/// Read-only by default. Tap to expand (JSON-colored dump), trash to
/// delete with confirm, per-section clear-all.
///
/// HydratedBloc has no public key-enumeration API so this widget keeps
/// a manifest of known cubit storage tokens. Add a new HydratedCubit
/// → append to [_kHydratedTokens] so it shows up here.
class DebugStorageView extends StatefulWidget {
  const DebugStorageView({super.key});

  @override
  State<DebugStorageView> createState() => _DebugStorageViewState();
}

/// Default `storageToken` on `HydratedCubit<T>` is the runtimeType
/// string. Mirror that here so the inspector reads the same key.
/// MUST list every `extends HydratedCubit` class in lib/.
const _kHydratedTokens = <String>[
  'PreferencesCubit',
  'MaintenanceCubit',
  'UpdateCubit',
  'PdfBookmarksCubit',
  'SearchHistoryCubit',
  'WizardDraftsCubit',
  'FaqHistoryCubit',
];

class _DebugStorageViewState extends State<DebugStorageView> {
  final _secure = const FlutterSecureStorage();
  Map<String, String>? _secureSnapshot;
  Object? _secureError;
  bool _loadingSecure = false;
  final _expanded = <String>{};

  @override
  void initState() {
    super.initState();
    _refreshSecure();
  }

  Future<void> _refreshSecure() async {
    if (kIsWeb) {
      // FlutterSecureStorage on web uses IndexedDB but is largely
      // useless for inspection — most apps don't use it on web.
      setState(() => _secureSnapshot = const {});
      return;
    }
    setState(() => _loadingSecure = true);
    try {
      final all = await _secure.readAll();
      if (!mounted) return;
      setState(() {
        _secureSnapshot = all;
        _secureError = null;
        _loadingSecure = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _secureError = e;
        _loadingSecure = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hydratedCount = _kHydratedTokens
        .where((t) => HydratedBloc.storage.read(t) != null)
        .length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      children: [
        _SectionHeader(
          title: 'HydratedBloc',
          icon: Icons.storage_rounded,
          color: const Color(0xFF64B5F6),
          count: '$hydratedCount/${_kHydratedTokens.length} persisted',
          onRefresh: () => setState(() {}),
          onClearAll: hydratedCount == 0
              ? null
              : () => _confirm(
                  context,
                  title: 'Clear ALL hydrated state?',
                  body:
                      'Wipes every persisted cubit blob. Live cubits keep '
                      'their in-memory state and re-persist on their next '
                      'emit — restart to see true defaults.',
                  onConfirm: () async {
                    await HydratedBloc.storage.clear();
                    GlobalToast.info('Hydrated storage cleared');
                    if (mounted) setState(() {});
                  },
                ),
        ),
        _Group(
          children: [
            for (final token in _kHydratedTokens)
              _HydratedRow(
                token: token,
                expanded: _expanded.contains(token),
                onToggle: () => setState(() {
                  _expanded.contains(token)
                      ? _expanded.remove(token)
                      : _expanded.add(token);
                }),
                onDelete: () => _confirm(
                  context,
                  title: 'Delete $token?',
                  body:
                      "Wipes the cubit's persisted blob. The live cubit "
                      'keeps its state and re-persists on next emit.',
                  onConfirm: () async {
                    await HydratedBloc.storage.delete(token);
                    GlobalToast.info('$token wiped');
                    if (mounted) setState(() {});
                  },
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Live cubits re-persist on their next emit — deleting here only '
          'sticks after a restart-before-emit.',
          style: DebugOverlayTheme.ui.copyWith(
            fontSize: 10,
            color: DebugOverlayTheme.textDimmer,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        _SectionHeader(
          title: 'Secure storage',
          icon: Icons.lock_rounded,
          color: const Color(0xFFFFA726),
          count: kIsWeb ? 'web' : '${_secureSnapshot?.length ?? 0} key(s)',
          onRefresh: _refreshSecure,
          onClearAll: (_secureSnapshot?.isEmpty ?? true)
              ? null
              : () => _confirm(
                  context,
                  title: 'Clear ALL secure storage?',
                  body:
                      'Wipes every key in the keychain. Auth tokens / '
                      'encrypted prefs go with them. Continue?',
                  onConfirm: () async {
                    await _secure.deleteAll();
                    GlobalToast.info('Secure storage cleared');
                    await _refreshSecure();
                  },
                ),
        ),
        _SecureBody(
          loading: _loadingSecure,
          snapshot: _secureSnapshot,
          error: _secureError,
          expanded: _expanded,
          onToggle: (k) => setState(() {
            _expanded.contains(k) ? _expanded.remove(k) : _expanded.add(k);
          }),
          onDelete: (k) => _confirm(
            context,
            title: 'Delete $k?',
            body: 'Removes the key from the OS keychain. App stays up.',
            onConfirm: () async {
              await _secure.delete(key: k);
              GlobalToast.info('$k deleted');
              await _refreshSecure();
            },
          ),
        ),
      ],
    );
  }

  Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required Future<void> Function() onConfirm,
  }) async {
    final ok = await debugConfirmDialog(
      context,
      title: title,
      body: body,
      confirmLabel: CommonStrings.delete,
      destructive: true,
    );
    if (ok) await onConfirm();
  }
}

// ─────────────────────────────────────────────────────────────
// Section header + group
// ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
    required this.count,
    required this.onRefresh,
    required this.onClearAll,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String count;
  final VoidCallback onRefresh;
  final VoidCallback? onClearAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
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
          const SizedBox(width: 6),
          Text(
            count,
            style: DebugOverlayTheme.mono.copyWith(
              fontSize: 10,
              color: DebugOverlayTheme.textDimmer,
            ),
          ),
          const Spacer(),
          if (onClearAll != null)
            GlobalIconButton(
              tooltip: 'Clear all',
              enforceMinTouchTarget: false,
              iconData: Icons.delete_sweep_rounded,
              onPressed: onClearAll,
              iconSize: 14,
              style: const ButtonStateStyle(
                width: 28,
                height: 28,
                foregroundColor: Color(0xFFEF5350),
              ),
            ),
          GlobalIconButton(
            tooltip: 'Refresh',
            enforceMinTouchTarget: false,
            iconData: Icons.refresh_rounded,
            onPressed: onRefresh,
            iconSize: 14,
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

class _Group extends StatelessWidget {
  const _Group({required this.children});

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

// ─────────────────────────────────────────────────────────────
// HydratedBloc row
// ─────────────────────────────────────────────────────────────

class _HydratedRow extends StatelessWidget {
  const _HydratedRow({
    required this.token,
    required this.expanded,
    required this.onToggle,
    required this.onDelete,
  });

  final String token;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final raw = HydratedBloc.storage.read(token);
    final exists = raw != null;
    final pretty = exists ? _prettyJson(raw) : '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: exists ? onToggle : null,
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 7, 6, 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  AnimatedRotation(
                    turns: expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      exists
                          ? Icons.chevron_right_rounded
                          : Icons.remove_rounded,
                      size: 16,
                      color: exists
                          ? DebugOverlayTheme.accentDefault
                          : DebugOverlayTheme.textDimmer,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      token,
                      style: DebugOverlayTheme.mono.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: exists
                            ? DebugOverlayTheme.text
                            : DebugOverlayTheme.textDimmer,
                      ),
                    ),
                  ),
                  Text(
                    exists ? _sizeOf(pretty) : 'not persisted',
                    style: DebugOverlayTheme.mono.copyWith(
                      fontSize: 10,
                      color: DebugOverlayTheme.textDimmer,
                    ),
                  ),
                  if (exists) ...[
                    const SizedBox(width: 2),
                    GlobalIconButton(
                      tooltip: 'Copy JSON',
                      enforceMinTouchTarget: false,
                      iconData: Icons.copy_rounded,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: pretty));
                        GlobalToast.info('$token JSON copied');
                      },
                      iconSize: 14,
                      style: const ButtonStateStyle(
                        width: 28,
                        height: 28,
                        foregroundColor: DebugOverlayTheme.textDim,
                      ),
                    ),
                    GlobalIconButton(
                      tooltip: 'Delete',
                      enforceMinTouchTarget: false,
                      iconData: Icons.delete_outline_rounded,
                      onPressed: onDelete,
                      iconSize: 14,
                      style: const ButtonStateStyle(
                        width: 28,
                        height: 28,
                        foregroundColor: DebugOverlayTheme.textDim,
                      ),
                    ),
                  ],
                ],
              ),
              if (expanded && exists)
                Container(
                  margin: const EdgeInsets.fromLTRB(24, 6, 4, 2),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DebugOverlayTheme.bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText.rich(
                    TextSpan(
                      style: DebugOverlayTheme.mono.copyWith(
                        fontSize: 10.5,
                        height: 1.45,
                        color: DebugOverlayTheme.text,
                      ),
                      children: _jsonSpans(pretty),
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

// ─────────────────────────────────────────────────────────────
// Secure storage body
// ─────────────────────────────────────────────────────────────

class _SecureBody extends StatelessWidget {
  const _SecureBody({
    required this.loading,
    required this.snapshot,
    required this.error,
    required this.expanded,
    required this.onToggle,
    required this.onDelete,
  });

  final bool loading;
  final Map<String, String>? snapshot;
  final Object? error;
  final Set<String> expanded;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _note('Secure storage inspection skipped on web.');
    }
    if (loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: DebugOverlayTheme.accentDefault,
            ),
          ),
        ),
      );
    }
    if (error != null) {
      return Text(
        'Read failed: $error',
        style: DebugOverlayTheme.mono.copyWith(
          fontSize: 11,
          color: const Color(0xFFEF5350),
        ),
      );
    }
    final map = snapshot;
    if (map == null || map.isEmpty) {
      return _note('No entries in the keychain.');
    }
    final keys = map.keys.toList()..sort();
    return _Group(
      children: [
        for (final k in keys)
          _SecureRow(
            keyName: k,
            value: map[k]!,
            expanded: expanded.contains(k),
            onToggle: () => onToggle(k),
            onDelete: () => onDelete(k),
          ),
      ],
    );
  }

  static Widget _note(String text) => Container(
    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
    decoration: BoxDecoration(
      color: DebugOverlayTheme.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: DebugOverlayTheme.border),
    ),
    child: Text(
      text,
      style: DebugOverlayTheme.ui.copyWith(
        fontSize: 11,
        color: DebugOverlayTheme.textDimmer,
      ),
    ),
  );
}

class _SecureRow extends StatelessWidget {
  const _SecureRow({
    required this.keyName,
    required this.value,
    required this.expanded,
    required this.onToggle,
    required this.onDelete,
  });

  final String keyName;
  final String value;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    // Always mask the preview — these are tokens / encrypted prefs by
    // definition. Expand for the full value if the dev really needs it.
    final masked = _mask(value);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  AnimatedRotation(
                    turns: expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: DebugOverlayTheme.accentDefault,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      keyName,
                      style: DebugOverlayTheme.mono.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    masked,
                    style: DebugOverlayTheme.mono.copyWith(
                      fontSize: 10.5,
                      color: DebugOverlayTheme.textDim,
                    ),
                  ),
                  GlobalIconButton(
                    tooltip: 'Copy raw value',
                    enforceMinTouchTarget: false,
                    iconData: Icons.copy_rounded,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: value));
                      GlobalToast.info('$keyName copied');
                    },
                    iconSize: 14,
                    style: const ButtonStateStyle(
                      width: 26,
                      height: 26,
                      foregroundColor: DebugOverlayTheme.textDim,
                    ),
                  ),
                  GlobalIconButton(
                    tooltip: 'Delete',
                    enforceMinTouchTarget: false,
                    iconData: Icons.delete_outline_rounded,
                    onPressed: onDelete,
                    iconSize: 14,
                    style: const ButtonStateStyle(
                      width: 26,
                      height: 26,
                      foregroundColor: DebugOverlayTheme.textDim,
                    ),
                  ),
                ],
              ),
              if (expanded)
                Container(
                  margin: const EdgeInsets.fromLTRB(22, 4, 4, 2),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DebugOverlayTheme.bg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    value,
                    style: DebugOverlayTheme.mono.copyWith(fontSize: 10.5),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _mask(String v) {
    if (v.isEmpty) return '<empty>';
    if (v.length <= 8) return '••••';
    return '${v.substring(0, 4)}•••${v.substring(v.length - 4)}';
  }
}

// ─────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────

String _prettyJson(Object? raw) {
  try {
    return const JsonEncoder.withIndent('  ').convert(raw);
  } catch (_) {
    return raw.toString();
  }
}

String _sizeOf(String s) {
  final n = s.length;
  if (n < 1024) return '$n B';
  return '${(n / 1024).toStringAsFixed(1)} KB';
}

/// Regex JSON tokenizer — same palette as the network inspector.
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
