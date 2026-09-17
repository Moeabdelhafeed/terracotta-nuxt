import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/module_strings.dart';
import '../../../core/navigation/transitions/route_transition.dart';
import '../../../core/responsive/extensions.dart';
import '../../../core/responsive/responsive_value.dart';
import '../buttons/global_filled_button.dart';
import '../buttons/global_outlined_button.dart';
import '../icon/global_icon.dart';
import '../progress/global_progress.dart';
import '../text/global_text.dart';
import 'dialog_models.dart';

export 'dialog_models.dart';
export 'theme/dialog_theme.dart';

/// Bucket-aware max-width applied to centered dialogs when
/// `responsive: true` is passed to [GlobalDialog.show] or
/// [GlobalDialog.builder].
const ResponsiveValue<double> _kDialogMaxWidth = ResponsiveValue<double>(
  compact: double.infinity,
  medium: 560,
  expanded: 640,
  large: 720,
  extraLarge: 720,
);

/// Bucket-aware barrier insets — stops the dialog hugging the screen
/// edge on large windows.
const ResponsiveValue<EdgeInsets> _kDialogInsets = ResponsiveValue<EdgeInsets>(
  compact: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
  medium: EdgeInsets.all(40),
  expanded: EdgeInsets.all(64),
  large: EdgeInsets.all(96),
  extraLarge: EdgeInsets.all(120),
);

// Chrome constants mirrored from [_GlobalDialogState] so the
// responsive / builder paths produce the same surface as the default
// dialog (transparent outer Dialog, opaque inner container with
// radius 20 + soft shadow).
const double _kDialogChromeRadius = 20.0;
const double _kDialogChromeBlur = 24.0;
const double _kDialogChromeOffsetY = 8.0;

/// Wraps [body] in the same chrome the default [GlobalDialog] body
/// renders, sized to [maxWidth] with bucket-aware [insets].
///
/// * [wrapChrome] `false` → [body] already brings its own Dialog +
///   surface (e.g. a [GlobalDialog]). Just clamps width and applies
///   outer insets so the dialog stops hugging the screen edge on
///   large windows. No extra Material wrapper so M3 surfaceTint
///   doesn't bleed through.
/// * [wrapChrome] `true` → [body] is bare content (e.g. caller's
///   [GlobalDialog.builder] widget). Apply the default chrome:
///   transparent outer [Dialog], opaque inner container, custom
///   shadow, antialiased clip.
Widget _wrapResponsive(
  BuildContext ctx,
  Widget body, {
  required double maxWidth,
  required EdgeInsets insets,
  bool wrapChrome = false,
}) {
  if (!wrapChrome) {
    return Center(
      child: Padding(
        padding: insets,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: body,
        ),
      ),
    );
  }
  final isDark = ctx.isDarkMode;
  return Dialog(
    backgroundColor: Colors.transparent,
    elevation: 0,
    insetPadding: insets,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        decoration: BoxDecoration(
          color: ctx.backgroundColors.surface,
          borderRadius: BorderRadius.circular(_kDialogChromeRadius),
          boxShadow: [
            BoxShadow(
              // Shadows are physically black; only opacity is themed.
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
              blurRadius: _kDialogChromeBlur,
              offset: const Offset(0, _kDialogChromeOffsetY),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        // Ink host — splashes must paint above this opaque surface,
        // not on the route's transparent backdrop behind it.
        child: Material(type: MaterialType.transparency, child: body),
      ),
    ),
  );
}

/// A comprehensive, themed dialog widget with multiple types, animations,
/// custom content, loading states, and convenient static show methods.
class GlobalDialog extends StatefulWidget {
  // ─── Content ───────────────────────────────────────────────
  final String title;
  final String? message;
  final Widget? content;
  final IconData? icon;

  // ─── Type & Style ──────────────────────────────────────────
  final DialogType type;
  final DialogStyle style;

  // ─── Actions ───────────────────────────────────────────────
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final List<Widget>? customActions;
  final bool isConfirmLoading;
  final bool isCancelLoading;
  final bool isDestructive;

  // ─── Behavior ──────────────────────────────────────────────
  final bool barrierDismissible;
  final Color? barrierColor;
  final bool showCloseButton;
  final bool canPop;
  final bool autoDismissOnConfirm;

  /// Auto-dismiss after this duration. Shows a countdown indicator. Null = no auto-dismiss.
  final Duration? autoDismissDuration;

  // ─── Header ────────────────────────────────────────────────
  final Widget? headerWidget;
  final Widget? customTitle;

  /// Global navigator key — set once in main.dart.
  static GlobalKey<NavigatorState>? navigatorKey;

  const GlobalDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.icon,
    this.type = DialogType.custom,
    this.style = const DialogStyle(),
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.customActions,
    this.isConfirmLoading = false,
    this.isCancelLoading = false,
    this.isDestructive = false,
    this.barrierDismissible = true,
    this.barrierColor,
    this.showCloseButton = true,
    this.canPop = true,
    this.autoDismissOnConfirm = true,
    this.autoDismissDuration,
    this.headerWidget,
    this.customTitle,
  });

  // ─── Static show methods ───────────────────────────────────

  /// Show a dialog and return the result.
  static Future<T?> show<T>({
    BuildContext? context,
    required String title,
    String? message,
    Widget? content,
    IconData? icon,
    DialogType type = DialogType.custom,
    DialogStyle style = const DialogStyle(),
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    List<Widget>? customActions,
    bool isConfirmLoading = false,
    bool isCancelLoading = false,
    bool isDestructive = false,
    bool barrierDismissible = true,
    Color? barrierColor,
    bool showCloseButton = true,
    bool canPop = true,
    bool autoDismissOnConfirm = true,
    Duration? autoDismissDuration,
    Widget? headerWidget,
    Widget? customTitle,
    bool responsive = false,
    bool fullScreenOnCompact = false,
  }) {
    final ctx = context ?? navigatorKey?.currentContext;
    if (ctx == null) return Future.value(null);
    // Loading state blocks dismissal
    final effectiveCanPop = (isConfirmLoading || isCancelLoading)
        ? false
        : canPop;
    final effectiveBarrierDismissible = (isConfirmLoading || isCancelLoading)
        ? false
        : barrierDismissible;

    // Full-screen route on compact when opted in. Content-heavy
    // dialogs (multi-step flows, forms) read better as a route push
    // than a phone-sized modal.
    if (fullScreenOnCompact && ctx.windowSize.isCompact) {
      return Navigator.of(ctx, rootNavigator: true).push<T>(
        // A dialog promoted to a whole screen is still a MODAL: up
        // from the bottom, and no leading-edge swipe, or a form inside
        // it loses a drag to the route.
        RouteTransition.route<T>(
          context: ctx,
          name: 'dialog',
          fullscreenDialog: true,
          style: TransitionStyle.modal,
          child: Builder(
            builder: (innerCtx) => Scaffold(
              appBar: AppBar(title: Text(title)),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: GlobalDialog(
                    title: title,
                    message: message,
                    content: content,
                    icon: icon,
                    type: type,
                    style: style,
                    confirmText: confirmText,
                    cancelText: cancelText,
                    onConfirm: onConfirm,
                    onCancel: onCancel,
                    customActions: customActions,
                    isConfirmLoading: isConfirmLoading,
                    isCancelLoading: isCancelLoading,
                    isDestructive: isDestructive,
                    barrierDismissible: false,
                    barrierColor: barrierColor,
                    showCloseButton: false,
                    canPop: effectiveCanPop,
                    autoDismissOnConfirm: autoDismissOnConfirm,
                    autoDismissDuration: autoDismissDuration,
                    headerWidget: headerWidget,
                    customTitle: customTitle,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return showDialog<T>(
      context: ctx,
      barrierDismissible: effectiveBarrierDismissible,
      barrierColor: barrierColor ?? style.resolve(ctx).barrierColor,
      builder: (innerCtx) {
        final body = GlobalDialog(
          title: title,
          message: message,
          content: content,
          icon: icon,
          type: type,
          style: style,
          confirmText: confirmText,
          cancelText: cancelText,
          onConfirm: onConfirm,
          onCancel: onCancel,
          customActions: customActions,
          isConfirmLoading: isConfirmLoading,
          isCancelLoading: isCancelLoading,
          isDestructive: isDestructive,
          barrierDismissible: effectiveBarrierDismissible,
          barrierColor: barrierColor,
          showCloseButton: (isConfirmLoading || isCancelLoading)
              ? false
              : showCloseButton,
          canPop: effectiveCanPop,
          autoDismissOnConfirm: autoDismissOnConfirm,
          autoDismissDuration: autoDismissDuration,
          headerWidget: headerWidget,
          customTitle: customTitle,
        );
        // Responsive path: clamp max-width + bucket-aware barrier
        // insets so the dialog doesn't hug the screen edge on large
        // windows. No-op on compact + when caller didn't opt in.
        if (!responsive) return body;
        return _wrapResponsive(
          innerCtx,
          body,
          maxWidth: _kDialogMaxWidth.resolve(innerCtx),
          insets: _kDialogInsets.resolve(innerCtx),
        );
      },
    );
  }

  /// Generic builder-style presenter — no opinionated chrome.
  /// Use when you need bucket-aware insets + max-width over any
  /// custom widget (the [show] entry point wraps with the dialog
  /// chrome; this one doesn't).
  static Future<T?> builder<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool fullScreenOnCompact = false,
    bool barrierDismissible = true,
    Color? barrierColor,
    ResponsiveValue<double>? maxWidth,
    ResponsiveValue<EdgeInsets>? insets,
    String? barrierLabel,
    bool useRootNavigator = true,
  }) {
    if (fullScreenOnCompact && context.windowSize.isCompact) {
      return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
        RouteTransition.route<T>(
          context: context,
          name: 'dialog',
          fullscreenDialog: true,
          style: TransitionStyle.modal,
          child: Builder(
            builder: (ctx) => Scaffold(
              appBar: AppBar(),
              body: builder(ctx),
            ),
          ),
        ),
      );
    }

    return showDialog<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      builder: (ctx) => _wrapResponsive(
        ctx,
        builder(ctx),
        maxWidth: (maxWidth ?? _kDialogMaxWidth).resolve(ctx),
        insets: (insets ?? _kDialogInsets).resolve(ctx),
        wrapChrome: true,
      ),
    );
  }

  /// Quick confirmation dialog.
  static Future<bool> confirm({
    BuildContext? context,
    required String title,
    String? message,
    String? confirmText,
    String? cancelText,
    bool isDestructive = false,
    DialogType type = DialogType.custom,
    IconData? icon,
  }) async {
    var confirmed = false;
    await show(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText ?? DialogStrings.confirm,
      cancelText: cancelText ?? CommonStrings.cancel,
      type: type,
      icon: icon,
      isDestructive: isDestructive,
      onConfirm: () => confirmed = true,
      onCancel: () => confirmed = false,
    );
    return confirmed;
  }

  /// Quick info dialog with just an OK button.
  static Future<void> info({
    BuildContext? context,
    required String title,
    String? message,
    String? buttonText,
  }) => show(
    context: context,
    title: title,
    message: message,
    type: DialogType.info,
    confirmText: buttonText ?? CommonStrings.ok,
    showCloseButton: false,
  );

  /// Quick success dialog.
  static Future<void> success({
    BuildContext? context,
    required String title,
    String? message,
    String? buttonText,
  }) => show(
    context: context,
    title: title,
    message: message,
    type: DialogType.success,
    confirmText: buttonText ?? CommonStrings.ok,
    showCloseButton: false,
  );

  /// Quick error dialog.
  static Future<void> error({
    BuildContext? context,
    required String title,
    String? message,
    String? buttonText,
  }) => show(
    context: context,
    title: title,
    message: message,
    type: DialogType.error,
    confirmText: buttonText ?? CommonStrings.ok,
    showCloseButton: false,
  );

  /// Quick warning dialog.
  static Future<void> warning({
    BuildContext? context,
    required String title,
    String? message,
    String? confirmText,
    String? cancelText,
  }) => show(
    context: context,
    title: title,
    message: message,
    type: DialogType.warning,
    confirmText: confirmText ?? CommonStrings.continueLabel,
    cancelText: cancelText ?? CommonStrings.cancel,
  );

  /// Auto-dismiss dialog — closes after duration with countdown.
  static Future<void> autoDismiss({
    BuildContext? context,
    required String title,
    String? message,
    DialogType type = DialogType.success,
    Duration duration = const Duration(seconds: 3),
    String? buttonText,
  }) => show(
    context: context,
    title: title,
    message: message,
    type: type,
    autoDismissDuration: duration,
    confirmText: buttonText,
    showCloseButton: false,
  );

  @override
  State<GlobalDialog> createState() => _GlobalDialogState();
}

class _GlobalDialogState extends State<GlobalDialog>
    with TickerProviderStateMixin {
  // Layout constants
  static const _horizontalPadding = 24.0;
  static const _topPaddingDefault = 24.0;
  static const _topPaddingWithHeader = 16.0;
  static const _contentTopPadding = 12.0;
  static const _actionsTopPadding = 20.0;
  static const _bottomPadding = 24.0;
  static const _dismissBarPadding = EdgeInsets.fromLTRB(24, 12, 24, 20);
  static const _dialogInsetPadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 24,
  );
  static const _iconContainerPadding = 8.0;
  static const _iconSize = 22.0;
  static const _iconContainerRadius = 10.0;
  static const _iconSpacing = 12.0;
  static const _closeButtonSpacing = 8.0;
  static const _contentSpacing = 16.0;
  static const _buttonRadius = 10.0;
  static const _buttonSpacing = 12.0;
  static const _progressBarHeight = 3.0;
  static const _countdownFontSize = 11.0;
  static const _countdownSpacing = 8.0;
  static const _borderTraceStrokeWidth = 3.0;
  static const _maxHeightFraction = 0.85;
  static const _iconBgOpacity = 0.1;
  static const _closeBgOpacity = 0.05;
  static const _countdownTextOpacity = 0.4;
  static const _progressBgOpacity = 0.1;
  static const _progressBarOpacity = 0.6;

  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;
  late Animation<Offset> _slideAnim;

  /// Materialized style — resolved once dependencies are available
  /// (needs Theme + MediaQuery, so initState is too early).
  late ResolvedDialogStyle _rs;
  var _resolved = false;

  // Auto-dismiss
  AnimationController? _dismissCtrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);

    // Start auto-dismiss timer if set. This countdown is semantic
    // (it measures wall-clock time until close) — reduced motion
    // does NOT collapse it.
    if (widget.autoDismissDuration != null) {
      _dismissCtrl = AnimationController(
        vsync: this,
        duration: widget.autoDismissDuration,
      );
      _dismissCtrl!.addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) _dismiss();
      });
      _dismissCtrl!.forward();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rs = widget.style.resolve(context);
    if (_resolved) return;
    _resolved = true;

    // Entrance animation — resolve() already collapses to
    // DialogAnimation.none + zero duration under reduced motion.
    _ctrl.duration = _rs.animationDuration;
    final curve = CurvedAnimation(parent: _ctrl, curve: _rs.animationCurve);

    switch (_rs.animation) {
      case DialogAnimation.scale:
        _scaleAnim = Tween(begin: 0.85, end: 1.0).animate(curve);
        _opacityAnim = Tween(begin: 0.0, end: 1.0).animate(curve);
        _slideAnim = ConstantTween(Offset.zero).animate(curve);
      case DialogAnimation.slideUp:
        _scaleAnim = ConstantTween(1.0).animate(curve);
        _opacityAnim = Tween(begin: 0.0, end: 1.0).animate(curve);
        _slideAnim = Tween(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(curve);
      case DialogAnimation.slideDown:
        _scaleAnim = ConstantTween(1.0).animate(curve);
        _opacityAnim = Tween(begin: 0.0, end: 1.0).animate(curve);
        _slideAnim = Tween(
          begin: const Offset(0, -0.15),
          end: Offset.zero,
        ).animate(curve);
      case DialogAnimation.fade:
        _scaleAnim = ConstantTween(1.0).animate(curve);
        _opacityAnim = Tween(begin: 0.0, end: 1.0).animate(curve);
        _slideAnim = ConstantTween(Offset.zero).animate(curve);
      case DialogAnimation.none:
        _scaleAnim = ConstantTween(1.0).animate(curve);
        _opacityAnim = ConstantTween(1.0).animate(curve);
        _slideAnim = ConstantTween(Offset.zero).animate(curve);
    }

    if (_rs.animation != DialogAnimation.none) _ctrl.forward();
  }

  @override
  void dispose() {
    _dismissCtrl?.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  void _onConfirm() {
    widget.onConfirm?.call();
    if (widget.autoDismissOnConfirm) _dismiss();
  }

  void _onCancel() {
    widget.onCancel?.call();
    _dismiss();
  }

  // ─── Resolve type-based defaults ──────────────────────────

  IconData? get _icon => widget.icon ?? _typeIcon;
  Color get _iconColor => _typeColor;

  IconData? get _typeIcon => switch (widget.type) {
    DialogType.info => Icons.info_rounded,
    DialogType.success => Icons.check_circle_rounded,
    DialogType.warning => Icons.warning_rounded,
    DialogType.error => Icons.error_rounded,
    DialogType.custom => null,
  };

  Color get _typeColor => switch (widget.type) {
    DialogType.info => context.statusColors.info,
    DialogType.success => context.statusColors.success,
    DialogType.warning => context.statusColors.warning,
    DialogType.error => context.statusColors.error,
    DialogType.custom => context.primaryColors.primary,
  };

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final rs = _rs;
    final text = context.textColors;
    final radius = rs.borderRadius;
    final useBorderTrace =
        _dismissCtrl != null &&
        rs.dismissIndicator == DismissIndicatorStyle.borderTrace;

    final titleTextStyle =
        rs.titleStyle ??
        context.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        );
    final messageTextStyle =
        rs.messageStyle ??
        context.textTheme.bodyMedium?.copyWith(
          color: text.secondary,
          height: 1.5,
        );

    // Fix #2: Compute canPop dynamically based on current loading state
    final isLoading = widget.isConfirmLoading || widget.isCancelLoading;

    // Fix #1: No Stack — close button is inline in the Row. Flexible works correctly in a plain Column.
    final dialogContent = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.headerWidget != null) widget.headerWidget!,

        // Icon + Title + Close (all inline)
        Padding(
          padding: EdgeInsets.fromLTRB(
            _horizontalPadding,
            widget.headerWidget != null
                ? _topPaddingWithHeader
                : _topPaddingDefault,
            _horizontalPadding,
            0,
          ),
          child: Row(
            children: [
              if (_icon != null) ...[
                GlobalIcon(
                  icon: _icon!,
                  style: IconStyle(
                    size: _iconSize,
                    color: _iconColor,
                    backgroundColor: _iconColor,
                    backgroundOpacity: _iconBgOpacity,
                    containerShape: IconContainerShape.rounded,
                    borderRadius: BorderRadius.circular(_iconContainerRadius),
                    padding: const EdgeInsets.all(_iconContainerPadding),
                  ),
                ),
                const SizedBox(width: _iconSpacing),
              ],
              Expanded(
                child:
                    widget.customTitle ??
                    GlobalText(
                      widget.title,
                      preset: TextPreset.titleLarge,
                      textStyle: GlobalTextStyle(
                        color: titleTextStyle?.color,
                        fontSize: titleTextStyle?.fontSize,
                        fontWeight: titleTextStyle?.fontWeight,
                      ),
                    ),
              ),
              if (widget.showCloseButton && !isLoading) ...[
                const SizedBox(width: _closeButtonSpacing),
                Semantics(
                  button: true,
                  label: CommonStrings.close,
                  // InkWell (not GestureDetector) — focusable, activates
                  // on Enter/Space, ripples on the dialog's ink host.
                  child: Material(
                    color: text.primary.withValues(alpha: _closeBgOpacity),
                    borderRadius: BorderRadius.circular(_iconContainerRadius),
                    child: InkWell(
                      onTap: () {
                        if (rs.enableHaptic) HapticFeedback.lightImpact();
                        _onCancel();
                      },
                      borderRadius: BorderRadius.circular(_iconContainerRadius),
                      child: Padding(
                        padding: const EdgeInsets.all(_iconContainerPadding),
                        child: Icon(
                          Icons.close_rounded,
                          size: _iconSize,
                          color: context.iconColors.secondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Message + Content
        if (widget.message != null || widget.content != null)
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                _horizontalPadding,
                _contentTopPadding,
                _horizontalPadding,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.message != null)
                    GlobalText(
                      widget.message!,
                      preset: TextPreset.bodyMedium,
                      textStyle: GlobalTextStyle(
                        color: messageTextStyle?.color,
                        fontSize: messageTextStyle?.fontSize,
                        fontWeight: messageTextStyle?.fontWeight,
                      ),
                    ),
                  if (widget.message != null && widget.content != null)
                    const SizedBox(height: _contentSpacing),
                  if (widget.content != null) widget.content!,
                ],
              ),
            ),
          ),

        // Actions
        if (widget.confirmText != null ||
            widget.cancelText != null ||
            widget.customActions != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              _horizontalPadding,
              _actionsTopPadding,
              _horizontalPadding,
              _bottomPadding,
            ),
            child: widget.customActions != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: widget.customActions!,
                  )
                : _buildActions(),
          ),

        // No actions — bottom padding
        if (widget.confirmText == null &&
            widget.cancelText == null &&
            widget.customActions == null &&
            _dismissCtrl == null)
          const SizedBox(height: _bottomPadding),

        // Progress bar countdown
        if (_dismissCtrl != null &&
            rs.dismissIndicator == DismissIndicatorStyle.progressBar)
          Padding(
            padding: _dismissBarPadding,
            child: AnimatedBuilder(
              animation: _dismissCtrl!,
              builder: (_, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GlobalProgress.linear(
                    value: 1 - _dismissCtrl!.value,
                    style: ProgressStyle(
                      thickness: _progressBarHeight,
                      color: _iconColor.withValues(alpha: _progressBarOpacity),
                      trackColor: context.backgroundColors.outline.withValues(
                        alpha: _progressBgOpacity,
                      ),
                      animated: false,
                    ),
                  ),
                  const SizedBox(height: _countdownSpacing),
                  Text(
                    DialogStrings.closingIn(
                      ((widget.autoDismissDuration!.inMilliseconds *
                                  (1 - _dismissCtrl!.value)) /
                              1000)
                          .ceil(),
                    ),
                    style: TextStyle(
                      fontSize: _countdownFontSize,
                      color: text.secondary.withValues(
                        alpha: _countdownTextOpacity,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );

    // Build the container with background/border support
    final shadow = rs.resolveShadow();

    // Ink host — splashes must paint above the opaque background,
    // not on the route's transparent backdrop behind it.
    final inkHost = Material(
      type: MaterialType.transparency,
      child: dialogContent,
    );

    Widget container;
    if (rs.borderGradient != null) {
      // Gradient border: outer gradient container + inner solid container
      container = Container(
        constraints: BoxConstraints(
          maxWidth: rs.maxWidth,
          maxHeight:
              rs.maxHeight ??
              MediaQuery.of(context).size.height * _maxHeightFraction,
        ),
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
          child: inkHost,
        ),
      );
    } else {
      container = Container(
        constraints: BoxConstraints(
          maxWidth: rs.maxWidth,
          maxHeight:
              rs.maxHeight ??
              MediaQuery.of(context).size.height * _maxHeightFraction,
        ),
        decoration: BoxDecoration(
          color: rs.backgroundGradient == null ? rs.backgroundColor : null,
          gradient: rs.backgroundGradient,
          borderRadius: radius,
          border: rs.border,
          boxShadow: shadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: inkHost,
      );
    }

    // Border trace countdown overlay
    if (useBorderTrace) {
      final traceColor = _iconColor;
      container = Stack(
        children: [
          container,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _dismissCtrl!,
                builder: (_, _) => CustomPaint(
                  painter: _BorderTracePainter(
                    progress: 1 - _dismissCtrl!.value,
                    color: traceColor,
                    strokeWidth: _borderTraceStrokeWidth,
                    borderRadius: radius,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return PopScope(
      canPop: isLoading ? false : widget.canPop,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: _dialogInsetPadding,
        child: SlideTransition(
          position: _slideAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: FadeTransition(opacity: _opacityAnim, child: container),
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        if (widget.cancelText != null)
          Expanded(
            child: GlobalOutlinedButton(
              text: widget.cancelText!,
              onPressed: widget.isCancelLoading ? null : _onCancel,
              isLoading: widget.isCancelLoading,
              style: ButtonStateStyle(
                borderRadius: BorderRadius.circular(_buttonRadius),
              ),
            ),
          ),
        if (widget.cancelText != null && widget.confirmText != null)
          const SizedBox(width: _buttonSpacing),
        if (widget.confirmText != null)
          Expanded(
            child: GlobalFilledButton(
              text: widget.confirmText!,
              onPressed: widget.isConfirmLoading ? null : _onConfirm,
              isLoading: widget.isConfirmLoading,
              style: ButtonStateStyle(
                borderRadius: BorderRadius.circular(_buttonRadius),
                backgroundColor: widget.isDestructive
                    ? context.statusColors.error
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}

/// Paints an animated border trace that follows the rounded rectangle path.
class _BorderTracePainter extends CustomPainter {
  _BorderTracePainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.borderRadius,
  });

  final double progress;
  final Color color;
  final double strokeWidth;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final rect = Offset.zero & size;
    final rrect = borderRadius
        .resolve(TextDirection.ltr)
        .toRRect(rect)
        .deflate(strokeWidth / 2);

    // Create the full rounded rect path
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().first;
    final totalLength = metrics.length;

    // Extract the portion to draw
    final drawLength = totalLength * progress.clamp(0.0, 1.0);
    final extractedPath = metrics.extractPath(0, drawLength);

    canvas.drawPath(
      extractedPath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_BorderTracePainter old) => old.progress != progress;
}
