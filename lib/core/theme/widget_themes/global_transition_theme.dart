import 'package:flutter/material.dart';

import '../../animations/animation_presets.dart';
import '../../navigation/transitions/route_transition.dart';
import '../../tokens/app_tokens.dart';

/// Project-tuned defaults for page transitions.
///
/// The app-wide rebrand hook, and the one place a house says how its
/// pages move. A route still wins per route, and a `TransitionOverride`
/// wins per push.
///
/// It takes [tokens] like every other widget theme for symmetry, and
/// deliberately reads NOTHING from them: a transition is motion, not
/// layout, and none of spacing, radii or icon sizes has an opinion
/// about how long a page takes to arrive.
class MyGlobalTransitionTheme {
  MyGlobalTransitionTheme._();

  static GlobalTransitionTheme build({required AppTokens tokens}) =>
      const GlobalTransitionTheme(
        style: TransitionStyle(
          // 300ms, not the 400 floor. These are FORM flows — you arrive
          // on a screen to type on it — and 400 reads as waiting for the
          // keyboard rather than moving toward it.
          //
          // No `type` here on purpose: the house sets the FEEL, each
          // route says whether it is a step forward or a change of
          // mode. A type here would give the splash a slide.
          duration: AppDurations.normal,
          curve: Curves.easeOutCubic,
        ),
      );
}
