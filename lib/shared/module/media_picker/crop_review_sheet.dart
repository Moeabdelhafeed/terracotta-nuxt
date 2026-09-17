// Dart imports:
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/media_strings.dart';
import '../../../data/services/media/image_cropper_service.dart';
import '../buttons/global_filled_button.dart';
import '../image/global_image.dart';
import '../sheet/global_sheet.dart';
import 'media_picker_models.dart';

/// Result surfaced by [showCropReviewSheet].
///   - `files` non-null  → user tapped Done; safe to consume.
///   - `files` null      → user cancelled (tap outside, Cancel, drag).
typedef CropReviewResult = List<File>?;

/// Review sheet for [CropMultiBehavior.editAfter]. Shows every
/// picked file as a tile. Tiles that fail [validator] are badged
/// "must crop" (red) and block the Done button until cropped. All
/// other tiles have an "Edit" affordance (optional crop).
///
/// Tapping a tile opens the cropper with [cropOptions]. The returned
/// file replaces the tile's source in-place. Re-runs the validator
/// after each crop to clear the must-crop flag.
Future<CropReviewResult> showCropReviewSheet({
  required BuildContext context,
  required List<File> files,
  required CropOptions cropOptions,
  MediaPickerValidator? validator,
  String? title,
  String? subtitle,
  String? doneLabel,
  String? mustCropLabel,
  String? editLabel,
}) {
  return GlobalBottomSheet.show<List<File>>(
    context: context,
    title: title ?? MediaStrings.cropReviewTitle,
    subtitle: subtitle ?? MediaStrings.cropReviewSubtitle,
    icon: Icons.tune_rounded,
    style: const SheetStyle(floating: true),
    content: _CropReviewBody(
      initialFiles: files,
      cropOptions: cropOptions,
      validator: validator,
      doneLabel: doneLabel ?? CommonStrings.done,
      mustCropLabel: mustCropLabel ?? MediaStrings.mustCrop,
      editLabel: editLabel ?? CommonStrings.edit,
    ),
  );
}

// ---------------------------------------------------------------------------
// Body — stateful because tile sources + must-crop flags mutate
// as the user cycles through crops.
// ---------------------------------------------------------------------------

class _CropReviewBody extends StatefulWidget {
  const _CropReviewBody({
    required this.initialFiles,
    required this.cropOptions,
    required this.validator,
    required this.doneLabel,
    required this.mustCropLabel,
    required this.editLabel,
  });

  final List<File> initialFiles;
  final CropOptions cropOptions;
  final MediaPickerValidator? validator;
  final String doneLabel, mustCropLabel, editLabel;

  @override
  State<_CropReviewBody> createState() => _CropReviewBodyState();
}

class _CropReviewBodyState extends State<_CropReviewBody> {
  late List<File> _files;
  late List<bool> _mustCrop;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _files = [...widget.initialFiles];
    _mustCrop = List.filled(_files.length, false);
    _refreshValidation();
  }

  /// Re-run the validator over every file. Any failure marks the
  /// tile "must crop". No validator → nothing is forced.
  Future<void> _refreshValidation() async {
    setState(() => _checking = true);
    final next = List<bool>.filled(_files.length, false);
    for (var i = 0; i < _files.length; i++) {
      final err = await widget.validator?.validate(_files[i]);
      next[i] = err != null;
    }
    if (mounted) {
      setState(() {
        _mustCrop = next;
        _checking = false;
      });
    }
  }

  Future<void> _cropAt(int index) async {
    final cropped = await ImageCropperService.crop(
      _files[index],
      options: widget.cropOptions,
    );
    if (cropped == null) return;
    setState(() => _files[index] = cropped);
    // Re-run validator just for this tile — the rest are still up
    // to date from initState / the previous crop.
    final err = await widget.validator?.validate(cropped);
    if (!mounted) return;
    setState(() => _mustCrop[index] = err != null);
  }

  void _removeAt(int index) {
    setState(() {
      _files.removeAt(index);
      _mustCrop.removeAt(index);
    });
  }

  bool get _canConfirm =>
      !_checking && _files.isNotEmpty && !_mustCrop.contains(true);

  @override
  Widget build(BuildContext context) {
    final status = context.statusColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tiles grid — max 3 per row, square thumbs.
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < _files.length; i++)
              _Tile(
                key: ValueKey(_files[i].path),
                file: _files[i],
                mustCrop: _mustCrop[i],
                mustCropLabel: widget.mustCropLabel,
                editLabel: widget.editLabel,
                onEdit: () => _cropAt(i),
                onRemove: () => _removeAt(i),
              ),
          ],
        ),
        const SizedBox(height: 20),
        // Loading spinner, disabled colours and press gating are all
        // built into the primitive — no hand-rolled state machinery.
        GlobalFilledButton(
          text: widget.doneLabel,
          icon: Icons.check_rounded,
          isLoading: _checking,
          loadingStyle: const ButtonLoadingStyle(
            loadingType: LoadingType.circular,
          ),
          enabled: _canConfirm,
          onPressed: () => Navigator.of(context).pop(_files),
        ),
        if (!_checking && _mustCrop.contains(true))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${_mustCrop.where((e) => e).length} tile(s) need cropping',
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall?.copyWith(
                color: status.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tile — thumb + status badge + remove + tap-to-crop.
// ---------------------------------------------------------------------------

class _Tile extends StatelessWidget {
  const _Tile({
    super.key,
    required this.file,
    required this.mustCrop,
    required this.mustCropLabel,
    required this.editLabel,
    required this.onEdit,
    required this.onRemove,
  });

  final File file;
  final bool mustCrop;
  final String mustCropLabel, editLabel;
  final VoidCallback onEdit, onRemove;

  @override
  Widget build(BuildContext context) {
    final status = context.statusColors;
    const size = 90.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onEdit,
      child: SizedBox(
        width: size,
        height: size + 22,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                GlobalImage.f(
                  file,
                  width: size,
                  height: size,
                  style: ImageStyle(borderRadius: BorderRadius.circular(10)),
                ),
                if (mustCrop)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: status.error, width: 2.5),
                        color: status.error.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white70, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: mustCrop ? status.error : Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          mustCrop
                              ? Icons.priority_high_rounded
                              : Icons.edit_rounded,
                          size: 10,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          mustCrop ? mustCropLabel : editLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
