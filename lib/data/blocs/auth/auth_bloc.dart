import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/secure_credential_store.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Bloc owning the authentication lifecycle. Replaces the old
/// `SecureStore` + `UserDataStore` + `PreferencesStore.isLoggedIn`
/// combo with a single sealed state.
///
/// Bootstrap sequence:
/// ```dart
/// final bloc = AuthBloc(repo)..add(const AuthEvent.bootstrapped());
/// ```
///
/// State consumers check via pattern match:
/// ```dart
/// switch (state) {
///   AuthAuthenticated(:final user, :final token) => ...,
///   AuthUnauthenticated() => ...,
///   _ => ...,
/// }
/// ```
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repo) : super(const AuthState.unknown()) {
    on<AuthBootstrapped>(_onBootstrapped);
    on<AuthSignedIn>(_onSignedIn);
    on<AuthSignedOut>(_onSignedOut);
    on<AuthPendingTokenSet>(_onPendingTokenSet);
    on<AuthPendingTokenCleared>(_onPendingTokenCleared);
    on<AuthFcmTokenChanged>(_onFcmTokenChanged);
    on<AuthUserUpdated>(_onUserUpdated);
  }

  final SecureCredentialStore _repo;

  /// Last known FCM token, cached OUTSIDE the state.
  ///
  /// `AuthAuthenticated` carries its own copy, but the Terracotta API
  /// demands `X-FCM-Token` on every mobile request — guest reads of the
  /// shop, the gallery and the workshops included — and the header
  /// resolver in `ApiService` is synchronous, so it can neither await
  /// `_repo.readFcmToken()` nor find the token on an unauthenticated
  /// state. Without this, every guest request 422s.
  String _fcmToken = '';

  Future<void> _onBootstrapped(
    AuthBootstrapped event,
    Emitter<AuthState> emit,
  ) async {
    final token = await _repo.readAuthToken();
    final user = await _repo.readUser();
    final fcm = await _repo.readFcmToken();
    // WHICH APP this session belongs to. See
    // [AuthAuthenticated.isScanner] — without it a cold start cannot
    // tell staff from a customer.
    final isScanner = await _repo.readIsScanner();
    _fcmToken = fcm ?? '';
    if (token != null && user != null) {
      emit(
        AuthState.authenticated(
          user: user,
          token: token,
          fcmToken: fcm ?? '',
          isScanner: isScanner,
        ),
      );
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onSignedIn(AuthSignedIn event, Emitter<AuthState> emit) async {
    // NOT WRITTEN when the reader unticked «أبقني مسجّل الدخول». The
    // session still works for this run — it lives in the state below,
    // which is what every request reads — but nothing reaches secure
    // storage, so killing the app ends it. Writing the token and
    // deleting it on the next launch would be the same outcome with
    // the token on disk in between.
    if (event.remember) {
      await _repo.writeAuthToken(event.token);
      await _repo.writeUser(event.user);
      await _repo.writeIsScanner(event.isScanner);
    } else {
      // And clear anything a PREVIOUS remembered session left, or the
      // old token would come back on the next launch.
      await _repo.clearAuthToken();
      await _repo.clearUser();
      await _repo.clearIsScanner();
    }
    final fcm = await _repo.readFcmToken();
    _fcmToken = fcm ?? '';
    emit(
      AuthState.authenticated(
        user: event.user,
        token: event.token,
        isScanner: event.isScanner,
        fcmToken: fcm ?? '',
      ),
    );
  }

  Future<void> _onSignedOut(
    AuthSignedOut event,
    Emitter<AuthState> emit,
  ) async {
    await _repo.clearAuthToken();
    await _repo.clearUser();
    // AND WHICH APP it was. A staff flag left behind would send the
    // next person to sign in on this device to the desk, whoever they
    // are.
    await _repo.clearIsScanner();
    // Keep FCM token — device is still the same device, re-auth can reuse.
    emit(const AuthState.unauthenticated());
  }

  void _onPendingTokenSet(AuthPendingTokenSet event, Emitter<AuthState> emit) {
    emit(AuthState.pending(temporaryToken: event.token));
  }

  void _onPendingTokenCleared(
    AuthPendingTokenCleared event,
    Emitter<AuthState> emit,
  ) {
    emit(const AuthState.unauthenticated());
  }

  Future<void> _onFcmTokenChanged(
    AuthFcmTokenChanged event,
    Emitter<AuthState> emit,
  ) async {
    await _repo.writeFcmToken(event.token);
    _fcmToken = event.token;
    final s = state;
    if (s is AuthAuthenticated) {
      emit(s.copyWith(fcmToken: event.token));
    }
  }

  Future<void> _onUserUpdated(
    AuthUserUpdated event,
    Emitter<AuthState> emit,
  ) async {
    await _repo.writeUser(event.user);
    final s = state;
    if (s is AuthAuthenticated) {
      emit(s.copyWith(user: event.user));
    }
  }

  // ─── Convenience accessors (synchronous, for non-widget consumers) ─

  /// Current bearer token, or empty string when unauthenticated / pending.
  /// Pending-flow callers should read `pendingToken` instead.
  String get bearerToken {
    final s = state;
    return s is AuthAuthenticated ? s.token : '';
  }

  /// Current pending/OTP token, or empty string.
  String get pendingToken {
    final s = state;
    return s is AuthPending ? s.temporaryToken : '';
  }

  /// Current FCM token, or empty string before one has been issued.
  ///
  /// Deliberately NOT state-gated: the API requires `X-FCM-Token` on
  /// every mobile request, and most of those are guest reads made while
  /// unauthenticated. Prefers the authenticated state's copy so a
  /// sign-in that carries a fresher token still wins.
  String get fcmToken {
    final s = state;
    if (s is AuthAuthenticated && s.fcmToken.isNotEmpty) return s.fcmToken;
    return _fcmToken;
  }

  bool get isAuthenticated => state is AuthAuthenticated;
}
