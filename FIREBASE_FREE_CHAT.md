# 🔥 Firebase Gratuit - Configuration Chat (Sans Cloud Functions)

## ⚠️ Important : Version Gratuite de Firebase

Vous utilisez le **Spark Plan (gratuit)** qui ne permet **PAS** d'utiliser Cloud Functions.

**Limitations :**
- ❌ Pas de Cloud Functions
- ❌ Pas de notifications automatiques
- ❌ Pas de logique serveur

**Avantages :**
- ✅ 100% GRATUIT
- ✅ Firestore disponible
- ✅ Authentication disponible
- ✅ Storage disponible
- ✅ Hébergement disponible

---

## 📊 Structure Firestore à Créer Manuellement

### 1. Collection `chats`

Créez dans la console Firebase : `Firestore Database` > `Start collection`

```javascript
chats/{chatId}
{
  chatId: string,                    // Auto-généré par Firestore
  activityId: string,                // ID de l'activité
  activityTitle: string,             // Titre de l'activité
  participants: string[],            // [userId1, userId2, ...]
  participantNames: string[],        // ["Alice", "Bob", ...]
  lastMessage: string | null,        // Dernier message texte
  lastMessageTime: timestamp | null, // Date du dernier message
  createdAt: timestamp,              // Date de création
  updatedAt: timestamp               // Date de mise à jour
}
```

**Exemple de document :**
```json
{
  "chatId": "chat_xyz123",
  "activityId": "activity_abc456",
  "activityTitle": "Football 5v5",
  "participants": ["user1_uid", "user2_uid", "user3_uid"],
  "participantNames": ["Alice", "Bob", "Charlie"],
  "lastMessage": "À quelle heure on se rejoint ?",
  "lastMessageTime": "2025-12-23T10:30:00Z",
  "createdAt": "2025-12-23T08:00:00Z",
  "updatedAt": "2025-12-23T10:30:00Z"
}
```

---

### 2. Sous-collection `messages`

Dans chaque chat : `chats/{chatId}/messages/{messageId}`

```javascript
messages/{messageId}
{
  messageId: string,                 // Auto-généré
  senderId: string,                  // UID de l'émetteur
  senderName: string,                // Nom de l'émetteur
  senderPhotoUrl: string | null,     // Photo de profil
  text: string,                      // Texte du message
  imageUrl: string | null,           // URL image (optionnel)
  timestamp: timestamp,              // Date/heure
  type: "text" | "image" | "system"  // Type de message
}
```

**Exemple de message :**
```json
{
  "messageId": "msg_789",
  "senderId": "user1_uid",
  "senderName": "Alice",
  "senderPhotoUrl": "https://...",
  "text": "Salut tout le monde !",
  "imageUrl": null,
  "timestamp": "2025-12-23T10:30:00Z",
  "type": "text"
}
```

---

## 🔒 Security Rules (Version Gratuite)

Copiez ces règles dans : `Firestore Database` > `Rules`

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Fonction helper : utilisateur authentifié
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Fonction helper : est participant du chat
    function isParticipant(chatId) {
      return isAuthenticated() 
        && request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
    }
    
    // === COLLECTION USERS ===
    match /users/{userId} {
      // Lire : tous les utilisateurs authentifiés
      allow read: if isAuthenticated();
      
      // Écrire : seulement son propre profil
      allow write: if isAuthenticated() && request.auth.uid == userId;
    }
    
    // === COLLECTION ACTIVITIES ===
    match /activities/{activityId} {
      // Lire : tous les utilisateurs authentifiés
      allow read: if isAuthenticated();
      
      // Créer : utilisateurs authentifiés
      allow create: if isAuthenticated()
        && request.resource.data.creatorId == request.auth.uid;
      
      // Modifier : seulement le créateur
      allow update: if isAuthenticated()
        && resource.data.creatorId == request.auth.uid;
      
      // Supprimer : seulement le créateur
      allow delete: if isAuthenticated()
        && resource.data.creatorId == request.auth.uid;
    }
    
    // === COLLECTION CHATS ===
    match /chats/{chatId} {
      // Lire : seulement les participants
      allow read: if isAuthenticated()
        && request.auth.uid in resource.data.participants;
      
      // Créer : quand on crée une activité
      allow create: if isAuthenticated()
        && request.auth.uid in request.resource.data.participants;
      
      // Modifier : les participants peuvent modifier (lastMessage, etc.)
      allow update: if isAuthenticated()
        && request.auth.uid in resource.data.participants;
      
      // === SOUS-COLLECTION MESSAGES ===
      match /messages/{messageId} {
        // Lire : si on participe au chat parent
        allow read: if isAuthenticated()
          && request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
        
        // Créer : si on participe au chat et qu'on est l'émetteur
        allow create: if isAuthenticated()
          && request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants
          && request.resource.data.senderId == request.auth.uid;
        
        // Pas de modification/suppression pour simplifier
        allow update, delete: if false;
      }
    }
  }
}
```

---

## 💻 Code Frontend Modifié (Sans Cloud Functions)

### 1. Service d'envoi de messages (créer ce fichier)

**Créez : `lib/core/services/chat_service.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  /// Envoyer un message
  Future<String> sendMessage({
    required String chatId,
    required String text,
    String? imageUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    try {
      // Récupérer infos utilisateur
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final userName = userData?['name'] ?? 'Utilisateur';
      final userPhoto = userData?['photoUrl'];

      // Ajouter le message
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
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return messageRef.id;
    } catch (e) {
      throw Exception('Erreur envoi message: $e');
    }
  }

  /// Rejoindre un chat (ajouter aux participants)
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
    } catch (e) {
      throw Exception('Erreur rejoindre chat: $e');
    }
  }

  /// Quitter un chat
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
    } catch (e) {
      throw Exception('Erreur quitter chat: $e');
    }
  }
}
```

---

### 2. Provider pour ChatService

**Ajoutez dans `lib/core/providers/firebase_providers.dart` :**

```dart
import 'package:mobile/core/services/chat_service.dart';

/// Provider pour ChatService
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});
```

---

### 3. Exemple d'utilisation dans l'UI

```dart
// Dans votre écran de chat
class ChatMessagesScreen extends ConsumerStatefulWidget {
  final String chatId;
  const ChatMessagesScreen({required this.chatId, super.key});

  @override
  ConsumerState<ChatMessagesScreen> createState() => _ChatMessagesScreenState();
}

class _ChatMessagesScreenState extends ConsumerState<ChatMessagesScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() => _isSending = true);

    try {
      final chatService = ref.read(chatServiceProvider);
      await chatService.sendMessage(
        chatId: widget.chatId,
        text: _messageController.text.trim(),
      );
      
      _messageController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Message envoyé'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Écouter les messages
    final messagesAsync = ref.watch(
      chatMessagesStreamProvider(widget.chatId)
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          // Liste des messages
          Expanded(
            child: messagesAsync.when(
              data: (messages) => ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return MessageBubble(message: message);
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Erreur: $e')),
            ),
          ),
          
          // Zone de saisie
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Votre message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isSending
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.send),
                  onPressed: _isSending ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 📋 Étapes pour Configurer

### 1. Dans Firebase Console

1. Allez sur [console.firebase.google.com](https://console.firebase.google.com)
2. Sélectionnez votre projet "join-me-mobile"
3. **Firestore Database** :
   - Créez la collection `chats` (peut être vide au début)
   - Allez dans **Rules** et collez les Security Rules ci-dessus
   - Publiez les règles
4. **Authentication** :
   - Vérifiez que Email/Password est activé

### 2. Dans votre code Flutter

1. Créez le fichier `lib/core/services/chat_service.dart` avec le code ci-dessus
2. Ajoutez le provider dans `firebase_providers.dart`
3. Utilisez `ChatService` au lieu d'appeler Cloud Functions

### 3. Test

```dart
// Quand vous créez une activité :
final chatService = ref.read(chatServiceProvider);
final chatId = await chatService.createChatForActivity(
  activityId: activityId,
  activityTitle: 'Football 5v5',
  creatorId: currentUser.uid,
  creatorName: currentUser.name,
);

// Pour envoyer un message :
await chatService.sendMessage(
  chatId: chatId,
  text: 'Bonjour !',
);
```

---

## ⚠️ Limitations Sans Cloud Functions

| Fonctionnalité | Avec Cloud Functions (Payant) | Sans Cloud Functions (Gratuit) |
|----------------|-------------------------------|--------------------------------|
| Envoyer messages | ✅ Automatique | ✅ Depuis le frontend |
| Notifications push | ✅ Automatiques | ❌ Non disponibles |
| Validation serveur | ✅ Oui | ⚠️ Via Security Rules uniquement |
| Compteur messages non lus | ✅ Automatique | ❌ À gérer manuellement |
| Modération contenu | ✅ Possible | ❌ Non |
| Logs centralisés | ✅ Oui | ❌ Non |

---

## 💡 Conseils

1. **Testez les Security Rules** dans la console Firebase (onglet "Rules Playground")
2. **Limitations de taille** : Firestore limite à 1 Mo par document
3. **Coût** : Le plan gratuit inclut :
   - 50,000 lectures/jour
   - 20,000 écritures/jour
   - 20,000 suppressions/jour
   - 1 GB stockage

C'est largement suffisant pour un prototype ou une petite application ! 🚀

---

## 🎯 Résumé

✅ **Ce qui fonctionne en gratuit :**
- Chat en temps réel
- Messages texte et images
- Plusieurs participants
- Sécurité via Rules

❌ **Ce qui nécessite le plan payant :**
- Notifications push automatiques
- Validation complexe côté serveur
- Analytics avancés

Votre frontend est **100% compatible** avec cette approche gratuite ! 🎉
