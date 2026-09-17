import 'package:flutter/foundation.dart';

import 'user.dart';

/// Test / skeleton-loader fixture for [User]. Only import from test
/// files, widget catalogs, or dev tools — never from production
/// feature code (the `@visibleForTesting` annotation will surface
/// misuse as a lint warning).
@visibleForTesting
final User dummyUser = User(
  id: 1,
  firstName: 'John',
  lastName: 'Doe',
  email: 'johndoe@gmail.com',
  emailVerifiedAt: DateTime.parse('2022-01-01T00:00:00.000000Z'),
  phoneNumber: '+1234567890',
  phoneVerifiedAt: DateTime.parse('2022-01-01T00:00:00.000000Z'),
  birthdate: DateTime.parse('2000-01-01T00:00:00.000000Z'),
  gender: 'male',
  avatar: 'https://example.com/avatar.jpg',
);
