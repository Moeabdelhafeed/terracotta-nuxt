import 'package:flutter/foundation.dart';

import '../../../core/error/app_exception.dart';

/// Supported social sign-in providers. Template ships stub adapters
/// for the major providers — each one's body is a no-op TODO until
/// you add its SDK to pubspec and wire the call.
enum SocialAuthProvider {
  google,
  facebook,
  apple,
  twitter,
  github,
  microsoft,
  linkedin,
  discord,
  yahoo,
  amazon,
  instagram,
}

/// Result of a sign-in attempt. Sealed so callers pattern-match.
///
/// ```dart
/// switch (await dispatcher.signIn(SocialAuthProvider.google)) {
///   SocialAuthSuccess(:final idToken, :final provider) =>
///     authBloc.add(AuthEvent.socialSignIn(provider, idToken)),
///   SocialAuthCancelled()        => null, // user bailed
///   SocialAuthFailure(:final error) => GlobalToast.e(error.message),
/// }
/// ```
sealed class SocialAuthResult {
  const SocialAuthResult();
}

@immutable
class SocialAuthSuccess extends SocialAuthResult {
  const SocialAuthSuccess({
    required this.provider,
    required this.idToken,
    this.accessToken,
    this.email,
    this.displayName,
    this.photoUrl,
    this.userId,
  });

  final SocialAuthProvider provider;

  /// Identity token (JWT) — send to your backend for verification.
  /// Backend validates + mints your app's own bearer token.
  final String idToken;

  /// OAuth access token — provider-scoped (only Google/Facebook
  /// return one, Apple doesn't).
  final String? accessToken;

  final String? email;
  final String? displayName;
  final String? photoUrl;

  /// Provider-side user ID (sub / uid). Useful when linking accounts.
  final String? userId;
}

class SocialAuthCancelled extends SocialAuthResult {
  const SocialAuthCancelled();
}

class SocialAuthFailure extends SocialAuthResult {
  const SocialAuthFailure(this.error);
  final AppException error;
}

/// Adapter interface — one implementation per provider. The
/// [SocialAuthDispatcher] routes incoming [SocialAuthProvider] calls
/// to the right adapter.
abstract class SocialAuthService {
  const SocialAuthService();

  /// Which provider this adapter handles.
  SocialAuthProvider get provider;

  /// Launch the provider's native sign-in UI and return the result.
  /// Adapters must never throw — catch everything and map to
  /// [SocialAuthFailure] / [SocialAuthCancelled].
  Future<SocialAuthResult> signIn();

  /// Sign the user out on the provider side. Idempotent.
  Future<void> signOut();
}
