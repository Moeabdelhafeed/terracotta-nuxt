import 'dart:collection';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/strings/common_strings.dart';
import '../../../core/painters/gradient_border_painter.dart';
import '../../../core/theme/app_text_strut.dart';
import '../buttons/button_internals.dart';
import '../buttons/global_icon_button.dart';
import '../buttons/global_text_button.dart';
import '../progress/global_progress.dart';
import 'theme/toast_theme.dart';
import 'toast_models.dart';
import 'toast_overlay.dart';

export 'theme/toast_theme.dart';
export 'toast_models.dart';

// ---------------------------------------------------------------------------
// Toast
// ---------------------------------------------------------------------------

class GlobalToast {
  GlobalToast._();

  /// The navigator whose ROOT overlay toasts are inserted into.
  ///
  /// A `GlobalKey`, not the app's `NavigationService`: the module needs
  /// exactly one thing from it, and importing the service would drag a
  /// primitive module into the data layer. It used to be typed
  /// `dynamic` to dodge that, which bought the loose coupling at the
  /// price of every mistake becoming a runtime `debugPrint` instead of
  /// a compile error.
  ///
  /// Wired in bootstrap:
  /// `GlobalToast.navigatorKey = getIt<NavigationService>().navigatorKey;`
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Max visible toasts. The oldest is dismissed when exceeded.
  ///
  /// Counted from the overlay itself. A private tally used to shadow it
  /// and was only decremented on the normal dismissal path — so a toast
  /// removed with its route left the count high, and once it reached
  /// this number EVERY new toast cleared the screen.
  static int maxVisible = kToastMaxVisible;

  /// When true, toasts queue instead of stacking.
  static bool queueMode = false;

  static final Queue<VoidCallback> _queue = Queue<VoidCallback>();

  // ─── Core show method ──────────────────────────────────────

  static ToastHandle? show({
    String? title,
    String? description,
    Widget? titleWidget,
    Widget? descriptionWidget,
    required ToastType type,
    ToastPreset? preset,
    ToastPosition? position,
    Duration? duration,
    Duration? animationDuration,
    bool? showProgressBar,
    bool? showCloseButton,
    Widget? icon,
    Widget? image,
    Widget? action,
    VoidCallback? onAction,
    String? actionLabel,
    VoidCallback? onDismiss,
    VoidCallback? onTap,
    DismissDirection? dismissDirection,
    ToastVariant? style,
    ToastStyle? toastStyle,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
    Color? foregroundColor,
    Gradient? backgroundGradient,
    Color? borderColor,
    Gradient? borderGradient,
    double? borderWidth,
    bool persistent = false,
    bool enableHaptic = false,
    ToastLoadingType? loadingType,
    Color? borderTraceColor,
  }) {
    // Runtime check — works in both debug and release
    if (navigatorKey == null) {
      debugPrint('GlobalToast.navigatorKey was never set — see bootstrap.');
      return null;
    }
    assert(
      title != null || titleWidget != null,
      'Either title or titleWidget required.',
    );

    // The ROOT overlay: a toast raised from inside a dialog belongs
    // above it, not buried by it.
    final overlayState = navigatorKey?.currentState?.overlay;
    if (overlayState == null) return null;

    // Everything the call actually does, as a closure so queue mode
    // can defer it without re-listing the signature.
    ToastHandle? present() {
      // Make room by dropping the OLDEST, which is what the knob has
      // always claimed. It used to clear the screen entirely.
      if (ToastOverlay.visible.length >= maxVisible) {
        ToastOverlay.dismissOldest();
      }

      // Materialized ONCE: caller > theme > defaults, then colours and
      // metrics from the palette and tokens. Everything below reads `rs`
      // instead of re-deriving a fallback per field.
      final context = overlayState.context;
      final rs = (toastStyle ?? const ToastStyle()).resolve(context);

      final p = preset;
      final effPosition = position ?? p?.position ?? rs.position;
      // The message as a screen reader would read it — used both for the
      // announcement and for how long the toast stays up.
      final spoken = [title, description].whereType<String>().join('. ');
      final hasAction =
          action != null || (actionLabel != null && onAction != null);
      // An explicit duration — caller or preset — is a decision and is
      // honoured. With none, the time scales with how much there is to
      // read: a fixed three seconds gave "Saved" and a two-line
      // explanation exactly the same window.
      final asked = duration ?? p?.duration;
      var effDuration = persistent
          ? Duration.zero
          : (asked ?? toastReadingDuration(spoken));
      // WCAG 2.2.1: a control that vanishes on a timer fails anyone slow
      // to read it, so an action-bearing toast gets a floor. An explicit
      // longer duration is respected; an explicitly SHORTER one is not.
      if (hasAction && !persistent && effDuration < kToastActionMinDuration) {
        effDuration = kToastActionMinDuration;
      }
      final effAnimDuration =
          animationDuration ?? p?.animationDuration ?? rs.animationDuration;
      final effShowProgress = showProgressBar ?? p?.showProgressBar ?? false;
      final effShowClose =
          showCloseButton ?? p?.showCloseButton ?? rs.showCloseButton;
      final effDismissDir =
          dismissDirection ?? p?.dismissDirection ?? rs.dismissDirection;
      final effStyle = style ?? p?.toastStyle ?? rs.variant;
      final effRadius = borderRadius ?? p?.borderRadius ?? rs.borderRadius;
      final effPadding = padding ?? p?.padding ?? rs.padding;
      final effHaptic = enableHaptic || (p?.enableHaptic ?? rs.enableHaptic);
      final effBg = backgroundColor ?? p?.backgroundColor;
      final effFg = foregroundColor ?? p?.foregroundColor ?? rs.foregroundColor;

      // Haptic
      if (effHaptic) {
        switch (type) {
          case ToastType.error:
            HapticFeedback.heavyImpact();
          case ToastType.warning:
            HapticFeedback.mediumImpact();
          case ToastType.success:
          case ToastType.info:
            HapticFeedback.lightImpact();
        }
      }

      // The one thing a SnackBar did that a toast did not: tell assistive
      // tech. Without it a message only sighted users receive is not an
      // answer to "did that work?", and swapping SnackBar for toast is an
      // accessibility regression rather than an upgrade.
      if (rs.announce) {
        if (spoken.isNotEmpty) {
          SemanticsService.sendAnnouncement(
            View.of(context),
            spoken,
            Directionality.maybeOf(context) ?? TextDirection.ltr,
            // An error interrupts; anything else waits its turn rather
            // than talking over what the user is already hearing.
            assertiveness: type == ToastType.error
                ? Assertiveness.assertive
                : Assertiveness.polite,
          );
        }
      }

      // A plain Text, NOT a GlobalText: GlobalText resolves a colour from
      // the type scale and pins it, which beat the surface's own
      // DefaultTextStyle and left dark text on a saturated background.
      // The strut still comes along, so metrics stay standardized.
      final effTitle =
          titleWidget ??
          Text(title!, strutStyle: AppTextStrut.forStyle(rs.titleStyle));

      final effDescription = _buildDescription(
        description: description,
        descriptionWidget: descriptionWidget,
        image: image,
        action: action,
        actionLabel: actionLabel,
        onAction: onAction,
        foregroundColor: effFg,
      );

      final effIcon = _buildIcon(
        icon: icon,
        presetIcon: p?.icon,
        type: type,
        loadingType: loadingType,
        foregroundColor: effFg,
      );

      final hasBorderTrace = loadingType == ToastLoadingType.borderTrace;
      // One renderer for every variant. There used to be two — a custom
      // path for gradients and the package's built-in container for
      // everything else — which meant a change to padding or the close
      // button had to be made twice and stayed right only by luck.
      final surface = _ToastSurface(
        resolved: rs,
        variant: effStyle,
        type: type,
        backgroundColor: effBg,
        foregroundColor: effFg,
        backgroundGradient: backgroundGradient,
        borderColor: borderColor,
        borderGradient: borderGradient,
        borderWidth: borderWidth,
        borderRadius: effRadius,
        padding: effPadding,
        showBorderTrace: hasBorderTrace,
        borderTraceColor: borderTraceColor,
      );

      return ToastOverlay.show(
        overlay: overlayState,
        alignment: effPosition.alignment,
        stackSpacing: rs.stackSpacing,
        showProgress: effShowProgress,
        duration: effDuration,
        animationDuration: effAnimDuration,
        onDismissed: () => _onToastDismissed(onDismiss),
        builder: (context, handle, animation) => Semantics(
          // The announcement SPEAKS the toast once; this makes it an
          // object. Without a node the message could not be focused,
          // re-read, or dismissed — the swipe and the close button were
          // sighted-only affordances.
          //
          // NOT a liveRegion: that would re-announce on every rebuild,
          // and the announcement above already handles the one-time
          // reading with the right assertiveness.
          container: true,
          label: spoken.isEmpty ? null : spoken,
          onDismiss: handle.dismiss,
          child: _SafeToastShell(
            handle: handle,
            dismissDirection: effDismissDir,
            onTap: onTap,
            child: surface.build(
              context,
              // Built once above, not per rebuild: a spinner icon would
              // otherwise restart every time the toast repaints.
              icon: effIcon,
              title: effTitle,
              description: effDescription,
              showCloseButton: effShowClose,
              onClose: handle.dismiss,
              progress: effShowProgress ? animation : null,
            ),
          ),
        ),
      );
    }

    // Queue mode defers the WHOLE call as a closure.
    //
    // It used to re-invoke `show` with all thirty parameters listed by
    // hand, and the copy had already fallen behind: `toastStyle` was
    // added and never forwarded, so a queued toast silently lost its
    // style bag. A closure captures whatever the signature happens to
    // be, so the drift cannot come back.
    if (queueMode && ToastOverlay.visible.isNotEmpty) {
      _queue.add(present);
      return null;
    }
    return present();
  }

  // ─── Description builder ───────────────────────────────────

  static Widget? _buildDescription({
    String? description,
    Widget? descriptionWidget,
    Widget? image,
    Widget? action,
    String? actionLabel,
    VoidCallback? onAction,
    Color? foregroundColor,
  }) {
    final hasDesc = description != null || descriptionWidget != null;
    final hasAction =
        action != null || (actionLabel != null && onAction != null);
    final hasImage = image != null;

    if (!hasDesc && !hasAction && !hasImage) return null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Plain Text for the same reason as the title — it must take
        // the foreground the surface decided on.
        if (hasDesc) descriptionWidget ?? Text(description!),
        if (hasImage) ...[
          if (hasDesc) const SizedBox(height: kToastActionSpacing),
          ClipRRect(
            borderRadius: BorderRadius.circular(kToastImageRadius),
            child: SizedBox(
              width: kToastImageSize,
              height: kToastImageSize,
              child: image,
            ),
          ),
        ],
        if (hasAction) ...[
          const SizedBox(height: kToastActionSpacing),
          action ??
              // The app's own button, not Material's. `link: true` is
              // exactly this shape: an inline action inside running
              // text, underlined, with no box of its own — and it
              // brings the module's focus and touch-target behaviour,
              // which a bare TextButton did not.
              GlobalTextButton(
                text: actionLabel!,
                onPressed: () => onAction?.call(),
                link: true,
                shrinkWidth: true,
                style: ButtonStateStyle(
                  foregroundColor: foregroundColor ?? Colors.white,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
        ],
      ],
    );
  }

  // ─── Dismiss handler (safe) ────────────────────────────────

  static void _onToastDismissed(VoidCallback? onDismiss) {
    if (onDismiss != null) {
      try {
        onDismiss();
      } catch (e) {
        debugPrint('Toast onDismiss error: $e');
      }
    }

    if (queueMode && _queue.isNotEmpty) {
      try {
        _queue.removeFirst()();
      } catch (e) {
        debugPrint('Toast queue error: $e');
      }
    }
  }

  static void _dismissAllInternal() => ToastOverlay.dismissAll();

  // ─── Icon builder ──────────────────────────────────────────

  /// The icon only. Spacing around it is the SURFACE's job — baking a
  /// trailing pad in here meant a preset could restyle the icon but
  /// never move it.
  /// The glyph only — no colour, no spacing.
  ///
  /// Both used to be baked in here. A colour on the `Icon` BEATS the
  /// surface's `IconTheme`, so a flat or outlined toast still got the
  /// white glyph meant for a saturated fill and it vanished against the
  /// surface. The variant decides the colour, so the surface does.
  ///
  /// [foregroundColor] survives only for the loading indicators, which
  /// take a colour rather than reading `IconTheme`. Null lets them fall
  /// back to the ambient icon colour the surface set.
  static Widget _buildIcon({
    Widget? icon,
    Widget? presetIcon,
    required ToastType type,
    ToastLoadingType? loadingType,
    Color? foregroundColor,
  }) {
    if (loadingType == null) {
      return icon ?? presetIcon ?? Icon(type.icon);
    }
    return Builder(
      builder: (context) {
        final color =
            foregroundColor ?? IconTheme.of(context).color ?? Colors.white;
        return switch (loadingType) {
          ToastLoadingType.circular => CircularIndicator(
            color: color.withValues(alpha: 0.8),
          ),
          ToastLoadingType.linear => LinearIndicator(color: color),
          ToastLoadingType.dots => DotsIndicator(color: color),
          // The trace paints around the CONTAINER, so the slot keeps the
          // ordinary severity glyph.
          ToastLoadingType.borderTrace => Icon(type.icon),
        };
      },
    );
  }

  // ─── Backwards-compatible call() ───────────────────────────

  static void call({
    required String title,
    String? description,
    required ToastType type,
    ToastPosition position = ToastPosition.bottom,
    Duration? duration,
    Duration? animationDuration,
    bool showProgressBar = false,
    bool showCloseButton = true,
    Widget? icon,
    VoidCallback? onDismiss,
    DismissDirection dismissDirection = DismissDirection.vertical,
    ToastVariant style = ToastVariant.filled,
  }) {
    show(
      title: title,
      description: description,
      type: type,
      position: position,
      duration: duration,
      animationDuration: animationDuration,
      showProgressBar: showProgressBar,
      showCloseButton: showCloseButton,
      icon: icon,
      onDismiss: onDismiss,
      dismissDirection: dismissDirection,
      style: style,
    );
  }

  // ─── Convenience methods ───────────────────────────────────

  static ToastHandle? success(
    String title, {
    String? description,
    ToastPosition position = ToastPosition.bottom,
    Duration? duration,
    VoidCallback? onDismiss,
    ToastPreset? preset,
    String? actionLabel,
    VoidCallback? onAction,
    bool enableHaptic = false,
  }) => show(
    title: title,
    description: description,
    type: ToastType.success,
    position: position,
    duration: duration,
    onDismiss: onDismiss,
    preset: preset,
    actionLabel: actionLabel,
    onAction: onAction,
    enableHaptic: enableHaptic,
  );

  static ToastHandle? error(
    String title, {
    String? description,
    ToastPosition position = ToastPosition.bottom,
    Duration? duration,
    VoidCallback? onDismiss,
    ToastPreset? preset,
    String? actionLabel,
    VoidCallback? onAction,
    bool enableHaptic = false,
  }) => show(
    title: title,
    description: description,
    type: ToastType.error,
    position: position,
    duration: duration,
    onDismiss: onDismiss,
    preset: preset,
    actionLabel: actionLabel,
    onAction: onAction,
    enableHaptic: enableHaptic,
  );

  static ToastHandle? warning(
    String title, {
    String? description,
    ToastPosition position = ToastPosition.bottom,
    Duration? duration,
    VoidCallback? onDismiss,
    ToastPreset? preset,
    String? actionLabel,
    VoidCallback? onAction,
    bool enableHaptic = false,
  }) => show(
    title: title,
    description: description,
    type: ToastType.warning,
    position: position,
    duration: duration,
    onDismiss: onDismiss,
    preset: preset,
    actionLabel: actionLabel,
    onAction: onAction,
    enableHaptic: enableHaptic,
  );

  static ToastHandle? info(
    String title, {
    String? description,
    ToastPosition position = ToastPosition.bottom,
    Duration? duration,
    VoidCallback? onDismiss,
    ToastPreset? preset,
    String? actionLabel,
    VoidCallback? onAction,
    bool enableHaptic = false,
  }) => show(
    title: title,
    description: description,
    type: ToastType.info,
    position: position,
    duration: duration,
    onDismiss: onDismiss,
    preset: preset,
    actionLabel: actionLabel,
    onAction: onAction,
    enableHaptic: enableHaptic,
  );

  // ─── Special toasts ────────────────────────────────────────

  static ToastHandle? loading(
    String title, {
    String? description,
    ToastPosition position = ToastPosition.bottom,
    Color? spinnerColor,
  }) => show(
    title: title,
    description: description,
    type: ToastType.info,
    position: position,
    persistent: true,
    showCloseButton: false,
    showProgressBar: true,
    icon: SizedBox(
      width: kToastLoadingSize,
      height: kToastLoadingSize,
      child: GlobalProgress.loading(
        type: ProgressType.circular,
        style: ProgressStyle(
          thickness: kToastLoadingStroke,
          color: spinnerColor,
        ),
      ),
    ),
  );

  static ToastHandle? undo(
    String title, {
    required VoidCallback onUndo,
    String? description,
    Duration duration = const Duration(seconds: 5),
    ToastPosition position = ToastPosition.bottom,
  }) => show(
    title: title,
    description: description,
    type: ToastType.info,
    position: position,
    duration: duration,
    showProgressBar: true,
    actionLabel: CommonStrings.undo,
    onAction: onUndo,
  );

  static ToastHandle? custom({
    required String title,
    String? description,
    required Widget icon,
    required Color backgroundColor,
    Color foregroundColor = Colors.white,
    ToastPosition position = ToastPosition.bottom,
    Duration? duration,
    VoidCallback? onDismiss,
    ToastPreset? preset,
  }) => show(
    title: title,
    description: description,
    type: ToastType.info,
    icon: icon,
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    position: position,
    duration: duration,
    onDismiss: onDismiss,
    preset: preset,
  );

  static ToastHandle? withImage({
    required String title,
    String? description,
    required Widget image,
    ToastType type = ToastType.info,
    ToastPosition position = ToastPosition.bottom,
    Duration? duration,
  }) => show(
    title: title,
    description: description,
    type: type,
    position: position,
    duration: duration,
    image: image,
  );

  // ─── Short aliases (backwards compatible) ──────────────────

  static void s(String title, {BuildContext? context, String? description}) =>
      success(title, description: description);
  static void e(String title, {BuildContext? context, String? description}) =>
      error(title, description: description);
  static void w(String title, {BuildContext? context, String? description}) =>
      warning(title, description: description);
  static void i(String title, {BuildContext? context, String? description}) =>
      info(title, description: description);

  // ─── Control ───────────────────────────────────────────────

  /// Closes everything and drops anything still queued.
  static void dismissAll() {
    _dismissAllInternal();
    _queue.clear();
  }

  /// Closes one toast — the `ScaffoldMessenger.removeCurrentSnackBar`
  /// shape, but for a specific toast rather than whatever is on top.
  static void dismiss(ToastHandle? handle) => ToastOverlay.dismiss(handle);

  /// Closes the most recent toast only. Mirrors
  /// `ScaffoldMessenger.hideCurrentSnackBar`.
  static void hideCurrent() => ToastOverlay.dismissCurrent();
}

// ---------------------------------------------------------------------------
// Toast surface — the ONE renderer
// ---------------------------------------------------------------------------

/// Paints the toast container for every variant.
///
/// There used to be two renderers: a custom one for gradients and the
/// toast package's built-in container for everything else. A change to
/// padding, to the close button or to the text styles had to be made in
/// both, and stayed identical only by luck. This is the single one.
@immutable
class _ToastSurface {
  const _ToastSurface({
    required this.resolved,
    required this.variant,
    required this.type,
    required this.borderRadius,
    required this.padding,
    this.backgroundColor,
    this.foregroundColor,
    this.backgroundGradient,
    this.borderColor,
    this.borderGradient,
    this.borderWidth,
    this.showBorderTrace = false,
    this.borderTraceColor,
  });

  final ResolvedToastStyle resolved;
  final ToastVariant variant;
  final ToastType type;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Gradient? backgroundGradient;
  final Color? borderColor;
  final Gradient? borderGradient;
  final double? borderWidth;
  final bool showBorderTrace;
  final Color? borderTraceColor;

  Widget build(
    BuildContext context, {
    required Widget icon,
    required Widget title,
    Widget? description,
    required bool showCloseButton,
    required VoidCallback onClose,
    Animation<double>? progress,
  }) {
    final scheme = Theme.of(context).colorScheme;
    // From the palette via the resolved bag, so a role or brightness
    // change moves it — the old hard-coded quartet could not.
    final severity = resolved.colorFor(type);

    // Variant decides the background, and the background decides the
    // foreground: the saturated fills put text on the severity colour,
    // where the surface's own foreground would vanish.
    final background = switch (variant) {
      ToastVariant.filled => backgroundColor ?? severity,
      // `vivid` paints a gradient instead — a flat colour underneath
      // would only show through at the corners.
      ToastVariant.vivid => backgroundColor,
      ToastVariant.flat ||
      ToastVariant.outlined => backgroundColor ?? scheme.surface,
      ToastVariant.minimal => backgroundColor,
    };

    // DERIVED from the severity rather than configured, so `vivid`
    // tracks the palette exactly like every other variant. Lifted
    // toward the leading edge and deepened at the trailing one so it
    // reads as a sheen, not as two toasts joined together.
    final effectiveGradient =
        backgroundGradient ??
        (variant == ToastVariant.vivid
            ? LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [
                  Color.lerp(severity, Colors.white, 0.22)!,
                  severity,
                  Color.lerp(severity, Colors.black, 0.16)!,
                ],
              )
            : null);

    final foreground =
        foregroundColor ??
        switch (variant) {
          ToastVariant.filled || ToastVariant.vivid => Colors.white,
          _ => scheme.onSurface,
        };

    final BoxBorder? border = borderColor != null
        ? Border.all(
            color: borderColor!,
            width: borderWidth ?? kToastBorderWidth,
          )
        : variant == ToastVariant.outlined
        ? Border.all(color: severity, width: borderWidth ?? kToastBorderWidth)
        : null;

    // The close button centres an 18dp glyph in a 48dp touch target, so
    // it already contributes (48 - 18) / 2 of empty space at the end.
    // Subtracting that from the trailing inset makes the two gaps equal
    // BY CONSTRUCTION rather than by a tuned constant that drifts the
    // moment either size changes.
    //
    // The subtraction has to happen in DIRECTIONAL space. Resolving
    // first and then writing `right:` pinned the shrunken inset to the
    // physical right — which in Arabic is the LEADING edge, so the icon
    // sat flush against the toast's start while the close button kept
    // the full inset.
    final direction = Directionality.of(context);
    final resolvedPadding = padding.resolve(direction);
    final startPad = direction == TextDirection.rtl
        ? resolvedPadding.right
        : resolvedPadding.left;
    final closeInset = showCloseButton
        ? (kMinTouchTarget - kToastCloseIconSize) / 2
        : 0.0;
    final effectivePadding = EdgeInsetsDirectional.fromSTEB(
      startPad,
      resolvedPadding.top,
      (startPad - closeInset).clamp(0.0, double.infinity),
      resolvedPadding.bottom,
    );

    Widget content = Container(
      // Keyed so a test can measure the PAINTED edges: the gaps must
      // stay balanced, and the close button's hit box makes that
      // impossible to eyeball from the padding value alone.
      key: kToastSurfaceKey,
      padding: effectivePadding,
      decoration: BoxDecoration(
        gradient: effectiveGradient,
        color: effectiveGradient != null ? null : background,
        borderRadius: borderRadius,
        border: borderGradient == null ? border : null,
        // A bare `minimal` toast has no surface to cast a shadow.
        boxShadow: variant == ToastVariant.minimal && background == null
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: resolved.elevation,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconTheme.merge(
            data: IconThemeData(
              color: switch (variant) {
                ToastVariant.filled || ToastVariant.vivid => foreground,
                _ => severity,
              },
            ),
            child: icon,
          ),
          SizedBox(width: resolved.iconSpacing),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // THE THEME'S STYLE, then the toast's overrides.
                //
                // A bare `TextStyle` REPLACES the inherited one rather
                // than merging with it — so the app's typeface went
                // with it and every toast in the app rendered in the
                // platform default while the screen behind it was in
                // Kufam. Starting from `bodyMedium` keeps the family
                // and the scale; the size and weight below are still
                // the toast's own.
                DefaultTextStyle(
                  style:
                      (resolved.titleStyle ??
                              (Theme.of(context).textTheme.bodyMedium ??
                                      const TextStyle())
                                  .copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ))
                          .copyWith(color: foreground),
                  child: title,
                ),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  DefaultTextStyle(
                    style:
                        (resolved.descriptionStyle ??
                                (Theme.of(context).textTheme.bodySmall ??
                                        const TextStyle())
                                    .copyWith(fontSize: 12))
                            .copyWith(color: foreground.withValues(alpha: 0.8)),
                    child: description,
                  ),
                ],
              ],
            ),
          ),
          if (showCloseButton)
            // The app's own button, not Material's: it carries the
            // module's focus, hover and 48dp-target behaviour, and a
            // raw IconButton here was the one control in the app that
            // did not.
            GlobalIconButton(
              onPressed: onClose,
              iconData: Icons.close_rounded,
              iconSize: kToastCloseIconSize,
              tooltip: CommonStrings.close,
              style: ButtonStateStyle(
                foregroundColor: foreground.withValues(
                  alpha: kToastCloseIconAlpha,
                ),
                backgroundColor: Colors.transparent,
                width: kToastCloseButtonSize,
              ),
            ),
        ],
      ),
    );

    if (progress != null) {
      // Inside the container and clipped to its shape — a bar appended
      // BELOW it sat outside the rounded edge and read as a separate,
      // differently-coloured object.
      //
      // It DRAINS: the life animation runs 0 → 1 over the toast's
      // lifetime, so what is left is `1 - value`. Wrapped in an
      // AnimatedBuilder because the toast itself does not rebuild as
      // that animation ticks.
      content = Stack(
        children: [
          content,
          Positioned.fill(
            child: ClipRRect(
              borderRadius: borderRadius,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedBuilder(
                  animation: progress,
                  builder: (context, _) => GlobalProgress.linear(
                    value: 1 - progress.value,
                    style: ProgressStyle(
                      thickness: kToastProgressHeight,
                      trackColor: Colors.transparent,
                      color: foreground.withValues(alpha: 0.55),
                      capStyle: ProgressCapStyle.flat,
                      animated: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      margin: resolved.margin,
      constraints: BoxConstraints(maxWidth: resolved.maxWidth),
      child: Stack(
        children: [
          content,
          if (borderGradient != null)
            Positioned.fill(
              child: CustomPaint(
                painter: GradientBorderPainter(
                  gradient: borderGradient!,
                  borderRadius: borderRadius,
                  borderWidth: borderWidth ?? kToastGradientBorderWidth,
                ),
              ),
            ),
          if (showBorderTrace)
            Positioned.fill(
              child: BorderLoadingOverlay(
                color: borderTraceColor ?? severity,
                borderRadius: borderRadius,
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gradient border painter
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Safe toast shell
// ---------------------------------------------------------------------------

/// Pause-on-hover/press and swipe-to-dismiss around a toast body.
///
/// It stops building the `Dismissible` the moment a swipe completes.
/// Keeping one alive through the exit animation is what makes Flutter
/// assert "A dismissed Dismissible widget is still part of the tree" —
/// the toast is still on screen for the length of its exit, so its
/// element keeps rebuilding after the dismissal finished. Changing the
/// widget type instead unmounts that element and leaves the departing
/// toast inert.
///
/// Pausing is guarded the same way: a toast on its way out must never
/// have its countdown restarted, since the only thing left for that
/// timer to do is fire into nothing.
class _SafeToastShell extends StatefulWidget {
  const _SafeToastShell({
    required this.handle,
    required this.dismissDirection,
    required this.child,
    this.onTap,
  });

  final ToastHandle handle;
  final DismissDirection dismissDirection;
  final VoidCallback? onTap;
  final Widget child;

  @override
  State<_SafeToastShell> createState() => _SafeToastShellState();
}

class _SafeToastShellState extends State<_SafeToastShell> {
  double _swipeProgress = 0;
  bool _dismissed = false;

  /// Runs the tap and closes the toast.
  ///
  /// Acting on a message that stays on screen reads as "nothing
  /// happened" — the notification the user just opened is still sitting
  /// over the thing it opened.
  void _handleTap() {
    if (_dismissed) return;
    widget.onTap!();
    widget.handle.dismiss();
  }

  @override
  Widget build(BuildContext context) {
    Widget toast = Opacity(
      opacity: 1 - _swipeProgress,
      child: widget.child,
    );

    if (widget.onTap != null) {
      // `translucent`, and BELOW the close button and action in the
      // tree, so those win their own taps — the deepest hit-test target
      // takes the gesture, and closing a notification must not also
      // open it.
      //
      // Placed inside the swipe shell rather than around it. Both
      // arrangements pass the swipe test, so this is not load-bearing
      // against the gesture arena; it keeps the tap next to the other
      // pointer handling instead of stacking another layer above it.
      toast = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _handleTap,
        child: toast,
      );
    }

    if (widget.handle.hasTimer()) {
      toast = MouseRegion(
        onEnter: (_) => widget.handle.pause(),
        onExit: (_) {
          // Never restart a toast already on its way out — that would
          // re-arm a timer whose only job left is to fire into nothing.
          if (!_dismissed) widget.handle.resume();
        },
        child: toast,
      );
    }

    if (widget.dismissDirection == DismissDirection.none || _dismissed) {
      return toast;
    }

    return Listener(
      // Touch-hold pauses the countdown; the mouse case is the hover
      // region above.
      onPointerDown: (event) {
        if (event.kind == PointerDeviceKind.mouse) return;
        widget.handle.pause();
      },
      onPointerUp: (event) {
        if (event.kind == PointerDeviceKind.mouse) return;
        if (!_dismissed) widget.handle.resume();
      },
      child: Dismissible(
        key: const ValueKey('toast-dismiss'),
        direction: widget.dismissDirection,
        behavior: HitTestBehavior.deferToChild,
        onUpdate: (details) =>
            setState(() => _swipeProgress = details.progress),
        onDismissed: (_) {
          _dismissed = true;
          // No exit animation: the swipe already carried it off screen,
          // and animating it away again reads as a stutter.
          ToastOverlay.dismiss(widget.handle, animate: false);
        },
        child: toast,
      ),
    );
  }
}
