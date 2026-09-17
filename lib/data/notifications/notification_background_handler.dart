import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../core/flavor/flavor.dart';
import '../../firebase_options.dart';

/// Top-level entry-point called by FCM when a push arrives while the
/// app is **terminated** or in the **background**. Runs in a separate
/// isolate, so it cannot touch in-app singletons (controllers,
/// HydratedBloc storage, the UI tree) — anything you do here has to be
/// isolate-local.
///
/// Requirements:
///  - Must be a top-level function (not a method).
///  - Must be annotated `@pragma('vm:entry-point')` so tree-shaking
///    doesn't drop it.
///  - Must call `Firebase.initializeApp` before using any Firebase
///    service from this isolate.
///
/// Register once at app startup **before** `runApp`:
///
/// ```dart
/// // main.dart
/// FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
/// ```
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // FCM background isolates need Firebase re-init. `FlavorConfig` is
  // not set in this isolate, so we re-resolve the flavor from the
  // compile-time `FLAVOR` dart-define (each `config/<flavor>.json`
  // sets it) and pick the matching per-flavor options.
  const flavorName = String.fromEnvironment('FLAVOR', defaultValue: 'prod');
  final flavor = Flavor.values.firstWhere(
    (f) => f.name == flavorName,
    orElse: () => Flavor.prod,
  );
  await Firebase.initializeApp(options: firebaseOptionsForFlavor(flavor));

  if (kDebugMode) {
    // ignore: avoid_print
    print('[BG notification] ${message.messageId} — ${message.data}');
  }

  // The OS handles *display* of the notification in background —
  // nothing else needed here unless you want to mutate the payload,
  // update a local DB, or increment a badge through a plugin that
  // works from a background isolate.
}
