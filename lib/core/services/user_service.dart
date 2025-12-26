import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile/core/models/user_model.dart';

/// Service pour gérer les données utilisateur
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Récupérer l'utilisateur actuel
  User? get currentUser => _auth.currentUser;

  /// Mettre à jour le profil utilisateur
  Future<void> updateProfile({
    String? name,
    String? bio,
    String? phoneNumber,
    List<String>? interests,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    final updates = <String, dynamic>{};
    
    if (name != null) {
      updates['name'] = name;
      // Mettre à jour aussi dans Firebase Auth
      await user.updateDisplayName(name);
    }
    if (bio != null) updates['bio'] = bio;
    if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
    if (interests != null) updates['interests'] = interests;
    
    updates['updatedAt'] = FieldValue.serverTimestamp();

    await _firestore.collection('users').doc(user.uid).update(updates);
  }

  /// Ajouter une activité aux favoris
  Future<void> addToFavorites(String activityId) async {
    final user = currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'favorites': FieldValue.arrayUnion([activityId]),
      }, SetOptions(merge: true));
      print('✅ Activité $activityId ajoutée aux favoris');
    } catch (e) {
      print('❌ Erreur ajout favori: $e');
      rethrow;
    }
  }

  /// Retirer une activité des favoris
  Future<void> removeFromFavorites(String activityId) async {
    final user = currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'favorites': FieldValue.arrayRemove([activityId]),
      });
      print('✅ Activité $activityId retirée des favoris');
    } catch (e) {
      print('❌ Erreur retrait favori: $e');
      rethrow;
    }
  }

  /// Vérifier si une activité est dans les favoris
  Future<bool> isFavorite(String activityId) async {
    final user = currentUser;
    if (user == null) return false;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    final favorites = List<String>.from(doc.data()?['favorites'] ?? []);
    return favorites.contains(activityId);
  }

  /// Stream des favoris de l'utilisateur
  Stream<List<String>> getFavoritesStream() {
    final user = currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) => List<String>.from(doc.data()?['favorites'] ?? []));
  }
}
