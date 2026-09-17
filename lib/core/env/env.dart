import 'package:envied/envied.dart';

part 'env.g.dart';

/// Compile-time secrets / static config sourced from `.env` at the
/// repo root. `dart run build_runner build` generates `env.g.dart`
/// with XOR-obfuscated constants.
///
/// **Layered resolution chain** (see `RemoteConfigService`):
/// 1. Firebase Remote Config (mobile only, when fetched)
/// 2. `Env.X` — this class, compile-time
/// 3. Hardcoded inline default
///
/// `obfuscate: true` runs a light XOR pass on the generated value so
/// the literal isn't grep-able in the bundle. **Not real security** —
/// anyone with the binary can deobfuscate. For genuine secrets that
/// need rotation, keep them server-side.
@Envied(path: '.env', obfuscate: true)
abstract class Env {
  // ─── API ─────────────────────────────────────────────────
  @EnviedField(varName: 'API_BASE_URL', defaultValue: 'https://api.example.com')
  static final String apiBaseUrl = _Env.apiBaseUrl;

  @EnviedField(varName: 'API_X_TOKEN', defaultValue: 'fallback-token')
  static final String apiXToken = _Env.apiXToken;

  // ─── Maps ────────────────────────────────────────────────
  @EnviedField(varName: 'MAPS_HTTP_API_KEY', defaultValue: '')
  static final String mapsHttpApiKey = _Env.mapsHttpApiKey;

  @EnviedField(varName: 'MAPS_NATIVE_API_KEY', defaultValue: '')
  static final String mapsNativeApiKey = _Env.mapsNativeApiKey;

  // ─── Support / contact ───────────────────────────────────
  @EnviedField(
    varName: 'SUPPORT_EMAIL',
    defaultValue: 'support@example.com',
  )
  static final String supportEmail = _Env.supportEmail;

  @EnviedField(varName: 'WEBSITE_URL', defaultValue: 'https://example.com')
  static final String websiteUrl = _Env.websiteUrl;

  // ─── Feedback ────────────────────────────────────────────
  @EnviedField(varName: 'FEEDBACK_ENDPOINT', defaultValue: '')
  static final String feedbackEndpoint = _Env.feedbackEndpoint;

  // ─── Web push ────────────────────────────────────────────
  // Empty for non-web builds. See docs/setup/17-web-fcm-setup.md.
  @EnviedField(varName: 'FCM_VAPID_KEY', defaultValue: '')
  static final String fcmVapidKey = _Env.fcmVapidKey;
}
