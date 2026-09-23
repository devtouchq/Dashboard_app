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

  /// Local path of the recorded audio for a voice message, null for a
  /// typed one. The file lives in the app's temp directory and is what
  /// gets uploaded.
  final String? audioPath;

  /// How long that recording runs, shown on the bubble.
  final Duration? audioDuration;

  bool get isAudio => audioPath != null;

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
    this.audioPath,
    this.audioDuration,
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
      audioPath: audioPath,
      audioDuration: audioDuration,
    );
  }

  @override
  List<Object?> get props =>
      [id, text, sender, timestamp, status, isHtml, audioPath, audioDuration];
}
