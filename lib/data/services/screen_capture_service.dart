import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Detects whether the screen is being RECORDED or SHARED (mirrored /
/// casted) and notifies listeners on change.
///
/// Platform support (graceful `false` everywhere else):
/// * **iOS 11+** — `UIScreen.isCaptured` + `capturedDidChangeNotification`
///   (covers recording, AirPlay mirroring, QuickTime capture).
/// * **Android 15+ (API 35)** — `WindowManager.addScreenRecordingCallback`
///   (requires the `DETECT_SCREEN_RECORDING` permission, declared in the
///   template manifest). Older Android cannot detect recording.
/// * Web / desktop — not detectable; always `false`.
///
/// Native side lives in `ios/Runner/AppDelegate.swift` and
/// `android/.../MainActivity.kt` on the `terracotta/screen_capture`
/// channel.
///
/// Consumers: `PasswordField(detectScreenCapture: true)` listens and, while
/// captured, shows a warning row + switches the field to instant obscuring
/// (`TextFieldBehavior.instantObscure`).
class ScreenCaptureService extends ChangeNotifier {
  ScreenCaptureService._() {
    _init();
  }

  /// Utility singleton (deliberately not in `getIt` — no config; tests use
  /// [debugOverride]).
  static final ScreenCaptureService instance = ScreenCaptureService._();

  static const _channel = MethodChannel('terracotta/screen_capture');

  bool _captured = false;
  bool? _debugOverride;

  /// True while the screen is recorded / shared. [debugOverride] wins.
  bool get isCaptured => _debugOverride ?? _captured;

  bool? get debugOverride => _debugOverride;

  /// Force a state for demos/tests (`null` returns to the real signal).
  set debugOverride(bool? value) {
    if (_debugOverride == value) return;
    _debugOverride = value;
    notifyListeners();
  }

  Future<void> _init() async {
    if (kIsWeb) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'captureChanged') {
        final captured = call.arguments == true;
        if (captured != _captured) {
          _captured = captured;
          notifyListeners();
        }
      }
    });
    try {
      _captured = await _channel.invokeMethod<bool>('isCaptured') ?? false;
      if (_captured) notifyListeners();
    } on MissingPluginException {
      // Platform without a native implementation — stays false.
    } on PlatformException {
      // Detection unavailable (e.g. Android < 15) — stays false.
    }
  }
}
