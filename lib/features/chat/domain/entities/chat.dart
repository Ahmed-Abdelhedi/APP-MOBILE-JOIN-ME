import 'package:equatable/equatable.dart';

class Chat extends Equatable {
  final String id;
  final String activityId;
  final String activityTitle;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCount;

  const Chat({
    required this.id,
    required this.activityId,
    required this.activityTitle,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    this.unreadCount = const {},
  });

  int getUnreadCount(String userId) => unreadCount[userId] ?? 0;

  Chat copyWith({
    String? id,
    String? activityId,
    String? activityTitle,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    Map<String, int>? unreadCount,
  }) {
    return Chat(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      activityTitle: activityTitle ?? this.activityTitle,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        activityId,
        activityTitle,
        participants,
        lastMessage,
        lastMessageTime,
        lastMessageSenderId,
        unreadCount,
      ];
}
