part of 'global_drawer.dart';

// ---------------------------------------------------------------------------
// Row sub-widgets
// ---------------------------------------------------------------------------
//
// `part of`, not a separate library, because these are private to the
// drawer and reach `_GlobalDrawerState`'s static badge/dot builders.
// Splitting them into an importable file would mean making all of that
// public — a wider API to buy a shorter file.

class _SwipeableItem extends StatefulWidget {
  const _SwipeableItem({
    required this.actions,
    required this.backgroundColor,
    required this.style,
    required this.child,
  });

  final ResolvedDrawerStyle style;
  final Widget child;
  final List<DrawerSwipeAction> actions;
  final Color backgroundColor;

  @override
  State<_SwipeableItem> createState() => _SwipeableItemState();
}

class _SwipeableItemState extends State<_SwipeableItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  double _dragExtent = 0;
  double _animStart = 0;
  double _animEnd = 0;

  double get _maxSlide =>
      widget.actions.length * DrawerDefaults.swipeActionWidth;
  double get _currentOffset {
    if (_ctrl.isAnimating) {
      return _animStart +
          (_animEnd - _animStart) * Curves.easeOut.transform(_ctrl.value);
    }
    return _dragExtent;
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: DrawerDefaults.animDuration,
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent = (_dragExtent + details.delta.dx).clamp(-_maxSlide, 0);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final open = _dragExtent.abs() > _maxSlide * DrawerDefaults.swipeThreshold;
    _animStart = _dragExtent;
    _animEnd = open ? -_maxSlide : 0.0;
    _ctrl.forward(from: 0).then((_) {
      _dragExtent = _animEnd;
    });
  }

  void _close() {
    _animStart = _dragExtent;
    _animEnd = 0;
    _ctrl.forward(from: 0).then((_) {
      _dragExtent = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final offset = _currentOffset;

    return ClipRect(
      child: Stack(
        children: [
          // Action buttons behind
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (final action in widget.actions)
                  Semantics(
                    container: true,
                    button: true,
                    // Without a label the action is a coloured square to
                    // a screen reader, and the glyph says nothing.
                    // `container` forces a node of its own — a bare
                    // label on a subtree that already has text merges
                    // instead of replacing it.
                    label: action.label,
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: () {
                        _close();
                        action.onTap?.call();
                      },
                      child: Container(
                        width: DrawerDefaults.swipeActionWidth,
                        alignment: Alignment.center,
                        color: action.color,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              action.icon,
                              color: widget.style.onAction(action.color),
                              size: DrawerDefaults.actionIconSize,
                            ),
                            if (action.label != null) ...[
                              const SizedBox(
                                height: DrawerDefaults.actionLabelGap,
                              ),
                              GlobalText(
                                action.label!,
                                textStyle: GlobalTextStyle(
                                  fontSize: DrawerDefaults.actionLabelSize,
                                  color: widget.style.onAction(action.color),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Foreground — opaque background so actions don't bleed through
          GestureDetector(
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            child: Transform.translate(
              offset: Offset(offset, 0),
              child: Container(
                color: widget.backgroundColor,
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Expandable item (with children)
// ═══════════════════════════════════════════════════════════════

class _ExpandableItem extends StatefulWidget {
  const _ExpandableItem({
    required this.item,
    required this.primary,
    required this.cs,
    required this.radius,
    required this.style,
    required this.depth,
    required this.onClose,
    required this.buildChild,
  });

  final DrawerItem item;
  final Color primary;
  final ColorScheme cs;
  final BorderRadius radius;
  final ResolvedDrawerStyle style;
  final int depth;
  final VoidCallback? onClose;
  final Widget Function(DrawerItem child, int childIndex) buildChild;

  @override
  State<_ExpandableItem> createState() => _ExpandableItemState();
}

class _ExpandableItemState extends State<_ExpandableItem>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _ctrl;
  late Animation<double> _expandAnim;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _expanded = widget.item.initiallyExpanded;
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.style.expandAnimationDuration,
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
      _expanded ? _ctrl.forward() : _ctrl.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.item.selected;
    final fg = selected ? widget.primary : widget.style.titleColor;
    final indent = widget.depth * DrawerDefaults.childIndent;
    final compact = widget.style.compact;
    final vPad = compact
        ? DrawerDefaults.compactVPad
        : DrawerDefaults.itemVPad / 2;
    final itemVPad = compact
        ? DrawerDefaults.compactItemVPad
        : DrawerDefaults.itemVPad * 3;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(
            start: indent,
            top: vPad,
            bottom: vPad,
          ),
          child: Material(
            color: selected
                ? widget.primary.withValues(
                    alpha: widget.style.selectedBgOpacity,
                  )
                : Colors.transparent,
            borderRadius: widget.radius,
            child: Semantics(
              button: true,
              expanded: _expanded,
              selected: selected,
              label: widget.item.semanticLabel ?? widget.item.spokenLabel(),
              excludeSemantics: true,
              child: InkWell(
                borderRadius: widget.radius,
                onTap: _toggle,
                child: Padding(
                  padding: widget.style.itemPadding.add(
                    EdgeInsets.symmetric(vertical: itemVPad),
                  ),
                  child: Row(
                    children: [
                      if (widget.item.avatar != null) ...[
                        SizedBox(
                          width: DrawerDefaults.avatarSize,
                          height: DrawerDefaults.avatarSize,
                          child: widget.item.avatar,
                        ),
                        const SizedBox(width: DrawerDefaults.avatarSpacing),
                      ] else if (widget.item.icon != null) ...[
                        Icon(
                          widget.item.icon,
                          size: widget.style.iconSize,
                          color: fg,
                        ),
                        const SizedBox(width: DrawerDefaults.iconSpacing),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GlobalText(
                              widget.item.title,
                              textStyle: GlobalTextStyle(
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: fg,
                              ),
                            ),
                            if (widget.item.subtitle != null)
                              GlobalText(
                                widget.item.subtitle!,
                                textStyle: GlobalTextStyle(
                                  fontSize: DrawerDefaults.subtitleFontSize,
                                  color: fg.withValues(
                                    alpha: DrawerDefaults.subtitleOpacity,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (widget.item.showDot)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            end: DrawerDefaults.trailingGap,
                          ),
                          child: _GlobalDrawerState.buildDot(
                            widget.item.dotColor ?? widget.primary,
                          ),
                        ),
                      if (widget.item.badge != null)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(
                            end: DrawerDefaults.trailingGap,
                          ),
                          child: _GlobalDrawerState.buildBadge(
                            widget.item.badge!,
                            widget.primary,
                            widget.style,
                          ),
                        ),
                      RotationTransition(
                        turns: _rotateAnim,
                        child: Icon(
                          Icons.expand_more_rounded,
                          size: DrawerDefaults.chevronSize,
                          color: fg.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: _expandAnim,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.item.children!.length; i++)
                widget.buildChild(widget.item.children![i], i),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Collapsible section title
// ═══════════════════════════════════════════════════════════════

class _CollapsibleSectionTitle extends StatefulWidget {
  const _CollapsibleSectionTitle({
    required this.title,
    this.itemCount,
    required this.initiallyExpanded,
    required this.duration,
    required this.cs,
    required this.style,
    required this.children,
  });

  final ResolvedDrawerStyle style;

  final String title;
  final int? itemCount;
  final bool initiallyExpanded;
  final Duration duration;
  final ColorScheme cs;
  final List<Widget> children;

  @override
  State<_CollapsibleSectionTitle> createState() =>
      _CollapsibleSectionTitleState();
}

class _CollapsibleSectionTitleState extends State<_CollapsibleSectionTitle>
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
      _expanded ? _ctrl.forward() : _ctrl.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final titleColor = widget.style.muted(DrawerDefaults.sectionTitleOpacity);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          button: true,
          expanded: _expanded,
          label: widget.itemCount == null
              ? widget.title
              : '${widget.title}, ${widget.itemCount}',
          excludeSemantics: true,
          child: InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(
              DrawerDefaults.sectionHeaderRadius,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                DrawerDefaults.itemHPad,
                DrawerDefaults.sectionTitlePad,
                DrawerDefaults.itemHPad,
                DrawerDefaults.itemVPad,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        GlobalText(
                          widget.title.toUpperCase(),
                          textStyle: GlobalTextStyle(
                            fontSize: DrawerDefaults.sectionTitleFontSize,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: titleColor,
                          ),
                        ),
                        if (widget.itemCount != null) ...[
                          const SizedBox(width: 6),
                          GlobalText(
                            '(${widget.itemCount})',
                            textStyle: GlobalTextStyle(
                              fontSize: DrawerDefaults.itemCountFontSize,
                              fontWeight: FontWeight.w600,
                              color: widget.style.muted(
                                DrawerDefaults.itemCountOpacity,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  RotationTransition(
                    turns: _rotateAnim,
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: DrawerDefaults.collapseChevronSize,
                      color: widget.style.muted(DrawerDefaults.chevronOpacity),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: _expandAnim,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.children,
          ),
        ),
      ],
    );
  }
}
