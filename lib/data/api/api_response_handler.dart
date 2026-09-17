import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/error/app_exception.dart';
import '../../core/types/paginated_result.dart';
import '../../core/types/result.dart';
import '../../core/utils/loggers/logger.dart';
import '../models/api/api_envelope/api_envelope.dart';
import '../models/api/envelope_list.dart';
import '../models/api/pagination_links/pagination_links.dart';
import '../models/api/pagination_meta/pagination_meta.dart';

// ---------------------------------------------------------------------------
// Response handling — one helper per response shape, all returning [Result].
// ---------------------------------------------------------------------------
//
// Every successful response is expected to conform to [ApiEnvelope]:
//
// ```json
// {
//   "status": true,
//   "status_code": 200,
//   "message": "…",
//   "data": { … }  or  [ … ]  or  { "items": [], "meta": {}, "links": {} },
//   "errors": [ "…" ]   // optional (usually on failure)
// }
// ```
//
// Each `handle*` helper parses the wire through `ApiEnvelope.fromJson`
// and returns a `Result<T, AppException>`. A falsy `status` or
// non-2xx status becomes [ValidationException] / [ServerException] /
// [AuthException] / [NotFoundException] via [_errorFromEnvelope].

/// Parse a single-object response into `Result<T, AppException>`.
Result<T, AppException> handleSingleResponse<T>(
  Response response,
  T Function(Map<String, dynamic>) fromJson,
) {
  return Result.runCatching<T, AppException>(
    () {
      final envelope = _decodeEnvelope<T>(
        response,
        (raw) {
          if (raw is! Map<String, dynamic>) {
            throw ValidationException(
              message:
                  'Expected `data` to be an object, got ${raw.runtimeType}',
              code: response.statusCode?.toString(),
            );
          }
          return fromJson(raw);
        },
      );
      if (isFailure(envelope, response.statusCode)) {
        throw _errorFromEnvelope(envelope, response.statusCode);
      }
      final data = envelope.data;
      if (data == null) {
        // A SUCCESSFUL call with no payload. Around forty operations on
        // this API answer `data: null` — changing a password, verifying
        // a code — and treating that as a parse failure turned every one
        // of them into an error the customer could not act on.
        //
        // Offered to the caller's own parser as an empty object, so it
        // succeeds exactly where an empty object is a valid value: an
        // identity `(json) => json` yields `{}`, while a real model
        // still refuses it for the required fields it is missing, and
        // falls through to the error below.
        try {
          return fromJson(const <String, dynamic>{});
        } on Object {
          throw ValidationException(
            message: 'Expected `data` on a successful response',
            code: response.statusCode?.toString(),
          );
        }
      }
      return data;
    },
    mapError: _logAndMap('handleSingleResponse'),
  );
}

/// Parse a single response AND the envelope's own `meta` beside it.
///
/// Same wire as [handleSingleResponse] — `data: { ... }` — but keeping
/// the top-level `meta`, which a `fromJson` handed `data` alone can
/// never see. `GET /api/notifications` is the caller: the tab tallies
/// are a SIBLING of `data`, not part of it. See [EnvelopeOne].
Result<EnvelopeOne<T>, AppException> handleSingleWithMetaResponse<T>(
  Response response,
  T Function(Map<String, dynamic>) fromJson,
) => handleSingleResponse<T>(response, fromJson).map(
  (value) => EnvelopeOne<T>(value: value, meta: _metaOf(response)),
);

/// The envelope's `meta`, read straight off the body.
///
/// [handleSingleResponse] decodes the envelope internally and hands
/// back only the payload, so rather than duplicate all of it — the
/// `success`/`status` split, the field-keyed 422, the `data: null`
/// success — this reaches for the one key it needs and lets that
/// function stay the single place any of the rest is decided.
Map<String, dynamic>? _metaOf(Response response) {
  final body = response.data;
  if (body is! Map) return null;
  final meta = body['meta'];
  return meta is Map<String, dynamic> ? meta : null;
}

/// Parse a list response (`data: [ ... ]`) into `Result<List<T>, AppException>`.
Result<List<T>, AppException> handleListResponse<T>(
  Response response,
  T Function(Map<String, dynamic>) fromJson,
) {
  return Result.runCatching<List<T>, AppException>(
    () {
      final envelope = _decodeEnvelope<List<T>>(
        response,
        (raw) {
          if (raw is! List) {
            throw ValidationException(
              message: 'Expected `data` to be a list, got ${raw.runtimeType}',
              code: response.statusCode?.toString(),
            );
          }
          return raw
              .cast<Map<String, dynamic>>()
              .map(fromJson)
              .toList(growable: false);
        },
      );
      if (isFailure(envelope, response.statusCode)) {
        throw _errorFromEnvelope(envelope, response.statusCode);
      }
      return envelope.data ?? const [];
    },
    mapError: _logAndMap('handleListResponse'),
  );
}

/// Parse a list response AND the envelope's own `meta` beside it.
///
/// Same wire as [handleListResponse] — `data: [ ... ]` — but keeping
/// the top-level `meta` the caller would otherwise never see, because
/// a `fromJson` is handed `data` alone. See [EnvelopeList].
Result<EnvelopeList<T>, AppException> handleListWithMetaResponse<T>(
  Response response,
  T Function(Map<String, dynamic>) fromJson,
) {
  return Result.runCatching<EnvelopeList<T>, AppException>(
    () {
      final envelope = _decodeEnvelope<List<T>>(
        response,
        (raw) {
          if (raw is! List) {
            throw ValidationException(
              message: 'Expected `data` to be a list, got ${raw.runtimeType}',
              code: response.statusCode?.toString(),
            );
          }
          return raw
              .cast<Map<String, dynamic>>()
              .map(fromJson)
              .toList(growable: false);
        },
      );
      if (isFailure(envelope, response.statusCode)) {
        throw _errorFromEnvelope(envelope, response.statusCode);
      }
      return EnvelopeList<T>(
        items: envelope.data ?? const [],
        meta: envelope.meta,
      );
    },
    mapError: _logAndMap('handleListWithMetaResponse'),
  );
}

/// Parse a paginated response (`data: { items: [], meta: {}, links: {} }`)
/// into `Result<PaginatedResult<T>, AppException>`.
Result<PaginatedResult<T>, AppException> handlePaginatedResponse<T>(
  Response response,
  T Function(Map<String, dynamic>) fromJson,
) {
  return Result.runCatching<PaginatedResult<T>, AppException>(
    () {
      final envelope = _decodeEnvelope<PaginatedResult<T>>(
        response,
        (raw) {
          if (raw is! Map<String, dynamic>) {
            throw ValidationException(
              message: 'Expected `data` to be an object with `items`',
              code: response.statusCode?.toString(),
            );
          }
          final rawItems = raw['items'];
          if (rawItems is! List) {
            throw ValidationException(
              message: 'Expected `data.items` to be a list',
              code: response.statusCode?.toString(),
            );
          }
          final items = rawItems
              .cast<Map<String, dynamic>>()
              .map(fromJson)
              .toList(growable: false);
          final meta = raw['meta'] is Map<String, dynamic>
              ? PaginationMeta.fromJson(raw['meta'] as Map<String, dynamic>)
              : null;
          final links = raw['links'] is Map<String, dynamic>
              ? PaginationLinks.fromJson(raw['links'] as Map<String, dynamic>)
              : null;
          return PaginatedResult<T>(items: items, meta: meta, links: links);
        },
      );
      if (isFailure(envelope, response.statusCode)) {
        throw _errorFromEnvelope(envelope, response.statusCode);
      }
      final data = envelope.data;
      if (data == null) {
        throw ValidationException(
          message: 'Expected `data` on a successful paginated response',
          code: response.statusCode?.toString(),
        );
      }
      return data;
    },
    mapError: _logAndMap('handlePaginatedResponse'),
  );
}

/// Decode a [Response] into a typed [ApiEnvelope]. Shared across the
/// three `handle*` helpers — each passes its shape-specific `fromJsonT`
/// to unwrap `data`.
ApiEnvelope<T> _decodeEnvelope<T>(
  Response response,
  T Function(Object?) fromJsonT,
) {
  final decoded = parseBody(response.data);
  if (decoded is! Map<String, dynamic>) {
    throw ValidationException(
      message: 'Expected object response, got ${decoded.runtimeType}',
      code: response.statusCode?.toString(),
    );
  }
  return ApiEnvelope.fromJson(decoded, fromJsonT);
}

/// Parses raw response data (String → JSON, or pass-through).
dynamic parseBody(dynamic data) {
  if (data is! String) return data;
  final trimmed = data.trim();
  if (trimmed.isEmpty) return null;
  try {
    var cleaned = trimmed;
    if (cleaned.startsWith('\uFEFF')) cleaned = cleaned.substring(1);
    return jsonDecode(cleaned);
  } catch (_) {
    return data;
  }
}

// ─── Internal helpers ───────────────────────────────────────────────

/// Whether a response failed, by either of the two things that can say
/// so.
///
/// The HTTP status is authoritative and is checked SEPARATELY from the
/// body's flag. A 422 whose body did not carry a flag this code
/// recognised used to sail into the success path — the transport had
/// already said it failed and nothing looked.
bool isFailure(ApiEnvelope<dynamic> envelope, int? statusCode) {
  if (!envelope.status) return true;
  if (statusCode == null) return false;
  return statusCode < 200 || statusCode >= 300;
}

/// Build the right [AppException] subtype from a failed envelope.
AppException _errorFromEnvelope(ApiEnvelope envelope, int? statusCode) {
  final message = envelope.message ?? 'Request failed';
  final errors = envelope.errors;
  final code = statusCode?.toString();

  if (statusCode == 401 || statusCode == 403) {
    return AuthException(message: message, code: code);
  }
  if (statusCode == 404) {
    return NotFoundException(message: message, code: code);
  }
  if (statusCode != null && statusCode >= 500) {
    return ServerException(message: message, code: code);
  }
  return ValidationException(
    message: message,
    code: code,
    errors: errors,
    fieldErrors: envelope.fieldErrors,
  );
}

/// Produce an [AppException] from any thrown object raised inside a
/// `handleXxxResponse`. Logs first so the parse failure is observable.
AppException Function(Object, StackTrace) _logAndMap(String ctx) =>
    (error, stackTrace) {
      // An `AppException` here was thrown ON PURPOSE, a few lines up, to
      // carry a rejection the server already explained — a 422 naming a
      // field, a 404, a 500. That is the handled path working, and
      // logging it as a crash with a stack trace said the opposite: a
      // sign-in refused with "User not found." printed an ERROR whose
      // trace pointed at our own throw site, which reads like the
      // failure was never handled at all.
      //
      // The response itself is already logged in full by the API
      // logger, so one line is enough here.
      if (error is AppException) {
        Logger.a.w('$ctx rejected: ${error.message}');
      } else {
        // Anything else really is unexpected — a shape that would not
        // parse, a type that was not what the model said. That wants
        // the stack.
        Logger.a.e('$ctx failed', error: error, stackTrace: stackTrace);
      }
      return AppException.fromError(error, stackTrace);
    };
