import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Moves its child with the device, so a flat drawing sits in a
/// shallow space rather than on the glass.
///
/// ## What it reads, and why not the gyroscope
///
/// The ACCELEROMETER, not `gyroscopeEventStream`. A gyroscope reports
/// angular VELOCITY, so holding a tilt reports zero and the only way
/// to a position is to integrate — which accumulates error, and the
/// art drifts off-centre over a minute of holding the phone still.
/// Correcting that needs a decay that fights the effect itself.
///
/// The accelerometer reports gravity, which IS the tilt: absolute, no
/// integration, no drift. It is noisier, and [_smoothing] is the whole
/// answer to that — a low-pass that also gives the movement its
/// weight, so the drawing settles rather than snapping.
///
/// ## What it costs, and what stops it costing that
///
/// The stream fires about 60 times a second. Driving `setState` from
/// it would rebuild this page — cubit builders, the whole booking —
/// every frame. So the offset lives in a [ValueNotifier] and only the
/// `ValueListenableBuilder` around the child listens: the rest of the
/// tree is built once and never hears about the phone moving.
///
/// ## Where it does nothing
///
///   * **Reduced motion.** Ambient movement nobody asked for is
///     exactly what that setting is about, and it is checked on every
///     build rather than once — the reader can turn it on while this
///     is on screen.
///   * **No sensor.** A simulator, a desktop, a widget test: the
///     stream simply never delivers, the offset stays zero and this is
///     a `Transform` of nothing. It must not be an error — half the
///     app's tests would fail on a machine with no accelerometer.
///
/// ## It centres on HOW THE PHONE IS BEING HELD
///
/// Not on upright. Nobody reads a phone at 0°, so treating gravity's
/// full 9.81 as the neutral put the drawing several points off the
/// moment the page opened — the reader sees the picture sitting wrong,
/// not an effect. The first reading after mount is taken as the rest
/// pose instead and everything is measured from there, so the art is
/// exactly where it was drawn before this widget existed and only
/// MOVEMENT moves it.
///
/// ## It is drawn slightly LARGER than its box
///
/// A layer that moves has to be bigger than the window it moves in, or
/// the far edge pulls away and shows what is behind it. That is what
/// happened here: the drawing runs edge to edge by design — its line
/// is a horizon — and fourteen points of travel took fourteen points
/// of it off one side and left a gap.
///
/// So the child is scaled by just enough to cover the box plus the
/// full travel on both axes. On a 14-point depth over a 360-point
/// screen that is under 8%, which nobody sees on a line drawing; what
/// they would see is the horizon stopping short of the edge.
///
/// ## Amplitude
///
/// [depth] is the FULL travel in logical pixels at the edge of
/// [_maxTilt]. Small on purpose: at thirty the page reads as loose
/// rather than deep, and on a drawing with a horizon in it the horizon
/// visibly slides. Six to ten is the range that reads as parallax
/// without anybody noticing why.
class ParallaxTilt extends StatefulWidget {
  const ParallaxTilt({
    required this.child,
    this.depth = 8,
    this.invert = false,
    super.key,
  });

  final Widget child;

  /// How far the child travels, in logical pixels, at full tilt.
  final double depth;

  /// Move AGAINST the tilt instead of with it.
  ///
  /// Two layers of one picture want opposite signs — that difference
  /// is what reads as depth. The foreground goes with the tilt, the
  /// ground behind it against.
  final bool invert;

  /// HOW FAR THE PHONE MUST LEAN for the effect to be at full travel,
  /// measured from the pose it arrived in, in m/s² on one axis.
  ///
  /// **This is the sensitivity, and it works backwards**: lower means
  /// a smaller lean reaches the end of [depth], so the drawing reacts
  /// MORE. Gravity is 9.81, so 2 is about a 12° lean — a wrist, not an
  /// arm. Three was a deliberate turn of the phone; the effect only
  /// showed if you went looking for it.
  ///
  /// Pair it with [depth]: this decides how FAR you lean, that decides
  /// how far the picture goes.
  static const _maxTilt = 2.0;

  /// How much of each reading survives. The rest is the previous
  /// value, which is what gives the movement its weight.
  ///
  /// Tuned WITH [_sampling], not against it: at 50 readings a second
  /// 0.12 settles in about a sixth of a second, which reads as heavy
  /// rather than late.
  static const _smoothing = 0.12;

  /// HOW OFTEN TO ASK. `sensors_plus` defaults to
  /// `SensorInterval.normalInterval` — **200ms**, five readings a
  /// second — and at that rate the drawing arrives in visible steps a
  /// third of a second behind the phone. It reads as lag because it is
  /// lag: the smoothing was never the problem.
  ///
  /// `gameInterval` is 20ms, which is a reading either side of every
  /// frame at 60Hz.
  static const _sampling = SensorInterval.gameInterval;

  /// The sampling period, for the guard that stops it drifting back to
  /// the package default.
  @visibleForTesting
  static Duration get debugSampling => _sampling;

  @override
  State<ParallaxTilt> createState() => _ParallaxTiltState();
}

class _ParallaxTiltState extends State<ParallaxTilt>
    with WidgetsBindingObserver {
  /// The child's offset, in logical pixels. NOT state: see the class
  /// doc — writing this through `setState` would rebuild the page at
  /// sensor rate.
  final _offset = ValueNotifier<Offset>(Offset.zero);

  StreamSubscription<AccelerometerEvent>? _sub;

  /// The smoothed reading, in the accelerometer's own units.
  double _x = 0;
  double _y = 0;

  /// The pose the phone was in when this arrived — see the class doc.
  /// Null until the first reading, which is what claims it.
  double? _restX;
  double? _restY;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listen();
  }

  @override
  void didUpdateWidget(ParallaxTilt old) {
    super.didUpdateWidget(old);
    if (old.depth != widget.depth || old.invert != widget.invert) _apply();
  }

  /// STOPS WITH THE APP. The sensor keeps delivering behind a locked
  /// screen otherwise, which is a radio and a wakelock spent on a
  /// drawing nobody is looking at.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _listen();
    } else {
      unawaited(_sub?.cancel());
      _sub = null;
      // THE POSE IS FORGOTTEN WITH THE SUBSCRIPTION. A phone that went
      // in a pocket and came back out is being held differently, and
      // measuring from where it was before would open the page with
      // the drawing already pushed to one side.
      _restX = null;
      _restY = null;
      _offset.value = Offset.zero;
    }
  }

  void _listen() {
    if (_sub != null) return;
    // `onError` rather than a throw: a device with no accelerometer is
    // a device that shows the drawing still, not one that red-screens.
    _sub = accelerometerEventStream(
      samplingPeriod: ParallaxTilt._sampling,
    ).listen(_onReading, onError: (_) {}, cancelOnError: true);
  }

  void _onReading(AccelerometerEvent event) {
    // THE FIRST ONE IS THE NEUTRAL, and it is taken WHOLE.
    //
    // Smoothing into it from zero swung the drawing across its full
    // travel and back over the first quarter second of the page — an
    // animation nobody asked for, on the thing the reader is looking
    // at as it arrives.
    if (_restX == null) {
      _restX = event.x;
      _restY = event.y;
      _x = event.x;
      _y = event.y;
      _apply();
      return;
    }

    // A LOW PASS. The raw signal shakes with the reader's hand, and
    // the drawing would shake with it.
    _x += (event.x - _x) * ParallaxTilt._smoothing;
    _y += (event.y - _y) * ParallaxTilt._smoothing;
    _apply();
  }

  void _apply() {
    if (!mounted) return;

    final sign = widget.invert ? -1.0 : 1.0;
    const max = ParallaxTilt._maxTilt;

    // The DEVICE's x grows to the right whichever way the app reads,
    // so the direction is flipped for Arabic — a drawing that leans
    // away from the tilt on one side and into it on the other reads as
    // broken rather than as depth.
    final rtl = Directionality.of(context) == TextDirection.rtl;

    // FROM THE POSE IT ARRIVED IN, not from upright — see the class
    // doc. Zero until the first reading claims one, which is also what
    // keeps a device with no sensor exactly where it was.
    final restX = _restX;
    final restY = _restY;
    if (restX == null || restY == null) return;

    _offset.value = Offset(
      // Negated: leaning the phone LEFT should slide the picture right,
      // the way a thing seen through a window does.
      -((_x - restX) / max).clamp(-1.0, 1.0) *
          widget.depth *
          sign *
          (rtl ? -1 : 1),
      ((_y - restY) / max).clamp(-1.0, 1.0) * widget.depth * sign,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_sub?.cancel());
    _offset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // CHECKED EVERY BUILD, not once. The reader can turn reduced
    // motion on while this is on screen, and the effect has to stop
    // when they do.
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;

    return LayoutBuilder(
      builder: (context, constraints) {
        // ENOUGH TO COVER THE TRAVEL, on whichever axis needs more.
        // Both ends move, so the box has to grow by twice the depth.
        final grow = widget.depth * 2;
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final scale = math.max(
          width.isFinite && width > 0 ? (width + grow) / width : 1.0,
          height.isFinite && height > 0 ? (height + grow) / height : 1.0,
        );

        return ValueListenableBuilder<Offset>(
          valueListenable: _offset,
          builder: (context, offset, child) => Transform.translate(
            offset: offset,
            // The child is passed THROUGH rather than rebuilt: it is
            // the same drawing at every offset, and rebuilding an
            // image sixty times a second is the cost this widget
            // exists to avoid.
            child: child,
          ),
          child: Transform.scale(scale: scale, child: widget.child),
        );
      },
    );
  }
}

/// Two layers, moving against each other.
///
/// The depth is the DIFFERENCE, not the travel: a drawing and its
/// ground both sliding the same way is the whole page moving, which
/// reads as a bug. [background] goes against the tilt and
/// [foreground] with it, so the gap between them opens and closes.
class ParallaxLayers extends StatelessWidget {
  const ParallaxLayers({
    required this.background,
    required this.foreground,
    this.depth = 8,
    super.key,
  });

  final Widget background;
  final Widget foreground;

  /// The FOREGROUND's travel. The ground behind moves a third as far
  /// and the other way — far things move less, which is the only
  /// reason any of this reads as distance.
  final double depth;

  static const _groundShare = 1 / 3;

  @override
  Widget build(BuildContext context) => Stack(
    alignment: AlignmentDirectional.center,
    children: [
      ParallaxTilt(
        depth: depth * _groundShare,
        invert: true,
        child: background,
      ),
      ParallaxTilt(depth: depth, child: foreground),
    ],
  );
}

/// How far a drawing should travel, by how much of the screen it fills.
///
/// Named rather than a number at each call site: the value that reads
/// as depth on a 300-point hero reads as a wobble on a 96-point chip,
/// and picking it per screen is how two screens end up disagreeing.
abstract final class ParallaxDepth {
  /// A page's own illustration, drawn edge to edge.
  ///
  /// Raised from 8 on 2026-09-16: eight points over an 18° lean was
  /// technically working and practically invisible on a phone in the
  /// hand. Fourteen over 12° is the same effect where you can see it.
  static const hero = 14.0;

  /// Something inside a card.
  static const inset = 7.0;
}
