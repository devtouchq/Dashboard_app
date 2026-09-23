import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:gap/gap.dart';

import '../../../core/constants/section_theme.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/di/injector.dart';
import '../../../core/services/speech_service.dart';
import '../../../data/models/chat.model.dart';
import '../../blocs/chat/chat_bloc.dart';

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

  // ── Voice input ───────────────────────────────────────────────
  /// Drag this far left of the mic to cancel instead of sending.
  static const _cancelSlideDistance = 90.0;

  final _speech = autoInjector.get<SpeechService>();

  bool _isRecording = false;
  bool _willCancel = false;
  String _transcript = '';
  double _dragDx = 0;
  double _soundLevel = 0;
  Duration _elapsed = Duration.zero;
  Timer? _elapsedTimer;

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
  //  Hold-to-talk: press the mic, speak, release to send.
  //  Recognition happens on the device; the transcript is sent as a
  //  normal text question, so the chat API is unchanged.
  // ─────────────────────────────────────────────────────────────
  Future<void> _startRecording() async {
    if (_isRecording) return;

    // Close the keyboard so the recording bar is fully visible.
    _inputFocus.unfocus();
    HapticFeedback.mediumImpact();

    setState(() {
      _isRecording = true;
      _willCancel = false;
      _transcript = '';
      _dragDx = 0;
      _soundLevel = 0;
      _elapsed = Duration.zero;
    });

    final started = await _speech.startListening(
      onResult: (transcript, _) {
        if (mounted) setState(() => _transcript = transcript);
      },
      onSoundLevel: (level) {
        if (mounted) setState(() => _soundLevel = level);
      },
      // Fires if the session can't start, and also if it dies while the
      // finger is still down — drop the recording UI and say why.
      onFailure: (_, message) {
        _elapsedTimer?.cancel();
        if (!mounted) return;
        setState(() {
          _isRecording = false;
          _willCancel = false;
          _transcript = '';
        });
        _showSnack(message);
      },
    );

    if (!started || !mounted) return;

    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || !_isRecording) {
        t.cancel();
        return;
      }
      setState(() => _elapsed = Duration(seconds: t.tick));
    });
  }

  /// Release — stop listening and send whatever was recognised.
  Future<void> _finishRecording() async {
    if (!_isRecording) return;
    _elapsedTimer?.cancel();

    await _speech.stop();
    // The final result usually lands just after stop(); give it a beat
    // so the last word isn't dropped.
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final spoken = _transcript.trim();
    setState(() {
      _isRecording = false;
      _transcript = '';
    });

    if (spoken.isEmpty) {
      _showSnack("Didn't catch that — try again.");
      return;
    }

    // Keep anything already typed and add the spoken part to it.
    final existing = _inputController.text.trim();
    _inputController.text = existing.isEmpty ? spoken : '$existing $spoken';
    _sendMessage();
  }

  /// Slid away from the mic — throw the transcript away.
  Future<void> _cancelRecording() async {
    if (!_isRecording) return;
    _elapsedTimer?.cancel();
    HapticFeedback.lightImpact();
    await _speech.cancel();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _transcript = '';
      _willCancel = false;
    });
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
      onTap: enabled ? () => _showSnack('Hold the mic to talk') : null,
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
                      // Grows with how loud the speaker is.
                      blurRadius: 8 + _soundLevel.clamp(0, 10) * 1.5,
                      spreadRadius: _soundLevel.clamp(0, 10) * 0.6,
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

  /// Replaces the text field while holding the mic.
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
                : Text(
                    _transcript.isEmpty ? '◀ Slide to cancel' : _transcript,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _transcript.isEmpty
                          ? DashboardColors.textOnDarkMuted
                          : DashboardColors.textOnDark,
                      fontSize: 13,
                    ),
                  ),
          ),
        ],
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
