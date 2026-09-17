// Dart imports:
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/media_strings.dart';
import '../sheet/global_sheet.dart';
import 'picker_sheet_row.dart';

// ---------------------------------------------------------------------------
// Result types
// ---------------------------------------------------------------------------

/// Reason a picked file was rejected by a [MediaPickerValidator].
enum MediaPickerErrorCode {
  tooLarge,
  wrongExtension,
  wrongAspectRatio,
  imageTooSmall,
  imageTooLarge,
  videoTooLong,
  pickFailed,
  custom,
}

@immutable
class MediaPickerError {
  const MediaPickerError({required this.code, required this.message});

  final MediaPickerErrorCode code;
  final String message;

  @override
  String toString() => '[${code.name}] $message';
}

// ---------------------------------------------------------------------------
// Source options
// ---------------------------------------------------------------------------

/// Where the user can pick from. A picker may expose a subset
/// (image: both, video: both, file: gallery-only usually).
enum MediaPickerSourceOption { gallery, camera, clipboard }

/// Kind of attachment — image, video, or generic file. Drives the
/// icon/label on the picked tile + lets callers fan out uploads to
/// type-specific endpoints.
enum AttachmentKind { image, video, file }

// ---------------------------------------------------------------------------
// PickerItem — unified value for update screens
// ---------------------------------------------------------------------------

/// One slot in a picker. Either a freshly-picked local [File] or an
/// already-uploaded remote [url].
///
/// Update screens hydrate the picker with [PickerItem.url]s pulled
/// from the server, let the user add new [PickerItem.file]s, and
/// submit a mix of both:
/// ```dart
/// final initial = user.photos.map((u) => PickerItem.url(u)).toList();
/// // later:
/// final toUpload  = items.whereType<PickerItemFile>().map((f) => f.file);
/// final toKeep    = items.whereType<PickerItemUrl>().map((u) => u.url);
/// ```
///
/// The UI flags [PickerItemFile] tiles with a "NEW" badge when
/// [PickerItemFile.isNew] is true so the user sees at a glance what
/// will upload. Pass `isNew: false` when you reconstruct a file
/// list from a local cache after submit.
sealed class PickerItem {
  const PickerItem();

  const factory PickerItem.file(File file, {bool isNew, String? filename}) =
      PickerItemFile;
  const factory PickerItem.url(String url, {String? filename}) = PickerItemUrl;

  /// Raw bytes, for a pick that never became a file.
  ///
  /// The web has no `File` to give: a picked image arrives as bytes,
  /// and everything here took a path — so a web pick had to be
  /// written to a temporary file and read back, a round trip for
  /// something already in memory. A camera frame and an image pasted
  /// from the clipboard are the same shape.
  const factory PickerItem.bytes(
    Uint8List bytes, {
    required String filename,
    bool isNew,
  }) = PickerItemBytes;
}

/// Bytes held in memory, named by the caller.
///
/// It carries a filename because there is nothing else to call it: a
/// path at least ends in something, and a tile with no name reads as
/// a file the picker lost.
@immutable
class PickerItemBytes extends PickerItem {
  const PickerItemBytes(
    this.bytes, {
    required this.filename,
    this.isNew = true,
  });

  final Uint8List bytes;
  final String filename;
  final bool isNew;

  String get displayName => filename;

  /// What it weighs — the one validator rule that can run against
  /// bytes without touching a disk.
  int get lengthInBytes => bytes.lengthInBytes;
}

@immutable
class PickerItemFile extends PickerItem {
  const PickerItemFile(this.file, {this.isNew = true, this.filename});

  final File file;
  final bool isNew;

  /// Original basename, preserved when the physical file has been
  /// renamed (e.g. copied into [RecentUploadsCache] with a UUID).
  /// Falls back to the file path's basename for display.
  final String? filename;

  /// Display name — [filename] if set, else the basename of [file].
  String get displayName {
    if (filename != null && filename!.isNotEmpty) return filename!;
    return file.path.split(Platform.pathSeparator).last;
  }
}

@immutable
class PickerItemUrl extends PickerItem {
  const PickerItemUrl(this.url, {this.filename});

  final String url;

  /// Optional display name. Falls back to the last URL segment when
  /// null.
  final String? filename;

  /// Returns [filename] or the last path segment of [url].
  String get displayName {
    if (filename != null && filename!.isNotEmpty) return filename!;
    final segments = Uri.tryParse(url)?.pathSegments ?? const <String>[];
    return segments.isNotEmpty ? segments.last : url;
  }
}

/// One picked item in a mixed-type picker. The caller owns a
/// `List<Attachment>` and flips it from `onChanged`.
@immutable
class Attachment {
  const Attachment({required this.source, required this.kind});

  /// Local [PickerItemFile] (newly picked) or remote
  /// [PickerItemUrl] (hydrated from server).
  final PickerItem source;
  final AttachmentKind kind;

  Attachment copyWith({PickerItem? source, AttachmentKind? kind}) =>
      Attachment(source: source ?? this.source, kind: kind ?? this.kind);
}

/// How multi-select pickers arrange picked items.
///
///  - [grid]             — fixed `maxItems` slots laid out in a
///                         [Wrap], Instagram-style. Good for
///                         fixed-count avatars, attachments.
///  - [horizontalList]   — scrollable row; trailing "+" tile adds
///                         more. Good for free-count photo decks,
///                         chat composers, reels.
///  - [rows]             — full-width stacked rows; used by
///                         [GlobalFilePicker] to show filename +
///                         icon side-by-side.
enum MediaPickerLayout { grid, horizontalList, rows }

// ---------------------------------------------------------------------------
// Validator — async rules applied to a picked file before accept
// ---------------------------------------------------------------------------

typedef MediaValidatorFn = FutureOr<MediaPickerError?> Function(File file);

/// Chainable validation for picked media. Rules run top-to-bottom;
/// first failure short-circuits.
///
/// ```dart
/// const v = MediaPickerValidator(
///   maxSizeBytes: 2 * 1024 * 1024,      // 2 MB
///   allowedExtensions: ['jpg', 'png'],
///   imageAspectRatio: 1.0,              // square-only
///   imageAspectRatioTolerance: 0.05,
///   minImageSide: 200,                  // at least 200x200
/// );
/// ```
@immutable
class MediaPickerValidator {
  const MediaPickerValidator({
    this.maxSizeBytes,
    this.allowedExtensions,
    this.imageAspectRatio,
    this.imageAspectRatioTolerance = 0.01,
    this.minImageSide,
    this.maxImageSide,
    this.maxDurationSeconds,
    this.stripExif = false,
    this.custom = const [],
  });

  /// Reject if file size > [maxSizeBytes]. Null disables.
  final int? maxSizeBytes;

  /// Case-insensitive extension whitelist without dots (e.g.
  /// `['jpg', 'png', 'webp']`). Null disables.
  final List<String>? allowedExtensions;

  /// Image width/height ratio (e.g. `16/9`, `1.0` for square).
  /// Null disables.
  final double? imageAspectRatio;

  /// Allowed deviation from [imageAspectRatio]. Defaults to 1% —
  /// most natural crops miss exact ratios by a few pixels.
  final double imageAspectRatioTolerance;

  /// Shortest side must be ≥ [minImageSide] px. Null disables.
  final int? minImageSide;

  /// Longest side must be ≤ [maxImageSide] px (pre-compression).
  /// Null disables.
  final int? maxImageSide;

  /// Video duration cap. Null disables. (Requires `video_player`
  /// probe at the call site; the validator skips this rule when
  /// duration isn't detectable.)
  final int? maxDurationSeconds;

  /// Scrub EXIF metadata (geotags, device, timestamps) from picked
  /// image files. Re-encodes as JPEG at near-lossless quality via
  /// `flutter_image_compress` — safe to pair with [maxSizeBytes]
  /// since it runs after compression. No-op for non-image picks.
  /// Off by default so app that surface EXIF (camera-roll tools)
  /// keep the original bytes.
  final bool stripExif;

  /// Drop-in extra rules for app-specific constraints.
  final List<MediaValidatorFn> custom;

  /// Run every rule. Returns `null` on pass, or the first
  /// [MediaPickerError] on fail.
  Future<MediaPickerError?> validate(File file) async {
    // Size
    if (maxSizeBytes != null) {
      final size = await file.length();
      if (size > maxSizeBytes!) {
        return MediaPickerError(
          code: MediaPickerErrorCode.tooLarge,
          message: MediaStrings.fileTooLarge(
            (size / (1024 * 1024)).toStringAsFixed(1),
            (maxSizeBytes! / (1024 * 1024)).toStringAsFixed(1),
          ),
        );
      }
    }

    // Extension
    if (allowedExtensions != null && allowedExtensions!.isNotEmpty) {
      final ext = _extensionOf(file);
      if (!allowedExtensions!.map((e) => e.toLowerCase()).contains(ext)) {
        return MediaPickerError(
          code: MediaPickerErrorCode.wrongExtension,
          message: MediaStrings.extensionNotAllowed(
            allowedExtensions!.join(', '),
          ),
        );
      }
    }

    // Image-specific rules (only if image decode succeeds; silently
    // skip for non-images).
    if (imageAspectRatio != null ||
        minImageSide != null ||
        maxImageSide != null) {
      final size = await _decodeImageSize(file);
      if (size != null) {
        if (minImageSide != null) {
          final shortest = size.width < size.height ? size.width : size.height;
          if (shortest < minImageSide!) {
            return MediaPickerError(
              code: MediaPickerErrorCode.imageTooSmall,
              message: MediaStrings.imageTooSmall(minImageSide!),
            );
          }
        }
        if (maxImageSide != null) {
          final longest = size.width > size.height ? size.width : size.height;
          if (longest > maxImageSide!) {
            return MediaPickerError(
              code: MediaPickerErrorCode.imageTooLarge,
              message: MediaStrings.imageTooLarge(maxImageSide!),
            );
          }
        }
        if (imageAspectRatio != null && size.height > 0) {
          final ratio = size.width / size.height;
          if ((ratio - imageAspectRatio!).abs() > imageAspectRatioTolerance) {
            return MediaPickerError(
              code: MediaPickerErrorCode.wrongAspectRatio,
              message: MediaStrings.wrongAspectRatio(
                ratio.toStringAsFixed(2),
                imageAspectRatio!.toStringAsFixed(2),
              ),
            );
          }
        }
      }
    }

    // Custom rules
    for (final rule in custom) {
      final result = await rule(file);
      if (result != null) return result;
    }

    return null;
  }
}

String _extensionOf(File file) {
  final segments = file.path.split('.');
  if (segments.length < 2) return '';
  return segments.last.toLowerCase();
}

Future<ui.Size?> _decodeImageSize(File file) async {
  try {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return ui.Size(frame.image.width.toDouble(), frame.image.height.toDouble());
  } catch (_) {
    return null;
  }
}

// ---------------------------------------------------------------------------
// Source translation helpers (UI → image_picker enum)
// ---------------------------------------------------------------------------

ImageSource imageSourceFrom(MediaPickerSourceOption option) =>
    option == MediaPickerSourceOption.camera
    ? ImageSource.camera
    : ImageSource.gallery;

// ---------------------------------------------------------------------------
// Source picker sheet — shared between image + video pickers
// ---------------------------------------------------------------------------

/// How the image picker handles cropping when the user picks more
/// than one image in a single gallery selection.
enum CropMultiBehavior {
  /// Open the cropper once per picked image, back-to-back. Strict
  /// but tedious on large selections. Default — matches the
  /// single-pick behaviour.
  sequential,

  /// Never open the cropper in multi-pick flows. Images go through
  /// raw (still validated / compressed). Useful for casual bulk
  /// uploads where aspect ratio doesn't matter.
  skip,

  /// Only the first picked image gets cropped; the rest go through
  /// raw. Good for a "hero + extras" pattern (gallery where the
  /// first image is the cover).
  firstOnly,

  /// After the gallery returns, show a mini review sheet — user
  /// sees every picked tile, can tap "Edit" on any to crop, and
  /// any tile that fails the validator (e.g. wrong aspect ratio)
  /// is marked "must crop" and blocks the Done button.
  editAfter,
}

/// Show a floating sheet that asks the user **what kind** of
/// attachment they want (image / video / file). Returns `null` on
/// cancel. Each option in [kinds] renders as a row; the default
/// covers the common trio.
Future<AttachmentKind?> showAttachmentKindSheet({
  required BuildContext context,
  List<AttachmentKind> kinds = const [
    AttachmentKind.image,
    AttachmentKind.video,
    AttachmentKind.file,
  ],
  Set<AttachmentKind> disabledKinds = const {},
  String? cancelLabel,
  String? imageLabel,
  String? videoLabel,
  String? fileLabel,
}) {
  final resolvedCancel = cancelLabel ?? CommonStrings.cancel;
  final resolvedImage = imageLabel ?? MediaStrings.photo;
  final resolvedVideo = videoLabel ?? MediaStrings.video;
  final resolvedFile = fileLabel ?? MediaStrings.file;
  return GlobalBottomSheet.show<AttachmentKind>(
    context: context,
    showCloseButton: false,
    useSafeArea: false,
    style: const SheetStyle(floating: true),
    content: Builder(
      builder: (ctx) => PickerSheetRows(
        choices: [
          for (final k in kinds)
            PickerSheetChoice(
              icon: _iconFor(k),
              label: _labelFor(k, resolvedImage, resolvedVideo, resolvedFile),
              enabled: !disabledKinds.contains(k),
              onTap: () => Navigator.of(ctx).pop(k),
            ),
          PickerSheetChoice(
            icon: Icons.cancel_rounded,
            label: resolvedCancel,
            destructive: true,
            onTap: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    ),
  );
}

IconData _iconFor(AttachmentKind k) => switch (k) {
  AttachmentKind.image => Icons.photo_library_rounded,
  AttachmentKind.video => Icons.videocam_rounded,
  AttachmentKind.file => Icons.insert_drive_file_rounded,
};

String _labelFor(AttachmentKind k, String image, String video, String file) =>
    switch (k) {
      AttachmentKind.image => image,
      AttachmentKind.video => video,
      AttachmentKind.file => file,
    };

/// Inline validator error row — matches the visual weight of a
/// `TextField.errorText` so pickers feel like peer form fields.
///
/// Public because each picker renders one under its body. Prefer
/// picker-level `onError` + `_error` state over reaching for this
/// widget directly.
class MediaPickerInlineError extends StatelessWidget {
  const MediaPickerInlineError({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: color, size: 14),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Show a floating [GlobalBottomSheet] that asks the user to pick a
/// source (gallery vs camera). Returns `null` on cancel / dismiss.
///
/// Used by [GlobalImagePicker] and [GlobalVideoPicker] — extracted
/// so both sheets have identical style, spacing, and behavior.
Future<MediaPickerSourceOption?> showMediaSourceSheet({
  required BuildContext context,
  String? title,
  IconData galleryIcon = Icons.photo_library_rounded,
  IconData cameraIcon = Icons.camera_alt_rounded,
  IconData clipboardIcon = Icons.content_paste_rounded,
  String? galleryLabel,
  String? cameraLabel,
  String? clipboardLabel,
  String? cancelLabel,
  bool showCamera = true,
  bool showClipboard = false,
  bool clipboardEnabled = true,
}) {
  final resolvedGallery = galleryLabel ?? MediaStrings.gallery;
  final resolvedCamera = cameraLabel ?? MediaStrings.camera;
  final resolvedClipboard = clipboardLabel ?? MediaStrings.clipboard;
  final resolvedCancel = cancelLabel ?? CommonStrings.cancel;
  return GlobalBottomSheet.show<MediaPickerSourceOption>(
    context: context,
    title: title,
    showCloseButton: false,
    // `floatingMargin` + inner `SafeArea(top: false)` already cover
    // the bottom gesture inset; letting `useSafeArea: true` stack a
    // second safe-area on top leaves ~34px of dead space after the
    // cancel row.
    useSafeArea: false,
    style: const SheetStyle(floating: true),
    content: Builder(
      builder: (ctx) => PickerSheetRows(
        choices: [
          PickerSheetChoice(
            icon: galleryIcon,
            label: resolvedGallery,
            subtitle: MediaStrings.gallerySubtitle,
            onTap: () => Navigator.of(ctx).pop(MediaPickerSourceOption.gallery),
          ),
          if (showCamera)
            PickerSheetChoice(
              icon: cameraIcon,
              label: resolvedCamera,
              onTap: () =>
                  Navigator.of(ctx).pop(MediaPickerSourceOption.camera),
            ),
          if (showClipboard)
            PickerSheetChoice(
              icon: clipboardIcon,
              label: resolvedClipboard,
              subtitle: MediaStrings.clipboardSubtitle,
              enabled: clipboardEnabled,
              onTap: () =>
                  Navigator.of(ctx).pop(MediaPickerSourceOption.clipboard),
            ),
          PickerSheetChoice(
            icon: Icons.cancel_rounded,
            label: resolvedCancel,
            destructive: true,
            onTap: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    ),
  );
}
