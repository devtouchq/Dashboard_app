import 'package:equatable/equatable.dart';

/// Who sent this message.
enum MessageSender { user, bot }

/// Delivery status for user messages. Bot messages are always `sent`.
enum MessageStatus { sending, sent, failed }

/// One entry in the chat log.
class ChatMessage extends Equatable {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final MessageStatus status;

  /// True when `text` contains HTML markup and should be rendered via
  /// an HTML widget. Bot answers from the AI backend are always HTML
  /// (tables, badges, lists). User messages are always plain text.
  final bool isHtml;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.isHtml = false,
  });

  ChatMessage copyWith({
    String? text,
    MessageStatus? status,
    bool? isHtml,
  }) {
    return ChatMessage(
      id: id,
      text: text ?? this.text,
      sender: sender,
      timestamp: timestamp,
      status: status ?? this.status,
      isHtml: isHtml ?? this.isHtml,
    );
  }

  @override
  List<Object?> get props => [id, text, sender, timestamp, status, isHtml];
}
