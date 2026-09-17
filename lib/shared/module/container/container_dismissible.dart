part of 'global_container.dart';

// A row that swipes away. Its own file: the drag maths, the settle and
// the action background are a self-contained piece, and `start` / `end`
// there are READING positions rather than physical ones.

class GlobalDismissibleContainer extends StatefulWidget {
  const GlobalDismissibleContainer({
    super.key,
    required this.child,
    required this.onDismiss,
    this.startIcon = Icons.delete_rounded,
    this.startColor,
    this.startLabel,
    this.endIcon = Icons.delete_rounded,
    this.endColor,
    this.endLabel,
  });

  final Widget child;
  final VoidCallback onDismiss;
  final IconData startIcon;

  /// The swipe-from-start action's fill. Null takes the palette's ERROR
  /// — a swipe-away is a destructive action, and it was `Colors.red`,
  /// which is a colour this app does not own.
  final Color? startColor;
  final String? startLabel;
  final IconData endIcon;

  /// Null takes the palette's ERROR, for the same reason.
  final Color? endColor;
  final String? endLabel;

  @override
  State<GlobalDismissibleContainer> createState() =>
      _GlobalDismissibleContainerState();
}

class _GlobalDismissibleContainerState extends State<GlobalDismissibleContainer>
    with SingleTickerProviderStateMixin {
  double _dragExtent = 0;
  late AnimationController _snapCtrl;
  double _snapFrom = 0;
  double _snapTo = 0;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _snapCtrl =
        AnimationController(
            vsync: this,
            duration: ContainerDefaults.dismissDuration,
          )
          ..addListener(() {
            setState(() {
              _dragExtent =
                  _snapFrom +
                  (_snapTo - _snapFrom) *
                      Curves.easeOut.transform(_snapCtrl.value);
            });
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && _snapTo.abs() > 0.9) {
              _dismissed = true;
              widget.onDismiss();
            }
          });
  }

  @override
  void dispose() {
    _snapCtrl.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details, double width) {
    setState(() {
      _dragExtent = (_dragExtent + details.delta.dx / width).clamp(-1.0, 1.0);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final shouldDismiss =
        _dragExtent.abs() > ContainerDefaults.dismissThreshold ||
        velocity.abs() > ContainerDefaults.dismissVelocity;

    _snapFrom = _dragExtent;
    _snapTo = shouldDismiss ? (_dragExtent > 0 ? 1.0 : -1.0) : 0.0;
    _snapCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final radius = BorderRadius.circular(ContainerDefaults.radius);
    final offset = _dragExtent;

    // WHICH action, by reading position rather than by which way the
    // finger went.
    //
    // `offset > 0` is a drag to the physical RIGHT, and in Arabic the
    // right is where a row STARTS — so archive-on-the-start-side and
    // delete-on-the-end-side came out swapped, and the two actions
    // silently traded places for every RTL reader. `start` and `end`
    // are reading positions; the drag direction that reveals them
    // mirrors with the text.
    final ltr = Directionality.of(context) == TextDirection.ltr;
    final draggedTowardEnd = ltr ? offset < 0 : offset > 0;
    final showStart = !draggedTowardEnd;
    // A swipe-away is DESTRUCTIVE, so the palette's error is the right
    // meaning — it was `Colors.red`, which is the right meaning from a
    // colour the app does not own.
    final actionColor =
        (showStart ? widget.startColor : widget.endColor) ??
        context.statusColors.error;
    final onActionColor = context.textColors.onAccent;
    final actionIcon = showStart ? widget.startIcon : widget.endIcon;
    final actionLabel = showStart ? widget.startLabel : widget.endLabel;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final pixelOffset = offset * width;

        return GestureDetector(
          onHorizontalDragUpdate: (d) => _onDragUpdate(d, width),
          onHorizontalDragEnd: _onDragEnd,
          child: Stack(
            children: [
              // Background action
              if (offset != 0)
                Positioned.fill(
                  child: Container(
                    alignment: showStart
                        ? AlignmentDirectional.centerStart
                        : AlignmentDirectional.centerEnd,
                    padding: EdgeInsetsDirectional.only(
                      start: showStart ? ContainerDefaults.actionPad : 0,
                      end: showStart ? 0 : ContainerDefaults.actionPad,
                    ),
                    decoration: BoxDecoration(
                      color: actionColor,
                      borderRadius: radius,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!showStart && actionLabel != null) ...[
                          Text(
                            actionLabel,
                            style: TextStyle(
                              color: onActionColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: ContainerDefaults.headerGap),
                        ],
                        Icon(actionIcon, color: onActionColor),
                        if (showStart && actionLabel != null) ...[
                          const SizedBox(width: ContainerDefaults.headerGap),
                          Text(
                            actionLabel,
                            style: TextStyle(
                              color: onActionColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              // Child — no ClipRRect so shadow renders. The child's own Container
              // handles its border radius; dynamic flattening is cosmetic only.
              Transform.translate(
                offset: Offset(pixelOffset, 0),
                child: widget.child,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Bucket-aware width clamp ────────────────────────────────────
//
// Backing widget for [GlobalContainer.shell] / .prose / .form /
// .clamped. Centers [child] under a [maxWidth] that may vary by
// window-size bucket. Compact buckets typically pass through full-
// bleed via `double.infinity`.
