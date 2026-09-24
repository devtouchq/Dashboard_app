import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:gap/gap.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/constants/section_theme.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/voice_languages.dart';
import '../../../core/di/injector.dart';
import '../../../core/di/local_storage_service.dart';
import '../../../core/services/speech_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/chat.model.dart';
import '../../blocs/chat/chat_bloc.dart';
import 'voice_assistant_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => autoInjector.get<ChatBloc>(),
      child: const _ChatScreenView(),
    );
  }
}

class _ChatScreenView extends StatefulWidget {
  const _ChatScreenView();

  @override
  State<_ChatScreenView> createState() => _ChatScreenViewState();
}

class _ChatScreenViewState extends State<_ChatScreenView> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocus = FocusNode();

  // ── Voice input (speech → text) ───────────────────────────────
  /// Drag this far left of the mic to cancel instead of sending.
  static const _cancelSlideDistance = 90.0;

  /// Longest a single hold can listen for.
  static const _maxListen = Duration(seconds: 60);

  /// After release, how long to wait for the recogniser's final words.
  static const _finalResultWait = Duration(milliseconds: 1500);

  final _speech = autoInjector.get<SpeechService>();
  final _storage = autoInjector.get<LocalStorageService>();

  bool _isRecording = false;
  bool _willCancel = false;
  double _dragDx = 0;
  double _level = 0;
  Duration _elapsed = Duration.zero;
  Timer? _elapsedTimer;

  /// Words recognised so far in the current hold.
  String _transcript = '';

  /// Completed by the recogniser's final result, so release can wait for
  /// the last words instead of sending a half sentence.
  Completer<void>? _finalResult;

  /// Bumped per hold so a late callback from an earlier one is ignored.
  int _listenGen = 0;

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    if (_isRecording) _speech.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    context.read<ChatBloc>().add(ChatMessageSent(text));
    _inputController.clear();
    _scrollToBottom();
  }

  // ─────────────────────────────────────────────────────────────
  //  Hold to talk: speech is turned into text on the phone, and on
  //  release that text is sent like a typed message.
  // ─────────────────────────────────────────────────────────────
  Future<void> _startRecording() async {
    if (_isRecording) return;

    // Close the keyboard so the listening bar is fully visible.
    _inputFocus.unfocus();
    HapticFeedback.mediumImpact();

    final gen = ++_listenGen;
    _finalResult = Completer<void>();
    setState(() {
      _isRecording = true;
      _willCancel = false;
      _dragDx = 0;
      _level = 0;
      _elapsed = Duration.zero;
      _transcript = '';
    });

    final language = VoiceLanguages.byCode(_storage.voiceLanguageCode);
    final started = await _speech.startListening(
      localeId: language.code,
      // The finger decides when the sentence ends, not a pause.
      pauseFor: _maxListen,
      listenFor: _maxListen,
      onResult: (text, isFinal) {
        if (gen != _listenGen || !mounted) return;
        setState(() => _transcript = text);
        if (isFinal) _completeFinal();
      },
      // The recogniser closed the session on its own; whatever it heard
      // is kept and sent on release.
      onDone: _completeFinal,
      onSoundLevel: (raw) {
        if (gen != _listenGen || !mounted || !_isRecording) return;
        // speech_to_text: about -2..10 on Android, -50..0 dB on iOS.
        final level = Platform.isIOS ? (raw + 50) / 50 : (raw + 2) / 12;
        setState(() => _level = level.clamp(0.0, 1.0));
      },
      onFailure: (reason, message) {
        if (gen != _listenGen) return;
        _completeFinal();
        // Nothing heard is not worth a message while still holding;
        // release handles the empty case.
        if (reason == SpeechFailure.noSpeech && _transcript.isNotEmpty) return;
        _stopTicking();
        if (!mounted) return;
        setState(() {
          _isRecording = false;
          _willCancel = false;
        });
        _showSnack(message);
      },
    );

    if (!started) return;
    if (!mounted) {
      // Screen went away while the permission prompt was up.
      await _speech.cancel();
      return;
    }

    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || !_isRecording) {
        t.cancel();
        return;
      }
      final elapsed = Duration(seconds: t.tick);
      setState(() => _elapsed = elapsed);
      // Don't let a forgotten finger listen forever.
      if (elapsed >= _maxListen) _finishRecording();
    });
  }

  void _completeFinal() {
    final c = _finalResult;
    if (c != null && !c.isCompleted) c.complete();
  }

  /// Release — stop listening and send what was said as text.
  Future<void> _finishRecording() async {
    if (!_isRecording) return;
    final gen = _listenGen;
    _stopTicking();

    setState(() {
      _isRecording = false;
      _willCancel = false;
      _level = 0;
    });

    // stop() makes the recogniser deliver its final result; give it a
    // moment so the last word isn't lost.
    await _speech.stop();
    final pending = _finalResult;
    if (pending != null && !pending.isCompleted) {
      await pending.future.timeout(_finalResultWait, onTimeout: () {});
    }
    if (!mounted || gen != _listenGen) return;

    final text = _transcript.trim();
    _transcript = '';
    if (text.isEmpty) {
      _showSnack("Didn't catch that — hold the mic and speak.");
      return;
    }

    AppLogger.info('ChatScreen', 'voice → text (${text.length} chars)');
    context.read<ChatBloc>().add(ChatMessageSent(text));
    _scrollToBottom();
  }

  /// Slid away from the mic — throw the words away.
  Future<void> _cancelRecording() async {
    if (!_isRecording) return;
    _listenGen++;
    _stopTicking();
    HapticFeedback.lightImpact();
    await _speech.cancel();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _willCancel = false;
      _transcript = '';
    });
  }

  void _stopTicking() {
    _elapsedTimer?.cancel();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1F2937),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _fmtElapsed(Duration d) {
    String pad(int v) => v.toString().padLeft(2, '0');
    return '${pad(d.inMinutes)}:${pad(d.inSeconds % 60)}';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        title: KStyles().bold(
          text: 'Clear conversation?',
          size: 16,
          color: DashboardColors.textOnDark,
        ),
        content: KStyles().reg(
          text:
              'This will start a fresh chat. Your current messages will be lost.',
          size: 13,
          color: DashboardColors.textOnDarkSecondary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(false),
            child: KStyles().semiBold(
              text: 'Cancel',
              size: 13,
              color: DashboardColors.textOnDarkSecondary,
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dCtx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: KStyles().semiBold(
              text: 'Clear',
              size: 13,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<ChatBloc>().add(const ChatCleared());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SectionTheme.home.backgroundGradient[0],
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: SectionTheme.home.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _appBar(),
              Expanded(
                child: BlocConsumer<ChatBloc, ChatState>(
                  listener: (context, state) {
                    _scrollToBottom();
                  },
                  builder: (context, state) {
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      itemCount:
                          state.messages.length + (state.isBotTyping ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == state.messages.length) {
                          return const _TypingIndicator();
                        }
                        return _MessageBubble(
                          message: state.messages[i],
                          onRetry: () => context.read<ChatBloc>().add(
                                ChatMessageRetried(state.messages[i].id),
                              ),
                        );
                      },
                    );
                  },
                ),
              ),
              _inputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back,
                color: DashboardColors.textOnDark, size: 24),
            tooltip: 'Back',
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: SectionTheme.home.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.smart_toy_outlined,
              color: SectionTheme.home.accent,
              size: 20,
            ),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KStyles().bold(
                  text: 'Ayurlive Assistant',
                  size: 15,
                  color: DashboardColors.textOnDark,
                ),
                BlocBuilder<ChatBloc, ChatState>(
                  buildWhen: (a, b) => a.isBotTyping != b.isBotTyping,
                  builder: (_, state) {
                    return KStyles().reg(
                      text: state.isBotTyping ? 'typing...' : 'online',
                      size: 10,
                      color: state.isBotTyping
                          ? SectionTheme.home.accent
                          : const Color(0xFF4ADE80),
                    );
                  },
                ),
              ],
            ),
          ),
          BlocBuilder<ChatBloc, ChatState>(
            buildWhen: (a, b) => a.isBotTyping != b.isBotTyping,
            builder: (context, state) => IconButton(
              // Not while a typed question is in flight: the two flows
              // would otherwise be answering at the same time.
              onPressed: state.isBotTyping ? null : _openVoiceAssistant,
              icon: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: SectionTheme.home.accent
                      .withValues(alpha: state.isBotTyping ? 0.08 : 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.graphic_eq_rounded,
                  color: SectionTheme.home.accent
                      .withValues(alpha: state.isBotTyping ? 0.4 : 1),
                  size: 20,
                ),
              ),
              tooltip: 'Talk to the assistant',
            ),
          ),
          IconButton(
            onPressed: _confirmClear,
            icon: const Icon(Icons.delete_outline,
                color: DashboardColors.textOnDark, size: 22),
            tooltip: 'Clear conversation',
          ),
        ],
      ),
    );
  }

  /// Opens the hands-free voice conversation on top of this chat.
  void _openVoiceAssistant() {
    if (_isRecording) return; // a hold-to-record is in progress
    _inputFocus.unfocus();
    HapticFeedback.lightImpact();
    VoiceAssistantScreen.open(context);
  }

  Widget _inputBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: SafeArea(
        top: false,
        child: BlocBuilder<ChatBloc, ChatState>(
          buildWhen: (a, b) => a.isBotTyping != b.isBotTyping,
          builder: (context, state) {
            final busy = state.isBotTyping;
            // The mic button stays mounted in the same slot whether or
            // not we're recording — replacing it mid-hold would kill the
            // gesture and leave the session stuck open.
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _isRecording ? _recordingIndicator() : _textField(),
                ),
                const Gap(8),
                _micButton(busy),
                if (!_isRecording) ...[
                  const Gap(8),
                  _sendButton(busy),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _textField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _inputController,
        focusNode: _inputFocus,
        minLines: 1,
        maxLines: 5,
        textInputAction: TextInputAction.newline,
        style: TextStyle(
          color: DashboardColors.textOnDark,
          fontSize: 14,
        ),
        cursorColor: SectionTheme.home.accent,
        decoration: InputDecoration(
          hintText: 'Ask me anything...',
          hintStyle: TextStyle(
            color: DashboardColors.textOnDarkMuted,
            fontSize: 14,
          ),
          border: InputBorder.none,
          isDense: true,
        ),
        onSubmitted: (_) => _sendMessage(),
      ),
    );
  }

  Widget _sendButton(bool busy) {
    final canSend = !busy;
    return Material(
      color: canSend
          ? SectionTheme.home.accent
          : SectionTheme.home.accent.withValues(alpha: 0.3),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: canSend
            ? () {
                HapticFeedback.lightImpact();
                _sendMessage();
              }
            : null,
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(
            Icons.arrow_upward_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  /// Hold to talk, release to send, slide left to cancel.
  Widget _micButton(bool busy) {
    final enabled = !busy;
    final color = _isRecording
        ? (_willCancel ? const Color(0xFFEF4444) : SectionTheme.home.accent)
        : Colors.white.withValues(alpha: enabled ? 0.12 : 0.06);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled
          ? () => _showSnack('Hold the mic and speak — release to send')
          : null,
      onLongPressStart: enabled ? (_) => _startRecording() : null,
      onLongPressMoveUpdate: enabled
          ? (details) {
              final dx = details.localOffsetFromOrigin.dx;
              final willCancel = dx < -_cancelSlideDistance;
              if (dx != _dragDx || willCancel != _willCancel) {
                setState(() {
                  _dragDx = dx;
                  _willCancel = willCancel;
                });
              }
            }
          : null,
      onLongPressEnd: enabled
          ? (_) => _willCancel ? _cancelRecording() : _finishRecording()
          : null,
      // Fires when the press is interrupted (a scroll steals it, the
      // route is popped) — don't leave the mic listening.
      onLongPressCancel: enabled ? _cancelRecording : null,
      child: AnimatedScale(
        scale: _isRecording ? 1.15 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: _isRecording
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      // Pulses with how loud the speaker is.
                      blurRadius: 8 + _level * 18,
                      spreadRadius: _level * 6,
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.all(12),
          child: Icon(
            _isRecording && _willCancel ? Icons.delete_outline : Icons.mic,
            color: _isRecording
                ? Colors.white
                : DashboardColors.textOnDark
                    .withValues(alpha: enabled ? 1 : 0.4),
            size: 20,
          ),
        ),
      ),
    );
  }

  /// Replaces the text field while holding the mic: timer, live words
  /// (or a level meter before any), and the cancel hint.
  Widget _recordingIndicator() {
    final cancelling = _willCancel;
    return Container(
      decoration: BoxDecoration(
        color: cancelling
            ? const Color(0xFFEF4444).withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: cancelling
              ? const Color(0xFFEF4444).withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
          ),
          const Gap(8),
          KStyles().semiBold(
            text: _fmtElapsed(_elapsed),
            size: 12,
            color: DashboardColors.textOnDark,
          ),
          const Gap(10),
          Expanded(
            child: cancelling
                ? KStyles().semiBold(
                    text: 'Release to cancel',
                    size: 12,
                    color: const Color(0xFFEF4444),
                  )
                : Row(
                    children: [
                      // The words as they are recognised; the level meter
                      // until the first one arrives.
                      Expanded(
                        child: _transcript.trim().isEmpty
                            ? _levelMeter()
                            : Text(
                                _transcript,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: DashboardColors.textOnDark,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                      const Gap(10),
                      KStyles().reg(
                        text: '◀ Slide to cancel',
                        size: 11,
                        color: DashboardColors.textOnDarkMuted,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// Simple live meter so it's obvious the mic is picking something up.
  Widget _levelMeter() {
    const bars = 14;
    return SizedBox(
      height: 18,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(bars, (i) {
          // Tallest in the middle, tapering to the edges, scaled by level.
          final distanceFromCentre = (i - (bars - 1) / 2).abs() / (bars / 2);
          final height =
              (3 + (1 - distanceFromCentre) * 15 * _level).clamp(3.0, 18.0);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                height: height,
                decoration: BoxDecoration(
                  color: SectionTheme.home.accent.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Message bubble
// ─────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onRetry;

  const _MessageBubble({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) _botAvatar(),
          if (!isUser) const Gap(8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser
                        ? SectionTheme.home.accent
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isUser
                        ? null
                        : Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                  ),
                  child: _bubbleContent(isUser),
                ),
                if (message.status == MessageStatus.failed) ...[
                  const Gap(4),
                  InkWell(
                    onTap: onRetry,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Color(0xFFEF4444), size: 12),
                        const Gap(4),
                        KStyles().reg(
                          text: 'Failed. Tap to retry',
                          size: 10,
                          color: const Color(0xFFEF4444),
                        ),
                      ],
                    ),
                  ),
                ],
                if (message.status == MessageStatus.sending) ...[
                  const Gap(4),
                  KStyles().reg(
                    text: 'Sending...',
                    size: 10,
                    color: DashboardColors.textOnDarkMuted,
                  ),
                ],
              ],
            ),
          ),
          if (isUser) const Gap(8),
          if (isUser) _userAvatar(),
        ],
      ),
    );
  }

  /// Bot answers from the AI backend come as HTML (tables, badges, lists).
  /// User messages are always plain text.
  Widget _bubbleContent(bool isUser) {
    final textColor = isUser ? Colors.white : DashboardColors.textOnDark;

    // Voice message — a small player instead of text.
    if (message.isAudio) {
      return _AudioBubble(
        path: message.audioPath!,
        duration: message.audioDuration ?? Duration.zero,
        color: textColor,
      );
    }

    if (!message.isHtml) {
      return SelectableText(
        message.text,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          height: 1.35,
        ),
      );
    }

    // HTML content — render via flutter_widget_from_html_core.
    return HtmlWidget(
      message.text,
      textStyle: TextStyle(
        color: textColor,
        fontSize: 13,
        height: 1.4,
      ),
      customStylesBuilder: _customStyles,
      customWidgetBuilder: null,
      // Force text/link colors to work on our dark background.
      onErrorBuilder: (context, element, error) => SelectableText(
        _stripHtml(message.text),
        style: TextStyle(color: textColor, fontSize: 14),
      ),
    );
  }

  /// Style overrides so the HTML renders well on a dark bubble.
  Map<String, String>? _customStyles(dom) {
    final tag = dom.localName;
    switch (tag) {
      case 'table':
        return {
          'border-collapse': 'collapse',
          'width': '100%',
          'margin-top': '8px',
          'margin-bottom': '8px',
        };
      case 'th':
        return {
          'background': '#334155',
          'color': '#FFFFFF',
          'padding': '6px 8px',
          'border': '1px solid #475569',
          'text-align': 'left',
          'font-weight': 'bold',
          'font-size': '11px',
        };
      case 'td':
        return {
          'padding': '6px 8px',
          'border': '1px solid #475569',
          'font-size': '11px',
          'color': '#E5E7EB',
        };
      case 'p':
        return {'margin': '0 0 6px 0'};
      case 'ul':
        return {'margin': '6px 0', 'padding-left': '18px'};
      case 'li':
        return {'margin': '3px 0'};
      case 'strong':
      case 'b':
        return {'color': '#FFFFFF', 'font-weight': 'bold'};
      case 'span':
        // Bootstrap-style badges: bg-primary / bg-success / bg-secondary etc.
        final classAttr = dom.attributes['class'] ?? '';
        if (classAttr.contains('badge')) {
          final bg = _badgeColor(classAttr);
          final fg = classAttr.contains('text-dark') ? '#111827' : '#FFFFFF';
          return {
            'background': bg,
            'color': fg,
            'padding': '2px 6px',
            'border-radius': '4px',
            'font-size': '10px',
            'font-weight': 'bold',
          };
        }
        return null;
      default:
        return null;
    }
  }

  String _badgeColor(String classes) {
    if (classes.contains('bg-primary')) return '#3B82F6';
    if (classes.contains('bg-success')) return '#10B981';
    if (classes.contains('bg-warning')) return '#F59E0B';
    if (classes.contains('bg-danger')) return '#EF4444';
    if (classes.contains('bg-info')) return '#22D3EE';
    if (classes.contains('bg-secondary')) return '#6B7280';
    if (classes.contains('bg-dark')) return '#1F2937';
    return '#6B7280';
  }

  /// Last-resort fallback if the HTML renderer throws — strips tags and
  /// shows plain text so the user still sees SOMETHING.
  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Widget _botAvatar() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: SectionTheme.home.accent.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.smart_toy_outlined,
        color: SectionTheme.home.accent,
        size: 16,
      ),
    );
  }

  Widget _userAvatar() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person_outline,
        color: Colors.white,
        size: 16,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Voice message player
// ─────────────────────────────────────────────────────────────
class _AudioBubble extends StatefulWidget {
  final String path;
  final Duration duration;
  final Color color;

  const _AudioBubble({
    required this.path,
    required this.duration,
    required this.color,
  });

  @override
  State<_AudioBubble> createState() => _AudioBubbleState();
}

class _AudioBubbleState extends State<_AudioBubble> {
  static const _tag = 'AudioBubble';

  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _positionSub;

  bool _playing = false;
  Duration _position = Duration.zero;

  @override
  void dispose() {
    _stateSub?.cancel();
    _positionSub?.cancel();
    _player?.dispose();
    super.dispose();
  }

  /// The player is created on first tap — most voice messages are never
  /// played back, so there's no point holding one per bubble.
  Future<void> _toggle() async {
    try {
      if (_player == null) {
        final player = AudioPlayer();
        await player.setFilePath(widget.path);

        _stateSub = player.playerStateStream.listen((s) {
          if (!mounted) return;
          if (s.processingState == ProcessingState.completed) {
            player.pause();
            player.seek(Duration.zero);
            setState(() {
              _playing = false;
              _position = Duration.zero;
            });
          } else {
            setState(() => _playing = s.playing);
          }
        });
        _positionSub = player.positionStream.listen((p) {
          if (mounted) setState(() => _position = p);
        });

        _player = player;
      }

      if (_player!.playing) {
        await _player!.pause();
      } else {
        await _player!.play();
      }
    } catch (e, st) {
      AppLogger.error(_tag, 'playback failed', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _playing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not play this recording.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _player?.duration ?? widget.duration;
    final progress = total.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    final remaining = _playing || _position > Duration.zero ? _position : total;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: _toggle,
          customBorder: const CircleBorder(),
          child: Icon(
            _playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
            color: widget.color,
            size: 32,
          ),
        ),
        const Gap(10),
        SizedBox(
          width: 110,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: widget.color.withValues(alpha: 0.25),
              valueColor: AlwaysStoppedAnimation<Color>(widget.color),
            ),
          ),
        ),
        const Gap(10),
        KStyles().reg(
          text: _fmt(remaining),
          size: 11,
          color: widget.color.withValues(alpha: 0.85),
        ),
      ],
    );
  }

  String _fmt(Duration d) {
    String pad(int v) => v.toString().padLeft(2, '0');
    return '${pad(d.inMinutes)}:${pad(d.inSeconds % 60)}';
  }
}

// ─────────────────────────────────────────────────────────────
//  Typing indicator
// ─────────────────────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: SectionTheme.home.accent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.smart_toy_outlined,
              color: SectionTheme.home.accent,
              size: 16,
            ),
          ),
          const Gap(8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dot(0),
                    const Gap(4),
                    _dot(1),
                    const Gap(4),
                    _dot(2),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int index) {
    final phase = (_controller.value - (index * 0.15)) % 1.0;
    final scale =
        phase < 0.5 ? (1.0 + phase * 0.8) : (1.4 - (phase - 0.5) * 0.8);
    final opacity =
        phase < 0.5 ? (0.4 + phase * 1.2) : (1.0 - (phase - 0.5) * 1.2);
    return Transform.scale(
      scale: scale.clamp(0.9, 1.4),
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: SectionTheme.home.accent
              .withValues(alpha: opacity.clamp(0.4, 1.0)),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
