import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const kToastBorderRadius = 100.0;
const kToastPaddingH = 14.0;
const kToastPaddingV = 10.0;

/// Trailing inset when a close button is present — smaller than the
/// leading one because the button brings its own tap padding.
const kToastPaddingEndWithClose = 4.0;
const kToastAnimDuration = AppDurations.normal;
const kToastAutoClose = Duration(seconds: 3);
const kToastIconEndPadding = 8.0;
const kToastCloseIconSize = 18.0;

/// PAINTED size of the close button. Its hit area is the module-wide
/// 48dp regardless — `MinTouchTarget` expands the target without
/// stretching the paint.
const kToastCloseButtonSize = 28.0;
const kToastCloseIconAlpha = 0.8;
const kToastCloseBgAlpha = 0.2;
const kToastActionSpacing = 8.0;
const kToastImageSize = 40.0;
const kToastImageRadius = 8.0;
const kToastMaxVisible = 5;
const kToastLoadingSize = 20.0;
const kToastLoadingStroke = 2.0;
const kToastBorderWidth = 1.5;
const kToastGradientBorderWidth = 2.0;

/// Vertical GAP between stacked toasts.
///
/// Was 68 when it had to stand in for a toast's whole height. Now that
/// each one reports its measured size, this is only the breathing room
/// between them — leaving it at 68 added a toast's height twice.
const kToastStackSpacing = 8.0;

/// Widest a toast grows before its text wraps — a full-bleed line of
/// text on a tablet is unreadable.
const kToastMaxWidth = 480.0;

/// Shadow depth under a toast.
const kToastElevation = 12.0;

/// Identifies the painted toast container, as distinct from its margin
/// box.
const kToastSurfaceKey = Key('toast-surface');

/// Thickness of the time-remaining bar.
const kToastProgressHeight = 3.0;

/// How far a toast travels on the way in, from its anchored edge.
const kToastEnterOffset = 40.0;

/// Floor for a toast that carries an ACTION.
///
/// WCAG 2.2.1 (Timing Adjustable): a control that disappears on a timer
/// fails anyone slow to read it. Three seconds is fine for a message
/// nobody has to act on and far too short for one they do — so anything
/// with an action gets at least this, and anything genuinely important
/// belongs in a `GlobalBanner` or a dialog instead.
const kToastActionMinDuration = Duration(seconds: 8);

/// Characters a reader gets through per second.
///
/// ~200 words per minute at ~5 characters a word, rounded down: the
/// point is a floor that is generous, not a stopwatch.
const kToastReadingCharsPerSecond = 14.0;

/// Never shorter than this, however brief the message.
const kToastMinReadDuration = kToastAutoClose;

/// Never longer than this from length alone — past it the message is
/// too big for a toast and belongs in a banner or a dialog.
const kToastMaxReadDuration = Duration(seconds: 10);

/// How long [text] plausibly takes to read, clamped to the range above.
///
/// A fixed three seconds is comfortable for "Saved" and far too short
/// for two lines of explanation — the reader gets the same time whether
/// there are eight characters or a hundred and eighty. Applies ONLY
/// when no duration was asked for: an explicit value, longer or
/// shorter, is the caller's decision.
Duration toastReadingDuration(String text) {
  if (text.isEmpty) return kToastMinReadDuration;
  final seconds = text.length / kToastReadingCharsPerSecond;
  final scaled = Duration(milliseconds: (seconds * 1000).round());
  if (scaled < kToastMinReadDuration) return kToastMinReadDuration;
  if (scaled > kToastMaxReadDuration) return kToastMaxReadDuration;
  return scaled;
}

// ---------------------------------------------------------------------------
// ToastType — severity, and the colour/icon that follow from it
// ---------------------------------------------------------------------------

/// Replaces the toast package's own type enum, which used to appear in
/// `GlobalToast.show`'s signature — a third-party symbol leaking into
/// this app's public API, which is why even the showcase had to import
/// the package.
enum ToastType {
  success(Icons.check_circle_outline_rounded),
  error(Icons.error_outline_rounded),
  warning(Icons.warning_amber_rounded),
  info(Icons.info_outline_rounded);

  const ToastType(this.icon);

  final IconData icon;
}

// ---------------------------------------------------------------------------
// ToastVariant — how the container is painted
// ---------------------------------------------------------------------------

enum ToastVariant {
  /// Solid severity colour, light foreground. The default.
  filled,

  /// Surface background with a severity-tinted icon.
  flat,

  /// Surface background with a severity-coloured border.
  outlined,

  /// No container at all — icon and text on the bare surface.
  minimal,

  /// Filled, but with a gradient derived from the severity colour
  /// rather than a flat fill. Same information, more presence — for
  /// apps that want their confirmations to feel less like plumbing.
  vivid,
}

// ---------------------------------------------------------------------------
// ToastHandle
// ---------------------------------------------------------------------------

/// A live toast, for closing it or holding its timer.
///
/// Callbacks rather than a reference to the entry, so nothing outside
/// the module can reach into the overlay's internals.
@immutable
class ToastHandle {
  const ToastHandle({
    required this.dismiss,
    required this.pause,
    required this.resume,
    required this.hasTimer,
  });

  /// Closes the toast with its exit animation.
  final VoidCallback dismiss;

  /// Holds the auto-close countdown — while hovered or held.
  final VoidCallback pause;

  /// Resumes it from where it stopped, not from the beginning.
  final VoidCallback resume;

  /// False for a persistent toast, which has nothing to pause.
  final bool Function() hasTimer;
}

// ---------------------------------------------------------------------------
// ToastLoadingType — matches button loading styles
// ---------------------------------------------------------------------------

enum ToastLoadingType {
  /// Standard circular spinner.
  circular,

  /// Linear progress line.
  linear,

  /// Bouncing dots.
  dots,

  /// Animated border trace around the toast.
  borderTrace,
}

// ---------------------------------------------------------------------------
// ToastPosition
// ---------------------------------------------------------------------------

enum ToastPosition {
  top(Alignment.topCenter),
  topLeft(Alignment.topLeft),
  topRight(Alignment.topRight),
  center(Alignment.center),
  bottom(Alignment.bottomCenter),
  bottomLeft(Alignment.bottomLeft),
  bottomRight(Alignment.bottomRight);

  const ToastPosition(this.alignment);
  final Alignment alignment;
}

// ---------------------------------------------------------------------------
// ToastPreset — reusable style bundles
// ---------------------------------------------------------------------------

class ToastPreset {
  const ToastPreset({
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
    this.borderRadius,
    this.padding,
    this.toastStyle,
    this.position,
    this.duration,
    this.animationDuration,
    this.showProgressBar,
    this.showCloseButton,
    this.dismissDirection,
    this.enableHaptic,
  });

  final Color? backgroundColor;
  final Color? foregroundColor;
  final Widget? icon;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final ToastVariant? toastStyle;
  final ToastPosition? position;
  final Duration? duration;
  final Duration? animationDuration;
  final bool? showProgressBar;
  final bool? showCloseButton;
  final DismissDirection? dismissDirection;
  final bool? enableHaptic;

  static const flat = ToastPreset(
    toastStyle: ToastVariant.flat,
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );

  static const outlined = ToastPreset(
    toastStyle: ToastVariant.outlined,
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );

  static const minimal = ToastPreset(
    toastStyle: ToastVariant.minimal,
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );

  static const snackbar = ToastPreset(
    position: ToastPosition.bottom,
    duration: Duration(seconds: 2),
    borderRadius: BorderRadius.all(Radius.circular(8)),
    toastStyle: ToastVariant.filled,
  );

  /// [ToastVariant.vivid] with the default geometry — the everyday
  /// toast, dressed up.
  static const vivid = ToastPreset(toastStyle: ToastVariant.vivid);

  static const banner = ToastPreset(
    position: ToastPosition.top,
    duration: Duration(seconds: 4),
    borderRadius: BorderRadius.all(Radius.circular(0)),
    toastStyle: ToastVariant.filled,
  );
}

// ---------------------------------------------------------------------------
// ToastStyle
// ---------------------------------------------------------------------------

/// Themeable styling bag for [GlobalToast] — EVERY field nullable.
///
/// Resolution order, materialized once per toast by `resolve`:
/// `caller > GlobalToastTheme.style > ToastStyle.defaults > tokens`.
///
/// Adding a themed field means touching five places: here, [mergedWith],
/// [copyWith], [ResolvedToastStyle] and `GlobalToastTheme.lerp`.
@immutable
class ToastStyle {
  const ToastStyle({
    this.variant,
    this.borderRadius,
    this.padding,
    this.margin,
    this.maxWidth,
    this.stackSpacing,
    this.elevation,
    this.successColor,
    this.errorColor,
    this.warningColor,
    this.infoColor,
    this.foregroundColor,
    this.titleStyle,
    this.descriptionStyle,
    this.iconSpacing,
    this.showCloseButton,
    this.position,
    this.duration,
    this.animationDuration,
    this.dismissDirection,
    this.enableHaptic,
    this.announce,
  });

  /// Compile-time floor. Severity colours are absent on purpose: they
  /// come from `context.statusColors` so a toast tracks the palette,
  /// role and brightness instead of freezing four hex values.
  static const ToastStyle defaults = ToastStyle(
    variant: ToastVariant.vivid,
    borderRadius: BorderRadius.all(Radius.circular(kToastBorderRadius)),
    // Asymmetric on purpose: the close button carries its own tap
    // padding, so matching the start inset on the end left a visible
    // gutter after the glyph.
    padding: EdgeInsetsDirectional.only(
      start: kToastPaddingH,
      end: kToastPaddingEndWithClose,
      top: kToastPaddingV,
      bottom: kToastPaddingV,
    ),
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    maxWidth: kToastMaxWidth,
    stackSpacing: kToastStackSpacing,
    elevation: kToastElevation,
    iconSpacing: kToastIconEndPadding,
    showCloseButton: true,
    position: ToastPosition.bottom,
    duration: kToastAutoClose,
    animationDuration: kToastAnimDuration,
    dismissDirection: DismissDirection.vertical,
    enableHaptic: false,
    announce: true,
  );

  final ToastVariant? variant;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  /// Gap between the toast and the screen edge.
  final EdgeInsetsGeometry? margin;

  /// Widest the toast grows before its text wraps.
  final double? maxWidth;

  /// Vertical gap between stacked toasts in the same pile.
  final double? stackSpacing;
  final double? elevation;

  final Color? successColor;
  final Color? errorColor;
  final Color? warningColor;
  final Color? infoColor;

  /// Null → derived from the variant: white on a filled severity
  /// background, the surface's own foreground otherwise.
  final Color? foregroundColor;

  final TextStyle? titleStyle;
  final TextStyle? descriptionStyle;

  /// Gap between the icon and the text.
  final double? iconSpacing;

  final bool? showCloseButton;
  final ToastPosition? position;
  final Duration? duration;
  final Duration? animationDuration;
  final DismissDirection? dismissDirection;
  final bool? enableHaptic;

  /// Announce the toast to assistive tech as a live region.
  ///
  /// On by default. A toast is the app's answer to "did that work?", and
  /// a message only sighted users receive is not an answer — this is the
  /// one behaviour a `SnackBar` had that a toast did not, and the reason
  /// swapping one for the other used to be an accessibility regression.
  final bool? announce;

  /// Field-by-field override — [other]'s non-null fields win.
  ToastStyle mergedWith(ToastStyle? other) {
    if (other == null) return this;
    return ToastStyle(
      variant: other.variant ?? variant,
      borderRadius: other.borderRadius ?? borderRadius,
      padding: other.padding ?? padding,
      margin: other.margin ?? margin,
      maxWidth: other.maxWidth ?? maxWidth,
      stackSpacing: other.stackSpacing ?? stackSpacing,
      elevation: other.elevation ?? elevation,
      successColor: other.successColor ?? successColor,
      errorColor: other.errorColor ?? errorColor,
      warningColor: other.warningColor ?? warningColor,
      infoColor: other.infoColor ?? infoColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      titleStyle: other.titleStyle ?? titleStyle,
      descriptionStyle: other.descriptionStyle ?? descriptionStyle,
      iconSpacing: other.iconSpacing ?? iconSpacing,
      showCloseButton: other.showCloseButton ?? showCloseButton,
      position: other.position ?? position,
      duration: other.duration ?? duration,
      animationDuration: other.animationDuration ?? animationDuration,
      dismissDirection: other.dismissDirection ?? dismissDirection,
      enableHaptic: other.enableHaptic ?? enableHaptic,
      announce: other.announce ?? announce,
    );
  }

  ToastStyle copyWith({
    ToastVariant? variant,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? maxWidth,
    double? stackSpacing,
    double? elevation,
    Color? successColor,
    Color? errorColor,
    Color? warningColor,
    Color? infoColor,
    Color? foregroundColor,
    TextStyle? titleStyle,
    TextStyle? descriptionStyle,
    double? iconSpacing,
    bool? showCloseButton,
    ToastPosition? position,
    Duration? duration,
    Duration? animationDuration,
    DismissDirection? dismissDirection,
    bool? enableHaptic,
    bool? announce,
  }) => ToastStyle(
    variant: variant ?? this.variant,
    borderRadius: borderRadius ?? this.borderRadius,
    padding: padding ?? this.padding,
    margin: margin ?? this.margin,
    maxWidth: maxWidth ?? this.maxWidth,
    stackSpacing: stackSpacing ?? this.stackSpacing,
    elevation: elevation ?? this.elevation,
    successColor: successColor ?? this.successColor,
    errorColor: errorColor ?? this.errorColor,
    warningColor: warningColor ?? this.warningColor,
    infoColor: infoColor ?? this.infoColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    titleStyle: titleStyle ?? this.titleStyle,
    descriptionStyle: descriptionStyle ?? this.descriptionStyle,
    iconSpacing: iconSpacing ?? this.iconSpacing,
    showCloseButton: showCloseButton ?? this.showCloseButton,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    animationDuration: animationDuration ?? this.animationDuration,
    dismissDirection: dismissDirection ?? this.dismissDirection,
    enableHaptic: enableHaptic ?? this.enableHaptic,
    announce: announce ?? this.announce,
  );
}

// ---------------------------------------------------------------------------
// ResolvedToastStyle
// ---------------------------------------------------------------------------

/// Materialized [ToastStyle] — every themed field non-null.
@immutable
class ResolvedToastStyle {
  const ResolvedToastStyle({
    required this.variant,
    required this.borderRadius,
    required this.padding,
    required this.margin,
    required this.maxWidth,
    required this.stackSpacing,
    required this.elevation,
    required this.successColor,
    required this.errorColor,
    required this.warningColor,
    required this.infoColor,
    required this.iconSpacing,
    required this.showCloseButton,
    required this.position,
    required this.duration,
    required this.animationDuration,
    required this.dismissDirection,
    required this.enableHaptic,
    required this.announce,
    this.foregroundColor,
    this.titleStyle,
    this.descriptionStyle,
  });

  final ToastVariant variant;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double maxWidth;
  final double stackSpacing;
  final double elevation;
  final Color successColor;
  final Color errorColor;
  final Color warningColor;
  final Color infoColor;
  final double iconSpacing;
  final bool showCloseButton;
  final ToastPosition position;
  final Duration duration;
  final Duration animationDuration;
  final DismissDirection dismissDirection;
  final bool enableHaptic;
  final bool announce;

  // Genuinely opt-in — absent means "derive it".
  final Color? foregroundColor;
  final TextStyle? titleStyle;
  final TextStyle? descriptionStyle;

  /// Severity colour for [type].
  Color colorFor(ToastType type) => switch (type) {
    ToastType.success => successColor,
    ToastType.error => errorColor,
    ToastType.warning => warningColor,
    ToastType.info => infoColor,
  };
}
