import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/voice_languages.dart';
import '../../../core/di/local_storage_service.dart';
import '../../../core/services/speech_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/repositories/chat_repo.dart';

// ─────────────────────────────────────────────────────────────
//  Events
// ─────────────────────────────────────────────────────────────
abstract class VoiceAssistantEvent extends Equatable {
  const VoiceAssistantEvent();
  @override
  List<Object?> get props => [];
}

/// The voice screen opened: start listening straight away.
class VoiceSessionStarted extends VoiceAssistantEvent {
  const VoiceSessionStarted();
}

/// The big button in the middle. What it does depends on the phase:
/// idle/error → listen, listening → send what was heard, thinking →
/// cancel, speaking → interrupt and listen.
class VoiceOrbTapped extends VoiceAssistantEvent {
  const VoiceOrbTapped();
}

class VoiceLanguageChanged extends VoiceAssistantEvent {
  final VoiceLanguage language;
  const VoiceLanguageChanged(this.language);
  @override
  List<Object?> get props => [language];
}

class VoiceMuteToggled extends VoiceAssistantEvent {
  const VoiceMuteToggled();
}

/// The screen is closing: stop the mic and the speaker.
class VoiceSessionEnded extends VoiceAssistantEvent {
  const VoiceSessionEnded();
}

// Internal events raised by the recogniser, the player and timers. Each
// carries the generation it belongs to so a late callback from an
// interrupted session is ignored.
class _TranscriptChanged extends VoiceAssistantEvent {
  final int generation;
  final String text;
  final bool isFinal;
  const _TranscriptChanged(this.generation, this.text, this.isFinal);
  @override
  List<Object?> get props => [generation, text, isFinal];
}

class _ListenEnded extends VoiceAssistantEvent {
  final int generation;
  const _ListenEnded(this.generation);
  @override
  List<Object?> get props => [generation];
}

class _LevelChanged extends VoiceAssistantEvent {
  final int generation;
  final double level;
  const _LevelChanged(this.generation, this.level);
  @override
  List<Object?> get props => [generation, level];
}

class _PlaybackFinished extends VoiceAssistantEvent {
  final int generation;
  const _PlaybackFinished(this.generation);
  @override
  List<Object?> get props => [generation];
}

class _Failed extends VoiceAssistantEvent {
  final int generation;
  final SpeechFailure reason;
  final String message;
  const _Failed(this.generation, this.reason, this.message);
  @override
  List<Object?> get props => [generation, reason, message];
}

// ─────────────────────────────────────────────────────────────
//  State
// ─────────────────────────────────────────────────────────────
enum VoicePhase {
  /// Mic off, waiting for a tap.
  idle,

  /// Recognising the user's speech.
  listening,

  /// Question sent, waiting for the server.
  thinking,

  /// Playing (or, when muted, showing) the answer.
  speaking,

  /// Something went wrong; the message is in [VoiceAssistantState.error].
  error,
}

/// One question + answer, kept so the screen can show the latest and the
/// chat can log it.
class VoiceExchange extends Equatable {
  final int id;

  /// What the phone recognised: the question as sent to the server.
  final String transcript;

  /// The answer as the server sent it (may be HTML, like SendMessage).
  final String reply;

  /// The answer with markup removed, for the voice screen.
  final String replyPlainText;
  final VoiceLanguage language;

  const VoiceExchange({
    required this.id,
    required this.transcript,
    required this.reply,
    required this.replyPlainText,
    required this.language,
  });

  @override
  List<Object?> get props => [id, transcript, reply, replyPlainText, language];
}

class VoiceAssistantState extends Equatable {
  final VoicePhase phase;

  /// Mic input level 0..1 while listening, for the orb animation.
  final double level;

  /// Words recognised so far in the current utterance, updated live
  /// while the user talks. Cleared when a new utterance starts.
  final String liveTranscript;

  final bool muted;
  final VoiceLanguage language;

  /// Latest completed turn; null before the first answer.
  final VoiceExchange? lastExchange;

  final String? error;

  /// Lower-case BCP-47 codes this device can recognise. Empty until
  /// loaded, or when the device gave no usable list; then every language
  /// is treated as supported and the recogniser has the final say.
  final Set<String> supportedCodes;

  const VoiceAssistantState({
    this.phase = VoicePhase.idle,
    this.level = 0,
    this.liveTranscript = '',
    this.muted = false,
    this.language = VoiceLanguages.fallback,
    this.lastExchange,
    this.error,
    this.supportedCodes = const {},
  });

  bool get heardSpeech => liveTranscript.trim().isNotEmpty;

  /// Whether the device's recogniser handles [lang]. Unknown counts as
  /// supported.
  bool supports(VoiceLanguage lang) =>
      supportedCodes.isEmpty ||
      supportedCodes.contains(lang.code.toLowerCase());

  VoiceAssistantState copyWith({
    VoicePhase? phase,
    double? level,
    String? liveTranscript,
    bool? muted,
    VoiceLanguage? language,
    VoiceExchange? lastExchange,
    String? error,
    bool clearError = false,
    Set<String>? supportedCodes,
  }) {
    return VoiceAssistantState(
      phase: phase ?? this.phase,
      level: level ?? this.level,
      liveTranscript: liveTranscript ?? this.liveTranscript,
      muted: muted ?? this.muted,
      language: language ?? this.language,
      lastExchange: lastExchange ?? this.lastExchange,
      error: clearError ? null : (error ?? this.error),
      supportedCodes: supportedCodes ?? this.supportedCodes,
    );
  }

  @override
  List<Object?> get props => [
        phase,
        level,
        liveTranscript,
        muted,
        language,
        lastExchange,
        error,
        supportedCodes,
      ];
}

// ─────────────────────────────────────────────────────────────
//  Bloc
// ─────────────────────────────────────────────────────────────
/// Runs one hands-free voice conversation: recognise speech on the
/// device until the user pauses, send the text to the Speak endpoint,
/// play the spoken answer, then listen again. The screen only renders
/// state and forwards taps.
class VoiceAssistantBloc
    extends Bloc<VoiceAssistantEvent, VoiceAssistantState> {
  static const _tag = 'VoiceAssistantBloc';

  /// How long we wait for the user to START talking before the session
  /// is allowed to close. The plugin measures its pause from the start of
  /// the session until the first word, so this has to be generous.
  static const _waitForSpeech = Duration(seconds: 15);

  /// Once the user has started, a pause this long ends the utterance and
  /// sends it.
  static const _pauseToSend = Duration(seconds: 2);

  /// Longest single session the recogniser keeps open.
  static const _maxUtterance = Duration(seconds: 45);

  /// The recogniser itself gives up after a few silent seconds. In a
  /// hands-free conversation we quietly start it again this many times
  /// before falling back to "Tap to speak".
  static const _maxSilentRestarts = 2;

  /// Pause before listening again once an answer has been read (muted) so
  /// the reply doesn't vanish under a new "Listening…" instantly.
  static const _mutedReadPause = Duration(milliseconds: 900);

  final ChatRepository _repository;
  final SpeechService _speech;
  final LocalStorageService _storage;
  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<PlayerState>? _playerSub;
  Timer? _resumeTimer;

  /// Bumped every time the user interrupts (tap, close, language change)
  /// so a recogniser callback, request or playback that finishes late is
  /// ignored instead of hijacking the UI.
  int _generation = 0;

  /// Generation whose transcript has already been sent, so the final
  /// result and the "done" status can't both submit it.
  int _submittedGeneration = -1;

  int _exchangeCounter = 0;
  File? _replyFile;
  bool _supportChecked = false;

  /// One automatic retry per utterance for transient listen failures.
  bool _retriedListen = false;
  static const _retryDelay = Duration(milliseconds: 600);

  /// True once the pause has been shortened to [_pauseToSend] for the
  /// current session (done when the first words arrive).
  bool _pauseShortened = false;

  /// Silent restarts used since the user last spoke or tapped.
  int _silentRestarts = 0;

  String _unsupportedMessage(VoiceLanguage lang) =>
      '${lang.name} speech recognition is not available on this device. '
      'Choose another language.';

  VoiceAssistantBloc(this._repository, this._speech, this._storage)
      : super(VoiceAssistantState(
          muted: _storage.voiceMuted,
          language: VoiceLanguages.byCode(_storage.voiceLanguageCode),
        )) {
    on<VoiceSessionStarted>((_, emit) => _startListening(emit));
    on<VoiceOrbTapped>(_onOrbTapped);
    on<VoiceLanguageChanged>(_onLanguageChanged);
    on<VoiceMuteToggled>(_onMuteToggled);
    on<VoiceSessionEnded>((_, emit) async => _stopEverything());
    on<_TranscriptChanged>(_onTranscript);
    on<_ListenEnded>(_onListenEnded);
    on<_LevelChanged>(_onLevel);
    on<_PlaybackFinished>(_onPlaybackFinished);
    on<_Failed>(_onFailed);

    _playerSub = _player.playerStateStream.listen((s) {
      if (s.processingState == ProcessingState.completed) {
        add(_PlaybackFinished(_generation));
      }
    });
  }

  // ── Listening ────────────────────────────────────────────────
  Future<void> _startListening(Emitter<VoiceAssistantState> emit) async {
    if (isClosed) return;
    _resumeTimer?.cancel();
    await _stopPlayback();
    await _speech.cancel();

    final gen = ++_generation;

    // First time through, ask the device which languages it recognises.
    // iOS in particular has no recogniser for several Indian languages,
    // and failing here with a clear message beats a cryptic listen error.
    if (!_supportChecked) {
      _supportChecked = true;
      final codes = await _speech.supportedLocaleCodes();
      if (gen != _generation || isClosed) return;
      emit(state.copyWith(supportedCodes: codes));
    }
    if (!state.supports(state.language)) {
      emit(state.copyWith(
        phase: VoicePhase.error,
        level: 0,
        liveTranscript: '',
        error: _unsupportedMessage(state.language),
      ));
      return;
    }

    emit(state.copyWith(
      phase: VoicePhase.listening,
      level: 0,
      liveTranscript: '',
      clearError: true,
    ));

    _pauseShortened = false;
    final started = await _speech.startListening(
      localeId: state.language.code,
      // Long at first so the user has time to start; shortened to
      // _pauseToSend in _onTranscript once words arrive.
      pauseFor: _waitForSpeech,
      listenFor: _maxUtterance,
      onResult: (text, isFinal) => add(_TranscriptChanged(gen, text, isFinal)),
      onDone: () => add(_ListenEnded(gen)),
      onSoundLevel: (raw) => add(_LevelChanged(gen, _normaliseLevel(raw))),
      onFailure: (reason, message) => add(_Failed(gen, reason, message)),
    );

    if (!started && gen == _generation && !isClosed &&
        state.phase == VoicePhase.listening) {
      // onFailure normally moves us to error first; this is the fallback.
      emit(state.copyWith(phase: VoicePhase.idle, level: 0));
    }
  }

  /// speech_to_text reports sound level in platform-specific units:
  /// roughly -2..10 on Android, about -50..0 (dB) on iOS. Map both to 0..1.
  double _normaliseLevel(double raw) {
    final level = Platform.isIOS ? (raw + 50) / 50 : (raw + 2) / 12;
    return level.clamp(0.0, 1.0);
  }

  void _onLevel(_LevelChanged event, Emitter<VoiceAssistantState> emit) {
    if (event.generation != _generation) return;
    if (state.phase != VoicePhase.listening) return;
    emit(state.copyWith(level: event.level));
  }

  Future<void> _onTranscript(
      _TranscriptChanged event, Emitter<VoiceAssistantState> emit) async {
    if (event.generation != _generation) return;
    if (state.phase != VoicePhase.listening) return;

    // Words are coming through, so this session is healthy: allow a
    // retry again for the next one, and reset the silence budget.
    _retriedListen = false;
    _silentRestarts = 0;

    // The user has started talking: from now on a 2-second pause means
    // the sentence is finished.
    if (!_pauseShortened && event.text.trim().isNotEmpty) {
      _pauseShortened = true;
      _speech.changePauseFor(_pauseToSend);
    }

    emit(state.copyWith(liveTranscript: event.text));

    if (event.isFinal) {
      await _submit(event.generation, event.text, emit);
    }
  }

  /// The recogniser closed the session on its own (pause or time limit).
  /// Usually the final result has already been submitted; if it never
  /// came, send what we have.
  Future<void> _onListenEnded(
      _ListenEnded event, Emitter<VoiceAssistantState> emit) async {
    if (event.generation != _generation) return;
    if (state.phase != VoicePhase.listening) return;

    if (state.heardSpeech) {
      await _submit(event.generation, state.liveTranscript, emit);
    } else {
      // Nothing said before the session closed. Keep the conversation
      // open a little longer, then rest.
      await _restartAfterSilenceOrIdle(emit);
    }
  }

  /// The recogniser closed with nothing heard. Start it again a couple of
  /// times so the user isn't cut off mid-thought; after that, go idle.
  Future<void> _restartAfterSilenceOrIdle(
      Emitter<VoiceAssistantState> emit) async {
    if (_silentRestarts < _maxSilentRestarts) {
      _silentRestarts++;
      AppLogger.info(
          _tag, 'nothing heard, listening again ($_silentRestarts)');
      await _startListening(emit);
      return;
    }
    _silentRestarts = 0;
    emit(state.copyWith(phase: VoicePhase.idle, level: 0, liveTranscript: ''));
  }

  /// Send the recognised text and handle the answer.
  Future<void> _submit(
      int gen, String text, Emitter<VoiceAssistantState> emit) async {
    if (gen != _generation || _submittedGeneration == gen) return;
    _submittedGeneration = gen;

    final question = text.trim();
    if (question.isEmpty) {
      emit(state.copyWith(phase: VoicePhase.idle, level: 0));
      return;
    }

    await _speech.stop();
    emit(state.copyWith(
      phase: VoicePhase.thinking,
      level: 0,
      liveTranscript: question,
    ));
    final language = state.language;

    final result = await _repository.speak(
      text: question,
      languageCode: language.code,
    );

    // The user tapped to cancel, or closed the screen, while we waited.
    if (gen != _generation || isClosed) return;

    if (!result.isSuccess) {
      emit(state.copyWith(
        phase: VoicePhase.error,
        error: result.errorMessage ?? 'Something went wrong. Please try again.',
      ));
      return;
    }

    final exchange = VoiceExchange(
      id: ++_exchangeCounter,
      transcript: question,
      reply: result.replyText,
      replyPlainText: result.replyPlainText,
      language: language,
    );
    emit(state.copyWith(phase: VoicePhase.speaking, lastExchange: exchange));

    if (state.muted || !result.hasAudio) {
      // Nothing to hear: give the reply a moment on screen, then listen.
      _scheduleResume(gen, _mutedReadPause);
      return;
    }

    try {
      await _stopPlayback();
      if (result.audioBytes != null) {
        final file =
            await _writeReplyFile(result.audioBytes!, result.audioExtension);
        await _player.setFilePath(file.path);
      } else {
        await _player.setUrl(result.audioUrl!);
      }
      if (gen != _generation || isClosed) return;
      // Not awaited: play() resolves when playback ends, and the
      // playerStateStream already tells us that.
      unawaited(_player.play());
    } catch (e, st) {
      AppLogger.error(_tag, 'playback failed', error: e, stackTrace: st);
      if (gen != _generation || isClosed) return;
      // The text is still on screen, so carry on as if muted.
      _scheduleResume(gen, _mutedReadPause);
    }
  }

  // ── Speaking ─────────────────────────────────────────────────
  void _onPlaybackFinished(
      _PlaybackFinished event, Emitter<VoiceAssistantState> emit) {
    if (event.generation != _generation) return;
    if (state.phase != VoicePhase.speaking) return;
    // Hands-free: straight back to listening, like a phone call.
    add(const VoiceSessionStarted());
  }

  void _scheduleResume(int gen, Duration after) {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(after, () {
      if (gen != _generation || isClosed) return;
      add(const VoiceSessionStarted());
    });
  }

  Future<void> _stopPlayback() async {
    try {
      if (_player.playing) await _player.stop();
    } catch (e) {
      AppLogger.info(_tag, 'stop playback failed: $e');
    }
  }

  Future<File> _writeReplyFile(List<int> bytes, String extension) async {
    final old = _replyFile;
    if (old != null) _deleteQuietly(old);
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/assistant_reply_${DateTime.now().millisecondsSinceEpoch}.$extension');
    await file.writeAsBytes(bytes, flush: true);
    _replyFile = file;
    return file;
  }

  // ── User controls ────────────────────────────────────────────
  Future<void> _onOrbTapped(
      VoiceOrbTapped event, Emitter<VoiceAssistantState> emit) async {
    switch (state.phase) {
      case VoicePhase.idle:
      case VoicePhase.error:
        _retriedListen = false;
        _silentRestarts = 0;
        await _startListening(emit);
        break;
      case VoicePhase.listening:
        if (state.heardSpeech) {
          // Don't wait for the pause: send what's on screen now.
          await _submit(_generation, state.liveTranscript, emit);
        } else {
          // Tapped again without saying anything: treat as "stop".
          _generation++;
          await _speech.cancel();
          emit(state.copyWith(phase: VoicePhase.idle, level: 0));
        }
        break;
      case VoicePhase.thinking:
        // Cancel the pending answer.
        _generation++;
        emit(state.copyWith(phase: VoicePhase.idle, level: 0));
        break;
      case VoicePhase.speaking:
        // Interrupt the answer and ask something else.
        await _startListening(emit);
        break;
    }
  }

  Future<void> _onLanguageChanged(
      VoiceLanguageChanged event, Emitter<VoiceAssistantState> emit) async {
    if (event.language == state.language) return;
    await _storage.setVoiceLanguageCode(event.language.code);
    final wasListening = state.phase == VoicePhase.listening;
    final wasBlocked = state.phase == VoicePhase.error;
    emit(state.copyWith(language: event.language));
    // The recogniser was started with the old locale; a half-spoken
    // sentence would come out wrong. Start that utterance over. Also
    // resume when the previous language was the reason we were stopped.
    if (wasListening || wasBlocked) {
      await _startListening(emit);
    }
  }

  Future<void> _onMuteToggled(
      VoiceMuteToggled event, Emitter<VoiceAssistantState> emit) async {
    final muted = !state.muted;
    await _storage.setVoiceMuted(muted);
    emit(state.copyWith(muted: muted));
    if (muted && state.phase == VoicePhase.speaking && _player.playing) {
      // Cut the current answer short and go back to listening.
      final gen = _generation;
      await _stopPlayback();
      if (gen == _generation && !isClosed) add(const VoiceSessionStarted());
    }
  }

  Future<void> _onFailed(
      _Failed event, Emitter<VoiceAssistantState> emit) async {
    if (event.generation != _generation) return;
    if (state.phase != VoicePhase.listening) return;

    // Nobody said anything before the recogniser gave up. That's not an
    // error in a hands-free conversation: listen again, then rest.
    if (event.reason == SpeechFailure.noSpeech) {
      await _restartAfterSilenceOrIdle(emit);
      return;
    }

    // A generic listen failure right after starting is usually the audio
    // session still switching over from playback. One quiet retry fixes
    // it on real phones; if it fails again the user sees the message.
    if (event.reason == SpeechFailure.error && !_retriedListen) {
      _retriedListen = true;
      AppLogger.info(_tag, 'listen failed once, retrying: ${event.message}');
      await _speech.cancel();
      await Future<void>.delayed(_retryDelay);
      if (event.generation != _generation || isClosed) return;
      await _startListening(emit);
      return;
    }

    emit(state.copyWith(
        phase: VoicePhase.error, level: 0, error: event.message));
  }

  // ── Teardown ─────────────────────────────────────────────────
  Future<void> _stopEverything() async {
    _generation++;
    _resumeTimer?.cancel();
    await _speech.cancel();
    await _stopPlayback();
  }

  /// Fire-and-forget delete for temp audio; a leftover file is not worth
  /// surfacing to the user.
  void _deleteQuietly(File file) {
    unawaited(() async {
      try {
        if (await file.exists()) await file.delete();
      } catch (e) {
        AppLogger.info(_tag, 'could not delete ${file.path}: $e');
      }
    }());
  }

  @override
  Future<void> close() async {
    await _stopEverything();
    await _playerSub?.cancel();
    await _player.dispose();
    final reply = _replyFile;
    if (reply != null) _deleteQuietly(reply);
    return super.close();
  }
}
