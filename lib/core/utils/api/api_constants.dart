// ---------------------------------------------------------------------------
// API Constants
// ---------------------------------------------------------------------------

/// Default timeout for API requests.
const Duration kApiTimeout = Duration(seconds: 30);

/// Timeout for upload/download requests (files, images).
const Duration kApiUploadTimeout = Duration(seconds: 120);

/// Max number of automatic retries on transient failures.
const int kApiMaxRetries = 2;

/// Delay between retries (multiplied by attempt number).
const Duration kApiRetryDelay = Duration(seconds: 1);

/// Max entries in the in-memory response cache.
const int kApiCacheMaxSize = 100;

/// Default cache TTL for GET responses.
const Duration kApiCacheDefaultTtl = Duration(minutes: 5);

/// Max concurrent HTTP requests before queuing.
const int kApiMaxConcurrent = 10;

// ─── Smart JSON log truncation ─────────────────────────────────────────
// Each subset of a logged JSON body has its own budget — one big field
// no longer eats the budget of its siblings. Tweak these freely.

/// Max characters per individual string value in logged JSON.
/// Longer strings are **middle-truncated**: `"head ... +N chars ... tail"`.
const int kApiLogMaxStringLength = 500;

/// Max items shown per array in logged JSON.
/// Longer arrays show the first/last halves with a middle marker:
/// `[ item1, item2, ..., ... +N truncated ..., itemLast-1, itemLast ]`.
const int kApiLogMaxArrayItems = 20;

/// Hard safety ceiling on the total logged-JSON length.
/// If the fully-budgeted output still exceeds this, a final
/// middle-truncation is applied as a last-resort safety net.
const int kApiLogTotalCeiling = 50000;

/// Headers that contain sensitive data — masked in logs.
const Set<String> kSensitiveHeaders = {
  'authorization',
  'x-api-token',
  'cookie',
  'set-cookie',
  'x-auth-token',
  'x-session-id',
};

/// Headers excluded from log output (noise).
const Set<String> kExcludedLogHeaders = {
  'content-length',
  'host',
  'user-agent',
  'accept-encoding',
  'connection',
};

// ---------------------------------------------------------------------------
// Log config — per-endpoint logging control
// ---------------------------------------------------------------------------

/// Per-endpoint log control. `null` = use global flag, `true`/`false` = force.
///
/// ```dart
/// static ApiLogConfig logGetUsers = (request: true, response: false);
/// ```
typedef ApiLogConfig = ({bool? request, bool? response});

/// Default log config — both null (use global).
const ApiLogConfig kApiLogDefault = (request: null, response: null);

/// Silent — both false (force off).
const ApiLogConfig kApiLogSilent = (request: false, response: false);

/// Verbose — both true (force on).
const ApiLogConfig kApiLogVerbose = (request: true, response: true);

// ---------------------------------------------------------------------------
// Cache entry
// ---------------------------------------------------------------------------

/// Internal cache entry with expiry timestamp.
class ApiCacheEntry {
  ApiCacheEntry(this.response, this.expiry);
  final dynamic response;
  final DateTime expiry;
  bool get isExpired => DateTime.now().isAfter(expiry);
}
