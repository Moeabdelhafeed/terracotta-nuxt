part of 'global_sheet.dart';

/// A themed bottom sheet with drag handle, title, subtitle, actions, and custom content.
class GlobalBottomSheet {
  GlobalBottomSheet._();
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Bucket-aware width applied to the responsive side-sheet form.
  /// Override per call via the `sideWidth` arg on [show].
  static const ResponsiveValue<double> defaultSideWidth =
      ResponsiveValue<double>(
        compact: double.infinity,
        medium: 360,
        expanded: 400,
        large: 440,
        extraLarge: 480,
      );

  /// Show a standard bottom sheet.
  ///
  /// When [responsive] is `true` AND the active window bucket is
  /// `medium` or larger, the sheet flips to a side-sheet that
  /// slides in from the trailing edge — same builder, different
  /// surface. Compact buckets stay on the classic bottom sheet.
  ///
  /// On bucket flip mid-show (e.g. window resize crossing the
  /// compact threshold) the active surface is popped and the
  /// matching surface is reopened with the same args. State inside
  /// [content] resets on flip — wrap callers in a hoisted state
  /// holder if persistence across flips matters.
  static Future<T?> show<T>({
    BuildContext? context,
    String? title,
    String? subtitle,
    required Widget content,
    double? height,
    double? minHeight,
    double? maxHeight,
    bool isDismissible = true,
    bool enableDrag = true,
    bool isScrollControlled = true,
    bool showCloseButton = true,
    IconData? icon,
    List<Widget>? actions,
    SheetStyle style = const SheetStyle(),
    bool useSafeArea = true,
    bool responsive = false,
    ResponsiveValue<double>? sideWidth,
    SheetSizing? sizing,
  }) {
    final ctx = context ?? navigatorKey?.currentContext;
    if (ctx == null) return Future.value(null);
    final rs = style.resolve(ctx);

    if (!responsive) {
      return _showBottomSheet<T>(
        ctx,
        title: title,
        subtitle: subtitle,
        content: content,
        height: height,
        minHeight: minHeight,
        maxHeight: maxHeight,
        isDismissible: isDismissible,
        enableDrag: enableDrag,
        isScrollControlled: isScrollControlled,
        showCloseButton: showCloseButton,
        icon: icon,
        actions: actions,
        rs: rs,
        useSafeArea: useSafeArea,
        sizing: sizing,
      );
    }

    // Single-route responsive flow. One [showGeneralDialog] hosts the
    // [_ResponsiveSurface], which watches the active `WindowSizeClass`
    // and morphs its own alignment / size / handle orientation
    // between bottom-sheet and side-sheet layouts. The user's
    // [content] sits at a stable [Element] location inside the
    // surface, so any [StatefulWidget] state inside (forms, text
    // controllers, scroll positions) survives a bucket flip — no
    // route push/pop, no GlobalKey reparenting, just an in-place
    // animation.
    return showGeneralDialog<T>(
      context: ctx,
      useRootNavigator: true,
      barrierDismissible: isDismissible,
      barrierLabel: CommonStrings.dismiss,
      barrierColor: rs.barrierColor,
      transitionDuration: rs.animationDuration,
      pageBuilder: (routeCtx, anim, _) {
        return _ResponsiveSurface(
          entryAnimation: anim,
          title: title,
          subtitle: subtitle,
          icon: icon,
          showCloseButton: showCloseButton,
          enableDrag: enableDrag,
          actions: actions,
          rs: rs,
          sideWidth: sideWidth ?? defaultSideWidth,
          height: height,
          minHeight: minHeight,
          maxHeight: maxHeight,
          sizing: sizing,
          content: content,
        );
      },
      transitionBuilder: (ctx, anim, _, child) => child,
    );
  }

  /// Bottom-sheet body — extracted so `responsive: true` can reopen
  /// the matching surface mid-show without duplicating chrome wiring.
  static Future<T?> _showBottomSheet<T>(
    BuildContext context, {
    String? title,
    String? subtitle,
    required Widget content,
    double? height,
    double? minHeight,
    double? maxHeight,
    bool isDismissible = true,
    bool enableDrag = true,
    bool isScrollControlled = true,
    bool showCloseButton = true,
    IconData? icon,
    List<Widget>? actions,
    required ResolvedSheetStyle rs,
    bool useSafeArea = true,
    SheetSizing? sizing,
  }) {
    final floating = rs.floating;
    final borderRadius = _resolveRadius(rs, floating, false);

    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      barrierColor: rs.barrierColor,
      showDragHandle: false,
      elevation: 0,
      clipBehavior: Clip.none,
      useSafeArea: useSafeArea,
      constraints: BoxConstraints(
        maxHeight: maxHeight ?? MediaQuery.of(context).size.height * 0.9,
        minHeight: minHeight ?? 0,
      ),
      builder: (sheetCtx) {
        Widget sheet = _SheetContainer(
          height: height,
          borderRadius: borderRadius,
          rs: rs,
          isTop: false,
          hideBottomBorder: rs.hideBottomBorder && !floating,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (rs.showHandle && enableDrag) _Handle(rs: rs),
              if (title != null || showCloseButton)
                _Header(
                  title: title,
                  subtitle: subtitle,
                  icon: icon,
                  showClose: showCloseButton,
                  hasHandle: rs.showHandle,
                  enableHaptic: rs.enableHaptic,
                  onClose: () => Navigator.of(sheetCtx).pop(),
                ),
              Flexible(
                child: SingleChildScrollView(
                  padding: rs.contentPadding,
                  child: SafeArea(top: false, bottom: false, child: content),
                ),
              ),
              if (actions != null && actions.isNotEmpty)
                _Actions(actions: actions),
            ],
          ),
        );
        if (floating) sheet = Padding(padding: rs.floatingMargin, child: sheet);
        return _wrapHorizontalSizing(
          sheet,
          sizing: sizing,
          crossAxis: CrossAxisAlignment.end,
        );
      },
    );
  }

  /// Show a resizable/draggable bottom sheet.
  static Future<T?> resizable<T>({
    BuildContext? context,
    String? title,
    required Widget Function(ScrollController controller) builder,
    double initialSize = 0.5,
    double minSize = 0.25,
    double maxSize = 0.95,
    bool isDismissible = true,
    bool showCloseButton = true,
    IconData? icon,
    SheetStyle style = const SheetStyle(),
  }) {
    final ctx = context ?? navigatorKey?.currentContext;
    if (ctx == null) return Future.value(null);

    final rs = style.resolve(ctx);
    final floating = rs.floating;
    final borderRadius = _resolveRadius(rs, floating, false);

    return showModalBottomSheet<T>(
      context: ctx,
      isDismissible: isDismissible,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: rs.barrierColor,
      showDragHandle: false,
      elevation: 0,
      clipBehavior: Clip.none,
      builder: (sheetCtx) {
        final sheetController = DraggableScrollableController();
        return DraggableScrollableSheet(
          controller: sheetController,
          initialChildSize: initialSize,
          minChildSize: minSize,
          maxChildSize: maxSize,
          snap: true,
          snapSizes: [minSize, (minSize + maxSize) / 2, maxSize],
          expand: false,
          builder: (ctx, scrollCtrl) {
            Widget sheet = _SheetContainer(
              borderRadius: borderRadius,
              rs: rs,
              isTop: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (rs.showHandle)
                    GestureDetector(
                      onVerticalDragUpdate: (d) {
                        final screenH = MediaQuery.of(ctx).size.height;
                        sheetController.jumpTo(
                          (sheetController.size - d.delta.dy / screenH).clamp(
                            minSize,
                            maxSize,
                          ),
                        );
                      },
                      behavior: HitTestBehavior.opaque,
                      child: _HandleArea(rs: rs),
                    ),
                  if (title != null || showCloseButton)
                    _Header(
                      title: title,
                      icon: icon,
                      showClose: showCloseButton,
                      hasHandle: rs.showHandle,
                      enableHaptic: rs.enableHaptic,
                      onClose: () => Navigator.of(sheetCtx).pop(),
                    ),
                  Expanded(child: builder(scrollCtrl)),
                ],
              ),
            );
            if (floating) {
              sheet = Padding(padding: rs.floatingMargin, child: sheet);
            }
            return sheet;
          },
        );
      },
    );
  }

  /// Show a multi-page bottom sheet with page indicator.
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
    final borderRadius = _resolveRadius(rs, floating, false);

    return showModalBottomSheet<T>(
      context: ctx,
      isDismissible: isDismissible,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: rs.barrierColor,
      showDragHandle: false,
      elevation: 0,
      clipBehavior: Clip.none,
      builder: (sheetCtx) {
        Widget sheet = _SheetContainer(
          height: height ?? MediaQuery.of(ctx).size.height * 0.55,
          borderRadius: borderRadius,
          rs: rs,
          isTop: false,
          child: _MultiPageContent(
            pages: pages,
            pageTitles: pageTitles,
            title: title,
            icon: icon,
            showClose: showCloseButton,
            showIndicator: showPageIndicator,
            rs: rs,
            onClose: () => Navigator.of(sheetCtx).pop(),
          ),
        );
        if (floating) sheet = Padding(padding: rs.floatingMargin, child: sheet);
        return sheet;
      },
    );
  }
}
