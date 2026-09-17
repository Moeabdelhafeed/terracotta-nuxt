// ignore_for_file: one_member_abstracts
// `FeedbackSubmitter` is a strategy interface with multiple concrete
// implementations (mailto / API / fallback / custom). The lint's
// "make it a top-level function" doesn't fit — we need a type to
// pass around as `FeedbackOptions.submitter`.

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/api/api_config.dart';
import '../localization/strings/api_status_strings.dart';
import '../utils/loggers/logger.dart';
import 'feedback_payload.dart';
import 'feedback_strings.dart';

/// Strategy for sending a [FeedbackPayload]. Implementations decide
/// where the payload goes (mailto, REST endpoint, custom backend).
abstract interface class FeedbackSubmitter {
  Future<FeedbackResult> submit(FeedbackPayload payload);
}

/// Composite strategy — tries [primary], falls back to [fallback]
/// when primary throws or returns failure. Used as `Api → Mailto`.
class FallbackFeedbackSubmitter implements FeedbackSubmitter {
  FallbackFeedbackSubmitter({required this.primary, required this.fallback});

  final FeedbackSubmitter primary;
  final FeedbackSubmitter fallback;

  @override
  Future<FeedbackResult> submit(FeedbackPayload payload) async {
    try {
      final r = await primary.submit(payload);
      if (r.kind == FeedbackResultKind.success ||
          r.kind == FeedbackResultKind.queuedOffline) {
        return r;
      }
    } catch (e, st) {
      Logger.m.w(
        '[Feedback] primary submit failed: $e',
        error: e,
        stackTrace: st,
      );
    }
    return fallback.submit(payload);
  }
}

/// Opens `mailto:` with subject + body pre-filled. Attachments are
/// not supported by `mailto:` — the submitter mentions them in the
/// body instead.
class MailtoFeedbackSubmitter implements FeedbackSubmitter {
  MailtoFeedbackSubmitter({required this.toEmail});

  final String toEmail;

  @override
  Future<FeedbackResult> submit(FeedbackPayload payload) async {
    final subject = Uri.encodeComponent(_subject(payload));
    final body = Uri.encodeComponent(_body(payload));
    final uri = Uri.parse('mailto:$toEmail?subject=$subject&body=$body');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return FeedbackResult.success();
      }
      return FeedbackResult.failure(FeedbackStrings.errorNoEmailApp);
    } catch (e) {
      return FeedbackResult.failure(FeedbackStrings.errorEmailOpenFailed('$e'));
    }
  }

  String _subject(FeedbackPayload p) {
    final sev = p.severity == null ? '' : '[${p.severity!.label}] ';
    return '$sev${p.type.label}: ${_oneLine(p.description)}';
  }

  String _oneLine(String input) {
    final stripped = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    return stripped.length > 80 ? '${stripped.substring(0, 77)}...' : stripped;
  }

  String _body(FeedbackPayload p) {
    final lines = <String>[
      'Type: ${p.type.label}',
      if (p.severity != null) 'Severity: ${p.severity!.label}',
      '',
      'Description:',
      p.description,
      if ((p.repro ?? '').isNotEmpty) ...[
        '',
        'Repro steps:',
        p.repro!,
      ],
      if (p.attachments.isNotEmpty) ...[
        '',
        'Attachments: ${p.attachments.length} screenshot(s) — '
            'unable to inline via mailto. Reattach when replying.',
      ],
      if (p.attachDiagnostics && p.diagnostics.isNotEmpty) ...[
        '',
        '--- Diagnostics ---',
        const JsonEncoder.withIndent('  ').convert(p.diagnostics),
      ],
    ];
    return lines.join('\n');
  }
}

/// Posts a JSON payload + multipart attachments to a backend
/// endpoint. Endpoint is joined onto `BaseApiConstants.baseUrl` when
/// it doesn't start with `http`.
class ApiFeedbackSubmitter implements FeedbackSubmitter {
  ApiFeedbackSubmitter({required this.endpoint, Dio? dio})
    : _dio = dio ?? Dio();

  final String endpoint;
  final Dio _dio;

  @override
  Future<FeedbackResult> submit(FeedbackPayload payload) async {
    if (endpoint.isEmpty) {
      return FeedbackResult.failure(FeedbackStrings.errorNoEndpoint);
    }
    final url = endpoint.startsWith('http')
        ? endpoint
        : '${BaseApiConstants.baseUrl.replaceAll(RegExp(r'/$'), '')}'
              '${endpoint.startsWith('/') ? endpoint : '/$endpoint'}';

    try {
      final form = FormData();
      form.fields.add(
        MapEntry(
          'payload',
          jsonEncode(payload.toJson()),
        ),
      );
      for (var i = 0; i < payload.attachments.length; i++) {
        final a = payload.attachments[i];
        form.files.add(
          MapEntry(
            'attachments',
            MultipartFile.fromBytes(
              a.bytes,
              filename: a.fileName,
            ),
          ),
        );
      }
      final res = await _dio.post<Map<String, dynamic>>(url, data: form);
      final ref =
          res.data?['id']?.toString() ?? res.data?['referenceId']?.toString();
      return FeedbackResult.success(referenceId: ref);
    } on DioException catch (e) {
      Logger.m.w('[Feedback] API submit failed: ${e.message}');
      return FeedbackResult.failure(
        e.response?.statusMessage ?? e.message ?? ApiStatusStrings.networkError,
      );
    } catch (e) {
      return FeedbackResult.failure('$e');
    }
  }
}

/// Wraps any submitter in a closure-based custom strategy. Use to
/// inject analytics, log redaction, or alternative transports
/// (Slack webhook, Linear / Jira API).
class CustomFeedbackSubmitter implements FeedbackSubmitter {
  const CustomFeedbackSubmitter(this.handler);

  final Future<FeedbackResult> Function(FeedbackPayload payload) handler;

  @override
  Future<FeedbackResult> submit(FeedbackPayload payload) => handler(payload);
}
