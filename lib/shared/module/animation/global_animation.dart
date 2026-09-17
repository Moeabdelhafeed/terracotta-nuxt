import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:archive/archive.dart' show ArchiveFile;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../core/a11y/semantics_extensions.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/module_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../core/utils/loggers/logger.dart';
import '../buttons/global_icon_button.dart';
import '../icon/global_icon.dart';
import '../progress/global_progress.dart';
import '../shimmer/global_shimmer.dart';
import 'animation_handle.dart';
import 'animation_models.dart';
import 'theme/animation_theme.dart';

export 'animation_handle.dart';
export 'animation_models.dart';
export 'theme/animation_theme.dart';

/// Downloaded `.lottie` archives, keyed by URL and newest-last.
///
/// The `.lottie` path unzips the archive itself, which means it cannot
/// use the lottie package's own network cache — so two players over one
/// URL each fetched it, and remounting fetched it again. A `.lottie` is
/// a zip of JSON and images, so a handful of them is real memory: the
/// map is bounded.
final Map<String, Uint8List> _kDotLottieBytes = <String, Uint8List>{};
const int _kDotLottieCacheEntries = 4;

/// The module's caches, and the way to drop them.
abstract final class AnimationCache {
  /// Every downloaded `.lottie` archive.
  static void clearAll() => _kDotLottieBytes.clear();

  /// One URL's archive.
  static void clearFor(String url) => _kDotLottieBytes.remove(url);

  static int get documentCount => _kDotLottieBytes.length;

  static int get byteCount =>
      _kDotLottieBytes.values.fold<int>(0, (sum, b) => sum + b.lengthInBytes);
}

/// How far one keyboard step moves the seek bar.
const double _kSeekStep = 0.1;

/// A unified widget for playing animated content — GIFs, Lottie JSON, and dotLottie (.lottie).
class GlobalAnimation extends StatefulWidget {
  final String source;
  final AnimationType type;
  final AnimationSourceType sourceType;

  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;

  final bool autoPlay;
  final bool reverse;
  final AnimationLoopMode loopMode;
  final double speed;

  final GlobalAnimationStyle style;

  // ─── Lottie delegates (dynamic property overrides) ────────
  /// Dynamically replace text in the Lottie animation.
  final String Function(String)? textDelegate;

  /// Override text styles for Lottie fonts.
  final TextStyle Function(LottieFontStyle)? textStyleDelegate;

  /// Value delegates to override colors, opacity, transforms at runtime.
  /// Use [ValueDelegate] from the lottie package.
  final List<ValueDelegate>? valueDelegates;

  // ─── Color filter / tint ──────────────────────────────────
  /// Apply a color tint over the entire animation.
  final Color? colorFilter;

  /// Blend mode for the color filter (default: srcATop).
  final BlendMode colorFilterBlendMode;

  /// Names the animation for assistive tech.
  ///
  /// Null means DECORATION, and a decoration is excluded from the tree
  /// entirely rather than left as an unlabelled node someone has to
  /// swipe past. A success tick or an empty-state illustration carries
  /// meaning and needs one; a looping background does not.
  final String? semanticLabel;

  /// Whether scrolling the player out of view pauses it.
  ///
  /// ON. `TickerMode` already stops an animation when its ROUTE is
  /// covered, but a Lottie scrolled out of a list keeps drawing frames
  /// nobody can see. Pausing holds the frame, so coming back is a
  /// resume rather than a restart.
  final bool pauseWhenOffscreen;

  /// Which animation to take out of a `.lottie` archive, by file name.
  ///
  /// A dotLottie can hold several. Without this the first non-manifest
  /// `.json` wins, which is whichever the zip happens to list first.
  final String? dotLottieAnimation;

  final VoidCallback? onLoaded;
  final VoidCallback? onComplete;

  /// Fires each time a LOOP completes — every lap for `loop`, every
  /// half-lap for `pingPong`. Nothing could count laps before.
  final VoidCallback? onLoop;

  final ValueChanged<String>? onError;

  /// Every transport change, for chrome outside the widget.
  final ValueChanged<AnimationStateSnapshot>? onStateChanged;

  const GlobalAnimation({
    super.key,
    required this.source,
    required this.type,
    this.sourceType = AnimationSourceType.asset,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.autoPlay = true,
    this.reverse = false,
    this.loopMode = AnimationLoopMode.loop,
    this.speed = 1.0,
    this.style = const GlobalAnimationStyle(),
    this.textDelegate,
    this.textStyleDelegate,
    this.valueDelegates,
    this.colorFilter,
    this.colorFilterBlendMode = BlendMode.srcATop,
    this.semanticLabel,
    this.pauseWhenOffscreen = true,
    this.dotLottieAnimation,
    this.onLoaded,
    this.onComplete,
    this.onLoop,
    this.onError,
    this.onStateChanged,
  });

  factory GlobalAnimation.gif(
    String source, {
    Key? key,
    AnimationSourceType sourceType = AnimationSourceType.asset,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    bool autoPlay = true,
    AnimationLoopMode loopMode = AnimationLoopMode.loop,
    GlobalAnimationStyle style = const GlobalAnimationStyle(),
    Color? colorFilter,
    BlendMode colorFilterBlendMode = BlendMode.srcATop,
    String? semanticLabel,
    bool pauseWhenOffscreen = true,
  }) => GlobalAnimation(
    key: key,
    semanticLabel: semanticLabel,
    pauseWhenOffscreen: pauseWhenOffscreen,
    source: source,
    type: AnimationType.gif,
    sourceType: sourceType,
    width: width,
    height: height,
    fit: fit,
    autoPlay: autoPlay,
    loopMode: loopMode,
    style: style,
    colorFilter: colorFilter,
    colorFilterBlendMode: colorFilterBlendMode,
  );

  factory GlobalAnimation.lottie(
    String source, {
    Key? key,
    AnimationSourceType sourceType = AnimationSourceType.asset,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    bool autoPlay = true,
    bool reverse = false,
    AnimationLoopMode loopMode = AnimationLoopMode.loop,
    double speed = 1.0,
    GlobalAnimationStyle style = const GlobalAnimationStyle(),
    String Function(String)? textDelegate,
    TextStyle Function(LottieFontStyle)? textStyleDelegate,
    List<ValueDelegate>? valueDelegates,
    Color? colorFilter,
    BlendMode colorFilterBlendMode = BlendMode.srcATop,
    VoidCallback? onLoaded,
    VoidCallback? onComplete,
    VoidCallback? onLoop,
    ValueChanged<AnimationStateSnapshot>? onStateChanged,
    String? semanticLabel,
    bool pauseWhenOffscreen = true,
    String? dotLottieAnimation,
  }) => GlobalAnimation(
    key: key,
    semanticLabel: semanticLabel,
    pauseWhenOffscreen: pauseWhenOffscreen,
    dotLottieAnimation: dotLottieAnimation,
    onLoop: onLoop,
    onStateChanged: onStateChanged,
    source: source,
    type: source.endsWith('.lottie')
        ? AnimationType.dotLottie
        : AnimationType.lottieJson,
    sourceType: sourceType,
    width: width,
    height: height,
    fit: fit,
    autoPlay: autoPlay,
    reverse: reverse,
    loopMode: loopMode,
    speed: speed,
    style: style,
    textDelegate: textDelegate,
    textStyleDelegate: textStyleDelegate,
    valueDelegates: valueDelegates,
    colorFilter: colorFilter,
    colorFilterBlendMode: colorFilterBlendMode,
    onLoaded: onLoaded,
    onComplete: onComplete,
  );

  @override
  State<GlobalAnimation> createState() => GlobalAnimationState();
}

class GlobalAnimationState extends State<GlobalAnimation>
    with SingleTickerProviderStateMixin
    implements AnimationHandle {
  late AnimationController _ctrl;
  LottieComposition? _composition;
  bool _loaded = false;
  bool _hasError = false;
  String? _errorMsg;
  bool _isPlaying = false;
  late double _speed;
  bool _reverseLooping = false;

  AnimationController get controller => _ctrl;
  bool get isPlaying => _isPlaying;
  double get speed => _speed;

  /// The style bag, materialized once per dependency change rather than
  /// per build — resolving reads the palette, and the palette is an
  /// inherited lookup.
  late ResolvedAnimationStyle _rs;

  /// Whether the platform asked for less motion AND this animation
  /// agreed to listen. Read here rather than in `initState`, where
  /// there is no `MediaQuery` yet.
  bool _reduceMotion = false;

  /// Generation token for the reverse loop.
  ///
  /// The loop re-enters itself through a `.then`, which is the exact
  /// shape that froze the marquee earlier: a controller that completes
  /// without advancing a frame turns it into an unbounded microtask
  /// chain, and an app with no frames and no exception is simply dead.
  /// Every continuation checks that it is still the current one.
  int _reverseDrive = 0;

  /// `VisibilityDetector` demands a unique key, and two players over
  /// one source in a list are ordinary.
  late final Key _visibilityKey = ValueKey(
    'global-animation-${identityHashCode(this)}',
  );
  bool _visible = true;
  bool _resumeOnVisible = false;

  final _stateController = StreamController<AnimationStateSnapshot>.broadcast();

  @override
  AnimationStateSnapshot get state => AnimationStateSnapshot(
    playing: _isPlaying,
    // A GIF has no reportable position: Flutter's decoder owns the
    // frame clock and does not say which frame it is on.
    progress: widget.type == AnimationType.gif ? 0 : _ctrl.value,
    speed: _speed,
    loaded: _loaded,
    errored: _hasError,
    reducedMotion: _reduceMotion,
    duration: _composition?.duration,
    error: _errorMsg,
  );

  @override
  Stream<AnimationStateSnapshot> get stateStream => _stateController.stream;

  /// `play` mutates through several branches; emitting once after the
  /// frame beats threading a call through each of them.
  void _emitAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _emit();
    });
  }

  void _emit() {
    final snap = state;
    widget.onStateChanged?.call(snap);
    if (!_stateController.isClosed) _stateController.add(snap);
  }

  @override
  void replay() {
    reset();
    // Deferred so the reset lands before the play does.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) play();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rs = widget.style.resolve(context);

    final reduce =
        _rs.respectReducedMotion && MediaQuery.disableAnimationsOf(context);
    if (reduce == _reduceMotion) return;
    _reduceMotion = reduce;
    // Turning it on stops a running animation; turning it off does not
    // start one the reader never asked to start.
    if (_reduceMotion && _isPlaying) pause();
  }

  @override
  void initState() {
    super.initState();
    _speed = _clampSpeed(widget.speed);
    // A GIF's frame delays are in the FILE and Flutter's decoder owns
    // them. Accepting a speed and ignoring it is worse than refusing
    // it, because the caller has no way to find out.
    assert(
      widget.type != AnimationType.gif || widget.speed == 1.0,
      'speed has no effect on a GIF — the frame delays are in the file '
      'and Flutter\'s decoder owns the clock. Use a Lottie if the rate '
      'has to change.',
    );
    _ctrl = AnimationController(vsync: this);

    if (widget.type == AnimationType.gif) {
      _loaded = true;
      _isPlaying = widget.autoPlay;
    } else {
      _loadLottie();
    }
  }

  @override
  void didUpdateWidget(GlobalAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source || oldWidget.type != widget.type) {
      _ctrl.stop();
      _composition = null;
      _loaded = false;
      _hasError = false;
      _errorMsg = null;
      if (widget.type == AnimationType.gif) {
        setState(() {
          _loaded = true;
          _isPlaying = widget.autoPlay;
        });
      } else {
        _loadLottie();
      }
    }
    if (oldWidget.speed != widget.speed) {
      setSpeed(widget.speed);
    }
  }

  // ─── Loading ──────────────────────────────────────────────

  /// Which animation to take out of the archive.
  ///
  /// A `.lottie` can hold several, and without a name the first
  /// non-manifest `.json` wins — whichever the zip happens to list
  /// first, which is not a choice anyone made.
  ArchiveFile? _dotLottieFilePicker(List<ArchiveFile> files) {
    final wanted = widget.dotLottieAnimation;
    if (wanted != null) {
      for (final f in files) {
        if (f.name == wanted || f.name.endsWith('/$wanted')) return f;
      }
      Logger.m.w(
        '[GlobalAnimation] no "$wanted" in ${widget.source} — '
        'falling back to the first animation in the archive',
      );
    }
    for (final f in files) {
      if (f.name.endsWith('.json') && !f.name.contains('manifest')) return f;
    }
    for (final f in files) {
      if (f.name.endsWith('.json')) return f;
    }
    return null;
  }

  Future<void> _loadLottie() async {
    try {
      LottieComposition comp;

      if (widget.type == AnimationType.dotLottie) {
        final List<int> bytes;
        switch (widget.sourceType) {
          case AnimationSourceType.asset:
            final data = await rootBundle.load(widget.source);
            bytes = data.buffer.asUint8List();
          case AnimationSourceType.network:
            // Cached by URL. This path unzips the archive itself, so
            // the lottie package's own network cache never sees it —
            // two players over one URL each fetched it, and a remount
            // fetched it again.
            final cached = _kDotLottieBytes[widget.source];
            if (cached != null) {
              bytes = cached;
            } else {
              final response = await http.get(Uri.parse(widget.source));
              if (response.statusCode != 200) {
                throw Exception(
                  'HTTP ${response.statusCode}: ${response.reasonPhrase}',
                );
              }
              bytes = response.bodyBytes;
              _kDotLottieBytes[widget.source] = response.bodyBytes;
              while (_kDotLottieBytes.length > _kDotLottieCacheEntries) {
                _kDotLottieBytes.remove(_kDotLottieBytes.keys.first);
              }
            }
          case AnimationSourceType.file:
            bytes = await File(widget.source).readAsBytes();
        }
        final result = await LottieComposition.decodeZip(
          bytes,
          filePicker: _dotLottieFilePicker,
        );
        if (result == null) throw Exception('Failed to decode dotLottie');
        comp = result;
      } else {
        switch (widget.sourceType) {
          case AnimationSourceType.asset:
            comp = await AssetLottie(widget.source).load();
          case AnimationSourceType.network:
            comp = await NetworkLottie(widget.source).load();
          case AnimationSourceType.file:
            // A `File`, not a path. `FileLottie` takes an `Object` and
            // casts it internally, so a String compiled fine and threw
            // "type 'String' is not a subtype of type 'File'" at load —
            // every file-sourced Lottie in the app, always.
            comp = await FileLottie(File(widget.source)).load();
        }
      }

      if (!mounted) return;
      _composition = comp;
      _applyDuration();
      setState(() => _loaded = true);
      widget.onLoaded?.call();
      _emit();
      // Reduce motion stops it from starting ITSELF. The controls still
      // work, because someone who presses play has asked for it.
      if (widget.autoPlay && !_reduceMotion) play();
    } catch (e) {
      if (!mounted) return;
      Logger.m.w('[GlobalAnimation] ${widget.source} failed to load', error: e);
      widget.onError?.call(e.toString());
      setState(() {
        _hasError = true;
        _errorMsg = e.toString();
      });
      _emit();
    }
  }

  /// Speed is a DIVISOR of the composition's duration, so zero is an
  /// infinite `Duration` and a negative one is a negative `Duration`.
  /// Both throw out of the controller rather than looking wrong, which
  /// is why the clamp is here and not left to the caller.
  void _applyDuration() {
    if (_composition == null) return;
    _ctrl.duration = _composition!.duration * (1.0 / _speed);
  }

  static double _clampSpeed(double speed) => speed.isFinite
      ? speed.clamp(AnimationDefaults.minSpeed, AnimationDefaults.maxSpeed)
      : 1.0;

  // ─── Playback ─────────────────────────────────────────────
  //
  // Uses AnimationController.repeat() for loop/pingPong to avoid
  // manual status listener recursion. Only playOnce uses a status listener.

  @override
  void play() {
    _emitAfterFrame();
    if (widget.type == AnimationType.gif) {
      setState(() => _isPlaying = true);
      return;
    }
    if (_composition == null) return;

    _ctrl.removeStatusListener(_onPlayOnceComplete);

    switch (widget.loopMode) {
      case AnimationLoopMode.loop:
        setState(() => _isPlaying = true);
        if (widget.reverse) {
          _startReverseLoop();
        } else {
          _ctrl.repeat();
        }
        _watchLaps();

      case AnimationLoopMode.pingPong:
        setState(() => _isPlaying = true);
        // `repeat(reverse: true)` always starts FORWARDS, so `reverse`
        // has nothing to change here — say so rather than accept a
        // parameter that quietly does nothing.
        assert(
          !widget.reverse,
          'pingPong already goes both ways; `reverse: true` on top of it '
          'has no meaning. Use loopMode: loop with reverse: true for a '
          'backwards loop.',
        );
        _ctrl.repeat(reverse: true);
        _watchLaps();

      case AnimationLoopMode.playOnce:
        setState(() => _isPlaying = true);
        _ctrl.addStatusListener(_onPlayOnceComplete);
        if (widget.reverse) {
          _ctrl.reverse(from: _ctrl.value <= 0.01 ? 1.0 : _ctrl.value);
        } else {
          _ctrl.forward(from: _ctrl.value >= 0.99 ? 0.0 : _ctrl.value);
        }
    }
  }

  void _startReverseLoop() {
    if (!mounted || !_isPlaying || _reverseLooping) return;
    _reverseLooping = true;
    final drive = ++_reverseDrive;
    _ctrl
        .reverse(from: 1.0)
        .then((_) {
          _reverseLooping = false;
          if (_isCurrentReverseDrive(drive)) _startReverseLoop();
        })
        .catchError((_) {
          _reverseLooping = false;
        });
  }

  bool _isCurrentReverseDrive(int drive) =>
      mounted && _isPlaying && drive == _reverseDrive;

  /// Reports every lap.
  ///
  /// `repeat` never emits a status, so a caller could not count laps at
  /// all: it drives the controller straight from the ticker. The value
  /// wrapping past the end is the only edge there is to see.
  void _watchLaps() {
    if (widget.onLoop == null) return;
    _ctrl.removeListener(_onLapTick);
    _lastLapValue = _ctrl.value;
    _ctrl.addListener(_onLapTick);
  }

  double _lastLapValue = 0;

  void _onLapTick() {
    final value = _ctrl.value;
    // Forward wrap (1 → 0) for `loop`, and either end for `pingPong`.
    final wrapped = widget.loopMode == AnimationLoopMode.pingPong
        ? (value >= 1 && _lastLapValue < 1) || (value <= 0 && _lastLapValue > 0)
        : value < _lastLapValue;
    _lastLapValue = value;
    if (wrapped) widget.onLoop?.call();
  }

  void _onPlayOnceComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      _ctrl.removeStatusListener(_onPlayOnceComplete);
      if (mounted) setState(() => _isPlaying = false);
      widget.onComplete?.call();
    }
  }

  @override
  void pause() {
    _reverseLooping = false;
    _reverseDrive += 1;
    _ctrl.stop();
    setState(() => _isPlaying = false);
    _emit();
  }

  @override
  void togglePlay() => _isPlaying ? pause() : play();

  @override
  void setSpeed(double speed) {
    _speed = _clampSpeed(speed);
    if (_composition == null) {
      if (mounted) setState(() {});
      return;
    }
    final wasPlaying = _isPlaying;
    _ctrl.stop();
    _applyDuration();
    if (wasPlaying) {
      play();
    } else {
      if (mounted) setState(() {});
    }
  }

  @override
  void seekTo(double value) {
    _ctrl.stop();
    _ctrl.value = value.clamp(0.0, 1.0);
    setState(() => _isPlaying = false);
  }

  @override
  void reset() {
    _ctrl.stop();
    _ctrl.value = widget.reverse ? 1.0 : 0.0;
    setState(() => _isPlaying = false);
  }

  @override
  void dispose() {
    unawaited(_stateController.close());
    _reverseLooping = false;
    _reverseDrive += 1;
    _isPlaying = false;
    _ctrl.removeStatusListener(_onPlayOnceComplete);
    _ctrl.removeListener(_onLapTick);
    _ctrl.dispose();
    super.dispose();
  }

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final st = _rs;

    Widget content;
    if (_hasError) {
      content = GestureDetector(
        onTap: _retry,
        child: st.errorWidget ?? _defaultError(),
      );
    } else if (!_loaded) {
      content = st.loadingWidget ?? _defaultLoading();
    } else if (widget.type == AnimationType.gif) {
      content = _buildGif();
    } else {
      content = _buildLottie();
    }

    // Apply color filter/tint
    if (widget.colorFilter != null && !_hasError && _loaded) {
      content = ColorFiltered(
        colorFilter: ColorFilter.mode(
          widget.colorFilter!,
          widget.colorFilterBlendMode,
        ),
        child: content,
      );
    }

    if (st.showControls || st.showProgressBar) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: content),
          if (st.showProgressBar && widget.type != AnimationType.gif)
            _buildProgressBar(st),
          if (st.showControls) _buildControls(st),
        ],
      );
    }

    final box = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: st.backgroundColor,
        borderRadius: st.borderRadius,
        border: st.border,
        boxShadow: st.boxShadow,
      ),
      clipBehavior: st.borderRadius != null ? Clip.antiAlias : Clip.none,
      child: content,
    );

    return _withVisibility(_withSemantics(box, st));
  }

  /// Pauses a player scrolled out of view.
  ///
  /// `TickerMode` already stops one whose ROUTE is covered, but a
  /// Lottie in a list keeps drawing frames nobody can see. Pausing
  /// holds the frame, so scrolling back is a resume and not a restart.
  ///
  /// The key is the widget's own identity — `VisibilityDetector`
  /// requires a unique one, and two players over the same source in one
  /// list are a normal thing to have.
  Widget _withVisibility(Widget child) {
    if (!widget.pauseWhenOffscreen) return child;
    return VisibilityDetector(
      key: _visibilityKey,
      onVisibilityChanged: _onVisibilityChanged,
      child: child,
    );
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!mounted) return;
    final visible = info.visibleFraction >= AnimationDefaults.visibleFraction;
    if (visible == _visible) return;
    _visible = visible;

    if (!visible) {
      // Remember whether it was OURS to resume. A player the reader
      // paused by hand must not start itself when it scrolls back.
      _resumeOnVisible = _isPlaying;
      if (_isPlaying) pause();
      return;
    }
    if (_resumeOnVisible && !_reduceMotion) {
      _resumeOnVisible = false;
      play();
    }
  }

  /// One node for the whole player, or none at all.
  ///
  /// A named animation is content — a success tick, an empty-state
  /// illustration — and says so. An unnamed one is DECORATION, and a
  /// decoration is excluded from the tree rather than left as an
  /// unlabelled node to swipe past. Same rule `GlobalImage` uses.
  ///
  /// The transport row is exempt: it is a control, and controls stay
  /// reachable whatever the animation beside them is.
  Widget _withSemantics(Widget box, ResolvedAnimationStyle st) {
    final label = widget.semanticLabel;
    if (label == null) {
      // Controls carry their own nodes and must survive the exclusion —
      // and so must the ERROR plate, which is a retry button whatever
      // the animation behind it was for. A decoration that failed to
      // load and offers a tap has to be reachable by something other
      // than a pointer.
      final interactive = st.showControls || st.showProgressBar || _hasError;
      return interactive ? box : ExcludeSemantics(child: box);
    }
    return Semantics(
      label: _reduceMotion
          ? '$label, ${AnimationStrings.pausedReducedMotion}'
          : label,
      image: true,
      child: box,
    );
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _errorMsg = null;
      _loaded = false;
    });
    if (widget.type == AnimationType.gif) {
      setState(() {
        _loaded = true;
        _isPlaying = widget.autoPlay;
      });
    } else {
      _loadLottie();
    }
  }

  Widget _buildGif() {
    final ImageProvider provider;
    switch (widget.sourceType) {
      case AnimationSourceType.asset:
        provider = AssetImage(widget.source);
      case AnimationSourceType.network:
        provider = NetworkImage(widget.source);
      case AnimationSourceType.file:
        provider = FileImage(File(widget.source));
    }

    // TickerMode is how Flutter pauses a multiframe image, and it holds
    // the frame it is on. The key used to carry `_isPlaying`, which
    // rebuilt the widget on every toggle: that re-resolved the provider
    // and restarted decoding, so "pause" was really "stop, and start
    // again from frame one when you resume".
    //
    // It is also why a GIF already stood still under reduce-motion
    // while a Lottie beside it kept going — Flutter checks
    // `disableAnimations` here itself.
    return TickerMode(
      enabled: _isPlaying,
      child: Image(
        key: ValueKey('gif_${widget.source}'),
        image: provider,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        alignment: widget.alignment,
        errorBuilder: (_, e, _) {
          if (!_hasError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                // The callback fires for Lottie failures too — a GIF
                // that cannot decode is the same event to a caller.
                widget.onError?.call(e.toString());
                setState(() {
                  _hasError = true;
                  _errorMsg = e.toString();
                });
              }
            });
          }
          return _rs.errorWidget ?? _defaultError();
        },
      ),
    );
  }

  bool get _hasDelegates =>
      widget.textDelegate != null ||
      widget.textStyleDelegate != null ||
      (widget.valueDelegates != null && widget.valueDelegates!.isNotEmpty);

  Widget _buildLottie() {
    return Lottie(
      composition: _composition,
      controller: _ctrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      delegates: _hasDelegates
          ? LottieDelegates(
              text: widget.textDelegate,
              textStyle: widget.textStyleDelegate,
              values: widget.valueDelegates,
            )
          : null,
    );
  }

  /// The seek bar. A drag target AND a value, so it announces itself as
  /// a slider rather than as a coloured line nothing can reach.
  Widget _buildProgressBar(ResolvedAnimationStyle st) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => LayoutBuilder(
        builder: (_, constraints) => GestureDetector(
          onTapDown: (d) {
            final inset = context.spacing.sm;
            final w = constraints.maxWidth - inset * 2;
            final fraction = ((d.localPosition.dx - inset) / w).clamp(0.0, 1.0);
            seekTo(fraction);
          },
          child: Container(
            height: st.progressBarHeight + context.spacing.md * 2,
            padding: EdgeInsets.symmetric(horizontal: context.spacing.sm),
            alignment: Alignment.center,
            child: GlobalProgress.linear(
              value: _ctrl.value,
              style: ProgressStyle(
                thickness: st.progressBarHeight,
                color: st.progressBarColor,
                trackColor: st.progressBarBackgroundColor,
                animated: false,
              ),
            ),
          ),
        ),
      ),
    ).asSlider(
      label: AnimationStrings.seek,
      value: AnimationStrings.percentPlayed(_percent),
      // What it WOULD become. Flutter asserts on a value with an
      // increase action and no increased value, every frame, from
      // inside the semantics flush.
      increasedValue: AnimationStrings.percentPlayed(
        _percentAfter(_kSeekStep),
      ),
      decreasedValue: AnimationStrings.percentPlayed(
        _percentAfter(-_kSeekStep),
      ),
      onIncrease: () => seekTo(_ctrl.value + _kSeekStep),
      onDecrease: () => seekTo(_ctrl.value - _kSeekStep),
    );
  }

  int get _percent => (_ctrl.value * 100).round();

  int _percentAfter(double delta) =>
      ((_ctrl.value + delta).clamp(0.0, 1.0) * 100).round();

  Widget _buildControls(ResolvedAnimationStyle st) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing.md,
          vertical: context.spacing.xs,
        ),
        color: st.controlsBackgroundColor,
        child: Row(
          children: [
            GlobalIconButton(
              iconData: _isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              tooltip: _isPlaying
                  ? AnimationStrings.pause
                  : AnimationStrings.play,
              onPressed: togglePlay,
              iconSize: st.controlsIconSize,
              style: ButtonStateStyle(foregroundColor: st.controlsColor),
            ),
            GlobalIconButton(
              iconData: Icons.replay_rounded,
              tooltip: AnimationStrings.replay,
              onPressed: _replay,
              iconSize: st.controlsIconSize - context.spacing.xs,
              style: ButtonStateStyle(foregroundColor: st.controlsColor),
            ),
            SizedBox(width: context.spacing.sm),
            if (_composition != null)
              Expanded(
                child: Text(
                  AnimationStrings.percentPlayed(_percent),
                  style: context.textTheme.labelSmall?.copyWith(
                    color: st.controlsColor.withValues(
                      alpha: AnimationDefaults.progressTextOpacity,
                    ),
                    // Tabular, or the row twitches sideways as the
                    // digits change under it.
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ).excludeFromSemantics(),
              ),
            _buildSpeedPill(st),
          ],
        ),
      ),
    );
  }

  void _replay() {
    reset();
    // Defer play to next frame so reset completes cleanly.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) play();
    });
  }

  /// Cycles the playback rate. A button, and it says what it does —
  /// "1x" alone tells a screen reader the current value and nothing
  /// about what tapping it would change.
  Widget _buildSpeedPill(ResolvedAnimationStyle st) {
    final label = _speed % 1 == 0 ? _speed.toInt().toString() : '$_speed';
    return GestureDetector(
      onTap: _cycleSpeed,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.spacing.sm,
          vertical: context.spacing.xs / 2,
        ),
        decoration: BoxDecoration(
          color: st.controlsColor.withValues(
            alpha: AnimationDefaults.speedPillOpacity,
          ),
          borderRadius: BorderRadius.circular(context.radii.sm),
        ),
        child: Text(
          AnimationStrings.speedMultiplier(label),
          style: context.textTheme.labelMedium?.copyWith(
            color: st.controlsColor,
            fontWeight: FontWeight.w700,
          ),
        ).excludeFromSemantics(),
      ),
    ).semantics(
      button: true,
      label: AnimationStrings.playbackSpeed,
      value: AnimationStrings.speedMultiplier(label),
      onTap: _cycleSpeed,
    );
  }

  void _cycleSpeed() {
    const speeds = AnimationDefaults.speeds;
    final idx = speeds.indexWhere((s) => (s - _speed).abs() < 0.01);
    setSpeed(speeds[(idx + 1) % speeds.length]);
  }

  Widget _defaultLoading() => GlobalShimmer.placeholder(
    width: widget.width ?? double.infinity,
    height: widget.height ?? 200,
    borderRadius: widget.style.borderRadius ?? BorderRadius.circular(8),
  );

  Widget _defaultError() {
    var msg = AnimationStrings.loadFailed;
    if (_errorMsg != null) {
      if (_errorMsg!.contains('404')) {
        msg = AnimationStrings.notFound;
      } else if (_errorMsg!.contains('403')) {
        msg = AnimationStrings.accessDenied;
      } else if (_errorMsg!.contains('SocketException') ||
          _errorMsg!.contains('ClientException')) {
        msg = AnimationStrings.networkError;
      } else if (_errorMsg!.contains('decode') ||
          _errorMsg!.contains('parse') ||
          _errorMsg!.contains('assertion')) {
        msg = AnimationStrings.invalidFile;
      }
    }

    // The plate has to FIT the box the caller gave. A glyph, a headline
    // and a retry line come to about 150dp, which overflowed every
    // animation smaller than that — and a 40dp spinner icon is a common
    // size for one. Below the threshold it degrades to the glyph alone,
    // which still says "this did not load" and still takes the tap.
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : double.infinity;
        final tiny = height < AnimationDefaults.errorPlateMinHeight;
        final glyph = tiny
            ? math.min(context.iconSizes.md, height * 0.6)
            : context.iconSizes.lg;

        return Center(
          child: Padding(
            padding: EdgeInsets.all(tiny ? 0 : context.spacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GlobalIcon(
                  icon: Icons.broken_image_rounded,
                  style: IconStyle(
                    size: glyph,
                    color: context.statusColors.error,
                    backgroundColor: context.statusColors.error,
                    backgroundOpacity: 0.10,
                    containerShape: IconContainerShape.circle,
                    padding: EdgeInsets.all(tiny ? 4 : context.spacing.sm),
                  ),
                ),
                if (!tiny) ...[
                  SizedBox(height: context.spacing.sm),
                  Text(
                    msg,
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.statusColors.error,
                    ),
                  ),
                  SizedBox(height: context.spacing.xs),
                  Text(
                    CommonStrings.tapToRetry,
                    textAlign: TextAlign.center,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.textColors.secondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    ).semantics(
      button: true,
      label: msg,
      hint: CommonStrings.tapToRetry,
      onTap: _retry,
    );
  }
}
