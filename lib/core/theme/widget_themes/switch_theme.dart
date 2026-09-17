import 'package:flutter/material.dart';

import '../../constants/colors/background_colors.dart';
import '../../constants/colors/primary_colors.dart';
import '../../constants/colors/text_colors.dart';
import '../../constants/sizes/app_sizes.dart';

/// Every Material switch in the app, including `Switch.adaptive` —
/// which is a CUPERTINO switch on iOS and a Material one on Android,
/// and only the Material half reads this.
///
/// ## The off state has to look like a control
///
/// It did not. The thumb resolved to `bg.outline` (#e5e5e5) and the
/// track to `bg.outlineVariant` — black at a tenth, which over a white
/// page is #e6e6e6. A #e5e5e5 circle on a #e6e6e6 bar is not a switch
/// that is off; it is a switch that is missing, and that is exactly how
/// the wallet toggle read on Android while the iOS build beside it
/// looked right.
///
/// So the off state is the one iOS draws and everyone recognises: a
/// WHITE thumb on a grey track. The thumb is the constant — white in
/// both states — and the TRACK is what changes, which is also what
/// makes the two states tell each other apart at a glance rather than
/// by a hue nobody can name.
class MySwitchTheme {
  MySwitchTheme._();

  /// How dark the OFF track is over the page behind it.
  ///
  /// The white thumb needs something to sit ON. Cupertino's own
  /// #E9E9EA is lighter than this and gets away with it because its
  /// thumb carries a drop shadow; Material's does not, so the track
  /// has to do the work.
  static const _offTrack = 0.34;

  static SwitchThemeData build({
    required PrimaryColors primary,
    required BackgroundColors bg,
    required TextColors text,
  }) => SwitchThemeData(
    // WHITE IN EVERY STATE. What moves is the thumb and what changes
    // is the track — a thumb that also changes colour gives the eye two
    // things to read where there is one fact.
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return text.onPrimary.withValues(alpha: AppSizes.opacityHigh);
      }
      return text.onPrimary;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return text.disabled.withValues(alpha: AppSizes.opacityOverlay);
      }
      // SOLID, not a wash. The old 40% left a pale brown track under a
      // brown thumb, which is the same problem the off state had.
      if (states.contains(WidgetState.selected)) return primary.primary;
      return text.disabled.withValues(alpha: _offTrack);
    }),
    trackOutlineColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return Colors.transparent;
      // Transparent OFF too: the track is dark enough to be its own
      // edge, and an outline over it only muddies the shape.
      return Colors.transparent;
    }),
    splashRadius: AppSizes.splashRadius,
  );
}
