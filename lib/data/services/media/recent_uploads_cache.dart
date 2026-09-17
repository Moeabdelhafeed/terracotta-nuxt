// Dart imports:
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

// Package imports:
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// Project imports:
import '../../../shared/module/media_picker/media_picker_models.dart';

// ---------------------------------------------------------------------------
// RecentUploadsCache
// ---------------------------------------------------------------------------

/// Persistent "recently added" store for the media pickers.
///
/// Keyed by [AttachmentKind] (image / video / file). Caller pushes
/// items after a successful upload so the user can re-pick them
/// without going through the native sheet again.
///
/// ## Persistence
///  - Metadata lives in [HydratedBloc.storage] under
///    [_storageKey] — survives app restart.
///  - [PickerItemFile] sources are **copied** to
///    `<app docs>/media_cache/<kind>/<uuid>.<ext>` so the stored
///    path stays valid after the OS garbage-collects temp dirs.
///  - URLs stored as-is; no download.
///
/// ## Dedup
///  - URL items deduped by exact string match.
///  - File items deduped by `(length, filename, mtime)` signature
///    — cheap to compute, good enough to catch the "same photo
///    picked twice via camera" case without pulling in `crypto`.
///
/// ## Eviction
///  - FIFO per kind, capped at [maxPerKind] (default 20). Evicted
///    file entries delete their backing file from disk.
///  - [recent] self-heals: any file entry whose backing file is
///    gone is dropped and the store rewritten.
class RecentUploadsCache {
  RecentUploadsCache({int maxPerKind = 20})
    : _box = _CacheBox(maxPerKind: maxPerKind) {
    _box.load();
  }

  final _CacheBox _box;

  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Fires on every add / remove / clear. Listeners should call
  /// [recent] to refresh.
  Stream<void> get changes => _changes.stream;

  /// Newest-first list for [kind]. Self-heals stale file entries.
  List<PickerItem> recent(AttachmentKind kind) {
    final pruned = _box.prune(kind);
    if (pruned) unawaited(_box.save());
    return _box.entries(kind).map((e) => e.toItem()).toList();
  }

  /// Store [item] under [kind]. For [PickerItemFile], the source is
  /// copied into the persistent cache directory and the returned
  /// [PickerItem] reflects the new stable path.
  Future<PickerItem> add(PickerItem item, AttachmentKind kind) async {
    // Bytes are not cached. This cache remembers WHERE something is —
    // a path or a URL — and bytes are neither; holding them would make
    // it a store of files it has to write, name and clean up, which is
    // a different thing from the one it is. The item comes back
    // unchanged, so a caller sees a pick that simply is not offered
    // again next time.
    if (item is PickerItemBytes) return item;

    final entry = switch (item) {
      PickerItemUrl(:final url, :final filename) => _Entry(
        type: _EntryType.url,
        value: url,
        filename: filename,
        addedAt: DateTime.now().millisecondsSinceEpoch,
      ),
      PickerItemFile(:final file) => await _copyFileEntry(file, kind),
      // Returned above — the switch has to name it to be exhaustive.
      PickerItemBytes() => throw StateError('bytes are not cached'),
    };

    _box.add(kind, entry);
    await _box.save();
    _changes.add(null);
    return entry.toItem();
  }

  /// Remove [item] from [kind]. For file entries, the cached file
  /// on disk is deleted too.
  Future<void> remove(PickerItem item, AttachmentKind kind) async {
    final sig = _signatureOf(item);
    final removed = _box.removeWhere(kind, (e) => _entrySignature(e) == sig);
    for (final e in removed) {
      await e.deleteBackingFile();
    }
    if (removed.isNotEmpty) {
      await _box.save();
      _changes.add(null);
    }
  }

  /// Drop entries. Pass [kind] null to wipe every kind.
  Future<void> clear([AttachmentKind? kind]) async {
    final removed = kind == null ? _box.clearAll() : _box.clearKind(kind);
    for (final e in removed) {
      await e.deleteBackingFile();
    }
    await _box.save();
    _changes.add(null);
  }

  /// Free resources — tests + `resetServiceLocator()` flows.
  Future<void> dispose() async {
    await _changes.close();
  }

  // ─── Internals ──────────────────────────────────────────────────

  Future<_Entry> _copyFileEntry(File source, AttachmentKind kind) async {
    final srcStat = await source.stat();
    final sig = await _contentSig(source, srcStat.size);
    final dir = await _cacheDirFor(kind);
    final ext = p.extension(source.path);
    final name =
        '${DateTime.now().microsecondsSinceEpoch}'
        '_${math.Random().nextInt(1 << 32)}$ext';
    final target = File(p.join(dir.path, name));
    await source.copy(target.path);
    return _Entry(
      type: _EntryType.file,
      value: target.path,
      filename: p.basename(source.path),
      addedAt: DateTime.now().millisecondsSinceEpoch,
      length: srcStat.size,
      mtime: srcStat.modified.millisecondsSinceEpoch,
      contentSig: sig,
    );
  }

  /// SHA-1 over the first [_sigBytes] of [source] plus total size.
  /// Bounded read keeps large videos fast; the prefix + size is
  /// sufficient for picker-level dedup (collision-resistant enough
  /// for user-chosen media).
  static const int _sigBytes = 256 * 1024;

  Future<String> _contentSig(File source, int size) async {
    final digest = await sha1.bind(source.openRead(0, _sigBytes)).first;
    return '$digest:$size';
  }

  String _signatureOf(PickerItem item) => switch (item) {
    PickerItemUrl(:final url) => 'url::$url',
    PickerItemFile(:final file) => 'file::${file.path}',
    // Never stored, so never matched — but it has to answer with
    // something that cannot collide with a real entry.
    PickerItemBytes(:final filename, :final lengthInBytes) =>
      'bytes::$filename::$lengthInBytes',
  };

  String _entrySignature(_Entry e) => switch (e.type) {
    _EntryType.url => 'url::${e.value}',
    _EntryType.file => 'file::${e.value}',
  };

  // ─── Lazy helpers ───────────────────────────────────────────────

  static Future<Directory> _cacheDirFor(AttachmentKind kind) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'media_cache', kind.name));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
}

// ---------------------------------------------------------------------------
// Internal model
// ---------------------------------------------------------------------------

enum _EntryType { url, file }

class _Entry {
  _Entry({
    required this.type,
    required this.value,
    required this.filename,
    required this.addedAt,
    this.length,
    this.mtime,
    this.contentSig,
  });

  factory _Entry.fromJson(Map<String, dynamic> j) => _Entry(
    type: _EntryType.values.byName(j['type'] as String),
    value: j['value'] as String,
    filename: j['filename'] as String?,
    addedAt: (j['addedAt'] as num).toInt(),
    length: (j['length'] as num?)?.toInt(),
    mtime: (j['mtime'] as num?)?.toInt(),
    contentSig: j['contentSig'] as String?,
  );

  final _EntryType type;
  final String value;
  final String? filename;
  final int addedAt;
  final int? length;
  final int? mtime;

  /// SHA-1 of the first 256 KB + size — the authoritative dedup
  /// key for file entries. image_picker hands us a fresh temp copy
  /// every pick, so path/mtime/filename vary even when content is
  /// identical. Hashing the bytes catches the true dup.
  final String? contentSig;

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'value': value,
    'filename': filename,
    'addedAt': addedAt,
    if (length != null) 'length': length,
    if (mtime != null) 'mtime': mtime,
    if (contentSig != null) 'contentSig': contentSig,
  };

  PickerItem toItem() => switch (type) {
    _EntryType.url => PickerItem.url(value, filename: filename),
    _EntryType.file => PickerItem.file(
      File(value),
      isNew: false,
      filename: filename,
    ),
  };

  /// Dedup key. URL entries: exact URL match. File entries:
  /// content signature (hash + size). Falls back to length +
  /// filename for legacy entries without a signature.
  String get dedupKey => switch (type) {
    _EntryType.url => 'url::$value',
    _EntryType.file =>
      contentSig != null ? 'file::$contentSig' : 'file::$length::$filename',
  };

  Future<void> deleteBackingFile() async {
    if (type != _EntryType.file) return;
    final f = File(value);
    try {
      if (await f.exists()) await f.delete();
    } catch (e) {
      if (kDebugMode) debugPrint('[RecentUploadsCache] delete failed: $e');
    }
  }
}

// ---------------------------------------------------------------------------
// Hydrated box — in-memory map + load/save against HydratedBloc.storage
// ---------------------------------------------------------------------------

class _CacheBox {
  _CacheBox({required this.maxPerKind});

  static const _storageKey = 'recent_uploads_cache_v1';

  final int maxPerKind;
  final Map<AttachmentKind, List<_Entry>> _entries = {
    for (final k in AttachmentKind.values) k: <_Entry>[],
  };

  void load() {
    final raw = HydratedBloc.storage.read(_storageKey);
    if (raw is! Map) return;
    for (final kind in AttachmentKind.values) {
      final list = raw[kind.name];
      if (list is! List) continue;
      _entries[kind] = list
          .whereType<Map>()
          .map((m) => _Entry.fromJson(m.cast<String, dynamic>()))
          .toList();
    }
  }

  Future<void> save() async {
    await HydratedBloc.storage.write(
      _storageKey,
      {
        for (final kind in AttachmentKind.values)
          kind.name: _entries[kind]!.map((e) => e.toJson()).toList(),
      },
    );
  }

  List<_Entry> entries(AttachmentKind kind) =>
      List.unmodifiable(_entries[kind]!);

  void add(AttachmentKind kind, _Entry entry) {
    final list = _entries[kind]!;
    // Dedup by signature.
    list.removeWhere((e) => e.dedupKey == entry.dedupKey);
    list.insert(0, entry);
    // FIFO cap.
    if (list.length > maxPerKind) {
      final overflow = list.sublist(maxPerKind);
      list.removeRange(maxPerKind, list.length);
      for (final e in overflow) {
        unawaited(e.deleteBackingFile());
      }
    }
  }

  List<_Entry> removeWhere(AttachmentKind kind, bool Function(_Entry) test) {
    final list = _entries[kind]!;
    final removed = list.where(test).toList();
    list.removeWhere(test);
    return removed;
  }

  List<_Entry> clearKind(AttachmentKind kind) {
    final list = _entries[kind]!;
    final removed = List<_Entry>.from(list);
    list.clear();
    return removed;
  }

  List<_Entry> clearAll() {
    final removed = [for (final l in _entries.values) ...l];
    for (final l in _entries.values) {
      l.clear();
    }
    return removed;
  }

  /// Drop stale file entries. Returns true when anything was
  /// removed so the caller knows to persist.
  bool prune(AttachmentKind kind) {
    final list = _entries[kind]!;
    final before = list.length;
    list.removeWhere((e) {
      if (e.type != _EntryType.file) return false;
      return !File(e.value).existsSync();
    });
    return list.length != before;
  }
}

// ---------------------------------------------------------------------------
// Convenience: jsonEncode helper if a caller wants to ship cache
// ---------------------------------------------------------------------------

/// Exposed for debugging; not part of the public API.
@visibleForTesting
String debugDumpCache(RecentUploadsCache cache) {
  final map = {
    for (final k in AttachmentKind.values)
      k.name: cache.recent(k).map((e) => e.toString()).toList(),
  };
  return jsonEncode(map);
}
