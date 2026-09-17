import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard;

import '../../../../core/navigation/go_router_config.dart';
import '../../../../data/stores/debug_overlay_prefs.dart';
import '../../buttons/global_icon_button.dart';
import '../../text_field/text_field.dart';
import '../debug_overlay_models.dart';
import '../widgets/debug_text_field.dart';

/// Deep-link tester. Paste any path or full URL — the resolved route
/// previews live under the field — then Go routes via `GoRouter.go`.
/// Recent inputs are MRU-cached in [DebugOverlayPrefs.recentDeepLinks]
/// so common flows replay without retyping.
class DebugDeepLinksView extends StatefulWidget {
  const DebugDeepLinksView({super.key});

  @override
  State<DebugDeepLinksView> createState() => _DebugDeepLinksViewState();
}

class _DebugDeepLinksViewState extends State<DebugDeepLinksView> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _go(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      setState(() => _error = 'Enter a URL or path');
      return;
    }
    final path = _toPath(trimmed);
    if (path == null) {
      setState(() => _error = 'Could not parse "$trimmed" as a route');
      return;
    }
    setState(() => _error = null);
    DebugOverlayPrefs.pushRecentDeepLink(trimmed);
    GoRouterConfig.router.go(path);
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    setState(() {
      _ctrl.text = text;
      _error = null;
    });
  }

  /// Accept three forms:
  ///   - Full URL (`https://app.example/foo/bar`) → strip host, keep path+query.
  ///   - `app://...` deep-link scheme → same as above.
  ///   - Bare path (`/foo`) or relative (`foo`) → prefix `/` if missing.
  ///
  /// Empty / unparseable inputs return null so the caller surfaces an
  /// error in the form.
  String? _toPath(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null) return null;
    if (uri.hasScheme) {
      final tail = uri.path.isEmpty ? '/' : uri.path;
      return uri.hasQuery ? '$tail?${uri.query}' : tail;
    }
    return raw.startsWith('/') ? raw : '/$raw';
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = _ctrl.text.trim();
    final resolved = trimmed.isEmpty ? null : _toPath(trimmed);
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      children: [
        _FlatSection(
          title: 'Navigate',
          icon: Icons.send_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DebugTextField(
                controller: _ctrl,
                hint: 'e.g. /settings or app://feed/42',
                onChanged: (_) => setState(() => _error = null),
                onSubmitted: _go,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 10,
                ),
                prefixIcon: const Icon(
                  Icons.link_rounded,
                  size: 16,
                  color: DebugOverlayTheme.textDim,
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 30),
                suffix: TextFieldSuffix.widget(
                  GlobalIconButton(
                    tooltip: 'Paste',
                    enforceMinTouchTarget: false,
                    iconData: Icons.content_paste_rounded,
                    onPressed: _paste,
                    iconSize: 14,
                    style: const ButtonStateStyle(
                      width: 30,
                      height: 30,
                      foregroundColor: DebugOverlayTheme.textDim,
                    ),
                  ),
                ),
                suffixIconConstraints: const BoxConstraints(
                  minHeight: 30,
                  maxHeight: 30,
                ),
              ),
              const SizedBox(height: 6),
              // Live parse preview — see what Go will route BEFORE going.
              if (_error != null)
                Text(
                  _error!,
                  style: DebugOverlayTheme.ui.copyWith(
                    fontSize: 11,
                    color: const Color(0xFFEF5350),
                  ),
                )
              else if (resolved != null)
                Row(
                  children: [
                    const Icon(
                      Icons.subdirectory_arrow_right_rounded,
                      size: 12,
                      color: DebugOverlayTheme.textDimmer,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'go → $resolved',
                        overflow: TextOverflow.ellipsis,
                        style: DebugOverlayTheme.mono.copyWith(
                          fontSize: 10.5,
                          color: DebugOverlayTheme.textDim,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 10),
              _GoButton(onTap: () => _go(_ctrl.text)),
            ],
          ),
        ),
        ValueListenableBuilder<List<String>>(
          valueListenable: DebugOverlayPrefs.recentDeepLinks,
          builder: (_, recents, _) {
            return _FlatSection(
              title: 'Recent',
              icon: Icons.history_rounded,
              trailing: recents.isEmpty
                  ? null
                  : const GlobalIconButton(
                      tooltip: 'Clear all',
                      enforceMinTouchTarget: false,
                      iconData: Icons.delete_sweep_rounded,
                      onPressed: DebugOverlayPrefs.clearRecentDeepLinks,
                      iconSize: 14,
                      style: ButtonStateStyle(
                        width: 28,
                        height: 28,
                        foregroundColor: DebugOverlayTheme.textDim,
                      ),
                    ),
              child: recents.isEmpty
                  ? Text(
                      'Links you fire land here for one-tap replay.',
                      style: DebugOverlayTheme.ui.copyWith(
                        fontSize: 11,
                        color: DebugOverlayTheme.textDimmer,
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < recents.length; i++)
                          Padding(
                            padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
                            child: _RecentRow(
                              url: recents[i],
                              onTap: () {
                                _ctrl.text = recents[i];
                                _go(recents[i]);
                              },
                              onEdit: () =>
                                  setState(() => _ctrl.text = recents[i]),
                              onDelete: () =>
                                  DebugOverlayPrefs.removeRecentDeepLink(
                                    recents[i],
                                  ),
                            ),
                          ),
                      ],
                    ),
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────

/// Accent-filled Go — the app-theme FilledButton clashed with the dev
/// surface (picked up the app's accent), same as the jump sheet.
class _GoButton extends StatelessWidget {
  const _GoButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = DebugOverlayTheme.accent;
    return Material(
      color: accent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: Colors.black.withValues(alpha: 0.15),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: Colors.black,
              ),
              const SizedBox(width: 6),
              Text(
                'Go',
                style: DebugOverlayTheme.ui.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.url,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final String url;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DebugOverlayTheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 4, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: DebugOverlayTheme.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.link_rounded,
                size: 14,
                color: DebugOverlayTheme.textDim,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  url,
                  style: DebugOverlayTheme.mono.copyWith(fontSize: 11.5),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              GlobalIconButton(
                tooltip: 'Edit in field',
                enforceMinTouchTarget: false,
                iconData: Icons.edit_rounded,
                onPressed: onEdit,
                iconSize: 14,
                style: const ButtonStateStyle(
                  width: 24,
                  height: 24,
                  foregroundColor: DebugOverlayTheme.textDimmer,
                ),
              ),
              GlobalIconButton(
                tooltip: 'Remove',
                enforceMinTouchTarget: false,
                iconData: Icons.close_rounded,
                onPressed: onDelete,
                iconSize: 14,
                style: const ButtonStateStyle(
                  width: 24,
                  height: 24,
                  foregroundColor: DebugOverlayTheme.textDimmer,
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
