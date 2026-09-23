import 'dart:async';

import 'package:flutter/services.dart' show MissingPluginException;
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../utils/app_logger.dart';

/// Why a listen session could not start.
enum SpeechFailure {
  /// Mic / speech-recognition permission was refused by the user.
  permissionDenied,

  /// The device has no speech recognition available at all.
  unavailable,

  /// The plugin's native side isn't in the running binary. Happens after
  /// adding the package and only hot-restarting — the app needs a full
  /// rebuild.
  notInstalled,

  /// Audio came through but no words were recognised.
  noSpeech,

  /// Something else went wrong (see the message).
  error,
}

/// Thin wrapper around `speech_to_text` so the UI never touches the
/// plugin directly.
///
/// Recognition runs ON THE DEVICE — no audio leaves the phone. What we
/// send to the server is the transcribed text, using the same
/// `/api/AIAssistant/SendMessage` endpoint the typed questions use.
class SpeechService {
  static const _tag = 'SpeechService';

  /// Safety net so a stuck session can't listen forever if the release
  /// gesture is somehow missed.
  static const _maxSession = Duration(minutes: 2);

  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;

  /// Kept so [startListening] can tell the caller WHY init failed
  /// instead of guessing.
  Object? _initError;

  /// Failure callback of the session currently running, so errors the
  /// plugin reports mid-session reach the UI instead of only the log.
  void Function(SpeechFailure reason, String message)? _activeFailure;

  bool get isListening => _speech.isListening;

  /// Initialises the plugin once. Returns false if speech recognition
  /// isn't available on this device (or permission was refused).
  Future<bool> init() async {
    if (_initialized) return true;
    try {
      _initError = null;
      _initialized = await _speech.initialize(
        onStatus: (status) => AppLogger.info(_tag, 'status: $status'),
        onError: _onSpeechError,
      );
    } catch (e, st) {
      AppLogger.error(_tag, 'initialize failed', error: e, stackTrace: st);
      _initError = e;
      _initialized = false;
    }
    AppLogger.info(_tag, 'initialized = $_initialized');
    return _initialized;
  }

  /// Errors reported by the platform, either while starting a session or
  /// part way through one. Without this the UI only ever hears silence
  /// and has to guess that nothing was said.
  void _onSpeechError(SpeechRecognitionError e) {
    AppLogger.info(_tag, 'error: ${e.errorMsg} (perm=${e.permanent})');

    final failure = _activeFailure;
    if (failure == null) return;
    // A session can only fail once.
    _activeFailure = null;

    switch (e.errorMsg) {
      // Heard audio, but couldn't make words out of it. Normal, and the
      // user just needs to try again.
      case 'error_no_match':
      case 'error_speech_timeout':
        failure(SpeechFailure.noSpeech, "Didn't catch that — try again.");
        break;
      case 'error_permission':
      case 'error_speech_recognizer_request_not_authorized':
        failure(
          SpeechFailure.permissionDenied,
          'Microphone access is off. Enable it in Settings to use voice.',
        );
        break;
      // The language pack for on-device recognition isn't downloaded.
      case 'error_assets_not_installed':
        failure(
          SpeechFailure.unavailable,
          'Speech recognition for this language is not installed on the device.',
        );
        break;
      case 'error_speech_recognizer_disabled':
        failure(
          SpeechFailure.unavailable,
          'Speech recognition is turned off in device settings.',
        );
        break;
      case 'error_network':
      case 'error_network_timeout':
        failure(
          SpeechFailure.error,
          'Voice input needs a network connection right now.',
        );
        break;
      default:
        // error_listen_failed, error_unknown (nnn), error_audio, …
        // Common on the iOS Simulator, where the speech service often
        // isn't usable at all.
        failure(
          SpeechFailure.error,
          'Voice input failed on this device (${e.errorMsg}).',
        );
    }
  }

  /// Starts a listen session.
  ///
  /// [onResult] fires repeatedly with the transcript so far; [isFinal] is
  /// true on the last one. [onFailure] fires if the session can't start
  /// or dies partway through.
  Future<bool> startListening({
    required void Function(String transcript, bool isFinal) onResult,
    required void Function(SpeechFailure reason, String message) onFailure,
    void Function(double level)? onSoundLevel,
    String? localeId,
  }) async {
    final ready = await init();
    if (!ready) {
      // The native side isn't in this binary — a hot restart after adding
      // the package isn't enough, the app has to be rebuilt. Checking the
      // permission here would also throw, so don't blame the microphone.
      if (_initError is MissingPluginException) {
        onFailure(
          SpeechFailure.notInstalled,
          'Voice input is not available in this build of the app.',
        );
        return false;
      }

      final denied = !await hasPermission();
      onFailure(
        denied ? SpeechFailure.permissionDenied : SpeechFailure.unavailable,
        denied
            ? 'Microphone access is off. Enable it in Settings to use voice.'
            : 'Voice input is not available on this device.',
      );
      return false;
    }

    _activeFailure = onFailure;
    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult r) =>
            onResult(r.recognizedWords, r.finalResult),
        onSoundLevelChange: onSoundLevel,
        listenOptions: SpeechListenOptions(
          // Partial results drive the live transcript while holding.
          partialResults: true,
          // The user decides when to stop by releasing the button, so
          // don't cut the session off on a natural pause.
          listenFor: _maxSession,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
          localeId: localeId,
        ),
      );
      return true;
    } catch (e, st) {
      AppLogger.error(_tag, 'listen failed', error: e, stackTrace: st);
      _activeFailure = null;
      onFailure(SpeechFailure.error, 'Could not start recording.');
      return false;
    }
  }

  /// Returns true if microphone permission has already been granted.
  Future<bool> hasPermission() async {
    try {
      return await _speech.hasPermission;
    } catch (_) {
      return false;
    }
  }

  /// Ends the session and keeps whatever was recognised.
  Future<void> stop() async {
    // The session is over — errors arriving now (a late "no match" after
    // a good transcript) shouldn't pop a message at the user.
    _activeFailure = null;
    if (!_initialized) return;
    try {
      await _speech.stop();
    } catch (e) {
      AppLogger.info(_tag, 'stop failed: $e');
    }
  }

  /// Ends the session and throws the transcript away.
  Future<void> cancel() async {
    _activeFailure = null;
    if (!_initialized) return;
    try {
      await _speech.cancel();
    } catch (e) {
      AppLogger.info(_tag, 'cancel failed: $e');
    }
  }
}
