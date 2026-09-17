import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'reveal_shapes.dart';

export 'reveal_shapes.dart';

/// Telegram-style reveal theme switcher. Snapshots the current frame,
/// runs [action] (which mutates theme/role/saturation/locale/etc.), then
/// hands the snapshot to a [RevealStrategy] which animates it out —
/// uncovering the freshly themed tree underneath.
///
/// Wrap the part of the tree you want to animate (typically the
/// `MaterialApp.router` `builder` child) and call:
///
///     RevealThemeSwitcher.reveal(
///       context,
///       origin: tapGlobalPosition,
///       strategy: RevealStrategy.diamond,        // optional override
///       direction: RevealDirection.collapse,     // optional override
///       action: () => prefs.setThemeMode(ThemeMode.dark),
///     );
///
/// Defaults come from the widget constructor; per-call overrides take
/// precedence.
class RevealThemeSwitcher extends StatefulWidget {
  const RevealThemeSwitcher({
    super.key,
    required this.child,
    this.defaultStrategy = RevealStrategy.circle,
    this.defaultDirection = RevealDirection.expand,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeInOutCubic,
  });

  final Widget child;
  final RevealStrategy defaultStrategy;
  final RevealDirection defaultDirection;
  final Duration duration;
  final Curve curve;

  static _RevealThemeSwitcherState? _of(BuildContext context) {
    return context.getInheritedWidgetOfExactType<_RevealScope>()?.state;
  }

  /// Trigger a reveal. [action] runs after the snapshot is captured;
  /// mutate prefs / theme / etc. inside it.
  static Future<void> reveal(
    BuildContext context, {
    required Offset origin,
    required VoidCallback action,
    RevealStrategy? strategy,
    RevealDirection? direction,
    Duration? duration,
    Curve? curve,
  }) async {
    final state = _of(context);
    if (state == null) {
      action();
      return;
    }
    await state._reveal(
      origin: origin,
      action: action,
      strategy: strategy,
      direction: direction,
      duration: duration,
      curve: curve,
    );
  }

  /// True if a reveal is currently animating.
  static bool isAnimating(BuildContext context) =>
      _of(context)?._isAnimating ?? false;

  @override
  State<RevealThemeSwitcher> createState() => _RevealThemeSwitcherState();
}

class _RevealThemeSwitcherState extends State<RevealThemeSwitcher>
    with SingleTickerProviderStateMixin {
  final GlobalKey _boundaryKey = GlobalKey();
  late final AnimationController _controller;
  late CurvedAnimation _curved;

  ui.Image? _snapshot;
  Offset _origin = Offset.zero;
  late RevealStrategy _activeStrategy;
  late RevealDirection _activeDirection;

  bool get _isAnimating => _controller.isAnimating || _snapshot != null;

  @override
  void initState() {
    super.initState();
    _activeStrategy = widget.defaultStrategy;
    _activeDirection = _activeStrategy.resolveDirection(
      widget.defaultDirection,
    );
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _curved = CurvedAnimation(parent: _controller, curve: widget.curve);
    _controller.addStatusListener(_onAnimationStatus);
  }

  @override
  void didUpdateWidget(covariant RevealThemeSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.curve != widget.curve) {
      _curved.dispose();
      _curved = CurvedAnimation(parent: _controller, curve: widget.curve);
    }
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      final image = _snapshot;
      setState(() => _snapshot = null);
      image?.dispose();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatus);
    _curved.dispose();
    _controller.dispose();
    _snapshot?.dispose();
    super.dispose();
  }

  Future<void> _reveal({
    required Offset origin,
    required VoidCallback action,
    RevealStrategy? strategy,
    RevealDirection? direction,
    Duration? duration,
    Curve? curve,
  }) async {
    if (_isAnimating) return;

    final boundary =
        _boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) {
      action();
      return;
    }

    final ratio = MediaQuery.of(context).devicePixelRatio;
    ui.Image image;
    try {
      image = await boundary.toImage(pixelRatio: ratio);
    } catch (_) {
      action();
      return;
    }

    if (!mounted) {
      image.dispose();
      return;
    }

    final nextStrategy = strategy ?? widget.defaultStrategy;
    final nextDirection = nextStrategy.resolveDirection(
      direction ?? widget.defaultDirection,
    );

    setState(() {
      _snapshot = image;
      _origin = origin;
      _activeStrategy = nextStrategy;
      _activeDirection = nextDirection;
    });

    if (duration != null) {
      _controller.duration = duration;
    } else if (_controller.duration != widget.duration) {
      _controller.duration = widget.duration;
    }

    if (curve != null) {
      _curved.dispose();
      _curved = CurvedAnimation(parent: _controller, curve: curve);
    } else if (_curved.curve != widget.curve) {
      _curved.dispose();
      _curved = CurvedAnimation(parent: _controller, curve: widget.curve);
    }

    // One frame so the snapshot paints before the theme swap.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    action();
    unawaited(_controller.forward(from: 0));
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return _RevealScope(
      state: this,
      child: Stack(
        children: [
          RepaintBoundary(key: _boundaryKey, child: widget.child),
          if (snapshot != null)
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return _activeStrategy.buildOverlay(
                    snapshot: snapshot,
                    progress: _curved,
                    origin: _origin,
                    size: constraints.biggest,
                    direction: _activeDirection,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _RevealScope extends InheritedWidget {
  const _RevealScope({required this.state, required super.child});

  final _RevealThemeSwitcherState state;

  @override
  bool updateShouldNotify(_RevealScope old) => false;
}

/// Helper to grab the global tap position from a render object's center.
/// Useful when you only have a widget context, not a tap event.
Offset originFromContext(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return Offset.zero;
  return box.localToGlobal(box.size.center(Offset.zero));
}
