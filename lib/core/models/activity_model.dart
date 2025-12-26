/// Modèle pour une activité
class ActivityModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String location;
  final double latitude;
  final double longitude;
  final DateTime dateTime;
  final int maxParticipants;
  final int currentParticipants;
  final double? cost;
  final String? imageUrl;
  final String creatorId;
  final String creatorName;
  final List<String> participants;
  final DateTime createdAt;
  final ActivityStatus status;

  ActivityModel({
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
    required this.creatorId,
    required this.creatorName,
    required this.participants,
    required this.createdAt,
    required this.status,
  });

  /// Vérifier si l'activité est complète
  bool get isFull => currentParticipants >= maxParticipants;

  /// Vérifier si l'utilisateur participe
  bool hasParticipant(String userId) => participants.contains(userId);

  /// Vérifier si c'est gratuit
  bool get isFree => cost == null || cost == 0;

  /// Nombre de places restantes
  int get availableSpots => maxParticipants - currentParticipants;

  /// Conversion depuis Firestore
  factory ActivityModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ActivityModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      location: data['location'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      dateTime: data['dateTime']?.toDate() ?? DateTime.now(),
      maxParticipants: data['maxParticipants'] ?? 0,
      currentParticipants: data['currentParticipants'] ?? 0,
      cost: data['cost']?.toDouble(),
      imageUrl: data['imageUrl'],
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'] ?? '',
      participants: List<String>.from(data['participants'] ?? []),
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      status: ActivityStatus.fromString(data['status'] ?? 'upcoming'),
    );
  }

  /// Conversion vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id, // Inclure l'ID dans la Map
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'dateTime': dateTime,
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'cost': cost,
      'imageUrl': imageUrl,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'participants': participants,
      'createdAt': createdAt,
      'status': status.value,
    };
  }
}

/// Statut d'une activité
enum ActivityStatus {
  upcoming('upcoming'),
  ongoing('ongoing'),
  completed('completed'),
  cancelled('cancelled');

  final String value;
  const ActivityStatus(this.value);

  static ActivityStatus fromString(String value) {
    switch (value) {
      case 'ongoing':
        return ActivityStatus.ongoing;
      case 'completed':
        return ActivityStatus.completed;
      case 'cancelled':
        return ActivityStatus.cancelled;
      default:
        return ActivityStatus.upcoming;
    }
  }
}
