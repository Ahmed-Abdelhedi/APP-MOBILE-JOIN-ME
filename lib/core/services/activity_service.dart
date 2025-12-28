import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service pour gérer les activités avec Firebase
class ActivityService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  ActivityService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _storage = storage ?? FirebaseStorage.instance;

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

  /// Upload an image to Firebase Storage and return the download URL
  /// Returns the download URL on success, throws an exception on failure
  Future<String> uploadActivityImage(File imageFile, String activityId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Create a unique filename using timestamp
      final String fileName = 'activity_${activityId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Reference to Firebase Storage location
      final Reference storageRef = _storage
          .ref()
          .child('activities')
          .child(activityId)
          .child(fileName);

      // Upload the file
      final UploadTask uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': userId,
            'activityId': activityId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      
      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading image: $e');
      throw Exception('Échec du téléchargement de l\'image: $e');
    }
  }

  /// Update activity image URL in Firestore
  Future<void> updateActivityImage(String activityId, String imageUrl) async {
    try {
      await _firestore.collection('activities').doc(activityId).update({
        'imageUrl': imageUrl,
      });
      print('✅ Activity image URL updated in Firestore');
    } catch (e) {
      print('❌ Error updating activity image: $e');
      rethrow;
    }
  }
}

/// Provider Riverpod pour ActivityService
final activityServiceProvider = Provider<ActivityService>((ref) {
  return ActivityService();
});
