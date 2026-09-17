// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:video_trimmer_plus/video_trimmer_plus.dart';

// Project imports:
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/media_strings.dart';
import '../../../core/navigation/transitions/route_transition.dart';
import '../../../core/utils/loggers/logger.dart';
import '../buttons/global_filled_button.dart';
import '../buttons/global_text_button.dart';
import '../progress/global_progress.dart';

/// Output of [showVideoTrimSheet]. [file] is the trimmed output —
/// null when the user cancels. [thumbnailMs] is the timestamp the
/// user picked for the cover frame (null = not set).
class VideoTrimResult {
  const VideoTrimResult({required this.file, required this.thumbnailMs});
  final File? file;
  final int? thumbnailMs;
}

/// Full-screen trim + cover-frame picker. Built on `video_trimmer`
/// — loads the source video, lets the user drag start/end handles,
/// scrub to select a thumbnail frame, then saves to a temp MP4.
Future<VideoTrimResult?> showVideoTrimSheet({
  required BuildContext context,
  required File source,
  Duration? maxDuration,
}) {
  return Navigator.of(context, rootNavigator: true).push<VideoTrimResult>(
    // A task screen, so it comes UP like a sheet and refuses the
    // leading-edge swipe — the drag inside it belongs to the trimmer.
    RouteTransition.route<VideoTrimResult>(
      context: context,
      name: 'video-trim',
      fullscreenDialog: true,
      style: TransitionStyle.modal,
      child: _VideoTrimScreen(source: source, maxDuration: maxDuration),
    ),
  );
}

class _VideoTrimScreen extends StatefulWidget {
  const _VideoTrimScreen({required this.source, required this.maxDuration});
  final File source;
  final Duration? maxDuration;

  @override
  State<_VideoTrimScreen> createState() => _VideoTrimScreenState();
}

class _VideoTrimScreenState extends State<_VideoTrimScreen> {
  final Trimmer _trimmer = Trimmer();
  double _start = 0;
  double _end = 0;
  bool _ready = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _trimmer.loadVideo(videoFile: widget.source);
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    _trimmer.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final name = 'trimmed_${DateTime.now().microsecondsSinceEpoch}';
    String? outPath;
    await _trimmer.saveTrimmedVideo(
      startValue: _start,
      endValue: _end,
      videoFolderName: 'PickerTrimmed',
      videoFileName: name,
      storageDir: StorageDir.temporaryDirectory,
      onSave: (path) {
        outPath = path;
      },
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (outPath == null) {
      Navigator.of(context).pop();
      return;
    }
    // `_start` / `_end` are in milliseconds (video_trimmer uses ms
    // in VideoViewer). Re-scrub playback picks the user's current
    // position as the cover frame.
    final playback = await _trimmer.videoPlayerController?.position;
    Navigator.of(context).pop(
      VideoTrimResult(
        file: File(outPath!),
        thumbnailMs: playback?.inMilliseconds ?? _start.toInt(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(MediaStrings.trimVideo),
        actions: [
          // Black fullscreen trim UI — the white foreground is
          // intentional, passed via the style bags.
          GlobalTextButton(
            text: CommonStrings.save,
            shrinkWidth: true,
            enabled: _ready && !_saving && _end > _start,
            isLoading: _saving,
            onPressed: _save,
            style: const ButtonStateStyle(
              foregroundColor: Colors.white,
              textStyle: TextStyle(fontWeight: FontWeight.w700),
            ),
            disabledStyle: const ButtonStateStyle(
              foregroundColor: Colors.white38,
            ),
            loadingStyle: ButtonLoadingStyle(
              text: CommonStrings.saving,
              foregroundColor: Colors.white38,
            ),
          ),
        ],
      ),
      body: _ready
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(child: VideoViewer(trimmer: _trimmer)),
                  const SizedBox(height: 16),
                  Center(
                    child: TrimViewer(
                      trimmer: _trimmer,
                      viewerHeight: 50,
                      viewerWidth: MediaQuery.of(context).size.width,
                      maxVideoLength:
                          widget.maxDuration ?? const Duration(minutes: 10),
                      onChangeStart: (v) => _start = v,
                      onChangeEnd: (v) => _end = v,
                      onChangePlaybackState: (_) {},
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlobalFilledButton(
                    text: MediaStrings.playPause,
                    icon: Icons.play_arrow_rounded,
                    shrinkWidth: true,
                    onPressed: () async {
                      final playing = await _trimmer.videoPlaybackControl(
                        startValue: _start,
                        endValue: _end,
                      );
                      // rebuild to update play/pause icon
                      if (mounted) setState(() {});
                      Logger.m.d('[VideoTrimSheet] playback: $playing');
                    },
                  ),
                ],
              ),
            )
          : Center(
              child: GlobalProgress.loading(
                type: ProgressType.circular,
                style: const ProgressStyle(color: Colors.white),
              ),
            ),
    );
  }
}
