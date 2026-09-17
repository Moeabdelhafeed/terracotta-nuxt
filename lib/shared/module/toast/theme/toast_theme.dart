import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/responsive/extensions.dart';
import '../../../../core/tokens/extensions.dart';
import '../toast_models.dart';

/// App-wide defaults for [GlobalToast].
///
/// The rebrand hook: set the toast's shape, spacing and severity colours
/// once here and every message in the app follows.
@immutable
class GlobalToastTheme extends ThemeExtension<GlobalToastTheme> {
  const GlobalToastTheme({this.style});

  final ToastStyle? style;

  static GlobalToastTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalToastTheme>();

  @override
  GlobalToastTheme copyWith({ToastStyle? style}) =>
      GlobalToastTheme(style: style ?? this.style);

  @override
  GlobalToastTheme lerp(ThemeExtension<GlobalToastTheme>? other, double t) {
    if (other is! GlobalToastTheme) return this;
    return GlobalToastTheme(style: _lerpStyle(style, other.style, t));
  }

  /// Continuous fields interpolate; discrete ones snap at the midpoint —
  /// half a variant is not a thing, and a half-swapped one would rebuild
  /// the container differently mid-animation.
  static ToastStyle? _lerpStyle(ToastStyle? a, ToastStyle? b, double t) {
    if (a == null && b == null) return null;
    final pick = t < 0.5 ? a : b;
    return ToastStyle(
      variant: pick?.variant,
      borderRadius: BorderRadius.lerp(a?.borderRadius, b?.borderRadius, t),
      padding: EdgeInsetsGeometry.lerp(a?.padding, b?.padding, t),
      margin: EdgeInsetsGeometry.lerp(a?.margin, b?.margin, t),
      maxWidth: lerpDouble(a?.maxWidth, b?.maxWidth, t),
      stackSpacing: lerpDouble(a?.stackSpacing, b?.stackSpacing, t),
      elevation: lerpDouble(a?.elevation, b?.elevation, t),
      successColor: Color.lerp(a?.successColor, b?.successColor, t),
      errorColor: Color.lerp(a?.errorColor, b?.errorColor, t),
      warningColor: Color.lerp(a?.warningColor, b?.warningColor, t),
      infoColor: Color.lerp(a?.infoColor, b?.infoColor, t),
      foregroundColor: Color.lerp(a?.foregroundColor, b?.foregroundColor, t),
      titleStyle: TextStyle.lerp(a?.titleStyle, b?.titleStyle, t),
      descriptionStyle: TextStyle.lerp(
        a?.descriptionStyle,
        b?.descriptionStyle,
        t,
      ),
      iconSpacing: lerpDouble(a?.iconSpacing, b?.iconSpacing, t),
      showCloseButton: pick?.showCloseButton,
      position: pick?.position,
      duration: pick?.duration,
      animationDuration: pick?.animationDuration,
      dismissDirection: pick?.dismissDirection,
      enableHaptic: pick?.enableHaptic,
      announce: pick?.announce,
    );
  }
}

extension ToastStyleResolve on ToastStyle {
  /// Stacks `caller > theme > defaults`, then fills colours and metrics
  /// from `context.<group>Colors` / tokens so a toast tracks the active
  /// palette and density.
  ///
  /// Token lookups DEGRADE: a toast is raised from an overlay that can
  /// sit outside the app shell, and a message must not require the
  /// responsive stack to draw.
  ResolvedToastStyle resolve(BuildContext context) {
    final merged = ToastStyle.defaults
        .mergedWith(GlobalToastTheme.maybeOf(context)?.style)
        .mergedWith(this);
    final tokens = context.maybeBreakpoints == null ? null : context.tokens;
    const floor = ToastStyle.defaults;
    final status = context.statusColors;

    return ResolvedToastStyle(
      variant: merged.variant ?? floor.variant!,
      borderRadius:
          merged.borderRadius ??
          (tokens == null
              ? floor.borderRadius!
              : BorderRadius.circular(tokens.radii.full)),
      padding: merged.padding ?? floor.padding!,
      margin: merged.margin ?? floor.margin!,
      maxWidth: merged.maxWidth ?? floor.maxWidth!,
      stackSpacing: merged.stackSpacing ?? floor.stackSpacing!,
      elevation: merged.elevation ?? floor.elevation!,
      successColor: merged.successColor ?? status.success,
      errorColor: merged.errorColor ?? status.error,
      warningColor: merged.warningColor ?? status.warning,
      infoColor: merged.infoColor ?? status.info,
      foregroundColor: merged.foregroundColor,
      titleStyle: merged.titleStyle,
      descriptionStyle: merged.descriptionStyle,
      iconSpacing: merged.iconSpacing ?? floor.iconSpacing!,
      showCloseButton: merged.showCloseButton ?? floor.showCloseButton!,
      position: merged.position ?? floor.position!,
      duration: merged.duration ?? floor.duration!,
      animationDuration: merged.animationDuration ?? floor.animationDuration!,
      dismissDirection: merged.dismissDirection ?? floor.dismissDirection!,
      enableHaptic: merged.enableHaptic ?? floor.enableHaptic!,
      announce: merged.announce ?? floor.announce!,
    );
  }
}
