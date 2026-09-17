// Dart imports:
import 'dart:async';
import 'dart:io' show File, Platform;

// Package imports:
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart' as sdd;

import '../../../core/extensions/theme_colors_extension.dart';
import 'media_picker_style.dart';

/// Drops OS-delivered files onto a picker slot. Desktop + web
/// routes through `desktop_drop`; iPad iOS routes through
/// `super_drag_and_drop` (the `desktop_drop` plugin has no iOS
/// implementation). Android + phone iOS fall through as a no-op —
/// those platforms don't expose a drop target outside DeX / iPad
/// split-view.
///
/// [onFilesDropped] receives the list of saved files once a drop
/// completes. `extensionWhitelist` filters incoming paths per
/// picker context (null = accept all).
class PickerDropRegion extends StatelessWidget {
  const PickerDropRegion({
    super.key,
    required this.child,
    required this.onFilesDropped,
    this.extensionWhitelist,
    this.enabled = true,
  });

  final Widget child;
  final Future<void> Function(List<File> files) onFilesDropped;
  final List<String>? extensionWhitelist;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    if (_useSuperDragAndDrop(context)) {
      return _SuperDropImpl(
        onFilesDropped: onFilesDropped,
        extensionWhitelist: extensionWhitelist,
        child: child,
      );
    }
    return _DesktopDropImpl(
      onFilesDropped: onFilesDropped,
      extensionWhitelist: extensionWhitelist,
      child: child,
    );
  }

  /// Platform + form-factor gate. iPad iOS (shortest side ≥ 600dp)
  /// is the practical sweet spot where drag-drop is common (Files /
  /// Photos split-view). iPhone + Android ignored — drag gestures
  /// aren't part of their UX.
  bool _useSuperDragAndDrop(BuildContext context) {
    if (kIsWeb) return false;
    if (!Platform.isIOS) return false;
    return MediaQuery.sizeOf(context).shortestSide >= 600;
  }
}

// ---------------------------------------------------------------------------
// desktop_drop path — macOS / Windows / Linux / web
// ---------------------------------------------------------------------------

class _DesktopDropImpl extends StatefulWidget {
  const _DesktopDropImpl({
    required this.child,
    required this.onFilesDropped,
    required this.extensionWhitelist,
  });

  final Widget child;
  final Future<void> Function(List<File> files) onFilesDropped;
  final List<String>? extensionWhitelist;

  @override
  State<_DesktopDropImpl> createState() => _DesktopDropImplState();
}

class _DesktopDropImplState extends State<_DesktopDropImpl> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (_) => setState(() => _hover = true),
      onDragExited: (_) => setState(() => _hover = false),
      onDragDone: _onDragDone,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          if (_hover) _dropHighlight(context),
        ],
      ),
    );
  }

  Future<void> _onDragDone(DropDoneDetails detail) async {
    setState(() => _hover = false);
    final collected = <File>[];
    for (final x in detail.files) {
      if (!_allowed(x.path, widget.extensionWhitelist)) continue;
      final f = File(x.path);
      if (await f.exists()) collected.add(f);
    }
    if (collected.isEmpty) return;
    await widget.onFilesDropped(collected);
  }
}

// ---------------------------------------------------------------------------
// super_drag_and_drop path — iPad iOS (and works on macOS too, but
// desktop_drop already covers that more cheaply)
// ---------------------------------------------------------------------------

class _SuperDropImpl extends StatefulWidget {
  const _SuperDropImpl({
    required this.child,
    required this.onFilesDropped,
    required this.extensionWhitelist,
  });

  final Widget child;
  final Future<void> Function(List<File> files) onFilesDropped;
  final List<String>? extensionWhitelist;

  @override
  State<_SuperDropImpl> createState() => _SuperDropImplState();
}

class _SuperDropImplState extends State<_SuperDropImpl> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return sdd.DropRegion(
      formats: const [sdd.Formats.fileUri],
      hitTestBehavior: HitTestBehavior.opaque,
      onDropOver: (_) {
        if (!_hover) setState(() => _hover = true);
        return sdd.DropOperation.copy;
      },
      onDropLeave: (_) {
        if (_hover) setState(() => _hover = false);
      },
      onPerformDrop: _onPerformDrop,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          if (_hover) _dropHighlight(context),
        ],
      ),
    );
  }

  Future<void> _onPerformDrop(sdd.PerformDropEvent event) async {
    final futures = <Future<void>>[];
    final collected = <File>[];
    for (final item in event.session.items) {
      final reader = item.dataReader;
      if (reader == null) continue;
      if (!reader.canProvide(sdd.Formats.fileUri)) continue;
      final c = Completer<void>();
      futures.add(c.future);
      reader.getValue<Uri>(sdd.Formats.fileUri, (value) async {
        try {
          final uri = value;
          if (uri == null) return;
          final path = uri.toFilePath();
          if (!_allowed(path, widget.extensionWhitelist)) return;
          final f = File(path);
          if (await f.exists()) {
            collected.add(f);
            return;
          }
          // iPad can hand us security-scoped URIs whose path is not
          // directly readable — copy the bytes into the app sandbox
          // via the virtual file receiver (if available) as a
          // fallback. Best effort; skip on failure.
          final receiver = await reader.getVirtualFileReceiver();
          if (receiver == null) return;
          final tmp = await getTemporaryDirectory();
          final (pathFuture, _) = receiver.copyVirtualFile(
            targetFolder: tmp.path,
          );
          final actualOutPath = await pathFuture;
          final out = File(actualOutPath);
          if (await out.exists()) collected.add(out);
        } finally {
          c.complete();
        }
      });
    }
    await Future.wait(futures);
    if (mounted) setState(() => _hover = false);
    if (collected.isNotEmpty) await widget.onFilesDropped(collected);
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

bool _allowed(String path, List<String>? whitelist) {
  if (whitelist == null) return true;
  final dot = path.lastIndexOf('.');
  if (dot < 0) return false;
  final ext = path.substring(dot + 1).toLowerCase();
  return whitelist.map((e) => e.toLowerCase()).contains(ext);
}

Widget _dropHighlight(BuildContext context) {
  final primary = context.primaryColors;
  return Positioned.fill(
    child: IgnorePointer(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: primary.primary.withValues(alpha: 0.12),
          border: Border.all(color: primary.primary, width: 2),
          borderRadius: BorderRadius.circular(MediaPickerDefaults.tileRadius),
        ),
      ),
    ),
  );
}
