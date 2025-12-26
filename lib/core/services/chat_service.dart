import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service de chat pour Firebase gratuit (sans Cloud Functions)
/// Écrit directement dans Firestore avec Security Rules
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Créer un chat pour une activité
  Future<String> createChatForActivity({
    required String activityId,
    required String activityTitle,
    required String creatorId,
    required String creatorName,
  }) async {
    try {
      final chatRef = await _firestore.collection('chats').add({
        'activityId': activityId,
        'activityTitle': activityTitle,
        'participants': [creatorId],
        'participantNames': [creatorName],
        'lastMessage': null,
        'lastMessageTime': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return chatRef.id;
    } catch (e) {
      throw Exception('Erreur création chat: $e');
    }
  }

  /// Envoyer un message dans un chat
  Future<String> sendMessage({
    required String chatId,
    required String text,
    String? imageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    try {
      // Récupérer infos utilisateur depuis Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final userName = userData?['name'] ?? user.displayName ?? 'Utilisateur';
      final userPhoto = userData?['photoUrl'] ?? user.photoURL;

      // Ajouter le message dans la sous-collection
      final messageRef = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': user.uid,
        'senderName': userName,
        'senderPhotoUrl': userPhoto,
        'text': text,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'type': imageUrl != null ? 'image' : 'text',
      });

      // Mettre à jour le chat avec le dernier message
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': text.length > 50 ? '${text.substring(0, 50)}...' : text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return messageRef.id;
    } catch (e) {
      throw Exception('Erreur envoi message: $e');
    }
  }

  /// Rejoindre un chat (quand on rejoint une activité)
  Future<void> joinChat({
    required String chatId,
    required String userId,
    required String userName,
  }) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'participants': FieldValue.arrayUnion([userId]),
        'participantNames': FieldValue.arrayUnion([userName]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Message système optionnel
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': 'system',
        'senderName': 'Système',
        'senderPhotoUrl': null,
        'text': '$userName a rejoint l\'activité',
        'imageUrl': null,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'system',
      });
    } catch (e) {
      throw Exception('Erreur rejoindre chat: $e');
    }
  }

  /// Quitter un chat (quand on quitte une activité)
  Future<void> leaveChat({
    required String chatId,
    required String userId,
    required String userName,
  }) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'participants': FieldValue.arrayRemove([userId]),
        'participantNames': FieldValue.arrayRemove([userName]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Message système optionnel
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': 'system',
        'senderName': 'Système',
        'senderPhotoUrl': null,
        'text': '$userName a quitté l\'activité',
        'imageUrl': null,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'system',
      });
    } catch (e) {
      throw Exception('Erreur quitter chat: $e');
    }
  }

  /// Récupérer le chat d'une activité
  Future<Map<String, dynamic>?> getChatByActivityId(String activityId) async {
    try {
      final querySnapshot = await _firestore
          .collection('chats')
          .where('activityId', isEqualTo: activityId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final doc = querySnapshot.docs.first;
      return {...doc.data(), 'id': doc.id};
    } catch (e) {
      throw Exception('Erreur récupération chat: $e');
    }
  }

  /// Supprimer un message (soft delete)
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    try {
      final messageDoc = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .get();

      // Vérifier que c'est bien l'émetteur
      if (messageDoc.data()?['senderId'] != user.uid) {
        throw Exception('Vous ne pouvez supprimer que vos propres messages');
      }

      // Soft delete : modifier le texte
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'text': '[Message supprimé]',
        'imageUrl': null,
      });
    } catch (e) {
      throw Exception('Erreur suppression message: $e');
    }
  }
}
