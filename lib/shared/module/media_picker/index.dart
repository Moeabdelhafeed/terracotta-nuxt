/// Barrel for the media-picker widget family:
/// image (single/multi) · video (single) · file (single/multi).
///
/// All three share `MediaPickerValidator` (size / extension /
/// dimensions / aspect-ratio / duration / custom rules) and surface
/// typed [MediaPickerError] via `onError` instead of snackbars —
/// so error UX is whatever the call site wants (toast, banner,
/// inline text).
///
/// Services powering the picks:
///  - `MediaPickerService` — `image_picker` wrapper.
///  - `FilePickerService`  — `file_picker` wrapper.
///  - `ImageCompressionService` — `flutter_image_compress`, used by
///    [GlobalImagePicker] when `compress: true` (default).
library;

export '../../../data/services/media/image_cropper_service.dart'
    show CropOptions, CropPreset;
export 'global_attachment_picker.dart';
export 'global_file_picker.dart';
export 'global_image_picker.dart';
export 'global_video_picker.dart';
export 'media_picker_models.dart';
export 'media_picker_style.dart';
export 'recent_picker_overlay.dart'
    show RecentOverlayResult, showRecentPickerOverlay;
export 'theme/media_picker_theme.dart';
export 'upload_controller.dart';
