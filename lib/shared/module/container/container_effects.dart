part of 'global_container.dart';

// The two effects the container wears but does not own: a focus ring
// driven by the ink's node, and a press scale. Both are stateful and
// the container is not, which is why they are widgets rather than
// branches in `build`.

/// Draws a ring round its child while the keyboard is on it.
///
/// The ring is painted as a FOREGROUND decoration, so it costs no
/// layout — a border that changed the box's size would shift the row
/// under the focus and move the thing the reader is aiming at.
///
/// The focus flag comes from the caller through [builder], because the
/// `InkWell` inside owns the focus node and nothing below that node can
/// hear it.
class _FocusRing extends StatefulWidget {
  const _FocusRing({
    required this.color,
    required this.width,
    required this.borderRadius,
    required this.builder,
  });

  final Color color;
  final double width;
  final BorderRadius borderRadius;
  final Widget Function(ValueChanged<bool> onFocusChange) builder;

  @override
  State<_FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<_FocusRing> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    // ALWAYS the same tree, focused or not — only the colour changes.
    //
    // Adding the `DecoratedBox` on focus and removing it again reparents
    // everything below, which rebuilds the `InkWell`, which builds a new
    // `FocusNode`, which loses the focus, which fires `onFocusChange`
    // again: the widget test did not fail, it HUNG.
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        border: Border.all(
          color: _focused ? widget.color : Colors.transparent,
          width: widget.width,
        ),
      ),
      child: widget.builder((value) {
        if (_focused == value) return;
        setState(() => _focused = value);
      }),
    );
  }
}

/// Sinks its child while a finger is on it.
///
/// A separate widget because `GlobalContainer` is stateless and a press
/// is state. It listens on a `Listener` rather than a second
/// `GestureDetector` so it cannot win the arena from the `InkWell`
/// underneath it — a card that scales but stops responding is worse
/// than one that does not scale.
class _PressScale extends StatefulWidget {
  const _PressScale({
    required this.scale,
    required this.duration,
    required this.child,
  });

  final double scale;
  final Duration duration;
  final Widget child;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;

  void _set(bool value) {
    if (_down == value) return;
    setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _set(true),
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: AnimatedScale(
      duration: widget.duration,
      curve: Curves.easeOut,
      scale: _down ? widget.scale : 1,
      child: widget.child,
    ),
  );
}
