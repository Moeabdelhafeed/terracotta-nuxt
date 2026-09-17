import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/types/result.dart';
import '../../../core/utils/loggers/logger.dart';
import '../../api/calls/content_apis.dart';
import '../../models/terracotta/content/media_library.dart';
import '../../models/terracotta/core/api_image.dart';

/// THE STUDIO'S OWN ARTWORK, with the app's as the fallback.
///
/// ## The contract
///
/// Every dynamic asset has a `(section, key)` and a BUNDLED default.
///
///   * the CMS carries that key → the studio's file is shown;
///   * it does not → the bundled default is shown, **and uploaded into
///     the key** so the studio has something to edit next time.
///
/// That second half is what makes the feature usable. `GET /api/media`
/// on this backend answers `media: []` today: there is nothing to edit
/// because nothing has ever been put there, and the CMS has no way to
/// know what an `onboarding_1` is meant to look like. The app does —
/// it ships one — so it seeds the slot and the studio replaces it when
/// they want to.
///
/// **Seeding can never overwrite the studio.** It fires only when a
/// key is MISSING. Once the CMS holds a value the app reads it and
/// uploads nothing, so a stale build cannot put an old drawing back
/// over a new one.
///
/// ## What it does not do
///
/// It does not retry. A key that failed to seed is tried again on the
/// next launch and not before — a device with no signal must not spend
/// the session pushing files at a server that is not answering.
///
/// `POST /api/media` is PUBLIC on this backend (no bearer). That is
/// the server's choice and this relies on it; it is also why seeding
/// is restricted to a key nobody has filled.
class DynamicAssets {
  DynamicAssets({MediaFetch? fetch, MediaUpload? upload})
    : _fetch = fetch ?? ContentApis.getMedia,
      _upload = upload ?? ContentApis.uploadMedia;

  final MediaFetch _fetch;
  final MediaUpload _upload;

  /// The consumer group. `app` or `web` — never the bucket name.
  static const group = 'app';

  MediaLibrary? _library;

  /// Keys this run has already tried to seed, so one miss is one
  /// upload however many widgets ask for it.
  final _seeded = <String>{};

  /// Whether the library has arrived. Until it has, every lookup
  /// answers null and every caller draws its bundled default — which
  /// is the right thing to show while a network call is in flight.
  bool get loaded => _library != null;

  /// Read the whole group once. Never throws.
  Future<void> load({CancelToken? cancelToken}) async {
    switch (await _fetch(group: group, cancelToken: cancelToken)) {
      case Success(:final value):
        _library = value;
        Logger.m.i(
          '[Media] ${value.media.length} sections from the CMS',
        );
      case Failure(:final error):
        Logger.m.w('[Media] unavailable, using bundled assets: $error');
    }
  }

  /// The studio's image for this slot, or null to use the bundled one.
  ApiImage? imageFor(String section, String key) =>
      _library?.slot(section, key)?.image;

  /// Warm every image the manifest carries.
  ///
  /// The widget already shows the bundled drawing while a remote file
  /// downloads, so nothing waits on this — it only means the swap has
  /// usually happened before the screen is reached, instead of a
  /// visible change a second in.
  ///
  /// Cheap on purpose: this manifest is the app's own illustration
  /// set, a handful of small files, not a catalogue. Called after the
  /// first frame and never awaited.
  Future<void> precache(BuildContext context) async {
    final library = _library;
    if (library == null) return;

    for (final section in library.media.values) {
      for (final item in section.values) {
        final url = item.image?.display ?? '';
        if (url.isEmpty) continue;
        if (!context.mounted) return;
        // Each one on its own: a 404 on one drawing must not stop the
        // rest being warmed.
        try {
          await precacheImage(NetworkImage(url), context);
        } on Object {
          continue;
        }
      }
    }
  }

  /// Put the bundled default into an empty slot.
  ///
  /// Called by the widget that just fell back to it. Does nothing when
  /// the library has not arrived (the key may well exist), when the
  /// key is already filled, or when this run has tried already.
  Future<void> seed({
    required String section,
    required String key,
    required String assetPath,
  }) async {
    if (!loaded) return;
    if (imageFor(section, key) != null) return;
    if (!_seeded.add('$section/$key')) return;

    try {
      // The bundle is not a filesystem — the upload wants a path, so
      // the bytes are written out first.
      final bytes = await rootBundle.load(assetPath);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/seed_${section}_$key${_ext(assetPath)}');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);

      switch (await _upload(
        subGroup: section,
        key: key,
        filePath: file.path,
        group: group,
      )) {
        case Success():
          Logger.m.i('[Media] seeded $section/$key from the bundle');
        case Failure(:final error):
          Logger.m.w('[Media] could not seed $section/$key: $error');
      }
      // Whatever happened, the copy is not wanted.
      await file.delete().catchError((_) => file);
    } on Object catch (e) {
      // A missing bundle entry, a read-only temp dir, a refused
      // upload. None of it is the reader's problem: they are looking
      // at the bundled asset either way.
      Logger.m.w('[Media] seeding $section/$key failed: $e');
    }
  }

  static String _ext(String assetPath) {
    final dot = assetPath.lastIndexOf('.');
    return dot == -1 ? '' : assetPath.substring(dot);
  }

  @visibleForTesting
  void setLibrary(MediaLibrary? library) => _library = library;
}

typedef MediaFetch =
    AsyncResult<MediaLibrary> Function({
      String? group,
      CancelToken? cancelToken,
      Duration? timeout,
    });

typedef MediaUpload =
    AsyncResult<Map<String, dynamic>> Function({
      required String subGroup,
      required String key,
      required String filePath,
      String? group,
      String? thumbnailPath,
      CancelToken? cancelToken,
      Duration? timeout,
    });
