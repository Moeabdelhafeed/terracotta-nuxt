// Dart imports:
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:lottie/lottie.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart' as mkv;

import '../../../core/di/service_locator.dart';
import '../../../core/notifications/notification_routing.dart';
import '../../../core/splash/default_splash_next.dart';
import '../../../core/splash/splash_models.dart';
import '../../../core/splash/splash_redirect.dart';
import '../../../core/splash/splash_warmer.dart';
import '../../../data/services/navigation_service.dart';
import '../../../shared/module/image/global_image.dart';
import '../../_shared/first_run_artwork.dart';
import '../widgets/vessel_reveal.dart';
import '../widgets/vessel_reveal_gate.dart';

/// Mark geometry, straight from the design's `splash screen` frame.
const double _kMarkHeight = 147.76;

/// The splash GROUND — the app's own terracotta, not white.
///
/// The design's splash frame is white with the mark on it, and that is
/// what this was. The launch is an animation now: the mark draws
/// itself, fills, and then becomes a hole in this colour which opens
/// until the app is behind it — and a hole has to be cut out of
/// something. White would make the reveal invisible, since the app it
/// reveals is white too.
///
/// Stated explicitly rather than read from the theme, and it MUST
/// match the native launch colour in all four flavours: the native
/// screen is a solid colour and the first Flutter frame replaces it,
/// so any difference between the two blinks.
const Color _kSplashBackground = Color(0xFF81341A);

/// The one reveal, shared by the two halves of a builder hero.
///
/// `SplashHero.builder` takes a renderer and a readiness future as
/// SEPARATE callbacks, so something has to join them — the animation
/// knows when it has finished and the future is what the gate waits
/// on. `SplashPage.defaults` is a getter and runs on every build, so
/// this lives outside it: two different objects would mean waiting on
/// a future nothing ever completes.
final _VesselSplashHero _reveal = _VesselSplashHero();

class _VesselSplashHero {
  /// Replaced on each [readiness], which the splash calls once per
  /// mount and always before the animation can finish. Without that a
  /// second launch in the same process — every test after the first —
  /// would find it already complete and never wait.
  Completer<void> _done = Completer<void>();

  Widget build(BuildContext context) => VesselReveal(
    // The DRAW half only. The opening happens on an overlay above the
    // app, where a hole can be transparent — see [VesselRevealGate].
    ground: _kSplashBackground,
    markHeight: _kMarkHeight,
    onDone: () {
      if (!_done.isCompleted) _done.complete();
    },
  );

  Future<void> readiness(BuildContext context) {
    if (_done.isCompleted) _done = Completer<void>();
    return _done.future;
  }
}

/// Splash route. Orchestrates: native-bridge bg color → hero render
/// → hero readiness → bootstrap gate → optional extra delay →
/// destination decider.
///
/// All behavior is driven by [SplashOptions]. The default
/// configuration mirrors the prior hardcoded splash (white bg,
/// 800ms hold, [defaultSplashNext] decider) so wiring the new
/// screen into an existing app is a no-op.
class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    SplashOptions? options,
  }) : _options = options;

  /// Terracotta's splash: the vessel draws itself on the terracotta
  /// ground, fills, then opens outward as a hole until the app is
  /// revealed through it. See [VesselReveal].
  ///
  /// A BUILDER hero, because the reveal both renders and says when it
  /// is finished — the canonical variants either hold for a fixed time
  /// or end with a file. `readiness` completes when the animation
  /// does, and the gate that follows it is unchanged: bootstrap, then
  /// `minDuration`, then the decider.
  ///
  /// The mark's height is the design's own (147.76 in an 844-tall
  /// frame) rather than a rounded number, because the silhouette's
  /// neck is narrow enough that rounding visibly changes its weight.
  static SplashOptions get defaults => SplashOptions(
    hero: SplashHero.builder(
      builder: _reveal.build,
      readiness: _reveal.readiness,
    ),
    backgroundColor: _kSplashBackground,
    nextDecider: defaultSplashNext,
    // The reveal runs 3.4s and the floor must not cut it short — the
    // gate takes the LONGER of the two, so a hold shorter than the
    // animation simply never binds.
    minDuration: const Duration(milliseconds: 800),
  );

  final SplashOptions? _options;

  SplashOptions get options => _options ?? defaults;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  Timer? _maxTimer;
  late final DateTime _mountedAt;
  bool _navigated = false;
  final Completer<void> _heroReady = Completer<void>();

  @override
  void initState() {
    super.initState();
    _mountedAt = DateTime.now();
    _emit('splash_mounted', {
      'hero': widget.options.hero.runtimeType.toString(),
    });
    _orchestrate();

    // Decode the next screens' drawings while this one is still up.
    //
    // NOT awaited, and deliberately not part of the orchestration: the
    // splash must never wait on artwork. If it finishes first the
    // onboarding and auth screens paint their drawings on frame one; if
    // it does not, they decode as they always did. Either way the
    // customer leaves the splash on the same schedule.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(FirstRunArtwork.warm(context));
    });
  }

  @override
  void dispose() {
    _maxTimer?.cancel();
    super.dispose();
  }

  void _emit(String name, Map<String, Object?> params) {
    widget.options.onAnalyticsEvent?.call(name, params);
  }

  // ─── Orchestration ──────────────────────────────────────────

  Future<void> _orchestrate() async {
    // Hard ceiling: bail out no matter what.
    _maxTimer = Timer(widget.options.maxDuration, () {
      if (_navigated) return;
      _emit('splash_max_duration_exceeded', {});
      _navigate();
    });

    final futures = <Future<void>>[
      _heroReady.future,
      Future<void>.delayed(widget.options.minDuration),
    ];
    if (widget.options.waitForBootstrap) {
      futures.add(SplashWarmer.instance.bootstrapDone);
    }

    if (SplashRedirect.isOverridden) {
      switch (SplashRedirect.devOverride.value) {
        case SplashDevOverride.forceHold:
          return; // never auto-navigate; tap-to-skip still works
        case SplashDevOverride.forceSkip:
          // Wait only on bootstrap so the app doesn't crash mid-init.
          if (widget.options.waitForBootstrap) {
            await SplashWarmer.instance.bootstrapDone;
          }
          unawaited(_navigate());
          return;
        case SplashDevOverride.auto:
          break;
      }
    }

    try {
      await Future.wait(futures);
    } catch (_) {
      /* swallow — orchestrator falls through to navigate */
    }
    if (widget.options.extraDelay > Duration.zero) {
      await Future<void>.delayed(widget.options.extraDelay);
    }
    if (!mounted || _navigated) return;
    unawaited(_navigate());
  }

  void _signalHeroReady() {
    if (!_heroReady.isCompleted) {
      _heroReady.complete();
      _emit('splash_hero_ready', {
        'elapsed_ms': DateTime.now().difference(_mountedAt).inMilliseconds,
      });
    }
  }

  void _onTapSkip() {
    if (!widget.options.tapToSkip || _navigated) return;
    _emit('splash_skipped', {});
    _signalHeroReady();
    unawaited(_navigate());
  }

  Future<void> _navigate() async {
    if (_navigated) return;
    _navigated = true;
    final ctx = context;
    if (!ctx.mounted) return;
    final dest = await widget.options.nextDecider(ctx);
    if (!ctx.mounted) return;
    _emit('splash_navigated', {
      'mode': dest.mode.name,
      'location': dest.location,
    });
    // COVER FIRST, then navigate.
    //
    // The overlay above the `Navigator` takes over the launch here: it
    // comes up painting exactly what this route is already painting —
    // the ground and the filled mark — so the swap cannot be seen, and
    // the destination's first frame lands underneath it rather than in
    // front of the reader. Opening before covering would flash that
    // frame; the reveal then cuts a transparent hole down to it, which
    // is the whole point and the one thing a route could not do.
    VesselRevealGate.instance.open();
    final nav = getIt<NavigationService>();
    switch (dest.mode) {
      case SplashPushMode.go:
        nav.router.go(dest.location, extra: dest.extra);
      case SplashPushMode.replace:
        unawaited(
          nav.router.pushReplacement(dest.location, extra: dest.extra),
        );
      case SplashPushMode.push:
        unawaited(nav.router.push(dest.location, extra: dest.extra));
    }

    // A NOTIFICATION THAT LAUNCHED THE APP, claimed now.
    //
    // It arrived through `getInitialMessage` before the router
    // existed, so `FCMService` stashed it. Here is the first moment
    // there is somewhere to navigate TO — after the splash has put the
    // real destination on the stack, so the pushed screen has that
    // underneath it rather than the splash.
    NotificationRouting.claimLaunchTap();
  }

  // ─── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bg =
        widget.options.backgroundColor ??
        Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: bg,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTapSkip,
        child: Stack(
          children: [
            Positioned.fill(
              child: _SplashHeroRenderer(
                hero: widget.options.hero,
                respectReduceMotion: widget.options.respectReduceMotion,
                onHeroReady: _signalHeroReady,
              ),
            ),
            if (widget.options.footerBuilder != null)
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: 0,
                child: _FooterDriver(
                  builder: widget.options.footerBuilder!,
                  vsync: this,
                  total: widget.options.maxDuration,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Hero renderer — switches on type, signals readiness via callback
// ═══════════════════════════════════════════════════════════════

class _SplashHeroRenderer extends StatelessWidget {
  const _SplashHeroRenderer({
    required this.hero,
    required this.respectReduceMotion,
    required this.onHeroReady,
  });

  final SplashHero hero;
  final bool respectReduceMotion;
  final VoidCallback onHeroReady;

  @override
  Widget build(BuildContext context) {
    final reduce =
        respectReduceMotion && MediaQuery.disableAnimationsOf(context);
    return switch (hero) {
      SplashStaticHero(:final child, :final display) => _Timed(
        duration: display,
        onReady: onHeroReady,
        child: child,
      ),
      SplashIconHero(:final icon, :final color, :final size, :final display) =>
        _Timed(
          duration: display,
          onReady: onHeroReady,
          child: Center(
            child: Icon(icon, size: size, color: color),
          ),
        ),
      SplashImageHero(
        :final ref,
        :final display,
        :final width,
        :final height,
        :final fit,
      ) =>
        _Timed(
          duration: display,
          onReady: onHeroReady,
          child: Center(
            child: GlobalImage.a(
              ref.resolve(context),
              width: width,
              height: height,
              // NO placeholder. `GlobalImage` shows a shimmer once a
              // load passes 200ms and then holds it for 400 — right for
              // a network image, absurd here: this screen IS the
              // loading screen, and a skeleton of the logo shimmering
              // on top of it says the splash is waiting for the splash.
              //
              // Nothing is a better wait than something wrong. The mark
              // is 21KB and decodes in a few frames, and those frames
              // are blank against a background of exactly the colour
              // they would have been anyway.
              placeholder: const SizedBox.shrink(),
              style: ImageStyle(fit: fit, borderRadius: BorderRadius.zero),
            ),
          ),
        ),
      SplashLottieHero h => _LottieHero(hero: h, onReady: onHeroReady),
      SplashVideoHero h =>
        reduce
            ? _Timed(
                duration: const Duration(milliseconds: 800),
                onReady: onHeroReady,
                child: h.poster ?? const SizedBox.shrink(),
              )
            : _VideoHero(hero: h, onReady: onHeroReady),
      SplashBuilderHero(:final builder, :final readiness) => _BuilderHero(
        builder: builder,
        readiness: readiness,
        onReady: onHeroReady,
      ),
    };
  }
}

// ─── Timed (static / icon / image) ─────────────────────────────

class _Timed extends StatefulWidget {
  const _Timed({
    required this.duration,
    required this.child,
    required this.onReady,
  });
  final Duration duration;
  final Widget child;
  final VoidCallback onReady;

  @override
  State<_Timed> createState() => _TimedState();
}

class _TimedState extends State<_Timed> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, widget.onReady);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ─── Lottie ────────────────────────────────────────────────────

class _LottieHero extends StatefulWidget {
  const _LottieHero({required this.hero, required this.onReady});
  final SplashLottieHero hero;
  final VoidCallback onReady;

  @override
  State<_LottieHero> createState() => _LottieHeroState();
}

class _LottieHeroState extends State<_LottieHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  int _completedLoops = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
    _ctrl.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      _completedLoops++;
      if (_completedLoops >= widget.hero.repeatCount) {
        widget.onReady();
        return;
      }
      if (widget.hero.loop) _ctrl.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        widget.hero.asset,
        controller: _ctrl,
        width: widget.hero.width,
        height: widget.hero.height,
        fit: widget.hero.fit,
        onLoaded: (composition) {
          _ctrl
            ..duration = composition.duration
            ..forward();
        },
      ),
    );
  }
}

// ─── Video ─────────────────────────────────────────────────────

class _VideoHero extends StatefulWidget {
  const _VideoHero({required this.hero, required this.onReady});
  final SplashVideoHero hero;
  final VoidCallback onReady;

  @override
  State<_VideoHero> createState() => _VideoHeroState();
}

class _VideoHeroState extends State<_VideoHero> {
  Player? _player;
  mkv.VideoController? _controller;
  StreamSubscription<bool>? _completedSub;
  StreamSubscription<Duration>? _positionSub;
  int _completedLoops = 0;
  bool _firstFrameSeen = false;
  bool _readied = false;

  @override
  void initState() {
    super.initState();
    _attach();
  }

  Future<void> _attach() async {
    // Try to take the pre-warmed player from bootstrap. Fall back
    // to a cold open if warmup never ran or failed.
    var player = SplashWarmer.instance.takePlayer();
    final fromWarmer = player != null;
    player ??= Player();

    try {
      _controller = mkv.VideoController(player);
      await _controller!.waitUntilFirstFrameRendered;
      if (!fromWarmer) {
        final media = _media(widget.hero.source);
        await player.open(Media(media), play: false);
      }
      if (widget.hero.muted) await player.setVolume(0);
      await player.setPlaylistMode(
        widget.hero.loop ? PlaylistMode.single : PlaylistMode.none,
      );
      // Listen for end-of-stream completions.
      _completedSub = player.stream.completed.listen((completed) {
        if (!completed) return;
        _completedLoops++;
        if (_completedLoops >= widget.hero.minLoops && !_readied) {
          _readied = true;
          widget.onReady();
        }
      });
      // Cross-fade trigger — once position > 0, the first decoded
      // frame has been pushed to the texture. Until then we show
      // the poster.
      _positionSub = player.stream.position.listen((p) {
        if (!_firstFrameSeen && p > Duration.zero) {
          if (mounted) setState(() => _firstFrameSeen = true);
        }
      });
      await player.play();
    } catch (e, st) {
      debugPrint('[SplashVideo] attach failed: $e');
      debugPrintStack(stackTrace: st);
      // Fail open — treat as ready so the orchestrator can move on.
      widget.onReady();
    }
    _player = player;
  }

  String _media(SplashVideoSource s) => switch (s) {
    SplashVideoAsset(:final path) => 'asset:///$path',
    SplashVideoFile(:final path) => path,
    SplashVideoNetwork(:final url) => url,
  };

  @override
  void dispose() {
    _completedSub?.cancel();
    _positionSub?.cancel();
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final poster = widget.hero.poster;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (poster != null && !_firstFrameSeen) poster,
        AnimatedOpacity(
          opacity: controller != null && _firstFrameSeen ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: controller == null
              ? const SizedBox.shrink()
              : mkv.Video(
                  controller: controller,
                  fit: widget.hero.fit,
                  controls: mkv.NoVideoControls,
                ),
        ),
      ],
    );
  }
}

// ─── Builder escape hatch ──────────────────────────────────────

class _BuilderHero extends StatefulWidget {
  const _BuilderHero({
    required this.builder,
    required this.readiness,
    required this.onReady,
  });
  final WidgetBuilder builder;
  final Future<void> Function(BuildContext) readiness;
  final VoidCallback onReady;

  @override
  State<_BuilderHero> createState() => _BuilderHeroState();
}

class _BuilderHeroState extends State<_BuilderHero> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await widget.readiness(context);
      } catch (_) {}
      widget.onReady();
    });
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

// ─── Footer driver ─────────────────────────────────────────────

class _FooterDriver extends StatefulWidget {
  const _FooterDriver({
    required this.builder,
    required this.vsync,
    required this.total,
  });
  final Widget Function(BuildContext, double) builder;
  final TickerProvider vsync;
  final Duration total;

  @override
  State<_FooterDriver> createState() => _FooterDriverState();
}

class _FooterDriverState extends State<_FooterDriver> {
  late final Ticker _ticker;
  late final DateTime _start;
  double _p = 0;

  @override
  void initState() {
    super.initState();
    _start = DateTime.now();
    _ticker = widget.vsync.createTicker((_) {
      final elapsed = DateTime.now()
          .difference(_start)
          .inMilliseconds
          .toDouble();
      final next = (elapsed / widget.total.inMilliseconds).clamp(0.0, 1.0);
      if ((next - _p).abs() < 0.01) return;
      setState(() => _p = next);
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _p);
}
