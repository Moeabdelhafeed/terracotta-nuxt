part of 'global_sheet.dart';

/// Combined top + bottom sheet — both panels live in a single
/// [showGeneralDialog] entry and share drag/dismiss state:
///
///  - Dragging either panel outward (top → up, bottom → down)
///    drives a common dismiss offset, so both slide off together.
///  - Past [_kDismissThreshold] or a fling past [_kDismissVelocity]
///    → both dismiss in a single [Navigator.pop].
///  - Heights are budget-clamped ([maxCombinedFraction] of screen)
///    so the pair never exceeds the visible area.
///  - Each panel has its own [SheetStyle] + header/actions, so it
///    renders identically to a standalone Global[Top|Bottom]Sheet.
class GlobalCombinedSheet {
  GlobalCombinedSheet._();
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Show a coordinated top + bottom sheet.
  static Future<T?> show<T>({
    BuildContext? context,
    // ─── Top panel ───
    required Widget topContent,
    String? topTitle,
    String? topSubtitle,
    IconData? topIcon,
    List<Widget>? topActions,
    List<Widget>? topHeaderActions,
    double? topHeight,
    double? topMinHeight,
    double? topMaxHeight,
    bool topShowClose = true,
    EdgeInsets? topContentPadding,
    SheetStyle topStyle = const SheetStyle(),
    // ─── Bottom panel ───
    required Widget bottomContent,
    String? bottomTitle,
    String? bottomSubtitle,
    IconData? bottomIcon,
    List<Widget>? bottomActions,
    double? bottomHeight,
    double? bottomMinHeight,
    double? bottomMaxHeight,
    bool bottomShowClose = true,
    EdgeInsets? bottomContentPadding,
    SheetStyle bottomStyle = const SheetStyle(),
    // ─── Shared ───
    bool isDismissible = true,
    double maxCombinedFraction = 0.9,
    Color? barrierColor,
  }) {
    final ctx = context ?? navigatorKey?.currentContext;
    if (ctx == null) return Future.value(null);

    final topRs = topStyle.resolve(ctx);
    final bottomRs = bottomStyle.resolve(ctx);

    return showGeneralDialog<T>(
      context: ctx,
      barrierDismissible: isDismissible,
      barrierLabel: CommonStrings.dismiss,
      barrierColor: barrierColor ?? topRs.barrierColor,
      transitionDuration: topRs.animationDuration,
      pageBuilder: (dlgCtx, anim, _) => _CombinedSheetBody(
        animation: anim,
        topContent: topContent,
        topTitle: topTitle,
        topSubtitle: topSubtitle,
        topIcon: topIcon,
        topActions: topActions,
        topHeaderActions: topHeaderActions,
        topHeight: topHeight,
        topMinHeight: topMinHeight,
        topMaxHeight: topMaxHeight,
        topShowClose: topShowClose,
        topContentPadding: topContentPadding,
        topRs: topRs,
        bottomContent: bottomContent,
        bottomTitle: bottomTitle,
        bottomSubtitle: bottomSubtitle,
        bottomIcon: bottomIcon,
        bottomActions: bottomActions,
        bottomHeight: bottomHeight,
        bottomMinHeight: bottomMinHeight,
        bottomMaxHeight: bottomMaxHeight,
        bottomShowClose: bottomShowClose,
        bottomContentPadding: bottomContentPadding,
        bottomRs: bottomRs,
        maxCombinedFraction: maxCombinedFraction,
      ),
      transitionBuilder: (ctx, anim, _, child) => child,
    );
  }
}

enum _DragPanel { top, bottom }

class _CombinedSheetBody extends StatefulWidget {
  const _CombinedSheetBody({
    required this.animation,
    required this.topContent,
    this.topTitle,
    this.topSubtitle,
    this.topIcon,
    this.topActions,
    this.topHeaderActions,
    this.topHeight,
    this.topMinHeight,
    this.topMaxHeight,
    required this.topShowClose,
    this.topContentPadding,
    required this.topRs,
    required this.bottomContent,
    this.bottomTitle,
    this.bottomSubtitle,
    this.bottomIcon,
    this.bottomActions,
    this.bottomHeight,
    this.bottomMinHeight,
    this.bottomMaxHeight,
    required this.bottomShowClose,
    this.bottomContentPadding,
    required this.bottomRs,
    required this.maxCombinedFraction,
  });

  final Animation<double> animation;

  final Widget topContent;
  final String? topTitle, topSubtitle;
  final IconData? topIcon;
  final List<Widget>? topActions, topHeaderActions;
  final double? topHeight, topMinHeight, topMaxHeight;
  final bool topShowClose;
  final EdgeInsets? topContentPadding;
  final ResolvedSheetStyle topRs;

  final Widget bottomContent;
  final String? bottomTitle, bottomSubtitle;
  final IconData? bottomIcon;
  final List<Widget>? bottomActions;
  final double? bottomHeight, bottomMinHeight, bottomMaxHeight;
  final bool bottomShowClose;
  final EdgeInsets? bottomContentPadding;
  final ResolvedSheetStyle bottomRs;

  final double maxCombinedFraction;

  @override
  State<_CombinedSheetBody> createState() => _CombinedSheetBodyState();
}

class _CombinedSheetBodyState extends State<_CombinedSheetBody> {
  /// Shared dismiss offset in pixels. ≥ 0. Top slides up by this
  /// amount, bottom slides down by this amount — so both panels
  /// retract together regardless of which one the user grabbed.
  double _dismissPx = 0;

  void _onDragUpdate(_DragPanel panel, DragUpdateDetails d) {
    final delta = panel == _DragPanel.top ? -d.delta.dy : d.delta.dy;
    setState(() => _dismissPx = (_dismissPx + delta).clamp(0.0, 1000.0));
  }

  void _onDragEnd(_DragPanel panel, DragEndDetails d) {
    final v = d.velocity.pixelsPerSecond.dy;
    final fling = panel == _DragPanel.top
        ? v < -_kDismissVelocity
        : v > _kDismissVelocity;
    if (_dismissPx > _kDismissThreshold || fling) {
      final rs = panel == _DragPanel.top ? widget.topRs : widget.bottomRs;
      if (rs.enableHaptic) HapticFeedback.mediumImpact();
      Navigator.of(context).pop();
    } else {
      setState(() => _dismissPx = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final safePad = MediaQuery.of(context).padding;
    final avail = screenSize.height - safePad.vertical;
    final budget = avail * widget.maxCombinedFraction;

    // Clamp explicit heights so their sum never exceeds budget.
    var topH = widget.topHeight;
    var bottomH = widget.bottomHeight;
    if (topH != null && bottomH != null && topH + bottomH > budget) {
      final r = topH / (topH + bottomH);
      topH = budget * r;
      bottomH = budget - topH;
    }
    // Each panel is capped at the full budget when unconstrained —
    // the Column + Expanded spacer between them balances naturally,
    // so neither half sits on wasted space when the other is short.
    final topMaxH =
        widget.topMaxHeight ?? (budget - (bottomH ?? 0).clamp(0.0, budget));
    final bottomMaxH =
        widget.bottomMaxHeight ?? (budget - (topH ?? 0).clamp(0.0, budget));
    final reservedTop = topH ?? topMaxH;
    final reservedBottom = bottomH ?? bottomMaxH;

    final curved = CurvedAnimation(
      parent: widget.animation,
      curve: widget.topRs.animationCurve,
    );

    final topPanel = _buildPanel(
      isTop: true,
      rs: widget.topRs,
      content: widget.topContent,
      title: widget.topTitle,
      subtitle: widget.topSubtitle,
      icon: widget.topIcon,
      actions: widget.topActions,
      headerActions: widget.topHeaderActions,
      showClose: widget.topShowClose,
      contentPadding: widget.topContentPadding,
      height: topH,
      minHeight: widget.topMinHeight,
      maxHeight: topMaxH,
    );

    final bottomPanel = _buildPanel(
      isTop: false,
      rs: widget.bottomRs,
      content: widget.bottomContent,
      title: widget.bottomTitle,
      subtitle: widget.bottomSubtitle,
      icon: widget.bottomIcon,
      actions: widget.bottomActions,
      showClose: widget.bottomShowClose,
      contentPadding: widget.bottomContentPadding,
      height: bottomH,
      minHeight: widget.bottomMinHeight,
      maxHeight: bottomMaxH,
    );

    // Stack lets us pin top at the top and bottom at the bottom
    // while keeping a full-screen tap-to-dismiss layer behind them.
    // Using a Column with Expanded spacer caused overflow when top
    // grew large; using flex-only layout broke the natural-size
    // case. Stack + IgnoreBaseline fixes both.
    return Stack(
      children: [
        // ─── Barrier tap-to-dismiss (behind both panels) ────────
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),

        // ─── Layout: top uses natural size up to (screen -
        // bottomIntrinsic). Bottom always natural, capped.
        //  - flex: 0 on bottom means it's treated as non-flex, so
        //    Flutter lays it out with its intrinsic height first.
        //  - flex: 1 on top means top gets ALL remaining space as
        //    its share — but FlexFit.loose lets it use less than
        //    that share, so short top content stays short.
        //  - spaceBetween pins bottom to the bottom edge and top
        //    to the top edge; unused share in the middle renders
        //    as the barrier gap.
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -1),
                  end: Offset.zero,
                ).animate(curved),
                child: Transform.translate(
                  offset: Offset(0, -_dismissPx),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: (d) =>
                        _onDragUpdate(_DragPanel.top, d),
                    onVerticalDragEnd: (d) => _onDragEnd(_DragPanel.top, d),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: reservedTop),
                      child: topPanel,
                    ),
                  ),
                ),
              ),
            ),
            Flexible(
              flex: 0,
              fit: FlexFit.loose,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(curved),
                child: Transform.translate(
                  offset: Offset(0, _dismissPx),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: (d) =>
                        _onDragUpdate(_DragPanel.bottom, d),
                    onVerticalDragEnd: (d) => _onDragEnd(_DragPanel.bottom, d),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: reservedBottom),
                      child: bottomPanel,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPanel({
    required bool isTop,
    required ResolvedSheetStyle rs,
    required Widget content,
    required bool showClose,
    String? title,
    String? subtitle,
    IconData? icon,
    List<Widget>? actions,
    List<Widget>? headerActions,
    EdgeInsets? contentPadding,
    double? height,
    double? minHeight,
    double? maxHeight,
  }) {
    final floating = rs.floating;
    final radius = _resolveRadius(rs, floating, isTop);
    final safePad = MediaQuery.of(context).padding;

    final columnChildren = <Widget>[];

    if (isTop) {
      // Non-floating top sheet bleeds into the status-bar area —
      // pad from inside so content stays below the notch.
      if (!floating) columnChildren.add(SizedBox(height: safePad.top));
      if (title != null || showClose || headerActions != null) {
        columnChildren.add(
          _Header(
            title: title,
            subtitle: subtitle,
            icon: icon,
            showClose: showClose,
            hasHandle: false,
            enableHaptic: rs.enableHaptic,
            onClose: () => Navigator.of(context).pop(),
            actions: headerActions,
          ),
        );
        columnChildren.add(const SizedBox(height: 4));
      }
      columnChildren.add(
        Flexible(
          child: SingleChildScrollView(
            padding: contentPadding ?? rs.contentPadding.copyWith(top: 0),
            physics: const BouncingScrollPhysics(),
            child: content,
          ),
        ),
      );
      if (actions != null && actions.isNotEmpty) {
        columnChildren.add(_Actions(actions: actions));
      }
      if (rs.showHandle) {
        columnChildren.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _Handle(rs: rs),
          ),
        );
      }
    } else {
      if (rs.showHandle) columnChildren.add(_Handle(rs: rs));
      if (title != null || showClose) {
        columnChildren.add(
          _Header(
            title: title,
            subtitle: subtitle,
            icon: icon,
            showClose: showClose,
            hasHandle: rs.showHandle,
            enableHaptic: rs.enableHaptic,
            onClose: () => Navigator.of(context).pop(),
          ),
        );
      }
      columnChildren.add(
        Flexible(
          child: SingleChildScrollView(
            padding: contentPadding ?? rs.contentPadding,
            child: SafeArea(top: false, bottom: false, child: content),
          ),
        ),
      );
      if (actions != null && actions.isNotEmpty) {
        columnChildren.add(_Actions(actions: actions));
      }
    }

    // _SheetContainer hosts the ink (MaterialType.transparency inside
    // the opaque bg) — no extra Material needed here.
    Widget panel = _SheetContainer(
      height: height,
      borderRadius: radius,
      rs: rs,
      isTop: isTop,
      child: Column(mainAxisSize: MainAxisSize.min, children: columnChildren),
    );

    if (height == null) {
      panel = ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: minHeight ?? 0,
          maxHeight: maxHeight ?? double.infinity,
        ),
        child: panel,
      );
    }

    if (floating) {
      final extra = isTop ? EdgeInsets.only(top: safePad.top) : EdgeInsets.zero;
      panel = Padding(padding: rs.floatingMargin.add(extra), child: panel);
    }

    return panel;
  }
}
