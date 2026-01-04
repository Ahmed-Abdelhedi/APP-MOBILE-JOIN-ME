import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour un utilisateur
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String? bio;
  final List<String> interests;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime? lastSeen;
  final String? fcmToken;
  final List<String> favorites; // IDs des activités favorites
  final List<String> hiddenConversations; // IDs des conversations cachées

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.bio,
    this.interests = const [],
    this.phoneNumber,
    required this.createdAt,
    this.lastSeen,
    this.fcmToken,
    this.favorites = const [],
    this.hiddenConversations = const [],
  });

  /// Création depuis Firestore
  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      bio: data['bio'],
      interests: List<String>.from(data['interests'] ?? []),
      phoneNumber: data['phoneNumber'],
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      lastSeen: data['lastSeen']?.toDate(),
      fcmToken: data['fcmToken'],
      favorites: List<String>.from(data['favorites'] ?? []),
      hiddenConversations: List<String>.from(data['hiddenConversations'] ?? []),
    );
  }

  /// Conversion vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'bio': bio,
      'interests': interests,
      'phoneNumber': phoneNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'favorites': favorites,
      'fcmToken': fcmToken,
      'hiddenConversations': hiddenConversations,
    };
  }

  /// Copier avec modifications
  UserModel copyWith({
    String? name,
    String? photoUrl,
    String? bio,
    List<String>? interests,
    String? phoneNumber,
    DateTime? lastSeen,
    String? fcmToken,
    List<String>? favorites,
    List<String>? hiddenConversations,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      fcmToken: fcmToken ?? this.fcmToken,
      favorites: favorites ?? this.favorites,
      hiddenConversations: hiddenConversations ?? this.hiddenConversations,
    );
  }
}
