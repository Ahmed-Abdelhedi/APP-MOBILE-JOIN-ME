import 'package:equatable/equatable.dart';

enum ActivityCategory {
  sport,
  football,
  gym,
  cafe,
  cinema,
  music,
  gaming,
  food,
  art,
  study,
  other,
}

enum ActivityStatus {
  upcoming,
  ongoing,
  completed,
  cancelled,
}

class Activity extends Equatable {
  final String id;
  final String title;
  final String description;
  final ActivityCategory category;
  final String location;
  final double latitude;
  final double longitude;
  final DateTime dateTime;
  final int maxParticipants;
  final int currentParticipants;
  final double? cost;
  final String? imageUrl;
  final String? imageAssetPath; // For predefined images
  final String creatorId;
  final List<String> participants;
  final DateTime createdAt;
  final ActivityStatus status;

  const Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.dateTime,
    required this.maxParticipants,
    required this.currentParticipants,
    this.cost,
    this.imageUrl,
    this.imageAssetPath,
    required this.creatorId,
    required this.participants,
    required this.createdAt,
    required this.status,
  });

  bool get isFull => currentParticipants >= maxParticipants;

  bool get isFree => cost == null || cost == 0;

  Activity copyWith({
    String? id,
    String? title,
    String? description,
    ActivityCategory? category,
    String? location,
    double? latitude,
    double? longitude,
    DateTime? dateTime,
    int? maxParticipants,
    int? currentParticipants,
    double? cost,
    String? imageUrl,
    String? imageAssetPath,
    String? creatorId,
    List<String>? participants,
    DateTime? createdAt,
    ActivityStatus? status,
  }) {
    return Activity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      dateTime: dateTime ?? this.dateTime,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      cost: cost ?? this.cost,
      imageAssetPath: imageAssetPath ?? this.imageAssetPath,
      imageUrl: imageUrl ?? this.imageUrl,
      creatorId: creatorId ?? this.creatorId,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        location,
        latitude,
        longitude,
        dateTime,
        maxParticipants,
        currentParticipants,
        cost,
        imageAssetPath,
        imageUrl,
        creatorId,
        participants,
        createdAt,
        status,
      ];
}
