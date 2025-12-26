/// Modèle pour un message
class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String text;
  final String? imageUrl;
  final DateTime timestamp;
  final MessageType type;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.text,
    this.imageUrl,
    required this.timestamp,
    required this.type,
  });

  /// Vérifier si c'est un message système
  bool get isSystem => type == MessageType.system;

  /// Vérifier si c'est un message image
  bool get isImage => type == MessageType.image;

  /// Vérifier si c'est mon message
  bool isMyMessage(String userId) => senderId == userId;

  /// Conversion depuis Firestore
  factory MessageModel.fromFirestore(Map<String, dynamic> data, String id) {
    return MessageModel(
      id: id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Utilisateur',
      senderPhotoUrl: data['senderPhotoUrl'],
      text: data['text'] ?? '',
      imageUrl: data['imageUrl'],
      timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
      type: MessageType.fromString(data['type'] ?? 'text'),
    );
  }

  /// Conversion vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': timestamp,
      'type': type.value,
    };
  }
}

/// Type de message
enum MessageType {
  text('text'),
  image('image'),
  system('system');

  final String value;
  const MessageType(this.value);

  static MessageType fromString(String value) {
    switch (value) {
      case 'image':
        return MessageType.image;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }
}
