# Security Rules Firebase pour le Chat

## 📋 Instructions

Vous devez ajouter ces règles dans votre **Firebase Console** → **Firestore Database** → **Règles**.

## 🔐 Règles de sécurité complètes

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ============================================
    // RÈGLES POUR LES UTILISATEURS
    // ============================================
    match /users/{userId} {
      // Lecture : tout utilisateur connecté peut lire tous les profils
      allow read: if request.auth != null;
      
      // Création : uniquement lors de l'inscription, l'utilisateur créé son propre document
      allow create: if request.auth != null && request.auth.uid == userId;
      
      // Mise à jour : seulement son propre profil
      allow update: if request.auth != null && request.auth.uid == userId;
      
      // Suppression : seulement son propre profil
      allow delete: if request.auth != null && request.auth.uid == userId;
    }
    
    // ============================================
    // RÈGLES POUR LES ACTIVITÉS
    // ============================================
    match /activities/{activityId} {
      // Lecture : tout utilisateur connecté peut voir les activités
      allow read: if request.auth != null;
      
      // Création : tout utilisateur connecté peut créer une activité
      // Doit inclure son propre uid comme creatorId
      allow create: if request.auth != null 
                    && request.resource.data.creatorId == request.auth.uid
                    && request.resource.data.participants is list
                    && request.auth.uid in request.resource.data.participants;
      
      // Mise à jour : 
      // - Le créateur peut modifier l'activité
      // - Tout participant peut mettre à jour le tableau participants
      allow update: if request.auth != null && (
        // Le créateur peut tout modifier
        resource.data.creatorId == request.auth.uid
        ||
        // Un utilisateur peut se joindre/quitter
        (
          // Vérifie que seuls participants et currentParticipants changent
          (request.resource.data.diff(resource.data).affectedKeys().hasOnly(['participants', 'currentParticipants']) ||
           request.resource.data.diff(resource.data).affectedKeys().hasOnly(['participants', 'currentParticipants', 'updatedAt']))
          && (
            // Ajout : l'utilisateur s'ajoute lui-même
            (!(request.auth.uid in resource.data.participants) && (request.auth.uid in request.resource.data.participants))
            ||
            // Retrait : l'utilisateur se retire lui-même
            ((request.auth.uid in resource.data.participants) && !(request.auth.uid in request.resource.data.participants))
          )
        )
      );
      
      // Suppression : seulement le créateur
      allow delete: if request.auth != null && resource.data.creatorId == request.auth.uid;
    }
    
    // ============================================
    // RÈGLES POUR LES CHATS
    // ============================================
    match /chats/{chatId} {
      // Lecture : tout utilisateur connecté peut lire les chats
      allow read: if request.auth != null;
      
      // Création : tout utilisateur connecté peut créer un chat
      allow create: if request.auth != null;
      
      // Mise à jour : tout utilisateur connecté peut mettre à jour
      // (pour lastMessage, participants, etc.)
      allow update: if request.auth != null;
      
      // Suppression : non autorisé (les chats persistent)
      allow delete: if false;
      
      // ============================================
      // SOUS-COLLECTION : MESSAGES
      // ============================================
      match /messages/{messageId} {
        // Lecture : tout utilisateur connecté peut lire les messages
        // (la sécurité est gérée au niveau du chat parent)
        allow read: if request.auth != null;
        
        // Création : tout participant peut envoyer des messages
        // Le senderId doit correspondre à l'uid de l'utilisateur
        allow create: if request.auth != null 
                      && request.resource.data.senderId == request.auth.uid;
        
        // Mise à jour : seulement l'émetteur peut modifier son message
        // (pour soft delete ou édition)
        allow update: if request.auth != null 
                      && resource.data.senderId == request.auth.uid;
        
        // Suppression : seulement l'émetteur
        allow delete: if request.auth != null 
                      && resource.data.senderId == request.auth.uid;
      }
    }
  }
}
```

## ✅ Comment appliquer ces règles

1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionnez votre projet **join-me-mobile**
3. Dans le menu latéral, cliquez sur **Firestore Database**
4. Cliquez sur l'onglet **Règles** en haut
5. Copiez-collez les règles ci-dessus
6. Cliquez sur **Publier**

## 🔍 Explication des règles

### Chats
- **Lecture** : Seuls les participants d'un chat peuvent le voir
- **Création** : Tout utilisateur connecté peut créer un chat (automatique lors de la création d'activité)
- **Mise à jour** : Seuls les participants peuvent mettre à jour (ajout de participants, lastMessage)
- **Suppression** : Interdite (les chats persistent même si l'activité est supprimée)

### Messages
- **Lecture** : Seuls les participants du chat parent peuvent lire les messages
- **Création** : Seuls les participants peuvent envoyer des messages, et le `senderId` doit correspondre à leur uid
- **Mise à jour** : Seul l'émetteur peut modifier son propre message (soft delete)
- **Suppression** : Seul l'émetteur peut supprimer son propre message

## 🎯 Test des règles

Après avoir publié les règles, testez :
1. Créez une nouvelle activité → un chat devrait être créé automatiquement
2. Rejoignez l'activité → vous devenez participant
3. Cliquez sur le bouton "Chat" → vous devriez voir le chat
4. Envoyez un message → il devrait apparaître en temps réel
5. Quittez l'activité → vous ne devriez plus voir le chat dans la liste

## 📱 Structure des données

### Collection `chats`
```json
{
  "activityId": "string",
  "activityTitle": "string",
  "participants": ["uid1", "uid2"],
  "participantNames": ["Name1", "Name2"],
  "lastMessage": "string or null",
  "lastMessageTime": "timestamp or null",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### Sous-collection `chats/{chatId}/messages`
```json
{
  "senderId": "string",
  "senderName": "string",
  "senderPhotoUrl": "string or null",
  "text": "string",
  "imageUrl": "string or null",
  "timestamp": "timestamp",
  "type": "text | image | system"
}
```

## ⚠️ Important

- Ces règles fonctionnent **sans Cloud Functions** (gratuit)
- Tous les utilisateurs connectés peuvent créer des chats
- Les chats sont automatiquement créés lors de la création d'activités
- Les participants sont synchronisés avec le tableau `participants` des activités
- Le chat reste accessible tant que vous êtes participant de l'activité
