part of 'global_video.dart';

// ---------------------------------------------------------------------------
// PiP Overlay — draggable, resizable, snaps to edges, swipe to dismiss
// ---------------------------------------------------------------------------

class _PipOverlay extends StatefulWidget {
  const _PipOverlay({
    required this.player,
    required this.controller,
    required this.onClose,
    required this.onDismiss,
    required this.style,
    this.onFullscreen,
    this.sourceRect,
    this.onStateCreated,
  });
  final Player player;
  final VideoController controller;
  final VoidCallback onClose;
  final VoidCallback onDismiss;

  /// The same bag the inline player carries, so a mini player is not a
  /// second theme to keep in step.
  final VideoStyle style;
  final VoidCallback? onFullscreen;
  final Rect? sourceRect;
  final ValueChanged<_PipOverlayState>? onStateCreated;

  @override
  State<_PipOverlay> createState() => _PipOverlayState();
}

class _PipOverlayState extends State<_PipOverlay>
    with TickerProviderStateMixin {
  /// Resolved once per dependency change — the drag handlers read it
  /// between builds. Not `late`, for the same reason as the inline
  /// controls: a post-frame callback can reach it before
  /// `didChangeDependencies` has run.
  ResolvedVideoStyle _rs = ResolvedVideoStyle.fallback;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rs = widget.style.resolve(context);
  }

  static const _minW = 160.0;
  static const _maxW = 300.0;
  static const _ar = 16.0 / 9.0;
  static const _margin = 12.0;
  static const _dismissSpeed = 1200.0;
  static const _radius = 12.0;

  double _width = 200;
  Offset _offset = Offset.zero;
  late AnimationController _moveCtrl;
  late AnimationController _morphCtrl;
  Animation<Offset>? _moveAnim;
  bool _resizing = false;
  bool _resizePressed = false;
  double _morphProgress = 0.0;
  bool _ready = false;
  AnimationController? _outCtrl;

  @override
  void initState() {
    super.initState();
    widget.onStateCreated?.call(this);
    _moveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _morphCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final screen = MediaQuery.of(context).size;
      final pad = MediaQuery.of(context).padding;
      final pipH = _width / _ar;
      final targetOffset = Offset(
        screen.width - _width - _margin,
        screen.height - pipH - _margin - pad.bottom,
      );

      if (widget.sourceRect != null) {
        final src = widget.sourceRect!;
        _offset = Offset(src.left, src.top);
        _width = src.width;

        final offsetAnim = Tween<Offset>(begin: _offset, end: targetOffset)
            .animate(
              CurvedAnimation(parent: _morphCtrl, curve: Curves.easeInOutCubic),
            );
        final widthAnim = Tween<double>(begin: src.width, end: 200.0).animate(
          CurvedAnimation(parent: _morphCtrl, curve: Curves.easeInOutCubic),
        );

        _morphCtrl.addListener(() {
          if (mounted) {
            setState(() {
              _offset = offsetAnim.value;
              _width = widthAnim.value;
              _morphProgress = _morphCtrl.value;
            });
          }
        });
      } else {
        _offset = targetOffset;
        _width = 200;
        _morphCtrl.addListener(() {
          if (mounted) setState(() => _morphProgress = _morphCtrl.value);
        });
      }

      setState(() => _ready = true);
      _morphCtrl.forward();
    });
  }

  void animateOut(Rect? targetRect, VoidCallback onDone) {
    if (targetRect != null) {
      final startOffset = _offset;
      final startWidth = _width;
      _outCtrl?.dispose();
      _outCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 350),
      );
      final offsetAnim =
          Tween<Offset>(
            begin: startOffset,
            end: Offset(targetRect.left, targetRect.top),
          ).animate(
            CurvedAnimation(parent: _outCtrl!, curve: Curves.easeInOutCubic),
          );
      final widthAnim = Tween<double>(begin: startWidth, end: targetRect.width)
          .animate(
            CurvedAnimation(parent: _outCtrl!, curve: Curves.easeInOutCubic),
          );
      final opacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _outCtrl!, curve: const Interval(0.6, 1.0)),
      );

      _outCtrl!.addListener(() {
        if (mounted) {
          setState(() {
            _offset = offsetAnim.value;
            _width = widthAnim.value;
            _morphProgress = opacityAnim.value;
          });
        }
      });
      _outCtrl!.addStatusListener((status) {
        if (status == AnimationStatus.completed) onDone();
      });
      _outCtrl!.forward();
    } else {
      _morphCtrl.reverse().then((_) => onDone());
    }
  }

  @override
  void dispose() {
    _outCtrl?.dispose();
    _moveCtrl.dispose();
    _morphCtrl.dispose();
    super.dispose();
  }

  void _animateMoveTo(
    Offset target, {
    Curve curve = Curves.easeOutCubic,
    int ms = 350,
  }) {
    _moveCtrl.duration = Duration(milliseconds: ms);
    _moveAnim = Tween<Offset>(
      begin: _offset,
      end: target,
    ).animate(CurvedAnimation(parent: _moveCtrl, curve: curve));
    _moveAnim!.addListener(() {
      if (mounted) setState(() => _offset = _moveAnim!.value);
    });
    _moveCtrl.forward(from: 0);
  }

  void _snapToNearestEdge() {
    final screen = MediaQuery.of(context).size;
    final pad = MediaQuery.of(context).padding;
    final h = _width / _ar;
    final centerX = _offset.dx + _width / 2;

    final targetX = centerX < screen.width / 2
        ? _margin
        : screen.width - _width - _margin;
    final targetY = _offset.dy.clamp(
      _margin + pad.top,
      screen.height - h - _margin - pad.bottom,
    );

    _animateMoveTo(Offset(targetX, targetY));
  }

  void _flingAndSnap(Offset velocity) {
    final screen = MediaQuery.of(context).size;
    final pad = MediaQuery.of(context).padding;
    final h = _width / _ar;

    const friction = 0.15;
    final projectedX = (_offset.dx + velocity.dx * friction).clamp(
      -_width * 0.3,
      screen.width - _width * 0.7,
    );
    final projectedY = (_offset.dy + velocity.dy * friction).clamp(
      pad.top + _margin,
      screen.height - h - _margin - pad.bottom,
    );

    final centerX = projectedX + _width / 2;
    final snapX = centerX < screen.width / 2
        ? _margin
        : screen.width - _width - _margin;
    final snapY = projectedY.clamp(
      pad.top + _margin,
      screen.height - h - _margin - pad.bottom,
    );

    final dist = (Offset(snapX, snapY) - _offset).distance;
    final ms = (dist * 0.6).clamp(200, 600).toInt();

    _animateMoveTo(Offset(snapX, snapY), curve: Curves.easeOutCubic, ms: ms);
  }

  void _dismissWithVelocity(Offset velocity) {
    final screen = MediaQuery.of(context).size;
    final target = Offset(
      _offset.dx + velocity.dx.sign * screen.width,
      _offset.dy + velocity.dy.sign * screen.height,
    );
    _animateMoveTo(target, curve: Curves.easeIn, ms: 250);
    Future.delayed(const Duration(milliseconds: 250), widget.onDismiss);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();

    final h = _width / _ar;

    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: Opacity(
        opacity: _morphProgress.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.8 + 0.2 * _morphProgress,
          alignment: Alignment.bottomRight,
          child: GestureDetector(
            onPanUpdate: (d) {
              if (_resizing) return;
              setState(() => _offset += d.delta);
            },
            onPanEnd: (d) {
              if (_resizing) {
                _resizing = false;
                _snapToNearestEdge();
                return;
              }

              final vel = d.velocity.pixelsPerSecond;
              final screen = MediaQuery.of(context).size;
              final speed = vel.distance;

              if (speed > _dismissSpeed) {
                final futureX = _offset.dx + vel.dx * 0.15;
                final futureY = _offset.dy + vel.dy * 0.15;
                final wouldExit =
                    futureX < -_width * 0.5 ||
                    futureX > screen.width - _width * 0.5 ||
                    futureY < -h * 0.5 ||
                    futureY > screen.height - h * 0.5;
                if (wouldExit) {
                  _dismissWithVelocity(vel);
                  return;
                }
              }

              if (speed > 300) {
                _flingAndSnap(vel);
              } else {
                _snapToNearestEdge();
              }
            },
            onTap: widget.onFullscreen,
            child: Material(
              elevation: 16,
              borderRadius: BorderRadius.circular(_radius),
              clipBehavior: Clip.antiAlias,
              shadowColor: _rs.scrimColor,
              child: SizedBox(
                width: _width,
                height: h,
                child: Stack(
                  children: [
                    Video(
                      controller: widget.controller,
                      controls: NoVideoControls,
                      // media_kit draws its OWN subtitles on top of the
                      // texture, so the film carried two copies of every line:
                      // theirs mid-frame in a fixed style, ours in the bar. And
                      // theirs painted an empty plate between cues.
                      //
                      // Ours stays because it is the themeable one — it reads
                      // `subtitleStyle`, sits with the bar, moves when the bar
                      // appears and disappears when there is nothing to say.
                      subtitleViewConfiguration:
                          const SubtitleViewConfiguration(
                            visible: false,
                          ),
                      fill: Colors.black,
                    ),

                    Positioned(
                      top: 4,
                      right: 4,
                      child: _pipBtn(
                        Icons.close,
                        CommonStrings.close,
                        widget.onClose,
                      ),
                    ),

                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: StreamBuilder<bool>(
                        stream: widget.player.stream.playing,
                        initialData: true,
                        builder: (_, snap) => _pipBtn(
                          snap.data == true ? Icons.pause : Icons.play_arrow,
                          snap.data == true
                              ? VideoStrings.pause
                              : VideoStrings.play,
                          () {
                            try {
                              widget.player.playOrPause();
                            } catch (_) {}
                          },
                        ),
                      ),
                    ),

                    Positioned(
                      top: 0,
                      left: 0,
                      child: GestureDetector(
                        onPanStart: (_) => setState(() {
                          _resizing = true;
                          _resizePressed = true;
                        }),
                        onPanEnd: (_) => setState(() => _resizePressed = false),
                        onPanCancel: () =>
                            setState(() => _resizePressed = false),
                        onPanUpdate: (d) {
                          setState(() {
                            _width = (_width - d.delta.dx).clamp(_minW, _maxW);
                            _offset = Offset(
                              _offset.dx + d.delta.dx,
                              _offset.dy + d.delta.dy,
                            );
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: _resizePressed
                                    ? _rs.iconColor
                                    : _rs.iconColor.withValues(alpha: 0.6),
                                width: _resizePressed ? 3.0 : 2.0,
                              ),
                              left: BorderSide(
                                color: _resizePressed
                                    ? _rs.iconColor
                                    : _rs.iconColor.withValues(alpha: 0.6),
                                width: _resizePressed ? 3.0 : 2.0,
                              ),
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(_radius),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pipBtn(IconData icon, String label, VoidCallback onTap) =>
      _PipButton(icon: icon, label: label, onTap: onTap, style: _rs);
}

/// A glyph on the mini player.
///
/// [label] is required for the same reason it is on the inline
/// controls: a bare icon over film has no text near it to fall back on.
class _PipButton extends StatelessWidget {
  const _PipButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.style,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ResolvedVideoStyle style;

  @override
  Widget build(BuildContext context) => GlobalIcon.circle(
    icon,
    size: 16,
    containerSize: 24,
    color: style.iconColor,
    backgroundColor: style.scrimColor,
    onTap: onTap,
    semanticLabel: label,
  );
}
