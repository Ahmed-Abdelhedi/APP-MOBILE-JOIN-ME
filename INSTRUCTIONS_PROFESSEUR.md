# Instructions pour le Professeur / Évaluateur 👨‍🏫

## Méthodes d'évaluation du projet

### Option 1 : Installation rapide avec APK (Recommandé) ✅

**Temps requis : ~2 minutes**

1. Téléchargez le fichier `JOINMEFINALVERSION.apk` depuis le repository
2. Transférez-le sur un appareil Android
3. Installez l'APK (autoriser l'installation depuis des sources inconnues si nécessaire)
4. Lancez l'application "JoinMe"

**✅ Avantages :**
- Aucune configuration requise
- Test immédiat de toutes les fonctionnalités
- Application déjà connectée à Firebase

---

### Option 2 : Compilation depuis le code source

**Temps requis : ~30-45 minutes**

#### Prérequis
- Flutter SDK 3.10.1+
- Android Studio ou VS Code
- Un compte Firebase (gratuit)
- Émulateur Android ou appareil physique

#### Étapes détaillées

**1. Cloner et installer les dépendances**
```bash
git clone <url-du-repo>
cd mobile
flutter pub get
```

**2. Créer votre propre projet Firebase**

⚠️ **IMPORTANT** : Les fichiers de configuration Firebase originaux ne sont PAS inclus dans ce repository pour des raisons de sécurité.

a. Allez sur https://console.firebase.google.com
b. Créez un nouveau projet (ex: "joinme-test-eval")
c. Ajoutez une application Android :
   - Package name : `com.example.mobile`
   - Téléchargez le fichier `google-services.json`
   - Placez-le dans `android/app/`

**3. Configurer FlutterFire**
```bash
# Installer la CLI
dart pub global activate flutterfire_cli

# Configurer automatiquement
flutterfire configure
```
Cette commande va créer le fichier `lib/firebase_options.dart` automatiquement.

**4. Activer les services Firebase**

Dans la console Firebase, activez :
- ✅ Authentication → Email/Password
- ✅ Authentication → Google Sign-In
- ✅ Cloud Firestore → Mode test (règles publiques pour démo)
- ✅ Firebase Storage → Mode test
- ✅ Cloud Messaging

**5. Lancer l'application**
```bash
flutter run
```

---

## 🎯 Fonctionnalités à tester

### 1. Authentification
- ✅ Inscription avec email/mot de passe
- ✅ Connexion avec Google
- ✅ Déconnexion

### 2. Activités
- ✅ Liste des activités disponibles
- ✅ Filtres par catégorie (Sport, Culture, Gaming, etc.)
- ✅ Créer une nouvelle activité
- ✅ Rejoindre/Quitter une activité
- ✅ Voir les détails et participants

### 3. Chat
- ✅ Messagerie en temps réel
- ✅ Envoi de messages
- ✅ Historique des conversations

### 4. Carte
- ✅ Visualisation des activités sur carte
- ✅ Géolocalisation
- ✅ Navigation vers les détails

### 5. Profil
- ✅ Modification du profil
- ✅ Upload d'avatar
- ✅ Historique des activités

---

## 📋 Critères d'évaluation suggérés

| Critère | Points | Commentaire |
|---------|--------|-------------|
| **Architecture** | /20 | Clean Architecture, séparation des couches |
| **Qualité du code** | /20 | Organisation, commentaires, conventions |
| **Fonctionnalités** | /30 | Toutes les features MVP implémentées |
| **UI/UX** | /15 | Design moderne, navigation fluide |
| **Backend Firebase** | /15 | Intégration complète et fonctionnelle |
| **TOTAL** | **/100** | |

---

## ❓ FAQ pour l'évaluation

### Q: Pourquoi les fichiers Firebase ne sont pas inclus ?
**R:** Pour des raisons de sécurité. Les clés API Firebase doivent rester privées. Des fichiers `.example` sont fournis pour montrer la structure.

### Q: L'APK ne fonctionne pas sur mon téléphone
**R:** Vérifiez que :
- Vous avez autorisé l'installation depuis des sources inconnues
- Votre téléphone est sous Android 7.0+ (API 24+)
- Le fichier APK n'est pas corrompu (taille : ~63 MB)

### Q: Je veux compiler mais j'ai des erreurs
**R:** Les erreurs courantes :
- `google-services.json` manquant → Créez votre propre projet Firebase
- `firebase_options.dart` manquant → Exécutez `flutterfire configure`
- Dépendances → Exécutez `flutter clean && flutter pub get`

### Q: Comment tester sans compte Google ?
**R:** Utilisez l'authentification par email :
- Email : test@example.com
- Mot de passe : 123456 (ou créez un nouveau compte)

---

## 📞 Contact en cas de problème

Si vous rencontrez des difficultés techniques pour évaluer le projet :
- 📧 Email : [votre.email@example.com]
- 💬 Utilisez plutôt l'APK fourni pour un test rapide

---

**Merci pour votre évaluation ! 🙏**
