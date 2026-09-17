// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

// Project imports:
import '../user/user.dart';

part 'auth_response.freezed.dart';
part 'auth_response.g.dart';

/// Response body for authentication endpoints — both
/// `POST /auth/login` and `POST /auth/register` return this shape.
///
/// Both fields are required — a successful auth response without a
/// token or without a user is a contract violation from the backend,
/// not a state the app should try to handle. If your backend has a
/// two-step flow ("registered, verify email before we return a user"),
/// model it with a separate response type (`VerificationPending`)
/// rather than a nullable user here.
///
/// Consumed by: sign-in / sign-up screens → `UserDataStore` (persists
/// user) + `SecureStore` (persists token).
@freezed
abstract class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    required String token,
    required User user,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
}
