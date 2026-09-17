// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:image_cropper/image_cropper.dart';

/// Aspect-ratio preset shown in the cropper toolbar (Android) /
/// quick-switch grid (iOS). Kept as a plain `(x, y)` record so
/// callers don't have to import the underlying package.
typedef CropPreset = ({double x, double y, String? label});

/// User-facing crop configuration — passed to [ImageCropperService.crop]
/// or to any `cropOptions` parameter on the media picker widgets.
@immutable
class CropOptions {
  const CropOptions({
    this.aspectRatio,
    this.lockAspectRatio,
    this.circular = false,
    this.presets = const [],
    this.toolbarTitle = 'Crop',
    this.compressQuality = 90,
    this.toolbarColor,
    this.toolbarWidgetColor,
    this.activeControlsWidgetColor,
    this.hideBottomControls = false,
  });

  /// Initial / locked aspect ratio (width / height). `1.0` = square.
  final double? aspectRatio;

  /// Force the crop to keep [aspectRatio]. Defaults to `true` when
  /// [aspectRatio] is non-null, `false` otherwise (freeform crop).
  final bool? lockAspectRatio;

  /// Apply a circular mask — Android draws a preview overlay, iOS
  /// lets the user pan inside a circle. Great for avatars.
  final bool circular;

  /// Ratios the user can switch between from the toolbar. Empty =
  /// only the initial ratio is offered.
  final List<CropPreset> presets;

  final String toolbarTitle;

  /// Output JPEG quality 0–100. Lower saves bytes but loses detail.
  final int compressQuality;

  /// Android toolbar styling. iOS uses system chrome.
  final Color? toolbarColor;
  final Color? toolbarWidgetColor;
  final Color? activeControlsWidgetColor;

  /// Hide the rotate / ratio / aspect row on Android — useful for
  /// a locked-ratio experience.
  final bool hideBottomControls;

  bool get _effectiveLock => lockAspectRatio ?? (aspectRatio != null);
}

/// Thin wrapper around [ImageCropper] so the picker widgets don't
/// depend on the package directly. Returns the cropped file or
/// `null` when the user cancels.
class ImageCropperService {
  ImageCropperService._();

  static Future<File?> crop(
    File source, {
    CropOptions options = const CropOptions(),
  }) async {
    try {
      final result = await ImageCropper().cropImage(
        sourcePath: source.path,
        compressQuality: options.compressQuality,
        aspectRatio: options.aspectRatio != null
            ? CropAspectRatio(ratioX: options.aspectRatio!, ratioY: 1)
            : null,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: options.toolbarTitle,
            lockAspectRatio: options._effectiveLock,
            hideBottomControls: options.hideBottomControls,
            cropStyle: options.circular
                ? CropStyle.circle
                : CropStyle.rectangle,
            toolbarColor: options.toolbarColor,
            toolbarWidgetColor: options.toolbarWidgetColor,
            activeControlsWidgetColor: options.activeControlsWidgetColor,
            aspectRatioPresets: _androidPresets(options.presets),
          ),
          IOSUiSettings(
            title: options.toolbarTitle,
            aspectRatioLockEnabled: options._effectiveLock,
            cropStyle: options.circular
                ? CropStyle.circle
                : CropStyle.rectangle,
            aspectRatioPresets: _iosPresets(options.presets),
            // Shrink the iOS toolbar when bottom controls are
            // hidden — fewer buttons = less likely to clip behind
            // the home indicator on notch/home-bar iPhones.
            rotateButtonsHidden: options.hideBottomControls,
            rotateClockwiseButtonHidden: options.hideBottomControls,
            resetButtonHidden: options.hideBottomControls,
            aspectRatioPickerButtonHidden:
                options.hideBottomControls || options._effectiveLock,
          ),
        ],
      );
      if (result == null) return null;
      return File(result.path);
    } catch (e) {
      if (kDebugMode) debugPrint('[ImageCropperService] crop failed: $e');
      return null;
    }
  }

  // image_cropper's Android widget expects its own CropAspectRatioPreset
  // enum — translate from our (x,y) tuples to the closest built-in
  // preset. Custom ratios outside the built-ins map to
  // CropAspectRatioPresetCustom (constant).
  static List<CropAspectRatioPreset> _androidPresets(List<CropPreset> presets) {
    if (presets.isEmpty) return const [];
    return presets.map(_toPreset).toList();
  }

  static List<CropAspectRatioPreset> _iosPresets(List<CropPreset> presets) {
    if (presets.isEmpty) return const [];
    return presets.map(_toPreset).toList();
  }

  static CropAspectRatioPreset _toPreset(CropPreset p) {
    final r = p.x / p.y;
    // Match against a small table of built-ins. Anything else falls
    // through to "original" (free) which the plugin treats as custom.
    if ((r - 1).abs() < 0.01) return CropAspectRatioPreset.square;
    if ((r - 3 / 2).abs() < 0.01) return CropAspectRatioPreset.ratio3x2;
    if ((r - 4 / 3).abs() < 0.01) return CropAspectRatioPreset.ratio4x3;
    if ((r - 5 / 3).abs() < 0.01) return CropAspectRatioPreset.ratio5x3;
    if ((r - 5 / 4).abs() < 0.01) return CropAspectRatioPreset.ratio5x4;
    if ((r - 7 / 5).abs() < 0.01) return CropAspectRatioPreset.ratio7x5;
    if ((r - 16 / 9).abs() < 0.01) return CropAspectRatioPreset.ratio16x9;
    return CropAspectRatioPreset.original;
  }
}
