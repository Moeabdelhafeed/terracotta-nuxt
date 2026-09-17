part of 'global_sheet.dart';

// ---------------------------------------------------------------------------
// Sheet container — handles background, border, gradient border
// ---------------------------------------------------------------------------

class _SheetContainer extends StatelessWidget {
  const _SheetContainer({
    this.height,
    required this.borderRadius,
    required this.rs,
    required this.isTop,
    this.hideBottomBorder = false,
    required this.child,
  });
  final double? height;
  final BorderRadius borderRadius;
  final ResolvedSheetStyle rs;
  final bool isTop;
  final bool hideBottomBorder;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shadow = rs.resolveShadow(isTop: isTop);
    final bottomInset = hideBottomBorder
        ? rs.borderWidth + _kBorderHideExtra
        : 0.0;

    // MaterialType.transparency clips InkWell splashes to the sheet's
    // bounds without painting — INSIDE the opaque container, otherwise
    // ink lands on the modal route's transparent Material BEHIND the
    // background and taps show no ripple.
    final inkHost = Material(type: MaterialType.transparency, child: child);

    if (rs.borderGradient != null) {
      Widget container = Container(
        height: height != null ? height! + bottomInset : null,
        decoration: BoxDecoration(
          gradient: rs.borderGradient,
          borderRadius: borderRadius,
          boxShadow: shadow,
        ),
        child: Container(
          margin: EdgeInsets.fromLTRB(
            rs.borderWidth,
            rs.borderWidth,
            rs.borderWidth,
            hideBottomBorder ? 0 : rs.borderWidth,
          ),
          decoration: BoxDecoration(
            color: rs.backgroundGradient == null ? rs.backgroundColor : null,
            gradient: rs.backgroundGradient,
            borderRadius: borderRadius.subtract(
              BorderRadius.all(Radius.circular(rs.borderWidth)),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: inkHost,
        ),
      );
      if (hideBottomBorder) container = ClipRect(child: container);
      return container;
    }

    final effectiveBorder = hideBottomBorder && rs.border != null
        ? Border(
            top: rs.border!.top,
            left: rs.border!.left,
            right: rs.border!.right,
          )
        : rs.border;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: rs.backgroundGradient == null ? rs.backgroundColor : null,
        gradient: rs.backgroundGradient,
        borderRadius: borderRadius,
        border: effectiveBorder,
        boxShadow: shadow,
      ),
      child: ClipRRect(borderRadius: borderRadius, child: inkHost),
    );
  }
}

// ---------------------------------------------------------------------------
// Handle
// ---------------------------------------------------------------------------

class _Handle extends StatelessWidget {
  const _Handle({required this.rs});
  final ResolvedSheetStyle rs;

  @override
  Widget build(BuildContext context) {
    // Decorative — the drag affordance is announced by the sheet route.
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          width: rs.handleWidth,
          height: rs.handleHeight,
          decoration: BoxDecoration(
            color: rs.handleColor,
            borderRadius: BorderRadius.circular(rs.handleHeight / 2),
          ),
        ),
      ),
    );
  }
}

/// Draggable handle area with padding for resize gesture target.
class _HandleArea extends StatelessWidget {
  const _HandleArea({required this.rs});
  final ResolvedSheetStyle rs;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: rs.handleWidth,
            height: rs.handleHeight,
            decoration: BoxDecoration(
              color: rs.handleColor,
              borderRadius: BorderRadius.circular(rs.handleHeight / 2),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({
    this.title,
    this.subtitle,
    this.icon,
    required this.showClose,
    required this.hasHandle,
    required this.onClose,
    this.actions,
    this.enableHaptic = true,
  });
  final String? title, subtitle;
  final IconData? icon;
  final bool showClose, hasHandle;
  final VoidCallback onClose;
  final List<Widget>? actions;
  final bool enableHaptic;

  @override
  Widget build(BuildContext context) {
    final primary = context.primaryColors.primary;
    final text = context.textColors;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        _kPad,
        hasHandle ? 12 : _kPad,
        _kPad,
        0,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            GlobalIcon(
              icon: icon!,
              style: IconStyle(
                size: 20,
                color: primary,
                backgroundColor: primary,
                backgroundOpacity: 0.1,
                containerShape: IconContainerShape.rounded,
                borderRadius: BorderRadius.circular(10),
                padding: const EdgeInsets.all(8),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  GlobalText(
                    title!,
                    preset: TextPreset.titleLarge,
                    textStyle: const GlobalTextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: GlobalText(
                      subtitle!,
                      textStyle: GlobalTextStyle(color: text.secondary),
                    ),
                  ),
              ],
            ),
          ),
          if (actions != null)
            ...actions!.map(
              (a) => Padding(
                padding: const EdgeInsetsDirectional.only(start: 4),
                child: a,
              ),
            ),
          if (showClose) ...[
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: CommonStrings.close,
              // InkWell (not GestureDetector) — focusable, activates on
              // Enter/Space, and ripples on the sheet's ink host.
              child: Material(
                color: text.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () {
                    if (enableHaptic) HapticFeedback.lightImpact();
                    onClose();
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.close_rounded,
                      size: 22,
                      color: context.iconColors.secondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Actions — uses IntrinsicWidth to prevent infinite width crash
// ---------------------------------------------------------------------------

class _Actions extends StatelessWidget {
  const _Actions({required this.actions});
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kPad, 12, _kPad, _kPad),
      child: IntrinsicWidth(
        child: Row(
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: actions[i]),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Multi-page content
// ---------------------------------------------------------------------------

class _MultiPageContent extends StatefulWidget {
  const _MultiPageContent({
    required this.pages,
    this.pageTitles,
    this.title,
    this.icon,
    required this.showClose,
    required this.showIndicator,
    required this.rs,
    required this.onClose,
  });

  final List<Widget> pages;
  final List<String>? pageTitles;
  final String? title;
  final IconData? icon;
  final bool showClose, showIndicator;
  final ResolvedSheetStyle rs;
  final VoidCallback onClose;

  @override
  State<_MultiPageContent> createState() => _MultiPageContentState();
}

class _MultiPageContentState extends State<_MultiPageContent> {
  late PageController _pageCtrl;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  String get _title {
    if (widget.pageTitles != null && _currentPage < widget.pageTitles!.length) {
      return widget.pageTitles![_currentPage];
    }
    return widget.title ?? '';
  }

  void _goTo(int page) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _pageCtrl.jumpToPage(page);
      return;
    }
    _pageCtrl.animateToPage(
      page,
      duration: AppDurations.normal,
      curve: widget.rs.animationCurve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = context.primaryColors.primary;
    final outline = context.backgroundColors.outline;
    final isLast = _currentPage == widget.pages.length - 1;
    final isFirst = _currentPage == 0;

    return Column(
      children: [
        if (widget.rs.showHandle) _Handle(rs: widget.rs),
        _Header(
          title: _title,
          icon: widget.icon,
          showClose: widget.showClose,
          hasHandle: widget.rs.showHandle,
          enableHaptic: widget.rs.enableHaptic,
          onClose: widget.onClose,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: PageView(
            controller: _pageCtrl,
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: widget.pages
                .map(
                  (p) => SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: _kPad),
                    child: p,
                  ),
                )
                .toList(),
          ),
        ),
        if (widget.showIndicator)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(_kPad, 8, _kPad, 0),
              child: Row(
                children: [
                  // shrinkWidth — a Row hands out unbounded width; the
                  // buttons' default fill-width would force infinity.
                  if (!isFirst)
                    GlobalTextButton(
                      text: CommonStrings.back,
                      shrinkWidth: true,
                      onPressed: () => _goTo(_currentPage - 1),
                    )
                  else
                    const SizedBox(width: 72),
                  const Spacer(),
                  ExcludeSemantics(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < widget.pages.length; i++)
                          Container(
                            width: i == _currentPage ? 20 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: i == _currentPage
                                  ? primary
                                  : outline.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GlobalTextButton(
                    text: isLast ? CommonStrings.done : CommonStrings.next,
                    shrinkWidth: true,
                    onPressed: isLast
                        ? widget.onClose
                        : () => _goTo(_currentPage + 1),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Single-route surface backing [GlobalBottomSheet.show] with
/// `responsive: true`. Hosts the user [content] in a stable
/// [Element] location, then morphs its own alignment + size +
/// handle orientation between bottom-sheet and side-sheet layouts
/// in reaction to `WindowSizeClass` changes.
///
/// Because the route never changes, any state inside [content]
/// (forms, text controllers, scroll positions) survives a bucket
/// flip — Flutter just rebuilds the surrounding chrome around the
/// same content subtree.
///
/// Drag-to-dismiss is layout-aware: vertical drag in the compact
/// layout, horizontal drag in the side layout. Past
/// [_kDismissThreshold] / [_kDismissVelocity] the route is popped;
/// otherwise the sheet snaps back via [_dragSnapCtrl].
class _ResponsiveSurface extends StatefulWidget {
  const _ResponsiveSurface({
    required this.entryAnimation,
    required this.content,
    required this.rs,
    required this.sideWidth,
    this.title,
    this.subtitle,
    this.icon,
    this.showCloseButton = true,
    this.enableDrag = true,
    this.actions,
    this.height,
    this.minHeight,
    this.maxHeight,
    this.sizing,
  });

  final Animation<double> entryAnimation;
  final Widget content;
  final ResolvedSheetStyle rs;
  final ResponsiveValue<double> sideWidth;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final bool showCloseButton;
  final bool enableDrag;
  final List<Widget>? actions;
  final double? height;
  final double? minHeight;
  final double? maxHeight;
  final SheetSizing? sizing;

  @override
  State<_ResponsiveSurface> createState() => _ResponsiveSurfaceState();
}

class _ResponsiveSurfaceState extends State<_ResponsiveSurface>
    with TickerProviderStateMixin {
  // The "active" layout is the one currently driving the rendered
  // chrome. It lags behind the real bucket during a flip: the sheet
  // slides out in the active layout's direction, then the active
  // layout swaps once the sheet is off-screen, then the sheet
  // slides back in using the new layout's direction.
  bool? _activeIsCompact;
  bool? _pendingIsCompact;

  late final AnimationController _flipCtrl;
  late final CurvedAnimation _curvedFlip;
  late final CurvedAnimation _curvedEntry;

  late final AnimationController _dragSnapCtrl;
  Offset _dragOffset = Offset.zero;
  Offset _snapFrom = Offset.zero;

  // Stable key wrapping the user-supplied content. The compact and
  // side layouts nest content under different ancestor chains —
  // `Column→Flexible→ScrollView→content` vs
  // `Row→Expanded→Column→Flexible→ScrollView→content`. Without a
  // GlobalKey, Flutter would tear down the content's Element on
  // every layout swap and any [StatefulWidget] state inside
  // (TextEditingController, form fields, scroll position) would be
  // lost. The GlobalKey forces Flutter to reparent the existing
  // Element to its new slot instead.
  final GlobalKey _contentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // `_flipCtrl = 1` means the sheet is fully visible w.r.t. the
    // flip dimension. We only reverse it when a bucket flip starts.
    _flipCtrl = AnimationController(
      vsync: this,
      duration: AppDurations.quick,
      value: 1,
    )..addStatusListener(_onFlipStatus);
    _curvedFlip = CurvedAnimation(
      parent: _flipCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _curvedEntry = CurvedAnimation(
      parent: widget.entryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _dragSnapCtrl =
        AnimationController(
          vsync: this,
          duration: AppDurations.quick,
        )..addListener(() {
          setState(() {
            _dragOffset = _snapFrom * (1 - _dragSnapCtrl.value);
          });
        });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion collapses the flip + snap tweens; drag itself
    // stays live (direct manipulation) — the sheet just snaps.
    final reduce = MediaQuery.disableAnimationsOf(context);
    _flipCtrl.duration = reduce ? Duration.zero : AppDurations.quick;
    _dragSnapCtrl.duration = reduce ? Duration.zero : AppDurations.quick;
  }

  @override
  void dispose() {
    _curvedEntry.dispose();
    _curvedFlip.dispose();
    _flipCtrl.dispose();
    _dragSnapCtrl.dispose();
    super.dispose();
  }

  // Slide-out (flipCtrl 1→0) finished — swap the active layout
  // while the sheet is off-screen, then slide it back in.
  void _onFlipStatus(AnimationStatus s) {
    if (s == AnimationStatus.dismissed && _pendingIsCompact != null) {
      setState(() {
        _activeIsCompact = _pendingIsCompact;
        _pendingIsCompact = null;
        // Stale drag offset shouldn't carry into the new layout —
        // the axis it lived on may not even apply anymore.
        _dragOffset = Offset.zero;
      });
      _flipCtrl.forward();
    }
  }

  void _dismiss() {
    if (widget.rs.enableHaptic) HapticFeedback.mediumImpact();
    Navigator.of(context).maybePop();
  }

  void _onVerticalDragUpdate(DragUpdateDetails d) {
    setState(() {
      _dragOffset = Offset(
        0,
        (_dragOffset.dy + d.delta.dy).clamp(0, double.infinity),
      );
    });
  }

  void _onVerticalDragEnd(DragEndDetails d) {
    final v = d.velocity.pixelsPerSecond.dy;
    if (_dragOffset.dy > _kDismissThreshold || v > _kDismissVelocity) {
      _dismiss();
      return;
    }
    _snapBack();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails d, double dirSign) {
    setState(() {
      _dragOffset = Offset(
        (_dragOffset.dx + d.delta.dx * dirSign).clamp(0, double.infinity),
        0,
      );
    });
  }

  void _onHorizontalDragEnd(DragEndDetails d, double dirSign) {
    final v = d.velocity.pixelsPerSecond.dx * dirSign;
    if (_dragOffset.dx > _kDismissThreshold || v > _kDismissVelocity) {
      _dismiss();
      return;
    }
    _snapBack();
  }

  void _snapBack() {
    _snapFrom = _dragOffset;
    _dragSnapCtrl
      ..value = 0
      ..animateTo(1, curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = context.windowSize.isCompact;
    _activeIsCompact ??= isCompact;

    // Bucket flipped while the sheet is open — kick off the
    // slide-out phase if one isn't already in flight.
    if (_pendingIsCompact == null &&
        _activeIsCompact != isCompact &&
        _flipCtrl.status != AnimationStatus.reverse) {
      _pendingIsCompact = isCompact;
      _flipCtrl.reverse();
    }

    final active = _activeIsCompact!;
    final rs = widget.rs;
    final radii = context.radii;
    final floating = rs.floating;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final dirSign = isRtl ? -1.0 : 1.0;
    final mq = MediaQuery.of(context);
    final sideW = widget.sideWidth.resolve(context);

    // Border radius for the active layout.
    //
    // Through `SheetGeometry`, which is what the plain bottom-sheet
    // path has always used — this surface computed its own corner from
    // `radii.lg` and so was the ONE sheet in the app that ignored
    // `useDeviceRadius`. On a rounded phone every other sheet curved
    // with the hardware and a responsive one did not, in the same
    // session, on the same device.
    final BorderRadiusGeometry borderRadius;
    if (!active && !floating) {
      // An ATTACHED side sheet runs along one edge of the screen, so
      // only its leading edge is rounded — the far side is the screen's
      // own corner and the device already draws that.
      final edge = rs.useDeviceRadius && DeviceRadius.hasRoundedCorners
          ? DeviceRadius.average
          : radii.lg;
      borderRadius =
          rs.borderRadius ??
          BorderRadiusDirectional.only(
            topStart: Radius.circular(edge),
            bottomStart: Radius.circular(edge),
          );
    } else {
      // Everything else — a bottom sheet, and a FLOATING side sheet —
      // is a detached card, and a detached card takes the hardware's
      // corner like every other sheet in the app.
      borderRadius = SheetGeometry.outerRadius(
        rs,
        floating: floating,
        isTop: false,
      );
    }

    // Header (shared across both layouts).
    final header = (widget.title != null || widget.showCloseButton)
        ? _Header(
            title: widget.title,
            subtitle: widget.subtitle,
            icon: widget.icon,
            showClose: widget.showCloseButton,
            hasHandle: rs.showHandle && active,
            enableHaptic: rs.enableHaptic,
            onClose: () => Navigator.of(context).maybePop(),
          )
        : null;

    // Main column: optional handle (compact) + header + scrollable
    // content + actions.
    // The drag target is the handle AND the header, not the handle
    // alone.
    //
    // It used to hang off `_Handle` by itself — forty points by four —
    // so a swipe down anywhere else on the sheet did nothing at all,
    // while the plain bottom-sheet path (every other sheet in the app)
    // dismisses from a drag across its whole top. The list keeps its
    // own gesture: a drag there scrolls, which is what a list is for.
    final topBlock = <Widget>[
      if (rs.showHandle && active) _Handle(rs: rs),
      if (header != null) header,
    ];

    final mainColumn = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.enableDrag && topBlock.isNotEmpty)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            // The axis follows the LAYOUT: a bottom sheet is pushed
            // down, a side sheet is pushed out toward its own edge.
            // The side one used to take its drag from the thin
            // vertical handle alone, so its header — the obvious thing
            // to grab — did nothing.
            onVerticalDragUpdate: active ? _onVerticalDragUpdate : null,
            onVerticalDragEnd: active ? _onVerticalDragEnd : null,
            onHorizontalDragUpdate: active
                ? null
                : (d) => _onHorizontalDragUpdate(d, dirSign),
            onHorizontalDragEnd: active
                ? null
                : (d) => _onHorizontalDragEnd(d, dirSign),
            child: Column(mainAxisSize: MainAxisSize.min, children: topBlock),
          )
        else
          ...topBlock,
        Flexible(
          child: SingleChildScrollView(
            padding: rs.contentPadding,
            child: KeyedSubtree(key: _contentKey, child: widget.content),
          ),
        ),
        if (widget.actions != null && widget.actions!.isNotEmpty)
          _Actions(actions: widget.actions!),
      ],
    );

    // Side layout slots a vertical drag handle on the leading edge.
    final body = (!active && widget.enableDrag && rs.showHandle)
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (d) =>
                    _onHorizontalDragUpdate(d, dirSign),
                onHorizontalDragEnd: (d) => _onHorizontalDragEnd(d, dirSign),
                child: _VerticalHandle(
                  width: rs.handleHeight,
                  height: rs.handleWidth,
                  color: rs.handleColor,
                ),
              ),
              Expanded(child: mainColumn),
            ],
          )
        : mainColumn;

    // `SafeArea` pads the edges of the SCREEN, wherever it is put —
    // and a bottom sheet is at the bottom of one. A plain
    // `SafeArea(child: body)` therefore padded the NOTCH's inset
    // inside a sheet that never comes near the top: 47 points of
    // nothing above the heading on a notched phone, measured. Only a
    // SIDE sheet spans the full height and earns the top inset.
    //
    // The BOTTOM inset stays INSIDE the card, which is where every
    // other sheet in the app keeps it — the media source sheet is the
    // one to compare against, and its cancel row sits above the home
    // indicator with the clearance inside the white. Absorbing it into
    // the floating margin instead lifted the whole card off the bottom
    // and made this one sheet float higher than every other.
    // The HORIZONTAL insets belong OUTSIDE a floating card.
    //
    // "The surface covers the inset, the content sits inside it" is
    // the rule for chrome that sits ON an edge — an attached side
    // sheet, a nav bar. A FLOATING sheet is not on an edge: it is a
    // detached card held off by its margin. Applying the landscape
    // notch's inset inside it ran the card's own edge under the
    // housing and then pushed the rows 62 points back in, leaving a
    // white band along the side of the card. The margin clears it
    // instead, so the whole card is visible and the rows keep their
    // own padding.
    final viewPadding = MediaQuery.paddingOf(context);
    Widget surface = Material(
      color: rs.backgroundColor,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: !active,
        left: !floating,
        right: !floating,
        child: body,
      ),
    );

    if (floating) {
      final margin = rs.floatingMargin;
      surface = Padding(
        padding: margin.copyWith(
          left: margin.left + viewPadding.left,
          right: margin.right + viewPadding.right,
        ),
        child: surface,
      );
    }

    // Size the surface for the active layout. Compact varies on the
    // width axis (full / fixed / capped / adaptive); side varies on
    // the height axis. Each axis honors [SheetSizing] when supplied.
    final compactMaxHeight = widget.maxHeight ?? mq.size.height * 0.9;
    final compactMinHeight = widget.minHeight ?? 0;
    final sheetW = sideW + (floating ? rs.floatingMargin.horizontal : 0);
    final sizing = widget.sizing;
    Widget sized;
    if (active) {
      // Bound height by min/max, then resolve the width per sizing.
      Widget heightBounded = ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: compactMaxHeight,
          minHeight: compactMinHeight,
        ),
        child: surface,
      );
      if (sizing?.width != null) {
        sized = SizedBox(width: sizing!.width, child: heightBounded);
      } else if (sizing?.adaptiveWidth ?? false) {
        Widget intrinsic = IntrinsicWidth(child: heightBounded);
        if (sizing!.maxWidth != null) {
          intrinsic = ConstrainedBox(
            constraints: BoxConstraints(maxWidth: sizing.maxWidth!),
            child: intrinsic,
          );
        }
        sized = intrinsic;
      } else if (sizing?.maxWidth != null) {
        sized = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: sizing!.maxWidth!),
          child: heightBounded,
        );
      } else {
        sized = SizedBox(width: mq.size.width, child: heightBounded);
      }
    } else {
      // Width is fixed at [sheetW] for the side layout. Vary height.
      Widget widthSized;
      if (sizing?.height != null) {
        widthSized = SizedBox(
          width: sheetW,
          height: sizing!.height,
          child: surface,
        );
      } else if (sizing?.adaptiveHeight ?? false) {
        Widget intrinsic = IntrinsicHeight(child: surface);
        if (sizing!.maxHeight != null) {
          intrinsic = ConstrainedBox(
            constraints: BoxConstraints(maxHeight: sizing.maxHeight!),
            child: intrinsic,
          );
        }
        widthSized = SizedBox(width: sheetW, child: intrinsic);
      } else if (sizing?.maxHeight != null) {
        widthSized = ConstrainedBox(
          constraints: BoxConstraints(maxHeight: sizing!.maxHeight!),
          child: SizedBox(width: sheetW, child: surface),
        );
      } else {
        widthSized = SizedBox(
          width: sheetW,
          height: mq.size.height,
          child: surface,
        );
      }
      sized = widthSized;
    }

    // Drag translation along the active layout's axis.
    final translated = Transform.translate(
      offset: Offset(_dragOffset.dx * dirSign, _dragOffset.dy),
      child: sized,
    );

    // Two stacked slides:
    //   • Inner — flipCtrl, slides out / in during bucket flips.
    //   • Outer — entryAnimation, slides on initial push / final pop.
    // Both share the active layout's direction so the exit always
    // matches what the user sees (e.g. side-layout pop slides out
    // to the trailing edge, not down).
    final activeDirection = active ? const Offset(0, 1) : Offset(dirSign, 0);

    // Cross-axis alignment per [SheetSizing]:
    //   • compact → horizontalAlignment controls x (start/center/end)
    //                + y is always 1 (pinned to bottom edge).
    //   • side    → verticalAlignment controls y (top/center/bottom)
    //                + x is always 1 (pinned to trailing edge).
    final outerAlignment = active
        ? AlignmentDirectional(
            _crossAlignFactor(sizing?.horizontalAlignment),
            1,
          )
        : AlignmentDirectional(
            1,
            _crossAlignFactor(sizing?.verticalAlignment),
          );

    return Align(
      alignment: outerAlignment,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: activeDirection,
          end: Offset.zero,
        ).animate(_curvedEntry),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: activeDirection,
            end: Offset.zero,
          ).animate(_curvedFlip),
          child: translated,
        ),
      ),
    );
  }
}

/// Leading-edge vertical drag handle. Visual mirror of [_Handle] —
/// pill rotated 90° so width/height are swapped and the pill stands
/// upright along the leading edge of the side-sheet.
class _VerticalHandle extends StatelessWidget {
  const _VerticalHandle({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Center(
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(width / 2),
            ),
          ),
        ),
      ),
    );
  }
}
