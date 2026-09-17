/// Barrel export for `data/models/`. Import from here when a file
/// needs multiple model types — saves N individual import lines.
///
/// ```dart
/// // Instead of:
/// import '.../auth/user/user.dart';
/// import '.../auth/auth_response/auth_response.dart';
/// import '.../common/language/language.dart';
///
/// // Use:
/// import 'package:terracotta/data/models/models.dart';
/// ```
///
/// ## What's exported
/// - Every production domain model.
/// - **Not** exported: `.fixtures.dart` files (test-only).
///
/// ## Fixtures
/// Fixtures stay in their per-model files. If you need a fixture,
/// import the specific `*.fixtures.dart` — keeps `@visibleForTesting`
/// honest and doesn't leak dummy data into prod builds.
library;

// ─── API shapes ──────────────────────────────────────────────────
export 'api/api_envelope/api_envelope.dart';
export 'api/pagination_links/pagination_links.dart';
export 'api/pagination_meta/pagination_meta.dart';

// ─── Auth ────────────────────────────────────────────────────────
export 'auth/auth_response/auth_response.dart';
export 'auth/user/user.dart';

// ─── Common / shared ─────────────────────────────────────────────
export 'common/country_code/country_code.dart';
export 'common/language/language.dart';
