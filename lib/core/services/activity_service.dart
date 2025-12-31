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

      // Get activity details to fetch creator and activity title
      final activityDoc = await _firestore.collection('activities').doc(activityId).get();
      if (!activityDoc.exists) {
        throw Exception('Activité introuvable');
      }
      
      final activityData = activityDoc.data() as Map<String, dynamic>;
      final creatorId = activityData['creatorId'] as String?;
      final activityTitle = activityData['title'] as String? ?? 'Activité';
      
      // Get current participants list
      List<String> participants = List<String>.from(activityData['participants'] ?? []);
      int currentParticipants = activityData['currentParticipants'] ?? 0;
      
      // Check if already joined
      if (participants.contains(userId)) {
        print('⚠️ Utilisateur déjà inscrit');
        return;
      }
      
      // Add user to participants
      participants.add(userId);
      currentParticipants++;

      // Get user's name
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      final userName = userData?['displayName'] as String? ?? userData?['name'] as String? ?? 'Un utilisateur';

      // Update activity with new participants list
      await _firestore.collection('activities').doc(activityId).update({
        'participants': participants,
        'currentParticipants': currentParticipants,
      });

      // Send notification to the creator
      if (creatorId != null && creatorId != userId) {
        await _firestore
            .collection('users')
            .doc(creatorId)
            .collection('notifications')
            .add({
          'type': 'event_joined',
          'title': 'Nouveau participant',
          'body': '$userName a rejoint votre événement "$activityTitle"',
          'activityId': activityId,
          'activityTitle': activityTitle,
          'participantId': userId,
          'participantName': userName,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      print('✅ Utilisateur $userId ($userName) a rejoint l\'activité $activityId');
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

      // Get current activity data
      final activityDoc = await _firestore.collection('activities').doc(activityId).get();
      if (!activityDoc.exists) {
        throw Exception('Activité introuvable');
      }
      
      final activityData = activityDoc.data() as Map<String, dynamic>;
      final creatorId = activityData['creatorId'] as String?;
      final activityTitle = activityData['title'] as String? ?? 'Activité';
      
      // Get current participants list
      List<String> participants = List<String>.from(activityData['participants'] ?? []);
      int currentParticipants = activityData['currentParticipants'] ?? 0;
      
      // Check if user is in participants
      if (!participants.contains(userId)) {
        print('⚠️ Utilisateur pas inscrit');
        return;
      }
      
      // Get user's name
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      final userName = userData?['displayName'] as String? ?? userData?['name'] as String? ?? 'Un utilisateur';
      
      // Remove user from participants
      participants.remove(userId);
      currentParticipants = (currentParticipants - 1).clamp(0, 999);

      await _firestore.collection('activities').doc(activityId).update({
        'participants': participants,
        'currentParticipants': currentParticipants,
      });

      // Send notification to the creator
      if (creatorId != null && creatorId != userId) {
        await _firestore
            .collection('users')
            .doc(creatorId)
            .collection('notifications')
            .add({
          'type': 'event_left',
          'title': 'Participant a quitté',
          'body': '$userName a quitté votre événement "$activityTitle"',
          'activityId': activityId,
          'activityTitle': activityTitle,
          'participantId': userId,
          'participantName': userName,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      print('✅ Utilisateur $userId ($userName) a quitté l\'activité $activityId');
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

  // ============================================================
  // INTERESTED FUNCTIONALITY
  // ============================================================

  /// Mark user as interested in an activity
  Future<void> markInterested(String activityId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      await _firestore.collection('activities').doc(activityId).update({
        'interestedUsers': FieldValue.arrayUnion([userId]),
      });

      print('✅ Utilisateur $userId a marqué intérêt pour $activityId');
    } catch (e) {
      print('❌ Erreur markInterested: $e');
      rethrow;
    }
  }

  /// Remove user interest from an activity
  Future<void> removeInterested(String activityId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      await _firestore.collection('activities').doc(activityId).update({
        'interestedUsers': FieldValue.arrayRemove([userId]),
      });

      print('✅ Utilisateur $userId a retiré son intérêt pour $activityId');
    } catch (e) {
      print('❌ Erreur removeInterested: $e');
      rethrow;
    }
  }

  /// Check if user is interested in an activity
  Future<bool> isInterested(String activityId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final doc = await _firestore.collection('activities').doc(activityId).get();
      if (!doc.exists) return false;

      final interestedUsers = List<String>.from(doc.data()?['interestedUsers'] ?? []);
      return interestedUsers.contains(userId);
    } catch (e) {
      print('❌ Erreur isInterested: $e');
      return false;
    }
  }

  /// Stream to check if user is interested in an activity
  Stream<bool> isInterestedStream(String activityId) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(false);

    return _firestore
        .collection('activities')
        .doc(activityId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return false;
      final interestedUsers = List<String>.from(doc.data()?['interestedUsers'] ?? []);
      return interestedUsers.contains(userId);
    });
  }

  /// Get count of interested users for an activity
  Future<int> getInterestedCount(String activityId) async {
    try {
      final doc = await _firestore.collection('activities').doc(activityId).get();
      if (!doc.exists) return 0;
      final interestedUsers = List<String>.from(doc.data()?['interestedUsers'] ?? []);
      return interestedUsers.length;
    } catch (e) {
      return 0;
    }
  }

  /// Stream for interested count
  Stream<int> interestedCountStream(String activityId) {
    return _firestore
        .collection('activities')
        .doc(activityId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return 0;
      final interestedUsers = List<String>.from(doc.data()?['interestedUsers'] ?? []);
      return interestedUsers.length;
    });
  }
}

/// Provider Riverpod pour ActivityService
final activityServiceProvider = Provider<ActivityService>((ref) {
  return ActivityService();
});
