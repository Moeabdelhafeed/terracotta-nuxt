import '../../../generated/l10n.dart';
import '../tr.dart';

/// Image / video picker + compression error messages.
class MediaStrings {
  MediaStrings._();

  static String get failedToPickImage =>
      Tr.t('media_failed_to_pick_image', S.current.media_failed_to_pick_image);
  static String get failedToPickImages => Tr.t(
    'media_failed_to_pick_images',
    S.current.media_failed_to_pick_images,
  );
  static String get failedToPickVideo =>
      Tr.t('media_failed_to_pick_video', S.current.media_failed_to_pick_video);
  static String get failedToPickVideos => Tr.t(
    'media_failed_to_pick_videos',
    S.current.media_failed_to_pick_videos,
  );
  static String get failedToCompressImage => Tr.t(
    'media_failed_to_compress_image',
    S.current.media_failed_to_compress_image,
  );
  static String get imageTooLargeCompressionFailed => Tr.t(
    'media_image_too_large_compression_failed',
    S.current.media_image_too_large_compression_failed,
  );

  static String fileTooLarge(String size, String max) =>
      Tr.t('media.file_too_large', S.current.media_file_too_large(size, max));
  static String extensionNotAllowed(String extensions) => Tr.t(
    'media.extension_not_allowed',
    S.current.media_extension_not_allowed(extensions),
  );
  static String imageTooSmall(int side) =>
      Tr.t('media.image_too_small', S.current.media_image_too_small(side));
  static String imageTooLarge(int side) =>
      Tr.t('media.image_too_large', S.current.media_image_too_large(side));
  static String wrongAspectRatio(String ratio, String expected) => Tr.t(
    'media.wrong_aspect_ratio',
    S.current.media_wrong_aspect_ratio(ratio, expected),
  );
  static String get photo => Tr.t('media.photo', S.current.media_photo);
  static String get video => Tr.t('media.video', S.current.media_video);
  static String get file => Tr.t('media.file', S.current.media_file);
  static String get gallery => Tr.t('media.gallery', S.current.media_gallery);
  static String get camera => Tr.t('media.camera', S.current.media_camera);
  static String get clipboard =>
      Tr.t('media.clipboard', S.current.media_clipboard);
  static String get browse => Tr.t('media.browse', S.current.media_browse);
  static String get record => Tr.t('media.record', S.current.media_record);
  static String get imageCopied =>
      Tr.t('media.image_copied', S.current.media_image_copied);
  static String get videoCopied =>
      Tr.t('media.video_copied', S.current.media_video_copied);
  static String get fileCopied =>
      Tr.t('media.file_copied', S.current.media_file_copied);
  static String get copyFailed =>
      Tr.t('media.copy_failed', S.current.media_copy_failed);
  static String get copyImageTooltip =>
      Tr.t('media.copy_image_tooltip', S.current.media_copy_image_tooltip);
  static String get copyVideoTooltip =>
      Tr.t('media.copy_video_tooltip', S.current.media_copy_video_tooltip);
  static String get copyFileTooltip =>
      Tr.t('media.copy_file_tooltip', S.current.media_copy_file_tooltip);
  static String get trimVideo =>
      Tr.t('media.trim_video', S.current.media_trim_video);
  static String get chooseFile =>
      Tr.t('media.choose_file', S.current.media_choose_file);
  static String get addAttachment =>
      Tr.t('media.add_attachment', S.current.media_add_attachment);
  static String get cropReviewTitle =>
      Tr.t('media.crop_review_title', S.current.media_crop_review_title);
  static String get cropReviewSubtitle =>
      Tr.t('media.crop_review_subtitle', S.current.media_crop_review_subtitle);
  static String get mustCrop =>
      Tr.t('media.must_crop', S.current.media_must_crop);
  static String get recent => Tr.t('media.recent', S.current.media_recent);

  /// Badge on a tile that has not been uploaded yet.
  static String get newBadge =>
      Tr.t('media.new_badge', S.current.media_new_badge);

  /// And on one that WAS — the other half of the pair, so «جديد» has
  /// something to be new beside.
  static String get existingBadge =>
      Tr.t('media.existing_badge', S.current.media_existing_badge);

  static String get existingItem =>
      Tr.t('media.existing_item', S.current.media_existing_item);

  /// The native cropper's own chrome.
  static String get cropTitle =>
      Tr.t('media.crop_title', S.current.media_crop_title);

  static String get clipboardEmpty =>
      Tr.t('media.clipboard_empty', S.current.media_clipboard_empty);

  // ─── What a picker's controls are CALLED ──────────────────
  //
  // The module had none of these: a full page of tiles, dots and add
  // slots with not one accessible name between them.
  static String get addPhoto =>
      Tr.t('media.add_photo', S.current.media_add_photo);

  static String get addVideo =>
      Tr.t('media.add_video', S.current.media_add_video);

  static String get addFile => Tr.t('media.add_file', S.current.media_add_file);

  static String itemOf(int index, int total) =>
      Tr.t('media.item_of', S.current.media_item_of(index, total));

  static String get removeItem =>
      Tr.t('media.remove_item', S.current.media_remove_item);

  static String get downloadItem =>
      Tr.t('media.download_item', S.current.media_download_item);

  static String get newItem => Tr.t('media.new_item', S.current.media_new_item);

  static String get uploading =>
      Tr.t('media.uploading', S.current.media_uploading);

  static String get reorderHint =>
      Tr.t('media.reorder_hint', S.current.media_reorder_hint);

  /// Said when a multi-pick brought back more than there is room for.
  static String limitDropped(int count, int max) =>
      Tr.t('media.limit_dropped', S.current.media_limit_dropped(count, max));

  static String get duplicateSkipped =>
      Tr.t('media.duplicate_skipped', S.current.media_duplicate_skipped);

  static String get preparing =>
      Tr.t('media.preparing', S.current.media_preparing);

  static String get uploadCancel =>
      Tr.t('media.upload_cancel', S.current.media_upload_cancel);

  static String get uploadCancelled =>
      Tr.t('media.upload_cancelled', S.current.media_upload_cancelled);

  static String get uploadRetry =>
      Tr.t('media.upload_retry', S.current.media_upload_retry);

  static String get share => Tr.t('media.share', S.current.media_share);

  static String get gallerySubtitle =>
      Tr.t('media.gallery_subtitle', S.current.media_gallery_subtitle);

  static String get cameraSubtitle =>
      Tr.t('media.camera_subtitle', S.current.media_camera_subtitle);

  static String get clipboardSubtitle =>
      Tr.t('media.clipboard_subtitle', S.current.media_clipboard_subtitle);

  static String get browseSubtitle =>
      Tr.t('media.browse_subtitle', S.current.media_browse_subtitle);

  static String get cannotPreviewBytes => Tr.t(
    'media.cannot_preview_bytes',
    S.current.media_cannot_preview_bytes,
  );

  static String get moreActions =>
      Tr.t('media.more_actions', S.current.media_more_actions);

  static String get moveLeft =>
      Tr.t('media.move_left', S.current.media_move_left);

  static String get moveRight =>
      Tr.t('media.move_right', S.current.media_move_right);

  static String movedTo(int index) =>
      Tr.t('media.moved_to', S.current.media_moved_to(index));
  static String get limitReached =>
      Tr.t('media.limit_reached', S.current.media_limit_reached);
  static String openFailed(String message) =>
      Tr.t('media.open_failed', S.current.media_open_failed(message));
  static String get urlCopied =>
      Tr.t('media.url_copied', S.current.media_url_copied);
  static String get playPause =>
      Tr.t('media.play_pause', S.current.media_play_pause);

  static String get rotate => Tr.t('media.rotate', S.current.media_rotate);
  static String get realign => Tr.t('media.realign', S.current.media_realign);

  /// Parameterized — rides [Tr.plural] so a remote ICU template still
  /// interpolates (flat Tr.t returns overrides verbatim).
  static String selectedCount(int count, int max) => Tr.plural(
    'media.selected_count',
    count,
    S.current.media_selected_count(count, max),
    args: {'count': count, 'max': max},
  );
}
