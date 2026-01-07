# JoinMe - Application Mobile Flutter 🚀

Application mobile permettant aux utilisateurs de découvrir et rejoindre des activités locales.

[![Flutter](https://img.shields.io/badge/Flutter-3.10.1+-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/Dart-3.0.0+-0175C2?logo=dart)](https://dart.dev)

---

## 📱 Présentation du Projet

**JoinMe** est une application mobile qui connecte les personnes partageant les mêmes centres d'intérêt en leur permettant de :
- 🎯 Découvrir des activités locales (sports, culture, gaming, food, etc.)
- ✨ Créer et organiser leurs propres événements
- 💬 Rejoindre des groupes et communiquer via chat en temps réel
- 🗺️ Localiser les activités sur une carte interactive
- 👥 Gérer son profil et ses participations

---

## ⚠️ IMPORTANT - Configuration Sécurité

### Fichiers sensibles NON inclus dans ce repository public

Pour des raisons de sécurité, les fichiers suivants contenant des clés API **ne sont PAS** inclus :

```
❌ android/app/google-services.json       (Configuration Firebase Android)
❌ lib/firebase_options.dart              (Clés API Firebase)
❌ android/local.properties               (Configuration locale)
```

### 🔧 Configuration requise pour exécuter le projet

**Pour le professeur / évaluateur :** 
Des fichiers d'exemple sont fournis pour comprendre la structure :
- `android/app/google-services.json.example` - Structure du fichier Firebase Android
- `lib/firebase_options.dart.example` - Structure des options Firebase Flutter

**Pour exécuter l'application, vous devez :**

1. **Créer un projet Firebase** sur https://console.firebase.google.com
2. **Télécharger votre propre `google-services.json`**
   - Console Firebase → Paramètres du projet → Ajouter une application Android
   - Package name : `com.example.mobile`
   - Télécharger le fichier et le placer dans `android/app/`

3. **Configurer Firebase pour Flutter**
   ```bash
   # Installer FlutterFire CLI
   dart pub global activate flutterfire_cli
   
   # Générer firebase_options.dart
   flutterfire configure
   ```

4. **Activer les services Firebase nécessaires :**
   - ✅ Authentication (Email/Password + Google Sign-In)
   - ✅ Cloud Firestore
   - ✅ Firebase Storage
   - ✅ Cloud Messaging (notifications)

### 📦 APK de démonstration

Un APK pré-compilé est disponible pour tester l'application directement :
- Fichier : `JOINMEFINALVERSION.apk` (voir releases ou racine du projet)
- ⚠️ Cet APK est configuré avec un projet Firebase de test

---

## 🛠️ Technologies Utilisées

### Frontend
| Technologie | Utilisation |
|-------------|-------------|
| **Flutter** | Framework de développement mobile cross-platform |
| **Dart** | Langage de programmation |
| **Riverpod** | Gestion d'état (State Management) |
| **GoRouter** | Navigation et routing |
| **Flutter Map** | Carte interactive OpenStreetMap |

### Backend (Firebase)
| Service | Utilisation |
|---------|-------------|
| **Firebase Auth** | Authentification (Email/Password + Google Sign-In) |
| **Cloud Firestore** | Base de données NoSQL temps réel |
| **Firebase Storage** | Stockage des images (avatars, événements) |
| **Firebase Messaging** | Notifications push |

### Architecture
- **Clean Architecture** avec séparation en couches (data, domain, presentation)
- **Feature-based** structure pour une meilleure organisation du code

---

## 🚀 Installation et Exécution

### Prérequis
- Flutter SDK (3.10.1+)
- Dart SDK (3.0.0+)
- Android Studio ou VS Code avec les extensions Flutter/Dart
- Un appareil Android ou émulateur
- Un compte Firebase (pour la configuration)

### Étapes d'installation

```bash
# 1. Cloner le repository
git clone <url-du-repo>
cd mobile

# 2. Installer les dépendances
flutter pub get

# 3. Configurer Firebase (OBLIGATOIRE)
# Voir section "Configuration Sécurité" ci-dessus
# - Créer un projet Firebase
# - Télécharger google-services.json
# - Exécuter: flutterfire configure

# 4. Vérifier la configuration
flutter doctor

# 5. Lancer l'application en mode debug
flutter run

# 6. Ou lancer en mode release
flutter run --release
```

### Générer l'APK de production
```bash
# Clean puis build
flutter clean
flutter pub get
flutter build apk --release

# L'APK sera généré dans :
# build/app/outputs/flutter-apk/app-release.apk
```

### Tester avec l'APK fourni
```bash
# Installer directement sur un appareil Android
adb install JOINMEFINALVERSION.apk

# Ou transférer le fichier sur votre téléphone et l'installer manuellement
```

---

## 📁 Structure du Projet

```
lib/
├── main.dart                 # Point d'entrée de l'application
├── firebase_options.dart     # Configuration Firebase
├── core/                     # Éléments partagés (constants, providers, utils)
│   ├── constants/            # Couleurs, thèmes, dimensions
│   ├── providers/            # Providers globaux (Firebase, etc.)
│   └── utils/                # Utilitaires (formatters, validators)
├── features/                 # Fonctionnalités par module
│   ├── auth/                 # Authentification
│   │   ├── data/             # Datasources, repositories impl
│   │   ├── domain/           # Entities, repositories interfaces
│   │   └── presentation/     # Screens, widgets, providers
│   ├── activities/           # Gestion des activités
│   ├── chat/                 # Messagerie temps réel
│   ├── map/                  # Carte interactive
│   └── profile/              # Profil utilisateur
└── shared/                   # Composants réutilisables
```

---

## 📱 Fonctionnalités Implémentées (MVP)

### ✅ Authentification
- Inscription / Connexion par email
- Connexion avec Google (Google Sign-In)
- Déconnexion et gestion de session

### ✅ Activités
- Liste des activités avec filtres par catégorie
- Création d'une nouvelle activité
- Détail d'une activité (description, participants, date, lieu)
- Rejoindre / Quitter une activité

### ✅ Chat
- Messagerie en temps réel par activité
- Envoi de messages texte
- Historique des conversations

### ✅ Carte
- Visualisation des activités sur une carte
- Géolocalisation de l'utilisateur
- Navigation vers le détail d'une activité

### ✅ Profil
- Affichage et modification du profil
- Changement d'avatar
- Historique des activités rejointes

---

## 🔗 Connexion Frontend ↔ Backend

```
┌─────────────────┐         ┌─────────────────────────┐
│                 │         │       FIREBASE          │
│   FLUTTER APP   │ ◄─────► │                         │
│   (Frontend)    │         │  ┌─────────────────┐    │
│                 │         │  │  Firebase Auth  │    │
│  ┌───────────┐  │         │  └─────────────────┘    │
│  │ Providers │──┼─────────┼──►                      │
│  └───────────┘  │         │  ┌─────────────────┐    │
│                 │         │  │ Cloud Firestore │    │
│  ┌───────────┐  │         │  └─────────────────┘    │
│  │  Screens  │  │         │                         │
│  └───────────┘  │         │  ┌─────────────────┐    │
│                 │         │  │ Firebase Storage│    │
└─────────────────┘         │  └─────────────────┘    │
                            └─────────────────────────┘
```

L'application communique avec Firebase via les SDK officiels :
- **FirebaseAuth** : Gestion des utilisateurs (inscription, connexion, Google Sign-In)
- **FirebaseFirestore** : Base de données NoSQL temps réel (activités, messages, profils)
- **FirebaseStorage** : Stockage cloud des images (avatars, photos d'événements)
- **Firebase Messaging** : Notifications push pour les nouveaux messages et invitations

---

## 📸 Captures d'écran

### Écran d'authentification
- Interface moderne avec authentification par email/mot de passe
- Connexion rapide via Google Sign-In
- Design responsive avec gestion du clavier

### Écran d'accueil
- Liste des activités disponibles avec filtres par catégorie
- Cartes visuelles pour chaque activité
- Navigation fluide vers les détails

### Carte interactive
- Visualisation géographique des activités
- Géolocalisation en temps réel
- Marqueurs cliquables pour accéder aux détails

### Chat en temps réel
- Messagerie instantanée par activité
- Notifications push pour les nouveaux messages
- Interface conversationnelle intuitive

---


---

**Note pour l'évaluation :**  
Ce README contient toutes les informations nécessaires pour comprendre, configurer et exécuter le projet. Les fichiers sensibles (clés API Firebase) ont été exclus pour des raisons de sécurité mais des exemples de structure sont fournis. Un APK de démonstration est disponible pour tester l'application sans configuration Firebase.


