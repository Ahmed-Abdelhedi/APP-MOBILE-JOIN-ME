# JoinMe - Frontend Mobile

Application Flutter mobile pour rejoindre des activités locales.

## 🚀 Installation

### Prérequis

- Flutter SDK (3.10.1+)
- Dart SDK (3.0.0+)
- Firebase CLI
- Compte Firebase (projet: join-me-mobile)
- Dart SDK (3.10.1 or higher)
- Android Studio / VS Code
- Firebase account
- Google Maps API key (for map features)

### Installation

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd mobile
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   
   #### For Android:
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Add an Android app
   - Download `google-services.json`
   - Place it in `android/app/`
   
   #### For iOS:
   - Add an iOS app in Firebase Console
   - Download `GoogleService-Info.plist`
   - Place it in `ios/Runner/`

4. **Enable Firebase Services**
   
   In Firebase Console, enable:
   - Authentication (Email/Password & Google)
   - Cloud Firestore
   - Firebase Storage

### Configuration Firebase

⚠️ **NOUVEAUX DÉVELOPPEURS** : Consultez d'abord [SETUP_POUR_NOUVEAUX_DEVELOPPEURS.md](SETUP_POUR_NOUVEAUX_DEVELOPPEURS.md)

#### Configuration rapide (après clonage)

**1. Script automatique (RECOMMANDÉ) :**
```bash
# Windows PowerShell
.\setup.ps1

# macOS/Linux
chmod +x setup.sh
./setup.sh
```

**2. Obtenir les fichiers Firebase :**
- Demander `google-services.json` au chef de projet
- Le placer dans `android/app/`

**3. Lancer l'app :**
```bash
flutter run
```

#### Configuration complète Firebase CLI (optionnel)

```bash
# 1. Installer Firebase CLI
npm install -g firebase-tools

# 2. Se connecter à Firebase
firebase login

# 3. Configurer le projet
flutterfire configure --project=join-me-mobile

# 4. Installer les dépendances
flutter pub get

# 5. Lancer l'app
flutter run
```

## 📱 Fonctionnalités

- **Auth**: Connexion, inscription, Google Sign-In
- **Activités**: Découvrir et rejoindre des activités locales  
- **Chat**: Messagerie en temps réel par activité
- **Map**: Carte interactive avec activités géolocalisées
- **Profil**: Gestion du profil utilisateur

## 🏗️ Architecture

- **State Management**: Riverpod
- **Backend**: Firebase (Auth, Firestore, Storage, Messaging)
- **Structure**: Clean Architecture avec features

## 🔗 Backend

Le backend Firebase (Cloud Functions, Security Rules) est dans un projet séparé.
Ce frontend se connecte directement aux services Firebase via les providers.

