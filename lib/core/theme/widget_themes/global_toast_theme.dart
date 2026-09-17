import 'package:flutter/material.dart';

import '../../../shared/module/toast/global_toast.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for [GlobalToast].
///
/// The app-wide rebrand hook: set the shape and spacing of every
/// transient message once here.
///
/// Severity colours are deliberately NOT set. They resolve from
/// `context.statusColors` at show time, so they track the active
/// palette, role and brightness — pinning them here would freeze the
/// toast against all three.
class MyGlobalToastTheme {
  MyGlobalToastTheme._();

  static GlobalToastTheme build({required AppTokens tokens}) {
    return GlobalToastTheme(
      style: ToastStyle(
        // Rides the token bucket, so a density change moves the toast's
        // shape and breathing room with every other surface.
        borderRadius: BorderRadius.circular(tokens.radii.full),
        // ASYMMETRIC, and it has to stay that way: the close button
        // brings its own 48dp tap box, so a matching inset on the end
        // reads as a gutter after the glyph. A symmetric value here
        // silently overrode ToastStyle.defaults, which is why tuning the
        // constants alone changed nothing.
        padding: EdgeInsetsDirectional.only(
          start: tokens.spacing.md,
          end: 0,
          top: tokens.spacing.sm,
          bottom: tokens.spacing.sm,
        ),
        margin: EdgeInsets.symmetric(
          horizontal: tokens.spacing.md,
          vertical: tokens.spacing.xs,
        ),
      ),
    );
  }
}
