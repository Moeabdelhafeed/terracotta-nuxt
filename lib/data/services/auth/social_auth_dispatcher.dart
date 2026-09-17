import 'social_auth_service.dart';

/// Routes [SocialAuthProvider] calls to the right
/// [SocialAuthService] adapter. Feature code talks only to the
/// dispatcher — add a provider by registering a new adapter here and
/// in [SocialAuthProvider].
///
/// ```dart
/// final result = await getIt<SocialAuthDispatcher>()
///   .signIn(SocialAuthProvider.google);
///
/// switch (result) {
///   SocialAuthSuccess(:final idToken, :final provider) =>
///     authBloc.add(AuthEvent.socialSignIn(provider, idToken)),
///   SocialAuthCancelled()            => null,
///   SocialAuthFailure(:final error)  => GlobalToast.e(error.message),
/// }
/// ```
class SocialAuthDispatcher {
  SocialAuthDispatcher(List<SocialAuthService> adapters)
    : _adapters = {for (final a in adapters) a.provider: a};

  final Map<SocialAuthProvider, SocialAuthService> _adapters;

  /// True when an adapter is registered for [provider].
  bool supports(SocialAuthProvider provider) => _adapters.containsKey(provider);

  Future<SocialAuthResult> signIn(SocialAuthProvider provider) {
    final adapter = _adapters[provider];
    if (adapter == null) {
      throw StateError(
        'SocialAuthDispatcher: no adapter registered for $provider. '
        'Register one in service_locator.dart.',
      );
    }
    return adapter.signIn();
  }

  /// Sign the user out on [provider] (idempotent — no-op for
  /// providers that don't expose a sign-out).
  Future<void> signOut(SocialAuthProvider provider) async {
    await _adapters[provider]?.signOut();
  }

  /// Sign out of every registered provider. Useful in full logout
  /// flows so the next login doesn't silently pick the cached
  /// account.
  Future<void> signOutAll() async {
    for (final adapter in _adapters.values) {
      await adapter.signOut();
    }
  }
}
