// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// Authenticated principal — returned by auth endpoints
/// (`POST /auth/login`, `POST /auth/register`), persisted in
/// [UserDataStore], and consumed by any screen that surfaces identity.
///
/// - [id] is required — a User without an id is structurally
///   meaningless; backends that need an "anonymous" state should send
///   `null` at the parent level, not a User with a null id.
/// - [avatar] is a URL, not a local asset path.
/// - `emailVerifiedAt` / `phoneVerifiedAt` are null until the
///   user completes the verification flow.
///
/// Add domain-specific fields (subscription tier, role, preferences)
/// by extending this model in your app; keep the template shape as
/// the common denominator.
@freezed
abstract class User with _$User {
  const factory User({
    required int id,
    String? firstName,
    String? lastName,
    String? email,
    DateTime? emailVerifiedAt,
    String? phoneNumber,
    DateTime? phoneVerifiedAt,
    DateTime? birthdate,
    String? gender,
    String? avatar,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
