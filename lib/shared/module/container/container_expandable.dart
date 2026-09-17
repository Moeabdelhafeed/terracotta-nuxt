part of 'global_container.dart';

// A panel that opens. Split out of `global_container.dart`, which had
// grown to 2122 lines against this repo's own "prefer splitting over
// 400" rule — six widgets and four painters in one file.

/// A container that can expand/collapse its content.
class GlobalExpandableContainer extends StatefulWidget {
  const GlobalExpandableContainer({
    super.key,
    required this.header,
    required this.child,
    this.style = const ContainerStyle(),
    this.initiallyExpanded = false,
    this.duration = ContainerDefaults.expandDuration,
    this.onToggle,
    this.respectReducedMotion = true,
  });

  /// Whether "reduce motion" makes the panel ARRIVE instead of sliding.
  final bool respectReducedMotion;

  /// Header widget — always visible. Tapping toggles expand.
  final Widget header;

  /// Content revealed when expanded.
  final Widget child;

  /// Styling.
  final ContainerStyle style;

  /// Whether to start expanded.
  final bool initiallyExpanded;

  /// Animation duration.
  final Duration duration;

  /// Called when expand/collapse state changes.
  final ValueChanged<bool>? onToggle;

  @override
  State<GlobalExpandableContainer> createState() =>
      _GlobalExpandableContainerState();
}

class _GlobalExpandableContainerState extends State<GlobalExpandableContainer>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _ctrl;
  late Animation<double> _expandAnim;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: _expanded ? 1.0 : 0.0,
    );
    _expandAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _rotateAnim = Tween<double>(begin: 0, end: 0.5).animate(_expandAnim);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      // Reduce motion ARRIVES rather than travelling. Setting the value
      // is not the same as a zero-length `forward()`, which still runs
      // a frame for every step of a journey with no distance in it.
      if (widget.respectReducedMotion &&
          MediaQuery.disableAnimationsOf(context)) {
        _ctrl.value = _expanded ? 1 : 0;
      } else {
        _expanded ? _ctrl.forward() : _ctrl.reverse();
      }
    });
    widget.onToggle?.call(_expanded);
  }

  @override
  Widget build(BuildContext context) {
    return GlobalContainer(
      style: widget.style,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with chevron
          // A header that opens a panel is a BUTTON, and it has to say
          // which way it currently is — a chevron that rotates says
          // nothing to a reader who cannot see it.
          Semantics(
            button: true,
            expanded: _expanded,
            onTap: _toggle,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggle,
              child: Row(
                children: [
                  Expanded(child: widget.header),
                  RotationTransition(
                    turns: _rotateAnim,
                    // Decoration: the `expanded` flag above already
                    // carries what this glyph is drawing.
                    child: ExcludeSemantics(
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: ContainerDefaults.expandChevronSize,
                        color: context.textColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Collapsible content
          SizeTransition(
            sizeFactor: _expandAnim,
            child: Padding(
              padding: const EdgeInsets.only(top: ContainerDefaults.headerGap),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Inner shadow painter
// ═══════════════════════════════════════════════════════════════
