import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/models/chat.model.dart';
import '../../../data/repositories/chat_repo.dart';

// ─────────────────────────────────────────────────────────────
//  Events
// ─────────────────────────────────────────────────────────────
abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class ChatMessageSent extends ChatEvent {
  final String text;
  const ChatMessageSent(this.text);
  @override
  List<Object?> get props => [text];
}

class ChatMessageRetried extends ChatEvent {
  final String messageId;
  const ChatMessageRetried(this.messageId);
  @override
  List<Object?> get props => [messageId];
}

class ChatCleared extends ChatEvent {
  const ChatCleared();
}

// ─────────────────────────────────────────────────────────────
//  State
// ─────────────────────────────────────────────────────────────
class ChatState extends Equatable {
  final List<ChatMessage> messages;
  final bool isBotTyping;

  const ChatState({
    this.messages = const [],
    this.isBotTyping = false,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isBotTyping,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isBotTyping: isBotTyping ?? this.isBotTyping,
    );
  }

  @override
  List<Object?> get props => [messages, isBotTyping];
}

// ─────────────────────────────────────────────────────────────
//  Bloc
// ─────────────────────────────────────────────────────────────
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  static const _tag = 'ChatBloc';
  final ChatRepository _repository;

  int _msgCounter = 0;

  ChatBloc(this._repository) : super(const ChatState()) {
    on<ChatMessageSent>(_onSent);
    on<ChatMessageRetried>(_onRetry);
    on<ChatCleared>(_onCleared);

    _emitInitial();
  }

  void _emitInitial() {
    final welcome = ChatMessage(
      id: _nextId(),
      text:
          "Hi! I'm your Ayurliv assistant. Ask me about today's revenue, patients, appointments, or anything else about your dashboard.",
      sender: MessageSender.bot,
      timestamp: DateTime.now(),
    );
    emit(state.copyWith(messages: [welcome]));
  }

  String _nextId() =>
      'msg_${DateTime.now().millisecondsSinceEpoch}_${_msgCounter++}';

  Future<void> _onSent(ChatMessageSent event, Emitter<ChatState> emit) async {
    final trimmed = event.text.trim();
    if (trimmed.isEmpty) return;

    final userMsg = ChatMessage(
      id: _nextId(),
      text: trimmed,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );

    emit(state.copyWith(
      messages: [...state.messages, userMsg],
      isBotTyping: true,
    ));

    await _callApi(userMsg, emit);
  }

  Future<void> _onRetry(
      ChatMessageRetried event, Emitter<ChatState> emit) async {
    final idx = state.messages.indexWhere((m) => m.id == event.messageId);
    if (idx < 0) return;

    final msg = state.messages[idx];
    if (msg.sender != MessageSender.user) return;

    final updated = List<ChatMessage>.of(state.messages);
    updated[idx] = msg.copyWith(status: MessageStatus.sending);
    final kept = updated.sublist(0, idx + 1);

    emit(state.copyWith(messages: kept, isBotTyping: true));

    await _callApi(updated[idx], emit);
  }

  Future<void> _callApi(ChatMessage userMsg, Emitter<ChatState> emit) async {
    try {
      final res = await _repository.sendMessage(userMsg.text);

      final withSent = state.messages.map((m) {
        if (m.id == userMsg.id) {
          return m.copyWith(status: MessageStatus.sent);
        }
        return m;
      }).toList();

      if (!res.isSuccess) {
        final errorBubble = ChatMessage(
          id: _nextId(),
          text: res.errorMessage ?? 'Something went wrong. Please try again.',
          sender: MessageSender.bot,
          timestamp: DateTime.now(),
          // Error messages are plain text, never HTML.
          isHtml: false,
        );
        emit(state.copyWith(
          messages: [...withSent, errorBubble],
          isBotTyping: false,
        ));
        return;
      }

      final botMsg = ChatMessage(
        id: _nextId(),
        text: res.botMessage,
        sender: MessageSender.bot,
        timestamp: DateTime.now(),
        isHtml: res.isHtml,
      );

      emit(state.copyWith(
        messages: [...withSent, botMsg],
        isBotTyping: false,
      ));
    } catch (e, st) {
      AppLogger.error(_tag, 'send failed', error: e, stackTrace: st);

      final withFailed = state.messages.map((m) {
        if (m.id == userMsg.id) {
          return m.copyWith(status: MessageStatus.failed);
        }
        return m;
      }).toList();

      emit(state.copyWith(messages: withFailed, isBotTyping: false));
    }
  }

  void _onCleared(ChatCleared event, Emitter<ChatState> emit) {
    emit(const ChatState());
    _emitInitial();
  }
}
