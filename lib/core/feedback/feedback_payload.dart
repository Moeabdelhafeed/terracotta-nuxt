import 'package:flutter/foundation.dart';

import 'feedback_type.dart';

/// Single attached image. Stays in memory as bytes — submitters
/// upload as multipart fields. Keep [bytes] compressed before
/// constructing (`flutter_image_compress`).
@immutable
class FeedbackAttachment {
  const FeedbackAttachment({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;

  int get sizeBytes => bytes.lengthInBytes;
}

/// What `FeedbackScreen` collects, what `FeedbackSubmitter` sends.
@immutable
class FeedbackPayload {
  const FeedbackPayload({
    required this.type,
    required this.description,
    this.severity,
    this.repro,
    this.email,
    this.attachments = const [],
    this.diagnostics = const {},
    this.attachDiagnostics = true,
  });

  final FeedbackType type;
  final FeedbackSeverity? severity;
  final String description;
  final String? repro;
  final String? email;
  final List<FeedbackAttachment> attachments;

  /// Auto-collected device + app + route + connectivity snapshot.
  /// Round-trips to JSON so the offline queue can persist it.
  final Map<String, dynamic> diagnostics;

  /// User toggle — when false, submitters omit [diagnostics] from
  /// the payload.
  final bool attachDiagnostics;

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'severity': severity?.name,
    'description': description,
    'repro': repro,
    'email': email,
    if (attachDiagnostics) 'diagnostics': diagnostics,
    // Attachment bytes are NOT serialised here — too heavy for
    // disk persistence. Submitters that buffer for offline replay
    // should hold attachments outside this payload.
  };

  FeedbackPayload copyWith({
    FeedbackType? type,
    FeedbackSeverity? severity,
    String? description,
    String? repro,
    String? email,
    List<FeedbackAttachment>? attachments,
    Map<String, dynamic>? diagnostics,
    bool? attachDiagnostics,
  }) {
    return FeedbackPayload(
      type: type ?? this.type,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      repro: repro ?? this.repro,
      email: email ?? this.email,
      attachments: attachments ?? this.attachments,
      diagnostics: diagnostics ?? this.diagnostics,
      attachDiagnostics: attachDiagnostics ?? this.attachDiagnostics,
    );
  }
}

/// Outcome of a submission. The screen renders different UI states
/// for each.
enum FeedbackResultKind { success, queuedOffline, failure, cooldown }

@immutable
class FeedbackResult {
  const FeedbackResult({
    required this.kind,
    this.referenceId,
    this.message,
  });

  factory FeedbackResult.success({String? referenceId}) => FeedbackResult(
    kind: FeedbackResultKind.success,
    referenceId: referenceId,
  );
  factory FeedbackResult.queued() =>
      const FeedbackResult(kind: FeedbackResultKind.queuedOffline);
  factory FeedbackResult.failure(String message) =>
      FeedbackResult(kind: FeedbackResultKind.failure, message: message);
  factory FeedbackResult.cooldown() =>
      const FeedbackResult(kind: FeedbackResultKind.cooldown);

  final FeedbackResultKind kind;
  final String? referenceId;
  final String? message;
}
