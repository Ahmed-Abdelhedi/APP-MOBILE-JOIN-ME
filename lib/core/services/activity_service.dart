import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service pour gérer les activités avec Firebase
class ActivityService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ActivityService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Rejoindre une activité (ajout dans participants)
  Future<void> joinActivity(String activityId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      await _firestore.collection('activities').doc(activityId).update({
        'participants': FieldValue.arrayUnion([userId]),
        'currentParticipants': FieldValue.increment(1),
      });

      print('✅ Utilisateur $userId a rejoint l\'activité $activityId');
    } catch (e) {
      print('❌ Erreur joinActivity: $e');
      rethrow;
    }
  }

  /// Quitter une activité (retrait de participants)
  Future<void> leaveActivity(String activityId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      await _firestore.collection('activities').doc(activityId).update({
        'participants': FieldValue.arrayRemove([userId]),
        'currentParticipants': FieldValue.increment(-1),
      });

      print('✅ Utilisateur $userId a quitté l\'activité $activityId');
    } catch (e) {
      print('❌ Erreur leaveActivity: $e');
      rethrow;
    }
  }

  /// Vérifier si l'utilisateur a rejoint une activité
  Future<bool> hasJoined(String activityId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final doc = await _firestore.collection('activities').doc(activityId).get();
      if (!doc.exists) return false;

      final participants = List<String>.from(doc.data()?['participants'] ?? []);
      return participants.contains(userId);
    } catch (e) {
      print('❌ Erreur hasJoined: $e');
      return false;
    }
  }

  /// Stream pour vérifier si l'utilisateur a rejoint une activité
  Stream<bool> hasJoinedStream(String activityId) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(false);

    return _firestore
        .collection('activities')
        .doc(activityId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return false;
      final participants = List<String>.from(doc.data()?['participants'] ?? []);
      return participants.contains(userId);
    });
  }
}

/// Provider Riverpod pour ActivityService
final activityServiceProvider = Provider<ActivityService>((ref) {
  return ActivityService();
});
