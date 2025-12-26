# 💬 Architecture Chat - Liaison Frontend ↔️ Backend

## 📋 Vue d'ensemble

Le système de chat dans JoinMe connecte le **frontend Flutter** à votre **backend Firebase** (Cloud Functions + Firestore).

---

## 🏗️ Structure du Chat Frontend

### Localisation des fichiers
```
lib/features/chat/
├── presentation/
│   └── screens/
│       └── chat_screen.dart          # Interface utilisateur du chat
└── (data + domain à créer si besoin)

lib/core/providers/
└── firebase_providers.dart            # Providers pour connexion Firebase
```

---

## 🔌 Comment le Frontend se connecte au Backend

### 1. **Providers Firebase (lib/core/providers/firebase_providers.dart)**

```dart
// Provider pour récupérer les chats de l'utilisateur
final userChatsStreamProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('chats')
      .where('participants', arrayContains: user.uid)  // Chats où l'utilisateur participe
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList());
});

// Provider pour récupérer les messages d'un chat spécifique
final chatMessagesStreamProvider = StreamProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, chatId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('timestamp', descending: true)  // Messages récents en premier
      .limit(50)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList());
});
```

**Ce que fait le frontend :**
- ✅ **Écoute** les chats de l'utilisateur en temps réel via Firestore
- ✅ **Écoute** les messages d'un chat spécifique en temps réel
- ✅ **Affiche** les données reçues dans l'interface

**Ce que fait le backend :**
- ✅ Gère les règles de sécurité Firestore
- ✅ Crée les chats quand une activité est créée (Cloud Function)
- ✅ Notifie les utilisateurs de nouveaux messages (Cloud Function)
- ✅ Marque les messages comme lus (Cloud Function)

---

## 📊 Structure des Données Firestore

### Collection `chats`
```javascript
chats/{chatId}
{
  chatId: string,
  activityId: string,              // ID de l'activité liée
  activityTitle: string,           // Titre de l'activité
  participants: string[],          // Array des IDs utilisateurs
  participantDetails: [            // Détails des participants
    {
      userId: string,
      name: string,
      photoUrl: string?
    }
  ],
  lastMessage: string?,            // Dernier message envoyé
  lastMessageTime: timestamp?,     // Date du dernier message
  unreadCount: Map<string, number>, // {userId: count}
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### Sous-collection `chats/{chatId}/messages`
```javascript
chats/{chatId}/messages/{messageId}
{
  messageId: string,
  senderId: string,                // ID de l'utilisateur émetteur
  senderName: string,              // Nom de l'émetteur
  senderPhotoUrl: string?,         // Photo de l'émetteur
  text: string?,                   // Texte du message
  imageUrl: string?,               // URL d'une image (optionnel)
  type: string,                    // "text" | "image" | "system"
  timestamp: timestamp,            // Date/heure du message
  seenBy: string[],                // Array des IDs ayant vu le message
  isEdited: boolean?,              // Si le message a été modifié
  isDeleted: boolean?              // Si le message a été supprimé
}
```

---

## 🔄 Flux de Communication Frontend → Backend

### 1. **Affichage des Chats (chat_screen.dart)**

```dart
// Frontend écoute les chats de l'utilisateur
final chatsAsync = ref.watch(userChatsStreamProvider);

chatsAsync.when(
  data: (chats) {
    // Afficher la liste des chats
    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        return ChatTile(chat: chat);  // Widget pour afficher le chat
      },
    );
  },
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Erreur: $error'),
);
```

**Workflow :**
1. Frontend appelle `userChatsStreamProvider`
2. Provider se connecte à Firestore collection `chats`
3. Firestore retourne les chats en temps réel
4. Provider transforme les données en `List<Map>`
5. UI s'actualise automatiquement quand les données changent

---

### 2. **Affichage des Messages d'un Chat**

```dart
// Frontend écoute les messages d'un chat spécifique
final messagesAsync = ref.watch(chatMessagesStreamProvider(chatId));

messagesAsync.when(
  data: (messages) {
    // Afficher la liste des messages
    return ListView.builder(
      reverse: true,  // Messages récents en bas
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return MessageBubble(message: message);
      },
    );
  },
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Erreur: $error'),
);
```

---

### 3. **Envoyer un Message** (via Cloud Function)

```dart
// Frontend appelle une Cloud Function callable
Future<void> sendMessage(String chatId, String text) async {
  final functions = FirebaseFunctions.instance;
  
  try {
    final result = await functions.httpsCallable('sendMessage').call({
      'chatId': chatId,
      'text': text,
      'type': 'text',
    });
    
    print('Message envoyé: ${result.data}');
  } catch (e) {
    print('Erreur envoi message: $e');
    // Afficher erreur à l'utilisateur
  }
}
```

**Pourquoi utiliser une Cloud Function ?**
- ✅ **Sécurité** : Validation des données côté serveur
- ✅ **Notifications** : Envoi automatique de notifications push
- ✅ **Logique métier** : Mise à jour du compteur de messages non lus
- ✅ **Traçabilité** : Logs centralisés des actions

---

## 🔐 Ce que le Backend doit gérer

### Cloud Functions à implémenter

#### 1. **onCreate Activity → Créer Chat**
```javascript
// Quand une activité est créée, créer automatiquement un chat
exports.onActivityCreate = functions.firestore
  .document('activities/{activityId}')
  .onCreate(async (snap, context) => {
    const activity = snap.data();
    
    // Créer le chat lié à l'activité
    await admin.firestore().collection('chats').add({
      activityId: context.params.activityId,
      activityTitle: activity.title,
      participants: [activity.creatorId],  // Créateur au départ
      participantDetails: [
        {
          userId: activity.creatorId,
          name: activity.creatorName,
          photoUrl: activity.creatorPhoto
        }
      ],
      lastMessage: null,
      lastMessageTime: null,
      unreadCount: {},
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
  });
```

#### 2. **Callable sendMessage**
```javascript
exports.sendMessage = functions.https.onCall(async (data, context) => {
  // Vérifier que l'utilisateur est authentifié
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Utilisateur non authentifié');
  }

  const { chatId, text, type } = data;
  const userId = context.auth.uid;

  // Récupérer infos utilisateur
  const userDoc = await admin.firestore().collection('users').doc(userId).get();
  const user = userDoc.data();

  // Ajouter le message
  const messageRef = await admin.firestore()
    .collection('chats')
    .doc(chatId)
    .collection('messages')
    .add({
      senderId: userId,
      senderName: user.name,
      senderPhotoUrl: user.photoUrl || null,
      text: text,
      type: type || 'text',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      seenBy: [userId],  // Vu par l'émetteur
      isEdited: false,
      isDeleted: false
    });

  // Mettre à jour le chat avec lastMessage
  await admin.firestore().collection('chats').doc(chatId).update({
    lastMessage: text,
    lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });

  // Envoyer notifications aux autres participants
  // ... (code notification)

  return { messageId: messageRef.id, success: true };
});
```

#### 3. **Callable markMessagesAsRead**
```javascript
exports.markMessagesAsRead = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Utilisateur non authentifié');
  }

  const { chatId } = data;
  const userId = context.auth.uid;

  // Récupérer tous les messages non lus
  const messagesSnapshot = await admin.firestore()
    .collection('chats')
    .doc(chatId)
    .collection('messages')
    .where('seenBy', 'not-in', [[userId]])  // Messages non vus
    .get();

  // Marquer comme lus
  const batch = admin.firestore().batch();
  messagesSnapshot.docs.forEach(doc => {
    batch.update(doc.ref, {
      seenBy: admin.firestore.FieldValue.arrayUnion(userId)
    });
  });

  await batch.commit();

  return { success: true, markedCount: messagesSnapshot.size };
});
```

---

## 🔒 Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Règles pour les chats
    match /chats/{chatId} {
      // Lire seulement si on est participant
      allow read: if request.auth != null 
        && request.auth.uid in resource.data.participants;
      
      // Créer/modifier via Cloud Functions uniquement
      allow write: if false;
      
      // Messages du chat
      match /messages/{messageId} {
        // Lire si on participe au chat
        allow read: if request.auth != null 
          && request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
        
        // Écrire via Cloud Functions uniquement
        allow write: if false;
      }
    }
  }
}
```

---

## 📱 Résumé de la Liaison Frontend-Backend

### Frontend (Flutter) :
- ✅ **Affiche** les données via Riverpod Providers
- ✅ **Écoute** les Stream Firestore en temps réel
- ✅ **Appelle** les Cloud Functions pour les actions
- ✅ **UI seulement** - pas de logique métier

### Backend (Firebase) :
- ✅ **Gère** la création/mise à jour des chats
- ✅ **Valide** les données et permissions
- ✅ **Envoie** les notifications
- ✅ **Maintient** la cohérence des données
- ✅ **Logs** toutes les actions

---

## 🚀 Pour implémenter dans votre Backend

1. **Créez les Cloud Functions** listées ci-dessus
2. **Configurez les Security Rules** Firestore
3. **Testez** l'envoi de messages depuis le frontend
4. **Vérifiez** que les notifications fonctionnent

Le frontend est **déjà prêt** à se connecter, il attend juste que votre backend réponde ! ✨
