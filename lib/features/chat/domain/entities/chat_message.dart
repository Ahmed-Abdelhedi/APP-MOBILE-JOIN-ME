import 'package:equatable/equatable.dart';

enum MessageType {
  text,
  image,
  system,
}

class ChatMessage extends Equatable {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String? text;
  final String? imageUrl;
  final MessageType type;
  final DateTime timestamp;
  final List<String> seenBy;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    this.text,
    this.imageUrl,
    required this.type,
    required this.timestamp,
    required this.seenBy,
  });

  bool isSeenBy(String userId) => seenBy.contains(userId);

  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    String? text,
    String? imageUrl,
    MessageType? type,
    DateTime? timestamp,
    List<String>? seenBy,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      seenBy: seenBy ?? this.seenBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        chatId,
        senderId,
        senderName,
        senderPhotoUrl,
        text,
        imageUrl,
        type,
        timestamp,
        seenBy,
      ];
}
