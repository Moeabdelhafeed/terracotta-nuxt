import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/error/app_exception.dart';
import 'social_auth_service.dart';

// ─── Google ──────────────────────────────────────────────────────

/// Google sign-in adapter. Uses `google_sign_in` v7+ (static API
/// around [GoogleSignIn.instance]).
///
/// Platform wiring:
///  - **Android**: add OAuth client ID + SHA-1 to Firebase / GCP
///    console; gradle plugin reads google-services.json.
///  - **iOS**: add `GIDClientID` + reversed client ID to
///    `Info.plist` + URL schemes.
///  - **Web**: call [GoogleSignIn.instance.initialize] with a web
///    client ID during bootstrap.
class GoogleSocialAuthAdapter extends SocialAuthService {
  const GoogleSocialAuthAdapter();

  @override
  SocialAuthProvider get provider => SocialAuthProvider.google;

  @override
  Future<SocialAuthResult> signIn() async {
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final auth = account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        return const SocialAuthFailure(
          AuthException(message: 'Google sign-in returned no ID token'),
        );
      }
      return SocialAuthSuccess(
        provider: SocialAuthProvider.google,
        idToken: idToken,
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
        userId: account.id,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const SocialAuthCancelled();
      }
      return SocialAuthFailure(
        AuthException(
          message: 'Google sign-in failed: ${e.description ?? e.code.name}',
        ),
      );
    } catch (e, st) {
      if (kDebugMode) debugPrint('[GoogleSocialAuthAdapter] signIn failed: $e');
      return SocialAuthFailure(AppException.fromError(e, st));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[GoogleSocialAuthAdapter] signOut failed: $e');
      }
    }
  }
}

// ─── Facebook ────────────────────────────────────────────────────

/// Facebook sign-in adapter. Uses `flutter_facebook_auth`.
///
/// Platform wiring:
///  - **Android**: add Facebook app ID to `strings.xml` + activity
///    to `AndroidManifest.xml`.
///  - **iOS**: `Info.plist` keys (`FacebookAppID`, `CFBundleURLTypes`,
///    `LSApplicationQueriesSchemes`).
class FacebookSocialAuthAdapter extends SocialAuthService {
  const FacebookSocialAuthAdapter();

  @override
  SocialAuthProvider get provider => SocialAuthProvider.facebook;

  @override
  Future<SocialAuthResult> signIn() async {
    try {
      final result = await FacebookAuth.instance.login(
        permissions: const ['email', 'public_profile'],
      );
      switch (result.status) {
        case LoginStatus.success:
          final token = result.accessToken;
          if (token == null) {
            return const SocialAuthFailure(
              AuthException(
                message: 'Facebook sign-in returned no access token',
              ),
            );
          }
          final userData = await FacebookAuth.instance.getUserData();
          return SocialAuthSuccess(
            provider: SocialAuthProvider.facebook,
            // Facebook doesn't return an OIDC id_token — pass the
            // access token in its place; backend verifies via
            // Graph API.
            idToken: token.tokenString,
            accessToken: token.tokenString,
            email: userData['email'] as String?,
            displayName: userData['name'] as String?,
            photoUrl: (userData['picture'] as Map?)?['data']?['url'] as String?,
            userId: userData['id'] as String?,
          );
        case LoginStatus.cancelled:
          return const SocialAuthCancelled();
        case LoginStatus.failed:
        case LoginStatus.operationInProgress:
          return SocialAuthFailure(
            AuthException(message: result.message ?? 'Facebook sign-in failed'),
          );
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[FacebookSocialAuthAdapter] signIn failed: $e');
      }
      return SocialAuthFailure(AppException.fromError(e, st));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await FacebookAuth.instance.logOut();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FacebookSocialAuthAdapter] signOut failed: $e');
      }
    }
  }
}

// ─── Apple ───────────────────────────────────────────────────────

/// Apple sign-in adapter. Uses `sign_in_with_apple`.
///
/// Platform wiring:
///  - **iOS 13+**: add "Sign in with Apple" capability in Xcode.
///  - **Android / Web**: requires a backend callback for the
///    OAuth redirect — pass `webAuthenticationOptions`.
///
/// Note: Apple only returns [SocialAuthSuccess.email] +
/// [displayName] on the **first** sign-in. Persist on your backend.
class AppleSocialAuthAdapter extends SocialAuthService {
  const AppleSocialAuthAdapter();

  @override
  SocialAuthProvider get provider => SocialAuthProvider.apple;

  @override
  Future<SocialAuthResult> signIn() async {
    try {
      final cred = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final idToken = cred.identityToken;
      if (idToken == null) {
        return const SocialAuthFailure(
          AuthException(message: 'Apple sign-in returned no identity token'),
        );
      }
      final displayName = [
        cred.givenName,
        cred.familyName,
      ].whereType<String>().where((s) => s.isNotEmpty).join(' ');
      return SocialAuthSuccess(
        provider: SocialAuthProvider.apple,
        idToken: idToken,
        accessToken: cred.authorizationCode,
        email: cred.email,
        displayName: displayName.isEmpty ? null : displayName,
        userId: cred.userIdentifier,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return const SocialAuthCancelled();
      }
      return SocialAuthFailure(
        AuthException(message: 'Apple sign-in failed: ${e.message}'),
      );
    } catch (e, st) {
      if (kDebugMode) debugPrint('[AppleSocialAuthAdapter] signIn failed: $e');
      return SocialAuthFailure(AppException.fromError(e, st));
    }
  }

  @override
  Future<void> signOut() async {
    // Apple doesn't expose a sign-out call — the session is managed
    // by the OS. Clear your own credential store instead.
  }
}

// ─────────────────────────────────────────────────────────────────
//                         Stub adapters
// ─────────────────────────────────────────────────────────────────
//
// Each stub below matches a provider the app declares via
// [SocialAuthProvider] but hasn't wired yet. Calling `.signIn()`
// returns a [SocialAuthFailure] so UI code handles it the same as
// any other error — no crashes from unregistered providers.
//
// Flip a stub into a real adapter in three steps:
//   1. Add the SDK to `pubspec.yaml`.
//   2. Replace the `signIn` body with the SDK's sign-in call,
//      mapping the result to [SocialAuthSuccess] /
//      [SocialAuthCancelled] / [SocialAuthFailure].
//   3. Keep the registration line in `service_locator.dart` as-is.

abstract class _StubSocialAuthAdapter extends SocialAuthService {
  const _StubSocialAuthAdapter();

  /// Human-readable provider name used in the "not wired yet" error.
  String get label;

  @override
  Future<SocialAuthResult> signIn() async {
    return SocialAuthFailure(
      AuthException(
        message:
            '$label sign-in is not wired yet — see social_auth_adapters.dart.',
      ),
    );
  }

  @override
  Future<void> signOut() async {}
}

// ─── Twitter / X ─────────────────────────────────────────────────
///
/// Wire via `twitter_login` or `twitter_oauth2_pkce`:
/// ```dart
/// final login = TwitterLogin(apiKey: ..., apiSecretKey: ..., redirectURI: ...);
/// final result = await login.login();
/// ```
class TwitterSocialAuthAdapter extends _StubSocialAuthAdapter {
  const TwitterSocialAuthAdapter();
  @override
  SocialAuthProvider get provider => SocialAuthProvider.twitter;
  @override
  String get label => 'Twitter / X';
}

// ─── GitHub ──────────────────────────────────────────────────────
///
/// Wire via `github_sign_in` (OAuth2 web flow) or a generic
/// `flutter_appauth` / `oauth2` pipeline.
class GithubSocialAuthAdapter extends _StubSocialAuthAdapter {
  const GithubSocialAuthAdapter();
  @override
  SocialAuthProvider get provider => SocialAuthProvider.github;
  @override
  String get label => 'GitHub';
}

// ─── Microsoft ───────────────────────────────────────────────────
///
/// Wire via `aad_oauth` or `flutter_azure_b2c` for Azure AD /
/// Entra ID. Returns an Azure access token + id_token.
class MicrosoftSocialAuthAdapter extends _StubSocialAuthAdapter {
  const MicrosoftSocialAuthAdapter();
  @override
  SocialAuthProvider get provider => SocialAuthProvider.microsoft;
  @override
  String get label => 'Microsoft';
}

// ─── LinkedIn ────────────────────────────────────────────────────
///
/// Wire via `linkedin_login`. LinkedIn only exposes a thin profile —
/// most backends use it to seed a user record, not to sign in each
/// session.
class LinkedinSocialAuthAdapter extends _StubSocialAuthAdapter {
  const LinkedinSocialAuthAdapter();
  @override
  SocialAuthProvider get provider => SocialAuthProvider.linkedin;
  @override
  String get label => 'LinkedIn';
}

// ─── Discord ─────────────────────────────────────────────────────
///
/// Discord has no first-party Flutter SDK — use `flutter_appauth`
/// or a raw `oauth2` client against their `/oauth2/authorize`
/// endpoint. Scopes: `identify email`.
class DiscordSocialAuthAdapter extends _StubSocialAuthAdapter {
  const DiscordSocialAuthAdapter();
  @override
  SocialAuthProvider get provider => SocialAuthProvider.discord;
  @override
  String get label => 'Discord';
}

// ─── Yahoo ───────────────────────────────────────────────────────
///
/// Easiest path: Firebase Auth's `OAuthProvider('yahoo.com')`. If
/// Firebase Auth isn't in your stack, use `flutter_appauth` against
/// Yahoo's OpenID Connect endpoint.
class YahooSocialAuthAdapter extends _StubSocialAuthAdapter {
  const YahooSocialAuthAdapter();
  @override
  SocialAuthProvider get provider => SocialAuthProvider.yahoo;
  @override
  String get label => 'Yahoo';
}

// ─── Amazon ──────────────────────────────────────────────────────
///
/// Wire via `flutter_amazon_cognito_identity_provider` (if you use
/// Cognito) or `flutter_appauth` with Login with Amazon's OAuth
/// endpoint.
class AmazonSocialAuthAdapter extends _StubSocialAuthAdapter {
  const AmazonSocialAuthAdapter();
  @override
  SocialAuthProvider get provider => SocialAuthProvider.amazon;
  @override
  String get label => 'Amazon';
}

// ─── Instagram ───────────────────────────────────────────────────
///
/// Instagram Basic Display API is deprecated for most sign-in
/// flows; use Facebook Login with the `instagram_basic` scope via
/// [FacebookSocialAuthAdapter] instead, or `flutter_appauth` against
/// Instagram Graph.
class InstagramSocialAuthAdapter extends _StubSocialAuthAdapter {
  const InstagramSocialAuthAdapter();
  @override
  SocialAuthProvider get provider => SocialAuthProvider.instagram;
  @override
  String get label => 'Instagram';
}
