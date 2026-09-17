// Flutter imports:
import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';

// Project imports:
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/media_strings.dart';
import '../progress/global_progress.dart';
import 'media_picker_models.dart';
import 'media_picker_style.dart';
import 'upload_controller.dart';

/// Overlay rendered on top of a filled picker tile when an upload
/// is in flight, failed, or done. Hidden when no controller is
/// attached or the item is still `pending`.
///
/// Tap = retry on error tiles. Callers pass an `onRetry` to let
/// them hook analytics / snackbars; the default behaviour just
/// re-fires `controller.start`.
class UploadOverlay extends StatelessWidget {
  const UploadOverlay({
    super.key,
    required this.controller,
    required this.item,
    this.onRetry,
  });

  final UploadController controller;
  final PickerItem item;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (ctx, _) {
        final state = controller.stateOf(item);
        if (state.isPending) return const SizedBox.shrink();
        if (state.isDone) return _doneBadge(ctx);
        // Cancelled and failed both END in the same place — a tile
        // that will not upload until someone says so — so they wear
        // the same overlay and differ only in what it says.
        if (state.canRetry) return _errorOverlay(ctx, state);
        return _progressOverlay(ctx, state.progress);
      },
    );
  }

  Widget _progressOverlay(BuildContext context, double progress) {
    return Positioned.fill(
      // NOT ignoring pointers any more: an upload in flight is the one
      // state a reader most wants to stop, and there was no way to.
      // The whole tile is the stop button while it runs.
      child: Semantics(
        button: true,
        label: MediaStrings.uploadCancel,
        value: '${(progress * 100).round()}%',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => controller.cancel(item),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(
                MediaPickerDefaults.tileRadius,
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: progress > 0
                      ? GlobalProgress.circular(
                          value: progress,
                          style: const ProgressStyle(
                            thickness: 3,
                            color: Colors.white,
                            trackColor: Colors.white24,
                          ),
                        )
                      : GlobalProgress.loading(
                          type: ProgressType.circular,
                          style: const ProgressStyle(
                            thickness: 3,
                            color: Colors.white,
                            trackColor: Colors.white24,
                          ),
                        ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorOverlay(BuildContext context, UploadState state) {
    final status = context.statusColors;
    final stopped = state.isCancelled;
    return Positioned.fill(
      child: Semantics(
        button: true,
        label: stopped
            ? MediaStrings.uploadCancelled
            : MediaStrings.uploadRetry,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onRetry ?? () => controller.start(item),
            borderRadius: BorderRadius.circular(MediaPickerDefaults.tileRadius),
            child: Container(
              decoration: BoxDecoration(
                // A stop the reader asked for is not a FAILURE, and
                // painting it red says something went wrong when
                // nothing did.
                color: stopped
                    ? Colors.black.withValues(alpha: 0.6)
                    : status.error.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(
                  MediaPickerDefaults.tileRadius,
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    stopped
                        ? Icons.pause_circle_outline_rounded
                        : Icons.error_outline_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stopped ? MediaStrings.uploadRetry : CommonStrings.retry,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Small check badge bottom-left when the upload is done. Kept
  /// unobtrusive so the thumbnail stays readable.
  Widget _doneBadge(BuildContext context) {
    return Positioned(
      bottom: 4,
      left: 4,
      child: IgnorePointer(
        child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
        ),
      ),
    );
  }
}
