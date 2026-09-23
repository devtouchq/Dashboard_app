import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../utils/app_logger.dart';

/// Why a recording could not start.
enum RecordFailure {
  /// Mic permission was refused by the user.
  permissionDenied,

  /// The device has no usable microphone / the encoder isn't supported.
  unavailable,

  /// Something else went wrong (see the message).
  error,
}

/// A finished recording.
class Recording {
  final File file;
  final Duration duration;

  const Recording({required this.file, required this.duration});
}

/// Records microphone audio to an m4a (AAC) file, which is what gets sent
/// to the server. Nothing is transcribed on the device.
class AudioRecorderService {
  static const _tag = 'AudioRecorderService';

  /// Anything shorter than this is an accidental tap, not a message.
  static const minDuration = Duration(milliseconds: 700);

  /// Hard ceiling so a stuck session can't fill the disk.
  static const maxDuration = Duration(minutes: 5);

  final AudioRecorder _recorder = AudioRecorder();

  DateTime? _startedAt;
  String? _currentPath;

  bool get isRecording => _startedAt != null;

  /// Fires while recording with the current input level in dBFS
  /// (roughly -60 = silence, 0 = loudest).
  Stream<Amplitude> amplitude(
          [Duration interval = const Duration(milliseconds: 200)]) =>
      _recorder.onAmplitudeChanged(interval);

  /// Starts recording to a fresh file in the app's temp directory.
  Future<bool> start({
    required void Function(RecordFailure reason, String message) onFailure,
  }) async {
    if (isRecording) return false;

    try {
      // Prompts the user the first time.
      if (!await _recorder.hasPermission()) {
        onFailure(
          RecordFailure.permissionDenied,
          'Microphone access is off. Enable it in Settings to send voice messages.',
        );
        return false;
      }

      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,
        sampleRate: 44100,
        numChannels: 1,
      );

      if (!await _recorder.isEncoderSupported(config.encoder)) {
        onFailure(
          RecordFailure.unavailable,
          'This device cannot record audio in the required format.',
        );
        return false;
      }

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(config, path: path);
      _currentPath = path;
      _startedAt = DateTime.now();
      AppLogger.info(_tag, 'recording → $path');
      return true;
    } catch (e, st) {
      AppLogger.error(_tag, 'start failed', error: e, stackTrace: st);
      await _safeCleanup();
      onFailure(RecordFailure.error, 'Could not start recording.');
      return false;
    }
  }

  /// Stops and returns the finished file, or null if the recording was
  /// too short or the file never materialised.
  Future<Recording?> stop() async {
    if (!isRecording) return null;
    final startedAt = _startedAt!;
    _startedAt = null;

    try {
      final path = await _recorder.stop() ?? _currentPath;
      _currentPath = null;
      if (path == null) return null;

      final file = File(path);
      if (!await file.exists() || await file.length() == 0) {
        AppLogger.info(_tag, 'stop: no audio captured');
        return null;
      }

      final duration = DateTime.now().difference(startedAt);
      if (duration < minDuration) {
        AppLogger.info(_tag, 'stop: too short (${duration.inMilliseconds}ms)');
        await _delete(file);
        return null;
      }

      AppLogger.info(_tag,
          'recorded ${await file.length()} bytes, ${duration.inSeconds}s');
      return Recording(file: file, duration: duration);
    } catch (e, st) {
      AppLogger.error(_tag, 'stop failed', error: e, stackTrace: st);
      await _safeCleanup();
      return null;
    }
  }

  /// Stops and deletes the file — used when the user slides to cancel.
  Future<void> cancel() async {
    if (!isRecording) return;
    _startedAt = null;
    try {
      await _recorder.cancel();
    } catch (e) {
      AppLogger.info(_tag, 'cancel failed: $e');
    }
    await _safeCleanup();
  }

  Future<void> _safeCleanup() async {
    final path = _currentPath;
    _currentPath = null;
    if (path == null) return;
    await _delete(File(path));
  }

  Future<void> _delete(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (e) {
      AppLogger.info(_tag, 'could not delete ${file.path}: $e');
    }
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
