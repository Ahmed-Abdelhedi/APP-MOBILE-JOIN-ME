# JoinMe - Application Mobile Flutter

Application mobile permettant aux utilisateurs de découvrir et rejoindre des activités locales.

## 📱 Présentation du Projet

**JoinMe** est une application mobile qui connecte les personnes partageant les mêmes centres d'intérêt en leur permettant de :
- Découvrir des activités locales (sports, culture, gaming, food, etc.)
- Créer et organiser leurs propres événements
- Rejoindre des groupes et communiquer via chat en temps réel
- Localiser les activités sur une carte interactive

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
- Android Studio ou VS Code
- Un appareil Android ou émulateur

### Étapes d'installation

```bash
# 1. Cloner le repository
git clone <url-du-repo>
cd mobile

# 2. Installer les dépendances
flutter pub get

# 3. Lancer l'application
flutter run
```

### Générer l'APK
```bash
flutter build apk --release
```
L'APK sera généré dans : `build/app/outputs/flutter-apk/app-release.apk`

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
- **FirebaseAuth** : Gestion des utilisateurs
- **FirebaseFirestore** : Lecture/écriture des données (activités, messages, profils)
- **FirebaseStorage** : Upload/download des images

---

## 👥 Équipe

- [Ajouter les noms des membres de l'équipe]

---

## 📄 License

Projet académique - ENSA 2025/2026

