# 🔥 Configuration Firebase - Étapes Complètes

## ✅ État Actuel du Projet

Votre projet Flutter est **déjà configuré** pour Firebase :
- ✅ Packages installés (pubspec.yaml)
- ✅ Services créés (chat_service.dart)
- ✅ Providers configurés (firebase_providers.dart)
- ✅ Modèles créés (ChatModel, MessageModel, ActivityModel)

---

## 📋 Étape 1 : Configurer Firebase dans la Console

### 1.1 Aller sur Firebase Console

🌐 [https://console.firebase.google.com](https://console.firebase.google.com)

1. Connectez-vous avec votre compte Google
2. Sélectionnez le projet **"join-me-mobile"**

---

### 1.2 Configurer Firestore Database

1. Dans le menu de gauche → **Firestore Database**
2. Cliquez **"Créer une base de données"** (si pas encore fait)
3. Choisissez **"Mode production"**
4. Sélectionnez la région : **"europe-west"** (ou la plus proche)
5. Cliquez **"Activer"**

✅ Firestore est maintenant créé !

---

### 1.3 Configurer les Security Rules

1. Dans **Firestore Database** → Onglet **"Règles"**
2. **SUPPRIMEZ** tout le contenu actuel
3. **COLLEZ** ce code :

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Fonction : utilisateur authentifié
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Fonction : c'est mon profil
    function isMyProfile(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // === USERS ===
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isMyProfile(userId);
    }
    
    // === ACTIVITIES ===
    match /activities/{activityId} {
      allow read: if isAuthenticated();
      
      allow create: if isAuthenticated()
        && request.resource.data.creatorId == request.auth.uid
        && request.resource.data.title.size() >= 3
        && request.resource.data.maxParticipants > 0;
      
      allow update: if isAuthenticated()
        && (resource.data.creatorId == request.auth.uid
            || request.auth.uid in resource.data.participants);
      
      allow delete: if isAuthenticated()
        && resource.data.creatorId == request.auth.uid;
    }
    
    // === CHATS ===
    match /chats/{chatId} {
      allow read: if isAuthenticated()
        && request.auth.uid in resource.data.participants;
      
      allow create: if isAuthenticated()
        && request.auth.uid in request.resource.data.participants;
      
      allow update: if isAuthenticated()
        && request.auth.uid in resource.data.participants;
      
      // === MESSAGES ===
      match /messages/{messageId} {
        allow read: if isAuthenticated()
          && request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
        
        allow create: if isAuthenticated()
          && request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants
          && request.resource.data.senderId == request.auth.uid
          && request.resource.data.text.size() <= 500;
        
        allow update, delete: if false;
      }
    }
  }
}
```

4. Cliquez **"Publier"**

✅ Security Rules configurées !

---

### 1.4 Vérifier Authentication

1. Menu de gauche → **Authentication**
2. Onglet **"Sign-in method"**
3. Vérifiez que ces méthodes sont **activées** :
   - ✅ **Email/Password** → Activé
   - ✅ **Google** → Activé

Si pas activé :
1. Cliquez sur la méthode
2. Cliquez **"Activer"**
3. Sauvegardez

✅ Authentication configurée !

---

### 1.5 Vérifier Storage (optionnel pour images)

1. Menu de gauche → **Storage**
2. Si pas encore créé, cliquez **"Commencer"**
3. **Mode production** → Suivant
4. Région : **europe-west**
5. Cliquez **"Terminé"**

✅ Storage configuré !

---

## 📋 Étape 2 : Configurer le Frontend Flutter

### 2.1 Installer FlutterFire CLI

Ouvrez PowerShell dans le dossier du projet :

```bash
# Installer FlutterFire CLI
dart pub global activate flutterfire_cli

# Vérifier l'installation
flutterfire --version
```

---

### 2.2 Configurer Firebase dans le projet

```bash
# Se connecter à Firebase
firebase login

# Configurer le projet
flutterfire configure --project=join-me-mobile
```

**Questions posées** :
1. Sélectionnez le projet : **join-me-mobile** ✅
2. Plateformes : **Android** et **iOS** (utilisez espace pour sélectionner)
3. Confirmer : **Oui**

✅ Fichier `lib/firebase_options.dart` créé !

---

### 2.3 Mettre à jour main.dart

Le fichier existe déjà, mais vérifiez qu'il contient :

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Firebase AVEC les options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // ... reste du code
}
```

---

## 📋 Étape 3 : Tester la Configuration

### 3.1 Lancer l'application

```bash
flutter run
```

### 3.2 Tester l'authentification

1. Créez un compte avec email/password
2. Vérifiez dans **Firebase Console** → **Authentication** → **Users**
3. Vous devriez voir l'utilisateur créé ✅

### 3.3 Tester Firestore

1. Dans l'app, créez une activité
2. Vérifiez dans **Firebase Console** → **Firestore Database** → **Data**
3. Vous devriez voir la collection `activities` créée ✅

---

## 📊 Structure Firestore Finale

Après utilisation de l'app, vous aurez :

```
Firestore Database/
├── users/
│   └── {userId}
│       ├── name: "Alice"
│       ├── email: "alice@email.com"
│       └── photoUrl: "..."
│
├── activities/
│   └── {activityId}
│       ├── title: "Football 5v5"
│       ├── creatorId: "userId"
│       ├── participants: [userId1, userId2]
│       └── ...
│
└── chats/
    └── {chatId}
        ├── activityId: "activityId"
        ├── participants: [userId1, userId2]
        └── messages/
            └── {messageId}
                ├── senderId: "userId"
                ├── text: "Bonjour"
                └── timestamp: DateTime
```

---

## ✅ Checklist Finale

- [ ] Firebase Console configurée
  - [ ] Firestore Database créé
  - [ ] Security Rules publiées
  - [ ] Authentication activée
  - [ ] Storage créé (optionnel)

- [ ] Frontend configuré
  - [ ] FlutterFire CLI installé
  - [ ] `flutterfire configure` exécuté
  - [ ] `firebase_options.dart` créé
  - [ ] `main.dart` mis à jour

- [ ] Tests
  - [ ] App lance sans erreur
  - [ ] Connexion fonctionne
  - [ ] Données apparaissent dans Firestore

---

## 🎉 C'est terminé !

Votre application est **100% configurée** avec Firebase !

**Structure complète :**
```
mobile/
├── lib/
│   ├── core/
│   │   ├── models/              ✅ Créés
│   │   │   ├── chat_model.dart
│   │   │   ├── message_model.dart
│   │   │   └── activity_model.dart
│   │   ├── services/            ✅ Créés
│   │   │   ├── chat_service.dart
│   │   │   └── location_service.dart
│   │   ├── utils/               ✅ Créés
│   │   │   ├── validators.dart
│   │   │   └── formatters.dart
│   │   └── providers/           ✅ Créés
│   │       └── firebase_providers.dart
│   ├── firebase_options.dart    ✅ À créer (étape 2.2)
│   └── main.dart                ✅ À vérifier
│
└── Firebase (Console)            ✅ À configurer
    ├── Firestore + Rules
    ├── Authentication
    └── Storage
```

**Prêt à développer ! 🚀**
