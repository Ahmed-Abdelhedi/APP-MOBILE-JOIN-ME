/// Modèle pour un chat
class ChatModel {
  final String id;
  final String activityId;
  final String activityTitle;
  final List<String> participants;
  final List<String> participantNames;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatModel({
    required this.id,
    required this.activityId,
    required this.activityTitle,
    required this.participants,
    required this.participantNames,
    this.lastMessage,
    this.lastMessageTime,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Nombre de participants
  int get participantCount => participants.length;

  /// Vérifier si un utilisateur participe
  bool hasParticipant(String userId) => participants.contains(userId);

  /// Conversion depuis Firestore
  factory ChatModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ChatModel(
      id: id,
      activityId: data['activityId'] ?? '',
      activityTitle: data['activityTitle'] ?? '',
      participants: List<String>.from(data['participants'] ?? []),
      participantNames: List<String>.from(data['participantNames'] ?? []),
      lastMessage: data['lastMessage'],
      lastMessageTime: data['lastMessageTime']?.toDate(),
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  /// Conversion vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'activityId': activityId,
      'activityTitle': activityTitle,
      'participants': participants,
      'participantNames': participantNames,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Copie avec modifications
  ChatModel copyWith({
    String? lastMessage,
    DateTime? lastMessageTime,
    List<String>? participants,
    List<String>? participantNames,
  }) {
    return ChatModel(
      id: id,
      activityId: activityId,
      activityTitle: activityTitle,
      participants: participants ?? this.participants,
      participantNames: participantNames ?? this.participantNames,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
