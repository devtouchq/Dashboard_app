import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart' show MissingPluginException;
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../utils/app_logger.dart';

/// Why a listen session could not start or ended early.
enum SpeechFailure {
  /// Mic / speech-recognition permission was refused by the user.
  permissionDenied,

  /// The device has no speech recognition available at all, or not for
  /// the requested language.
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

/// Thin wrapper around `speech_to_text` so the bloc never touches the
/// plugin directly.
///
/// Recognition runs ON THE DEVICE — no audio leaves the phone. Only the
/// recognised text is sent to the server.
class SpeechService {
  static const _tag = 'SpeechService';

  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;

  /// Kept so [startListening] can tell the caller WHY init failed
  /// instead of guessing.
  Object? _initError;

  /// Callbacks of the session currently running, so errors and the
  /// "done" status the plugin reports mid-session reach the bloc.
  void Function(SpeechFailure reason, String message)? _activeFailure;
  void Function()? _activeDone;

  bool get isListening => _speech.isListening;

  /// Initialises the plugin once. Returns false if speech recognition
  /// isn't available on this device (or permission was refused).
  Future<bool> init() async {
    if (_initialized) return true;
    try {
      _initError = null;
      _initialized = await _speech.initialize(
        onStatus: _onStatus,
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

  /// Locales the device can recognise, as BCP-47-ish IDs (`en_IN` on
  /// Android, `en-IN` on iOS). Empty until [init] succeeded.
  Future<List<String>> availableLocaleIds() async {
    if (!await init()) return const [];
    try {
      final locales = await _speech.locales();
      return locales.map((l) => l.localeId).toList();
    } catch (e) {
      AppLogger.info(_tag, 'locales failed: $e');
      return const [];
    }
  }

  void _onStatus(String status) {
    AppLogger.info(_tag, 'status: $status');
    // "done" = the recogniser closed the session itself (pauseFor or
    // listenFor elapsed). "notListening" fires for the same reason on
    // some Android versions, and after stop()/cancel().
    if (status == 'done' || status == 'notListening') {
      final done = _activeDone;
      _activeDone = null;
      done?.call();
    }
  }

  /// Errors reported by the platform, either while starting a session or
  /// part way through one.
  void _onSpeechError(SpeechRecognitionError e) {
    AppLogger.info(_tag, 'error: ${e.errorMsg} (perm=${e.permanent})');

    final failure = _activeFailure;
    if (failure == null) return;
    // A session can only fail once.
    _activeFailure = null;
    _activeDone = null;

    switch (e.errorMsg) {
      // Heard audio, but couldn't make words out of it. Normal, and the
      // user just needs to try again.
      case 'error_no_match':
      case 'error_speech_timeout':
        failure(SpeechFailure.noSpeech, "Didn't catch that — tap to try again.");
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
      case 'error_language_not_supported':
      case 'error_language_unavailable':
        failure(
          SpeechFailure.unavailable,
          'Speech recognition for this language is not available on the device.',
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
      case 'error_busy':
      case 'error_client':
        failure(SpeechFailure.error, 'Voice input is busy. Tap to try again.');
        break;
      // The session opened but the recogniser gave up straight away. On
      // the iOS Simulator this is the normal outcome: it has no working
      // speech recognition. A real phone recovers on retry.
      case 'error_listen_failed':
      case 'error_retry':
        failure(
          SpeechFailure.error,
          'Speech recognition could not start. Tap to try again — note the iOS Simulator does not support it, use a real phone.',
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
  /// true on the last one. [onDone] fires when the recogniser ends the
  /// session on its own (the user paused for [pauseFor], or [listenFor]
  /// ran out). [onFailure] fires if the session can't start or dies
  /// partway through. [localeId] is a BCP-47 code such as `ml-IN`.
  Future<bool> startListening({
    required void Function(String transcript, bool isFinal) onResult,
    required void Function(SpeechFailure reason, String message) onFailure,
    required void Function() onDone,
    void Function(double level)? onSoundLevel,
    String? localeId,
    Duration pauseFor = const Duration(seconds: 2),
    Duration listenFor = const Duration(seconds: 30),
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
    _activeDone = onDone;
    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult r) =>
            onResult(r.recognizedWords, r.finalResult),
        onSoundLevelChange: onSoundLevel,
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          // Partial results drive the live transcript on screen.
          partialResults: true,
          // The recogniser ends the session itself after a pause —
          // that's what makes the conversation hands-free.
          listenFor: listenFor,
          pauseFor: pauseFor,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
        ),
      );
      return true;
    } on ListenFailedException catch (e) {
      // The platform refused to start. The message says why; the two
      // cases worth telling apart are an unsupported language (iOS makes
      // no recogniser for it) and a device with no microphone input,
      // which is what the iOS Simulator usually reports.
      final reason = '${e.message ?? ''} ${e.details ?? ''}'.trim();
      AppLogger.error(_tag, 'listen failed: $reason (locale=$localeId)');
      _activeFailure = null;
      _activeDone = null;
      final lower = reason.toLowerCase();
      if (lower.contains('recognizer') || lower.contains('recogniser')) {
        onFailure(
          SpeechFailure.unavailable,
          'Speech recognition for this language is not available on this device. Choose another language.',
        );
      } else if (lower.contains('input')) {
        onFailure(
          SpeechFailure.unavailable,
          'No microphone input is available on this device.',
        );
      } else {
        onFailure(
          SpeechFailure.error,
          reason.isEmpty
              ? 'Could not start listening.'
              : 'Could not start listening: $reason',
        );
      }
      return false;
    } catch (e, st) {
      AppLogger.error(_tag, 'listen failed', error: e, stackTrace: st);
      _activeFailure = null;
      _activeDone = null;
      onFailure(SpeechFailure.error, 'Could not start listening.');
      return false;
    }
  }

  Set<String>? _supportedCodes;

  /// Locale codes the device can recognise, normalised to lower-case
  /// BCP-47 (`ml-in`). Empty when the device did not tell us, in which
  /// case callers should not treat any language as unsupported: some
  /// Android recognisers only report the current locale.
  Future<Set<String>> supportedLocaleCodes() async {
    final cached = _supportedCodes;
    if (cached != null) return cached;
    final ids = await availableLocaleIds();
    final codes = ids.map(normaliseLocale).toSet();
    // On Android the list often holds only the downloaded offline
    // languages, while Google's online recogniser handles many more
    // (Malayalam, Tamil…). Don't block anything there: if a language
    // really is unsupported, listening fails with
    // error_language_not_supported and the user is told then.
    // A very short list isn't the real capability of the device either.
    final trusted = !Platform.isAndroid && codes.length >= 5;
    _supportedCodes = trusted ? codes : const <String>{};
    AppLogger.info(_tag,
        'device recognises ${ids.length} locales${trusted ? '' : ' (list not trusted)'}: ${codes.join(', ')}');
    return _supportedCodes!;
  }

  /// `en_IN` / `en-IN` / `EN-in` → `en-in`.
  static String normaliseLocale(String id) =>
      id.replaceAll('_', '-').toLowerCase();

  /// Changes how long a pause ends the current session. The plugin counts
  /// the pause from the last recognised word, or from the start of the
  /// session if nothing has been said yet, so callers start with a long
  /// value and shorten it once the first words arrive.
  void changePauseFor(Duration pauseFor) {
    if (!_initialized || !_speech.isListening) return;
    try {
      _speech.changePauseFor(pauseFor);
    } catch (e) {
      AppLogger.info(_tag, 'changePauseFor failed: $e');
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

  /// Ends the session and keeps whatever was recognised. The final
  /// result arrives through the session's onResult shortly after.
  Future<void> stop() async {
    // The session is over — errors arriving now (a late "no match" after
    // a good transcript) shouldn't pop a message at the user, and the
    // caller already knows it's done.
    _activeFailure = null;
    _activeDone = null;
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
    _activeDone = null;
    if (!_initialized) return;
    try {
      await _speech.cancel();
    } catch (e) {
      AppLogger.info(_tag, 'cancel failed: $e');
    }
  }
}
