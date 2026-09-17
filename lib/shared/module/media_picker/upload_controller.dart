// Flutter imports:
import 'package:flutter/foundation.dart';

// Project imports:
import 'media_picker_models.dart';

/// Lifecycle of a single picker-item upload.
enum UploadStatus { pending, uploading, done, error, cancelled }

/// The app's uploader, for every picker that does not carry its own.
///
/// The module has the whole upload UI — a ring per tile, an error
/// overlay, retry on tap — and nothing to drive it: a caller had to
/// build an [UploadController] and hand it to every picker, so most
/// call sites simply had no upload at all.
///
/// This is the seam the audio module's lock screen already uses, for
/// the same reason: `lib/shared/module` may not reach the API layer,
/// so an app wires it once in `bootstrap` and every picker gets it.
/// Left null, nothing changes — a picker with no controller and no
/// seam picks files and does not upload them.
class MediaUpload {
  const MediaUpload._();

  /// How a picked item actually reaches a server. Set in `bootstrap`.
  static Uploader? uploader;

  /// Whether an app has wired one.
  static bool get isWired => uploader != null;

  /// A controller over the seam, or null when nothing is wired.
  ///
  /// Null rather than a controller that throws on first use: a picker
  /// handed one of those would draw upload chrome for an upload that
  /// cannot happen.
  static UploadController? controller() {
    final fn = uploader;
    return fn == null ? null : UploadController(uploader: fn);
  }

  /// Forgets the wiring, so one test cannot decide the next one's
  /// answer.
  @visibleForTesting
  static void reset() => uploader = null;
}

/// Immutable snapshot of one item's upload progress. Tiles render
/// from this — [progress] is the 0..1 value driving the ring,
/// [error] surfaces the last failure so callers can build rich
/// retry UI.
@immutable
class UploadState {
  const UploadState({
    this.status = UploadStatus.pending,
    this.progress = 0,
    this.error,
  });

  final UploadStatus status;
  final double progress;
  final Object? error;

  bool get isUploading => status == UploadStatus.uploading;
  bool get isDone => status == UploadStatus.done;
  bool get isError => status == UploadStatus.error;
  bool get isPending => status == UploadStatus.pending;
  bool get isCancelled => status == UploadStatus.cancelled;

  /// Whether a retry would do anything.
  bool get canRetry => isError || isCancelled;
}

/// Function the caller implements to do the actual work. Receives
/// the item to upload and an `onProgress` callback to push 0..1
/// updates; return to indicate success, throw to indicate failure.
typedef Uploader =
    Future<void> Function(PickerItem item, ValueChanged<double> onProgress);

/// Per-item upload tracker. Picker tiles listen to this to render
/// progress rings + error overlays + retry affordances. Caller
/// supplies the [uploader] closure — usually wraps a Dio request
/// or chunked S3 client.
///
/// Attach via `GlobalImagePicker.uploadController` (or equivalent
/// on video / file / attachment pickers). Start an item by
/// tapping retry on an error tile, by calling [start] manually
/// from `onChanged`, or by setting `autoUpload: true` on the
/// picker which fires [start] for each new `PickerItemFile`.
class UploadController extends ChangeNotifier {
  UploadController({required this.uploader});

  final Uploader uploader;
  final Map<String, UploadState> _states = {};

  /// Items whose upload has been asked to stop.
  ///
  /// A `Future` cannot be cancelled, so this is what the progress
  /// callback checks: the transport keeps running until its next
  /// report and then finds itself unwanted. Anything better needs the
  /// uploader itself to take a cancel token, which is the app's to
  /// give.
  final Set<String> _cancelled = {};

  UploadState stateOf(PickerItem item) =>
      _states[_keyOf(item)] ?? const UploadState();

  /// Is any item currently uploading? Useful for disabling the
  /// submit button until all tiles land as done.
  bool get anyUploading => _states.values.any((s) => s.isUploading);

  /// Are all tracked items done?
  bool get allDone =>
      _states.isNotEmpty && _states.values.every((s) => s.isDone);

  /// Kick off / re-kick an upload. No-op when already uploading.
  Future<void> start(PickerItem item) async {
    final key = _keyOf(item);
    final current = _states[key];
    if (current?.isUploading ?? false) return;
    _cancelled.remove(key);
    _states[key] = const UploadState(status: UploadStatus.uploading);
    notifyListeners();
    try {
      await uploader(item, (p) {
        if (_cancelled.contains(key)) return;
        final clamped = p.clamp(0.0, 1.0);
        _states[key] = UploadState(
          status: UploadStatus.uploading,
          progress: clamped,
        );
        notifyListeners();
      });
      // A cancel that landed mid-flight WINS over the result: the
      // reader asked for it to stop, and reporting success for
      // something they cancelled is the one answer they will not
      // expect.
      _states[key] = _cancelled.contains(key)
          ? const UploadState(status: UploadStatus.cancelled)
          : const UploadState(status: UploadStatus.done, progress: 1);
    } catch (e) {
      _states[key] = _cancelled.contains(key)
          ? const UploadState(status: UploadStatus.cancelled)
          : UploadState(status: UploadStatus.error, error: e);
    }
    _cancelled.remove(key);
    notifyListeners();
  }

  /// Asks an in-flight upload to stop.
  ///
  /// The tile shows it as cancelled straight away — the reader pressed
  /// something and it has to answer — while the transport finishes
  /// whatever chunk it was on.
  void cancel(PickerItem item) {
    final key = _keyOf(item);
    if (!(_states[key]?.isUploading ?? false)) return;
    _cancelled.add(key);
    _states[key] = const UploadState(status: UploadStatus.cancelled);
    notifyListeners();
  }

  /// Starts everything that failed or was stopped.
  Future<void> retryFailed(List<PickerItem> items) async {
    for (final item in items) {
      if (stateOf(item).canRetry) await start(item);
    }
  }

  /// How many are still to finish — for a submit button that should
  /// not fire yet.
  int get inFlight => _states.values.where((s) => s.isUploading).length;

  /// Clear tracking for [item] — use when the tile is removed.
  void forget(PickerItem item) {
    _states.remove(_keyOf(item));
    notifyListeners();
  }

  /// Drop all state — handy for "upload again from scratch".
  void reset() {
    _states.clear();
    notifyListeners();
  }

  /// Stable key per item across rebuilds. File entries identify
  /// by path; URL entries by URL string.
  static String _keyOf(PickerItem item) => switch (item) {
    PickerItemFile(:final file) => 'f::${file.path}',
    PickerItemUrl(:final url) => 'u::$url',
    // Bytes have no path to name them by, so the name and the LENGTH
    // are what stand in — two picks of the same photograph pasted
    // twice are the same upload, and two different images are not.
    PickerItemBytes(:final filename, :final lengthInBytes) =>
      'b::$filename::$lengthInBytes',
  };
}
