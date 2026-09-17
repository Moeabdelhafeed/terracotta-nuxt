import 'package:flutter/foundation.dart';

import 'api_envelope.dart';

/// Test fixtures for [ApiEnvelope]. Three canonical shapes worth
/// exercising:
///  - **success** with a payload
///  - **success** with `data: null` (rare but allowed)
///  - **failure** with error strings and a falsy status
///
/// `@visibleForTesting` — production code never needs these.

/// A successful envelope wrapping an arbitrary `Map<String, dynamic>`
/// payload. Use when testing `handleSingleResponse`-style parsing.
@visibleForTesting
const ApiEnvelope<Map<String, dynamic>> dummyApiEnvelopeSuccess = ApiEnvelope(
  status: true,
  statusCode: 200,
  message: 'Ok',
  data: {'id': '1', 'name': 'Example'},
);

/// A successful envelope whose `data` is null — represents "accepted
/// but nothing to return" (e.g. `204`-style responses that still go
/// through the envelope).
@visibleForTesting
const ApiEnvelope<Map<String, dynamic>> dummyApiEnvelopeEmpty = ApiEnvelope(
  statusCode: 204,
  message: 'No Content',
);

/// A failure envelope — drives the `_errorFromEnvelope` path in the
/// handler.
@visibleForTesting
const ApiEnvelope<Map<String, dynamic>> dummyApiEnvelopeFailure = ApiEnvelope(
  status: false,
  statusCode: 422,
  message: 'Validation failed',
  errors: ['email: already taken', 'password: too short'],
);
