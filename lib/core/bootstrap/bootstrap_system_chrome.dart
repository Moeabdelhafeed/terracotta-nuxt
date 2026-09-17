import 'package:flutter/services.dart';

import '../constants/fonts.dart';
import '../utils/assets/asset_utils.dart';
import '../utils/device/info/notch_side.dart';

/// Declare the supported orientations, preload fonts, warm up Lottie
/// compositions that must render before first paint. Image preloads run
/// later in the root widget where a `BuildContext` is available.
/// The orientations this app allows.
///
/// Named so that a page which narrows them — a fullscreen video locking
/// to landscape, a scanner locking to portrait — can put back what the
/// app actually had. `DeviceOrientation.values` is NOT that list: it
/// includes upside-down, which both native configs omit on a phone, so
/// restoring it silently widened what the app permits.
/// **LANDSCAPE IS OFF FOR NOW — deliberately, and temporarily.**
///
/// The template's standing rule is that every screen works rotated,
/// and the work to honour it is DONE and still here: the bottom bar
/// becomes a rail down the end edge, sheets take a short window's full
/// height, grids gain columns by width, and
/// `auth_screens_test.dart` builds all 44 screens at 874×390 to keep
/// them from regressing. What is not done is the design pass — the
/// screens fit sideways, they are not yet drawn for it.
///
/// So the gate closes here rather than the work being deleted. Put
/// the two landscape lines back and everything above wakes up.
const kAppOrientations = <DeviceOrientation>[
  DeviceOrientation.portraitUp,
  // DeviceOrientation.landscapeLeft,
  // DeviceOrientation.landscapeRight,
];

Future<void> initSystemChrome() async {
  // PORTRAIT ONLY, for now — see [kAppOrientations] for what that
  // turns off and how to turn it back on.
  //
  // Upside-down is left out on purpose: on a phone it is a rotation
  // nobody asks for, and both native configs already omit it there.
  // The Info.plist and the Android manifest are the outer gate; this
  // call can only narrow what they allow, never widen it.
  await SystemChrome.setPreferredOrientations(kAppOrientations);
  // Which edge the sensor housing is on. UIKit mirrors the horizontal
  // safe-area inset across BOTH landscape edges, so without this the
  // clear side gives up a notch's width for a notch that is not on it.
  // Off iOS this settles to `unknown` and changes nothing.
  await DeviceNotch.init();

  await AppFonts.preload(['en', 'ar']);
  await AssetUtils.preloadLotties(const []);
}
