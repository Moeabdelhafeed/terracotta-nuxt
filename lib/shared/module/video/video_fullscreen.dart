part of 'global_video.dart';

// ---------------------------------------------------------------------------
// Fullscreen page — supports drag-to-dismiss and pinch-to-zoom
// ---------------------------------------------------------------------------

class _FullscreenVideoPage extends StatefulWidget {
  const _FullscreenVideoPage({
    required this.chapters,
    required this.onCastPressed,
    required this.controller,
    required this.player,
    required this.style,
    required this.onExit,
    required this.ownership,
    this.title,
    this.onScreenshot,
    this.hasNext = false,
    this.hasPrevious = false,
    this.onNext,
    this.onPrevious,
    this.showPlaylistButtons = false,
  });

  final VideoController controller;
  final Player player;

  /// Marked on the fullscreen timeline as well — the same film.
  final List<VideoChapter> chapters;

  /// Passed straight through: a cast button is as useful here as
  /// inline, and more so.
  final VoidCallback? onCastPressed;

  /// Who disposes the player. If the inline widget is destroyed while
  /// this page is up, it hands the player over rather than disposing
  /// it — and this page disposes it instead.
  final VideoOwnership ownership;

  /// The SAME bag the inline player carries. Fullscreen forces its own
  /// fullscreen button on and changes nothing else — a control the
  /// reader had a moment ago should not vanish because the frame grew.
  final VideoStyle style;
  final String? title;
  final ValueChanged<Uint8List>? onScreenshot;
  final VoidCallback onExit;
  final bool hasNext, hasPrevious, showPlaylistButtons;
  final VoidCallback? onNext, onPrevious;

  @override
  State<_FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<_FullscreenVideoPage>
    with SingleTickerProviderStateMixin {
  // Drag-to-dismiss
  double _dragOffset = 0;

  /// Whether the screen is LOCKED to the film.
  ///
  /// A phone held in one hand through a long scene collects taps from
  /// a thumb, a lap and a pocket — each of which seeks, pauses, or
  /// exits. Locked, the whole control layer is gone and one button
  /// remains, which is the only thing that can undo it.
  bool _locked = false;

  /// True once the picture has actually been zoomed in.
  ///
  /// Pan is gated on it: at 1x a drag belongs to the player's own
  /// gestures — seek, volume, brightness — and a pan that swallowed
  /// them would trade three for one.
  bool _zoomed = false;

  /// Whether the picture fills the frame rather than fitting it.
  bool _filling = false;
  bool _popping = false;
  late AnimationController _snapBackCtrl;
  Animation<double>? _snapBackAnim;

  // Pinch-to-zoom
  final TransformationController _zoomCtrl = TransformationController();

  static const _dismissThreshold = 120.0;
  static const _dismissVelocity = 800.0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _snapBackCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _snapBackCtrl.dispose();
    _zoomCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // The app's list, not `DeviceOrientation.values` — that one
    // includes upside-down, which both native configs omit on a phone,
    // so leaving fullscreen used to widen what the whole app allowed.
    SystemChrome.setPreferredOrientations(kAppOrientations);
    widget.onExit();
    // Only if the inline widget is already gone. Otherwise it still
    // owns the player and will dispose it itself.
    if (widget.ownership.orphaned) {
      try {
        // Park it for the widget replacing the one that died, if there
        // is somewhere to park it. Disposing here is what made leaving
        // fullscreen restart the clip from zero.
        final handBack = widget.ownership.onOrphanedClose;
        if (handBack != null) {
          handBack();
        } else {
          widget.player.dispose();
        }
      } catch (_) {}
    }
    super.dispose();
  }

  void _onDismissDrag(double offset) {
    if (_popping) return;
    setState(() => _dragOffset = offset);
  }

  void _onDismissDragEnd(double velocityY) {
    if (_popping) return;
    final shouldDismiss =
        _dragOffset.abs() > _dismissThreshold ||
        velocityY.abs() > _dismissVelocity;

    if (shouldDismiss && _dragOffset > 0) {
      // Only dismiss on downward drag
      _popping = true;
      Navigator.of(context).pop();
    } else {
      // Snap back
      final startOffset = _dragOffset;
      _snapBackAnim = Tween<double>(begin: startOffset, end: 0).animate(
        CurvedAnimation(parent: _snapBackCtrl, curve: Curves.easeOutCubic),
      );
      _snapBackAnim!.addListener(() {
        if (mounted) setState(() => _dragOffset = _snapBackAnim!.value);
      });
      _snapBackCtrl.forward(from: 0);
    }
  }

  void _resetZoom() {
    _zoomCtrl.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_dragOffset.abs() / 300).clamp(0.0, 1.0);
    final scale = 1.0 - progress * 0.15;
    final opacity = 1.0 - progress * 0.6;
    final borderRadius = BorderRadius.circular(progress * 16);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: opacity),
      body: Transform.translate(
        offset: Offset(0, _dragOffset),
        child: Transform.scale(
          scale: scale,
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Video with pinch-to-zoom
                // Pinch to zoom, drag to pan — the map gesture, and
                // the one people try on a picture without being told.
                //
                // Panning is enabled only ONCE ZOOMED. At 1x the drag
                // belongs to the player: that is where seek, volume and
                // brightness live, and a pan that swallowed them would
                // trade three gestures for one nobody asked for.
                //
                // `_zoomed` is state rather than a read of the matrix
                // because the gestures below have to know, and they run
                // between frames.
                // The viewer only TRANSFORMS now; the gestures come
                // from the controls above it. It is opaque and covers
                // the picture, so nothing here ever saw a pinch —
                // which is why zoom did nothing at all.
                InteractiveViewer(
                  transformationController: _zoomCtrl,
                  minScale: 1,
                  maxScale: VideoDefaults.maxZoom,
                  panEnabled: false,
                  scaleEnabled: false,
                  // Keeps the picture reachable when zoomed near an
                  // edge; without it the film springs back and half a
                  // zoomed frame can never be looked at.
                  // Unbounded: the transform is driven by hand, and a
                  // boundary would fight the pan rather than stop it.
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  child: Video(
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
                    subtitleViewConfiguration: const SubtitleViewConfiguration(
                      visible: false,
                    ),
                    fill: Colors.black,
                    // Fill crops to the frame; fit letterboxes it.
                    fit: _filling ? BoxFit.cover : BoxFit.contain,
                  ),
                ),

                // Locked: the controls are not built at all, rather
                // than built and ignored. A gesture layer that is
                // present but inert still swallows the pointer, and
                // the one button that undoes this has to receive it.
                if (_locked)
                  _LockedOverlay(
                    style: widget.style,
                    onUnlock: () => setState(() => _locked = false),
                  )
                else
                  VideoControls(
                    chapters: widget.chapters,
                    onCastPressed: widget.onCastPressed,
                    player: widget.player,
                    // The exit button is not optional here: turning it off
                    // would leave a fullscreen page with no way back except
                    // a drag nobody was told about.
                    style: widget.style.copyWith(showFullscreenButton: true),
                    title: widget.title,
                    isFullscreen: true,
                    onScreenshot: widget.onScreenshot,
                    onFullscreenToggle: () {
                      _resetZoom();
                      Navigator.of(context).pop();
                    },
                    showPlaylistButtons: widget.showPlaylistButtons,
                    hasNext: widget.hasNext,
                    hasPrevious: widget.hasPrevious,
                    onNext: widget.onNext,
                    onPrevious: widget.onPrevious,
                    onDismissDrag: _onDismissDrag,
                    onDismissDragEnd: _onDismissDragEnd,
                    onLock: () => setState(() => _locked = true),
                    // The toggle lives in the controls; the FIT lives
                    // out here, on the `Video` the controls sit over.
                    onZoomChanged: (filling) =>
                        setState(() => _filling = filling),
                    zoomController: _zoomCtrl,
                    onZoomScaleChanged: (scale) {
                      final zoomed = scale > 1.01;
                      if (zoomed == _zoomed) return;
                      setState(() => _zoomed = zoomed);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What is left on screen when the film is locked.
///
/// One button, in a corner, and nothing else — no gestures, no bars,
/// no transport. That is the point: a locked player must not be able
/// to seek or exit by accident, and the only way to be sure of that is
/// for the layer that would have done it not to exist.
class _LockedOverlay extends StatelessWidget {
  const _LockedOverlay({required this.style, required this.onUnlock});

  final VideoStyle style;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final resolved = style.resolve(context);
    // The same inset as the bars, so it lines up with the controls it
    // replaced — and clear of the housing in landscape.
    final safe = MediaQuery.of(context).viewPadding;

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: EdgeInsets.only(left: VideoDefaults.barPaddingH + safe.left),
        child: VideoControlButton(
          icon: Icons.lock_outline_rounded,
          size: resolved.iconSize,
          color: resolved.iconColor,
          label: VideoStrings.unlockScreen,
          onTap: onUnlock,
          background: Colors.black.withValues(
            alpha: VideoDefaults.buttonScrimOpacity,
          ),
        ),
      ),
    );
  }
}
