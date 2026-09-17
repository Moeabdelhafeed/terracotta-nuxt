import '../../shared/module/text_field/models/text_field_models.dart';
import 'speech_to_text_service.dart';

/// Bridges [SpeechToTextService] to the [TextFieldSpeechAdapter] expected by
/// `VoiceInputConfig` — keeps DI lookups outside the `lib/shared/module/`
/// boundary (see CLAUDE.md "No `getIt` in module widget code").
///
/// ```dart
/// VoiceInputConfig(
///   adapter: SpeechToTextTextFieldAdapter(getIt<SpeechToTextService>()),
///   locale: 'en_US',
/// )
/// ```
class SpeechToTextTextFieldAdapter implements TextFieldSpeechAdapter {
  SpeechToTextTextFieldAdapter(this._service);

  final SpeechToTextService _service;

  @override
  Future<void> start({
    String? localeId,
    required void Function(String text, bool isFinal) onResult,
    required void Function(String error) onError,
  }) {
    return _service.startListening(
      localeId: localeId,
      onResult: onResult,
      onError: onError,
    );
  }

  @override
  Future<void> stop() => _service.stopListening();

  @override
  void cancel() => _service.cancel();
}
