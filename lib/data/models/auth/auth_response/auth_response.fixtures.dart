// Fixtures composing other fixtures is the intended usage pattern —
// this file is itself only imported from tests/dev tools, so the
// cross-reference to `dummyUser` is safe.
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:flutter/foundation.dart';

import '../user/user.fixtures.dart';
import 'auth_response.dart';

/// Test / skeleton fixture for [AuthResponse]. Production features
/// should never import this — only tests, widget catalogs, dev tools.
@visibleForTesting
final AuthResponse dummyAuthResponse = AuthResponse(
  token: 'dummy_token_12345',
  user: dummyUser,
);
