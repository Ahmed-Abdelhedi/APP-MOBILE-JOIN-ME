import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final String? bio;
  final List<String> interests;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime? lastSeen;
  final String? fcmToken;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.bio,
    this.interests = const [],
    this.phoneNumber,
    required this.createdAt,
    this.lastSeen,
    this.fcmToken,
  });

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    String? bio,
    List<String>? interests,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? lastSeen,
    String? fcmToken,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        photoUrl,
        bio,
        interests,
        phoneNumber,
        createdAt,
        lastSeen,
        fcmToken,
      ];
}
