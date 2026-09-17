// Per-flavor Firebase options dispatcher.
//
// Each flavor has its own generated `firebase_options_<flavor>.dart`.
// Regenerate per-flavor:
//   flutterfire configure \
//     --project=<your-firebase-project-id> \
//     --out=lib/firebase_options_<flavor>.dart \
//     --ios-bundle-id=com.dottech.flutterBaseApp \
//     --android-package-name=com.dottech.terracotta
//
// On iOS / Android the native plugin reads the per-flavor config from
// the app bundle (`GoogleService-Info.plist` / `google-services.json`),
// so [firebaseOptionsForFlavor] only matters on web / desktop where
// there's no native slot.
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

import 'core/flavor/flavor.dart';
import 'firebase_options_dev.dart' as dev;
import 'firebase_options_prod.dart' as prod;
import 'firebase_options_staging.dart' as staging;
import 'firebase_options_uat.dart' as uat;

/// Picks the right `FirebaseOptions` for the active [Flavor]. Used by
/// `bootstrap_firebase.dart` on web / desktop. Mobile reads from native
/// per-flavor config files instead.
FirebaseOptions firebaseOptionsForFlavor(Flavor flavor) {
  switch (flavor) {
    case Flavor.dev:
      return dev.DefaultFirebaseOptions.currentPlatform;
    case Flavor.staging:
      return staging.DefaultFirebaseOptions.currentPlatform;
    case Flavor.uat:
      return uat.DefaultFirebaseOptions.currentPlatform;
    case Flavor.prod:
      return prod.DefaultFirebaseOptions.currentPlatform;
  }
}
