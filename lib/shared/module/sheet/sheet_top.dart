part of 'global_sheet.dart';

/// A themed top sheet that slides down from the top — supports drag to dismiss.
class GlobalTopSheet {
  GlobalTopSheet._();
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Show a standard top sheet.
  static Future<T?> show<T>({
    BuildContext? context,
    String? title,
    String? subtitle,
    required Widget content,
    double? height,
    double? minHeight,
    double? maxHeight,
    bool isDismissible = true,
    IconData? icon,
    List<Widget>? actions,
    List<Widget>? headerActions,
    bool showCloseButton = true,
    bool showHandle = true,
    EdgeInsets? contentPadding,
    VoidCallback? onDismissed,
    SheetStyle style = const SheetStyle(),
    SheetSizing? sizing,
  }) {
    final ctx = context ?? navigatorKey?.currentContext;
    if (ctx == null) return Future.value(null);
    final rs = style.resolve(ctx);

    return showGeneralDialog<T>(
      context: ctx,
      barrierDismissible: isDismissible,
      barrierLabel: CommonStrings.dismiss,
      barrierColor: rs.barrierColor,
      transitionDuration: rs.animationDuration,
      pageBuilder: (dialogCtx, anim1, anim2) => _TopSheetBody(
        title: title,
        subtitle: subtitle,
        content: content,
        height: height,
        minHeight: minHeight,
        maxHeight: maxHeight,
        icon: icon,
        actions: actions,
        headerActions: headerActions,
        showCloseButton: showCloseButton,
        showHandle: showHandle,
        contentPadding: contentPadding,
        onDismissed: onDismissed,
        rs: rs,
        sizing: sizing,
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: rs.animationCurve)),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: anim1,
              curve: const Interval(0, 0.5),
            ),
            child: child,
          ),
        );
      },
    ).then((value) {
      onDismissed?.call();
      return value;
    });
  }

  /// Show a multi-page top sheet.
  static Future<T?> multiPage<T>({
    BuildContext? context,
    required List<Widget> pages,
    List<String>? pageTitles,
    String? title,
    bool isDismissible = true,
    bool showCloseButton = true,
    bool showPageIndicator = true,
    IconData? icon,
    SheetStyle style = const SheetStyle(),
    double? height,
  }) {
    final ctx = context ?? navigatorKey?.currentContext;
    if (ctx == null) return Future.value(null);

    final rs = style.resolve(ctx);
    final floating = rs.floating;
    final radius = _resolveRadius(rs, floating, true);
    final screenH = MediaQuery.of(ctx).size.height;
    final screenW = MediaQuery.of(ctx).size.width;
    final safePad = MediaQuery.of(ctx).padding;
    final sheetHeight = height ?? screenH * 0.5;

    return showGeneralDialog<T>(
      context: ctx,
      barrierDismissible: isDismissible,
      barrierLabel: CommonStrings.dismiss,
      barrierColor: rs.barrierColor,
      transitionDuration: rs.animationDuration,
      pageBuilder: (dialogCtx, anim1, anim2) => Align(
        alignment: Alignment.topCenter,
        child: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: screenW,
            child: Padding(
              padding: floating
                  ? rs.floatingMargin.add(EdgeInsets.only(top: safePad.top))
                  : EdgeInsets.zero,
              child: Container(
                height: sheetHeight,
                decoration: BoxDecoration(
                  color: rs.backgroundGradient == null
                      ? rs.backgroundColor
                      : null,
                  gradient: rs.backgroundGradient,
                  borderRadius: radius,
                  border: rs.border,
                  boxShadow: rs.resolveShadow(isTop: true),
                ),
                clipBehavior: Clip.antiAlias,
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    children: [
                      if (!floating) SizedBox(height: safePad.top),
                      Expanded(
                        child: _MultiPageContent(
                          pages: pages,
                          pageTitles: pageTitles,
                          title: title,
                          icon: icon,
                          showClose: showCloseButton,
                          showIndicator: showPageIndicator,
                          rs: rs,
                          onClose: () => Navigator.of(dialogCtx).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: rs.animationCurve)),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: anim1,
              curve: const Interval(0, 0.5),
            ),
            child: child,
          ),
        );
      },
    );
  }

  /// Show a resizable top sheet.
  static Future<T?> resizable<T>({
    BuildContext? context,
    String? title,
    required Widget content,
    double initialHeight = 0.4,
    double minHeight = 0.2,
    double maxHeight = 0.85,
    List<double>? snapPoints,
    bool isDismissible = true,
    bool showCloseButton = true,
    IconData? icon,
    List<Widget>? headerActions,
    SheetStyle style = const SheetStyle(),
  }) {
    final ctx = context ?? navigatorKey?.currentContext;
    if (ctx == null) return Future.value(null);
    final rs = style.resolve(ctx);

    return showGeneralDialog<T>(
      context: ctx,
      barrierDismissible: isDismissible,
      barrierLabel: CommonStrings.dismiss,
      barrierColor: rs.barrierColor,
      transitionDuration: rs.animationDuration,
      pageBuilder: (dialogCtx, anim1, anim2) => _ResizableTopSheet(
        title: title,
        content: content,
        icon: icon,
        initialHeight: initialHeight,
        minHeight: minHeight,
        maxHeight: maxHeight,
        snapPoints: snapPoints,
        showCloseButton: showCloseButton,
        headerActions: headerActions,
        rs: rs,
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: rs.animationCurve)),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: anim1,
              curve: const Interval(0, 0.5),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Top sheet body with drag-to-dismiss
// ---------------------------------------------------------------------------

class _TopSheetBody extends StatefulWidget {
  const _TopSheetBody({
    this.title,
    this.subtitle,
    required this.content,
    this.height,
    this.minHeight,
    this.maxHeight,
    this.icon,
    this.actions,
    this.headerActions,
    this.showCloseButton = true,
    this.showHandle = true,
    this.contentPadding,
    this.onDismissed,
    required this.rs,
    this.sizing,
  });

  final String? title, subtitle;
  final Widget content;
  final double? height, minHeight, maxHeight;
  final IconData? icon;
  final List<Widget>? actions, headerActions;
  final bool showCloseButton, showHandle;
  final EdgeInsets? contentPadding;
  final VoidCallback? onDismissed;
  final ResolvedSheetStyle rs;
  final SheetSizing? sizing;

  @override
  State<_TopSheetBody> createState() => _TopSheetBodyState();
}

class _TopSheetBodyState extends State<_TopSheetBody> {
  double _dragOffset = 0;

  void _onDragUpdate(DragUpdateDetails d) {
    setState(
      () => _dragOffset = (_dragOffset + d.delta.dy).clamp(-double.infinity, 0),
    );
  }

  void _onDragEnd(DragEndDetails d) {
    if (_dragOffset.abs() > _kDismissThreshold ||
        d.velocity.pixelsPerSecond.dy < -_kDismissVelocity) {
      if (widget.rs.enableHaptic) HapticFeedback.mediumImpact();
      Navigator.of(context).pop();
      widget.onDismissed?.call();
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rs = widget.rs;
    final screenH = MediaQuery.of(context).size.height;
    final safePad = MediaQuery.of(context).padding;
    final floating = rs.floating;
    final radius = _resolveRadius(rs, floating, true);

    // Height: explicit > constrained > wrap content
    final maxH = widget.maxHeight ?? screenH * 0.9;
    final minH = widget.minHeight ?? 0.0;
    final sheetHeight = widget.height?.clamp(minH, maxH);

    // Build content column (shared between normal and gradient border
    // paths). Material.transparency hosts InkWell splashes above the
    // opaque background (see _SheetContainer).
    Widget sheetContent = Material(
      type: MaterialType.transparency,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!floating) SizedBox(height: safePad.top),
          _Header(
            title: widget.title,
            subtitle: widget.subtitle,
            icon: widget.icon,
            showClose: widget.showCloseButton,
            hasHandle: false,
            enableHaptic: rs.enableHaptic,
            onClose: () => Navigator.of(context).pop(),
            actions: widget.headerActions,
          ),
          const SizedBox(height: 4),
          Flexible(
            child: SingleChildScrollView(
              padding:
                  widget.contentPadding ?? rs.contentPadding.copyWith(top: 0),
              physics: const BouncingScrollPhysics(),
              child: widget.content,
            ),
          ),
          if (widget.actions != null && widget.actions!.isNotEmpty)
            _Actions(actions: widget.actions!),
          if (widget.showHandle)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _Handle(rs: rs),
            ),
        ],
      ),
    );

    final shadow = rs.resolveShadow(isTop: true);

    // Width comes from sizing (when provided). Default = full screen.
    final screenWidth = MediaQuery.of(context).size.width;
    final hasHSizing = _hasHorizontalSizing(widget.sizing);
    final containerWidth = hasHSizing ? null : screenWidth;

    Widget sheet;
    if (rs.borderGradient != null) {
      sheet = Container(
        width: containerWidth,
        height: sheetHeight,
        constraints: sheetHeight == null
            ? BoxConstraints(minHeight: minH, maxHeight: maxH)
            : null,
        decoration: BoxDecoration(
          gradient: rs.borderGradient,
          borderRadius: radius,
          boxShadow: shadow,
        ),
        child: Container(
          margin: EdgeInsets.all(rs.borderWidth),
          decoration: BoxDecoration(
            color: rs.backgroundGradient == null ? rs.backgroundColor : null,
            gradient: rs.backgroundGradient,
            borderRadius: radius.subtract(
              BorderRadius.all(Radius.circular(rs.borderWidth)),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: sheetContent,
        ),
      );
    } else {
      sheet = Container(
        width: containerWidth,
        height: sheetHeight,
        constraints: sheetHeight == null
            ? BoxConstraints(minHeight: minH, maxHeight: maxH)
            : null,
        decoration: BoxDecoration(
          color: rs.backgroundGradient == null ? rs.backgroundColor : null,
          gradient: rs.backgroundGradient,
          borderRadius: radius,
          border: rs.border,
          boxShadow: shadow,
        ),
        child: ClipRRect(borderRadius: radius, child: sheetContent),
      );
    }

    if (floating) {
      sheet = Padding(
        padding: rs.floatingMargin.add(EdgeInsets.only(top: safePad.top)),
        child: sheet,
      );
    }

    // Apply horizontal sizing + alignment. For top sheets pin to the
    // top edge inside the wrapping row so the sheet hugs its anchor.
    final sized = hasHSizing
        ? _wrapHorizontalSizing(
            sheet,
            sizing: widget.sizing,
            crossAxis: CrossAxisAlignment.start,
          )
        : SizedBox(width: screenWidth, child: sheet);

    return GestureDetector(
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: Align(
        alignment: Alignment.topCenter,
        child: Transform.translate(
          offset: Offset(0, _dragOffset),
          child: Material(color: Colors.transparent, child: sized),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Resizable top sheet
// ---------------------------------------------------------------------------

class _ResizableTopSheet extends StatefulWidget {
  const _ResizableTopSheet({
    this.title,
    required this.content,
    this.icon,
    required this.initialHeight,
    required this.minHeight,
    required this.maxHeight,
    this.snapPoints,
    this.showCloseButton = true,
    this.headerActions,
    required this.rs,
  });

  final String? title;
  final Widget content;
  final IconData? icon;
  final double initialHeight, minHeight, maxHeight;
  final List<double>? snapPoints;
  final bool showCloseButton;
  final List<Widget>? headerActions;
  final ResolvedSheetStyle rs;

  @override
  State<_ResizableTopSheet> createState() => _ResizableTopSheetState();
}

class _ResizableTopSheetState extends State<_ResizableTopSheet> {
  late double _heightFraction;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _heightFraction = widget.initialHeight;
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onHandleDrag(DragUpdateDetails d) {
    final screenH = MediaQuery.of(context).size.height;
    final newFraction = _heightFraction + d.delta.dy / screenH;
    if (newFraction < widget.minHeight - 0.05) {
      Navigator.of(context).pop();
      return;
    }
    setState(
      () => _heightFraction = newFraction.clamp(
        widget.minHeight,
        widget.maxHeight,
      ),
    );
  }

  void _onHandleDragEnd(DragEndDetails d) {
    if (d.velocity.pixelsPerSecond.dy < -_kDismissVelocity) {
      if (widget.rs.enableHaptic) HapticFeedback.mediumImpact();
      Navigator.of(context).pop();
      return;
    }
    final snaps = widget.snapPoints;
    if (snaps != null && snaps.isNotEmpty) {
      var nearest = snaps.first;
      var minDist = (_heightFraction - nearest).abs();
      for (final s in snaps) {
        final dist = (_heightFraction - s).abs();
        if (dist < minDist) {
          nearest = s;
          minDist = dist;
        }
      }
      setState(() => _heightFraction = nearest);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rs = widget.rs;
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
    final safePad = MediaQuery.of(context).padding;
    final floating = rs.floating;
    final radius = _resolveRadius(rs, floating, true);
    final sheetHeight = screenH * _heightFraction;
    // Drag-follow tween — collapses under reduced motion.
    final followDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 50);

    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: screenW,
          child: Padding(
            padding: floating
                ? rs.floatingMargin.add(EdgeInsets.only(top: safePad.top))
                : EdgeInsets.zero,
            child: AnimatedContainer(
              duration: followDuration,
              height: sheetHeight,
              decoration: BoxDecoration(
                color: rs.backgroundGradient == null
                    ? rs.backgroundColor
                    : null,
                gradient: rs.backgroundGradient,
                borderRadius: radius,
                border: rs.border,
                boxShadow: rs.resolveShadow(isTop: true),
              ),
              clipBehavior: Clip.antiAlias,
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  children: [
                    if (!floating) SizedBox(height: safePad.top),
                    _Header(
                      title: widget.title,
                      icon: widget.icon,
                      showClose: widget.showCloseButton,
                      hasHandle: false,
                      enableHaptic: rs.enableHaptic,
                      onClose: () => Navigator.of(context).pop(),
                      actions: widget.headerActions,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: ListView(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(_kPad, 0, _kPad, 0),
                        physics: const BouncingScrollPhysics(),
                        children: [widget.content],
                      ),
                    ),
                    GestureDetector(
                      onVerticalDragUpdate: _onHandleDrag,
                      onVerticalDragEnd: _onHandleDragEnd,
                      behavior: HitTestBehavior.opaque,
                      child: _HandleArea(rs: rs),
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
}
