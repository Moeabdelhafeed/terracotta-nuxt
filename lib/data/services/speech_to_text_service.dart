import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Lightweight wrapper around the `speech_to_text` package.
/// Registered in `service_locator.dart` — resolve via
/// `getIt<SpeechToTextService>()`.
///
/// Only one listening session runs at a time; starting a new one
/// while already listening replaces the active callbacks.
class SpeechToTextService {
  SpeechToTextService();

  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  /// Whether the engine is available (permissions granted, hardware OK).
  bool get isAvailable => _isInitialized;

  /// Whether a listening session is active right now.
  bool get isListening => _speech.isListening;

  /// Initialize the recognizer. Idempotent. Returns `false` when
  /// permissions are denied or the device doesn't support STT.
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    _isInitialized = await _speech.initialize(
      onError: _onError,
      onStatus: _onStatus,
    );
    return _isInitialized;
  }

  void Function(String text, bool isFinal)? _onResultCallback;
  void Function(String error)? _onErrorCallback;
  void Function(String status)? _onStatusCallback;

  /// Start listening for speech.
  ///
  /// [onResult] fires for each partial + final transcription.
  /// [localeId] selects the recognition language (e.g. `en_US`).
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    void Function(String error)? onError,
    void Function(String status)? onStatus,
    String? localeId,
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) {
        onError?.call('Speech recognition not available');
        return;
      }
    }

    if (_onResultCallback != null && kDebugMode) {
      debugPrint('[SpeechToTextService] Replacing active listening session.');
    }

    _onResultCallback = onResult;
    _onErrorCallback = onError;
    _onStatusCallback = onStatus;

    await _speech.listen(
      onResult: _handleResult,
      listenOptions: SpeechListenOptions(
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
        localeId: localeId,
        listenFor: listenFor,
        pauseFor: pauseFor,
      ),
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
    _clearCallbacks();
  }

  Future<void> cancel() async {
    await _speech.cancel();
    _clearCallbacks();
  }

  /// Available locales for recognition on this device.
  Future<List<LocaleName>> getLocales() async {
    if (!_isInitialized) await initialize();
    return _speech.locales();
  }

  void _clearCallbacks() {
    _onResultCallback = null;
    _onErrorCallback = null;
    _onStatusCallback = null;
  }

  void _handleResult(SpeechRecognitionResult result) {
    _onResultCallback?.call(result.recognizedWords, result.finalResult);
  }

  void _onError(SpeechRecognitionError error) {
    _onErrorCallback?.call(error.errorMsg);
  }

  void _onStatus(String status) {
    _onStatusCallback?.call(status);
  }
}
