import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/localization/strings/module_strings.dart';
import 'global_audio.dart';

/// Everything the player DRAWS.
///
/// Split from `global_audio.dart` because that file held two backend
/// lifecycles, the widget, the chrome and three control surfaces —
/// and the chrome is the one part of it that touches neither engine:
/// it reads an [AudioPlayerHandle] and nothing else, which is exactly
/// why both backends can share it.
class AudioPlayerChrome extends StatelessWidget {
  const AudioPlayerChrome({
    required this.handle,
    required this.player,
    super.key,
  });

  final AudioPlayerHandle handle;

  /// The widget being drawn — its variant, its style and its builder.
  /// Named `player` rather than `widget`, which is what a `State`
  /// calls its own and read as a mistake in a `StatelessWidget`.
  final GlobalAudioPlayer player;

  static String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  static String _formatSpeed(double v) {
    final s = v.toStringAsFixed(2);
    if (s.endsWith('00')) return s.substring(0, s.length - 3);
    if (s.endsWith('0')) return s.substring(0, s.length - 1);
    return s;
  }

  @override
  Widget build(BuildContext context) {
    // ONE resolve for the whole player. Each variant used to answer
    // the leftover questions itself out of `Theme.of`, so the same
    // accent was derived in four places and the waveform inside a
    // themed player could disagree with the player around it.
    final rs = player.style.resolve(context);
    final body = switch (player.variant) {
      AudioPlayerVariant.compact => _buildCompact(context, rs),
      AudioPlayerVariant.message => _buildMessage(context, rs),
      AudioPlayerVariant.full => _buildFull(context, rs),
      AudioPlayerVariant.custom => player.builder!(context, handle),
    };
    // The keys sit OUTSIDE the variants: a custom layout should answer
    // the space bar too, and the runner takes the skip distance from
    // this same bag, so an arrow moves by exactly what the button
    // beside it does.
    return AudioShortcuts(
      enabled: rs.enableKeyboard,
      onCommand: (c) => AudioShortcutRunner.run(
        c,
        handle: handle,
        skipSeconds: rs.skipSeconds,
      ),
      child: body,
    );
  }

  Widget _buildCompact(BuildContext context, ResolvedAudioStyle rs) {
    final s = handle.state;
    return SizedBox(
      height: rs.compactHeight,
      child: Row(
        children: [
          AudioPlayButton(
            playing: s.playing,
            loading: s.loading,
            errored: s.errored,
            color: rs.accent,
            onTap: s.errored ? handle.retry : handle.toggle,
          ),
          const SizedBox(width: AudioDefaults.gapMd),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: AudioDefaults.trackHeight,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: AudioDefaults.thumbRadius,
                ),
              ),
              child: Slider(
                // A slider announces a bare percentage otherwise, and
                // "43%" of an unnamed thing is not a position.
                semanticFormatterCallback: (v) => _formatDuration(
                  Duration(
                    milliseconds: (s.duration.inMilliseconds * v).round(),
                  ),
                ),
                value: handle.progress,
                onChangeStart: (_) => handle.scrubStart(),
                onChanged: (v) => handle.scrubUpdate(v),
                onChangeEnd: (v) => handle.scrubEnd(v),
                activeColor: rs.accent,
              ),
            ),
          ),
          const SizedBox(width: AudioDefaults.gapXs),
          Text(
            _formatDuration(s.duration - s.position),
            style: rs.timeTextStyle.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(BuildContext context, ResolvedAudioStyle rs) {
    final s = handle.state;
    // The HANDLE's samples, not the widget's. The handle answers
    // `decoded ?? caller ?? fallback`; reading `player.samples`
    // skipped the decode entirely, so a player told to decode its own
    // waveform drew the generic fallback shape forever and every clip
    // in a list looked identical.
    final samples = handle.samples;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AudioPlayButton(
          playing: s.playing,
          loading: s.loading,
          errored: s.errored,
          color: rs.accent,
          size: AudioDefaults.compactIconSize,
          onTap: s.errored ? handle.retry : handle.toggle,
        ),
        const SizedBox(width: AudioDefaults.gapSm),
        SizedBox(
          width: AudioDefaults.compactWaveformWidth,
          child: AudioWaveform(
            samples: samples,
            progress: handle.progress,
            style: rs.forWaveformHeight(AudioDefaults.compactWaveformHeight),
            onScrubStart: handle.scrubStart,
            onScrubUpdate: handle.scrubUpdate,
            onScrubEnd: handle.scrubEnd,
          ),
        ),
        const SizedBox(width: AudioDefaults.gapSm),
        Text(_formatDuration(s.position), style: rs.timeTextStyle),
      ],
    );
  }

  /// What the sleep chip READS. Short, because it sits in a chip
  /// beside two others.
  static String _sleepLabel(AudioSleep sleep) {
    final after = sleep.after;
    if (after != null) return AudioStrings.sleepShortMinutes(after.inMinutes);
    // Off is the glyph alone: a chip reading "Off" beside a bed icon
    // says the same thing twice and is the widest of the three.
    return sleep.atEndOfTrack ? AudioStrings.sleepShortEnd : '';
  }

  /// And what it SAYS. "30m" beside a bed glyph is not a sentence.
  static String _sleepSemantics(AudioSleep sleep) {
    final after = sleep.after;
    if (after != null) return AudioStrings.sleepMinutes(after.inMinutes);
    return sleep.atEndOfTrack
        ? AudioStrings.sleepEndOfTrack
        : AudioStrings.sleepOff;
  }

  Widget _buildFull(BuildContext context, ResolvedAudioStyle rs) {
    final st = handle.state;
    // A queue of one is not a queue — see `showQueue`.
    final hasQueue = rs.showQueue && handle.trackCount > 1;
    // The HANDLE's samples, not the widget's. The handle answers
    // `decoded ?? caller ?? fallback`; reading `player.samples`
    // skipped the decode entirely, so a player told to decode its own
    // waveform drew the generic fallback shape forever and every clip
    // in a list looked identical.
    final samples = handle.samples;

    final hasSurface = rs.gradient != null || rs.backgroundColor != null;
    final timeStyle = rs.timeTextStyle.copyWith(fontWeight: FontWeight.w600);
    // The total is the quieter of the two: one is where the reader IS
    // and the other is how far there is to go.
    final timeMutedStyle = timeStyle.copyWith(
      fontWeight: FontWeight.w500,
      color: timeStyle.color?.withValues(alpha: AudioDefaults.timeOpacity),
    );

    final inner = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AudioWaveform(
          samples: samples,
          progress: handle.progress,
          style: rs.forWaveformHeight(
            math.max(rs.waveformHeight, AudioDefaults.fullWaveformMinHeight),
          ),
          onScrubStart: handle.scrubStart,
          onScrubUpdate: handle.scrubUpdate,
          onScrubEnd: handle.scrubEnd,
        ),
        const SizedBox(height: AudioDefaults.gapMd),
        Row(
          children: [
            Text(_formatDuration(st.position), style: timeStyle),
            const Spacer(),
            Text(_formatDuration(st.duration), style: timeMutedStyle),
          ],
        ),
        const SizedBox(height: AudioDefaults.gapLg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Only when there IS a queue. A pair of arrows over a
            // single clip is two controls that cannot do anything.
            if (hasQueue)
              AudioCircleButton(
                onTap: handle.previous,
                icon: Icons.skip_previous_rounded,
                color: rs.controlsColor,
                label: AudioStrings.previous,
                tooltip: AudioStrings.previous,
              ),
            if (rs.showSkip)
              AudioCircleButton(
                onTap: () => handle.skip(-rs.skipSeconds),
                icon: Icons.replay_10_rounded,
                color: rs.controlsColor,
                label: AudioStrings.skipBack(rs.skipSeconds),
                tooltip: '-${rs.skipSeconds}s',
              )
            else
              const SizedBox(width: AudioDefaults.circleButtonSize),
            AudioPlayButton(
              playing: st.playing,
              loading: st.loading,
              errored: st.errored,
              color: rs.accent,
              gradient: rs.playButtonGradient,
              shadow: rs.playButtonShadow,
              size: AudioDefaults.playButtonSize,
              onTap: st.errored ? handle.retry : handle.toggle,
            ),
            if (rs.showSkip)
              AudioCircleButton(
                onTap: () => handle.skip(rs.skipSeconds),
                icon: Icons.forward_10_rounded,
                color: rs.controlsColor,
                label: AudioStrings.skipForward(rs.skipSeconds),
                tooltip: '+${rs.skipSeconds}s',
              )
            else
              const SizedBox(width: AudioDefaults.circleButtonSize),
            if (hasQueue)
              AudioCircleButton(
                onTap: handle.next,
                icon: Icons.skip_next_rounded,
                color: rs.controlsColor,
                label: AudioStrings.next,
                tooltip: AudioStrings.next,
              ),
          ],
        ),
        if (rs.showSpeed || rs.showLoop || rs.showSleepTimer) ...[
          const SizedBox(height: AudioDefaults.gapLg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (rs.showSpeed)
                AudioChipButton(
                  label: '${_formatSpeed(st.speed)}×',
                  semanticLabel: AudioStrings.speed,
                  active: st.speed != 1.0,
                  accent: rs.accent,
                  foreground: rs.controlsColor,
                  onTap: handle.cycleSpeed,
                ),
              if (rs.showSpeed && rs.showLoop)
                const SizedBox(width: AudioDefaults.gapSm),
              if (rs.showLoop)
                AudioChipButton(
                  icon: Icons.repeat_one_rounded,
                  label: AudioStrings.loop,
                  semanticLabel: AudioStrings.loop,
                  active: st.looping,
                  accent: rs.accent,
                  foreground: rs.controlsColor,
                  onTap: handle.toggleLoop,
                ),
              if ((rs.showSpeed || rs.showLoop) && rs.showSleepTimer)
                const SizedBox(width: AudioDefaults.gapSm),
              if (rs.showSleepTimer)
                AudioChipButton(
                  icon: Icons.bedtime_rounded,
                  label: _sleepLabel(handle.sleep),
                  // The label is a value ("30m"), so the node needs
                  // the name of the thing that value belongs to.
                  semanticLabel: _sleepSemantics(handle.sleep),
                  active: handle.sleep.isArmed,
                  accent: rs.accent,
                  foreground: rs.controlsColor,
                  // The OPTIONS live in the style, so the step is
                  // taken here and the handle only takes the answer.
                  onTap: () => handle.setSleep(rs.nextSleep(handle.sleep)),
                ),
            ],
          ),
        ],
      ],
    );

    // No surface asked for means no surface drawn. A player dropped
    // into a card that already has one should not paint a second.
    if (!hasSurface) return Padding(padding: rs.padding, child: inner);

    return Container(
      padding: rs.padding,
      decoration: BoxDecoration(
        color: rs.gradient == null ? rs.backgroundColor : null,
        gradient: rs.gradient,
        borderRadius: rs.borderRadius,
      ),
      child: inner,
    );
  }
}
