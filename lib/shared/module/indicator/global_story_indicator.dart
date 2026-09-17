import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/strings/module_strings.dart';
import '../progress/global_progress.dart';
import 'indicator_style.dart';
import 'story_player.dart';
import 'theme/indicator_theme.dart';

export 'indicator_style.dart';
export 'story_player.dart';

/// Story-style segmented progress bar — one segment per page. The
/// `active` segment fills from 0..1 driven by [progress]; segments
/// before it are 100% filled, segments after are empty.
///
/// Used by [GlobalPageView] when `storyMode: true` is set, but it's
/// a standalone widget — caller can render it independently.
///
/// The BAR is `GlobalProgress.stepped` with a fractional current step.
/// This drew its own — a `Stack` of two `Container`s per segment, one
/// `AnimatedContainer` wide — which is the same widget with a different
/// set of bugs available to it. What is left here is what a progress
/// bar has no business knowing: that each segment is a page you can tap
/// to jump to.
class GlobalStoryIndicator extends StatelessWidget {
  const GlobalStoryIndicator({
    super.key,
    required this.count,
    required this.activeIndex,
    required this.progress,
    this.style,
    this.onTap,
  }) : controller = null,
       assert(count > 0, 'count must be > 0'),
       assert(progress >= 0 && progress <= 1, 'progress in [0, 1]');

  /// A bar that RUNS, driven by a [StoryPlayerController].
  ///
  /// The plain constructor draws a position someone else is keeping;
  /// this one plays: per-segment durations, pause and resume, and a
  /// fill that moves a frame at a time rather than in whatever step a
  /// caller's timer happened to use.
  ///
  /// ```dart
  /// GlobalStoryIndicator.player(
  ///   controller: _story,
  ///   onTap: _story.goTo,
  /// )
  /// ```
  const GlobalStoryIndicator.player({
    super.key,
    required StoryPlayerController this.controller,
    this.style,
    this.onTap,
  }) : count = 0,
       activeIndex = 0,
       progress = 0;

  /// Set by [GlobalStoryIndicator.player] — when present it is the
  /// source of the count, the index and the fill.
  final StoryPlayerController? controller;

  /// Number of story segments (= page count).
  final int count;

  /// 0-based active segment. Out-of-range values clamp at render.
  final int activeIndex;

  /// Fill amount of the active segment in `[0, 1]`. Segments before
  /// it render as 100% filled regardless.
  final double progress;

  /// The caller's half of `caller > GlobalIndicatorTheme.storyStyle >
  /// StoryIndicatorStyle.defaults`.
  final StoryIndicatorStyle? style;

  /// Tap handler — fires with the tapped segment index. Use to
  /// jump pages on tap.
  final ValueChanged<int>? onTap;

  /// Extra height around the bar, so a three-pixel strip is still
  /// something a thumb can hit.
  static const _hitPadding = 8.0;

  @override
  Widget build(BuildContext context) {
    final player = controller;
    if (player != null) {
      // Rebuilt on every tick, and only this subtree — the page around
      // a story should not rebuild sixty times a second.
      return ListenableBuilder(
        listenable: player,
        builder: (context, _) => _build(
          context,
          count: player.count,
          activeIndex: player.index,
          progress: player.progress,
        ),
      );
    }
    return _build(
      context,
      count: count,
      activeIndex: activeIndex,
      progress: progress,
    );
  }

  Widget _build(
    BuildContext context, {
    required int count,
    required int activeIndex,
    required double progress,
  }) {
    final safeActive = activeIndex.clamp(0, count - 1);
    final resolved = (style ?? const StoryIndicatorStyle()).resolve(context);
    final height = resolved.height;
    final spacing = resolved.spacing;

    final bar = GlobalProgress.stepped(
      steps: count,
      currentStep: safeActive,
      stepProgress: progress,
      style: ProgressStyle(
        thickness: height,
        stepGap: spacing,
        borderRadius: BorderRadius.circular(resolved.radius),
        color: resolved.activeColor,
        trackColor: resolved.inactiveColor,
        // A story bar is driven by a page timer that already ticks
        // every frame; easing it a second time makes it lag the media.
        animated: false,
      ),
    );

    // A story bar is a REPORT, and a running one at that — a reader
    // who cannot see it has no other way to know which segment is
    // playing or how far through it is.
    String announce() {
      final where = IndicatorStrings.storySegment(safeActive + 1, count);
      final state = controller == null
          ? null
          : (controller!.isPlaying
                ? IndicatorStrings.playing
                : IndicatorStrings.paused);
      return state == null ? where : '$where, $state';
    }

    if (onTap == null) {
      return Semantics(
        container: true,
        label: announce(),
        // The percentage is read as a value rather than baked into the
        // label, so it is not re-announced sixty times a second.
        value: '${(progress * 100).round()}%',
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: _hitPadding / 2),
            child: bar,
          ),
        ),
      );
    }

    // The taps sit OVER the bar rather than around each segment, so the
    // hit zones cannot drift out of step with the segments they name.
    return Semantics(
      container: true,
      label: announce(),
      value: '${(progress * 100).round()}%',
      child: SizedBox(
        height: height + _hitPadding,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ExcludeSemantics(child: bar),
            Row(
              children: [
                for (var i = 0; i < count; i++) ...[
                  if (i > 0) SizedBox(width: spacing),
                  Expanded(
                    // Each segment IS a button — this is the one part
                    // of a story a reader can act on.
                    child: Semantics(
                      button: true,
                      label: IndicatorStrings.storySegment(i + 1, count),
                      onTap: () => onTap!(i),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (resolved.enableHaptic) {
                            HapticFeedback.selectionClick();
                          }
                          onTap!(i);
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
