# 🚀 Guide de Configuration - JoinMe Mobile

## ⚠️ ERREUR COURANTE APRÈS CLONAGE

Si vous voyez cette erreur après avoir cloné le projet :
```
FAILURE: Build failed with an exception.
Could not determine the dependencies of task ':cloud_firestore:compileDebugJavaWithJavac'.
> Cannot query the value of this provider because it has no value available.
```

**C'est NORMAL !** Suivez les étapes ci-dessous pour la résoudre.

---

## 📋 PRÉREQUIS

Avant de commencer, assurez-vous d'avoir installé :

- ✅ **Flutter SDK** (version 3.10.1 ou supérieure)
  - Vérifier : `flutter --version`
  - Installer : https://docs.flutter.dev/get-started/install

- ✅ **Android Studio** ou **VS Code** avec extensions Flutter/Dart

- ✅ **Java JDK 17** 
  - Vérifier : `java -version`
  - Le build nécessite Java 17 (configuré dans `build.gradle.kts`)

- ✅ **Git** 
  - Vérifier : `git --version`

---

## 🔧 ÉTAPES D'INSTALLATION (APRÈS CLONAGE)

### 1️⃣ Cloner le projet

```bash
git clone <url-du-repo>
cd mobile
```

### 2️⃣ Installer les dépendances Flutter

```bash
flutter pub get
```

### 3️⃣ **IMPORTANT** : Créer le fichier `local.properties`

Ce fichier est **ignoré par Git** car il contient des chemins spécifiques à chaque machine.

#### Sur Windows (PowerShell) :
```powershell
# Aller dans le dossier android
cd android

# Créer le fichier local.properties
New-Item -ItemType File -Path local.properties -Force

# Ouvrir le fichier et ajouter le chemin Flutter
notepad local.properties
```

#### Sur macOS/Linux :
```bash
cd android
touch local.properties
```

**Ajouter cette ligne dans `android/local.properties` :**
```properties
flutter.sdk=/chemin/vers/votre/flutter/sdk
```

**Comment trouver le chemin Flutter ?**
```bash
# Exécuter cette commande à la racine du projet
flutter doctor -v

# Le chemin s'affiche dans "Flutter version"
# Exemple Windows : C:\src\flutter
# Exemple macOS : /Users/votrenom/flutter
# Exemple Linux : /home/votrenom/flutter
```

**OU utiliser cette commande automatique :**

**Windows (PowerShell) :**
```powershell
cd android
$flutterPath = (Get-Command flutter).Source | Split-Path | Split-Path
"flutter.sdk=$flutterPath" | Out-File -FilePath local.properties -Encoding ASCII
```

**macOS/Linux (Bash) :**
```bash
cd android
echo "flutter.sdk=$(dirname $(dirname $(which flutter)))" > local.properties
```

### 4️⃣ Nettoyer le cache Gradle

```bash
# Retourner à la racine du projet
cd ..

# Sur Windows (PowerShell)
cd android
./gradlew clean
cd ..

# Sur macOS/Linux
cd android
./gradlew clean
cd ..
```

### 5️⃣ **Configuration Firebase** (OBLIGATOIRE)

⚠️ **Le projet ne compilera pas sans les fichiers Firebase !**

#### Pour Android :
1. Demander au chef de projet le fichier `google-services.json`
2. Le placer dans : `android/app/google-services.json`

#### Pour iOS :
1. Demander au chef de projet le fichier `GoogleService-Info.plist`
2. Le placer dans : `ios/Runner/GoogleService-Info.plist`

**Si vous n'avez pas ces fichiers :**
- Contactez l'administrateur du projet Firebase
- OU créez votre propre projet Firebase de test sur https://console.firebase.google.com/

### 6️⃣ Vérifier la configuration Flutter

```bash
flutter doctor

# Résoudre les problèmes éventuels affichés
```

### 7️⃣ Tester le build

```bash
# Build Android
flutter build apk --debug

# OU lancer directement sur émulateur/appareil
flutter run
```

---

## 🐛 RÉSOLUTION DES PROBLÈMES COURANTS

### Erreur : "flutter.sdk not set in local.properties"
**Solution :** Vérifier que `android/local.properties` existe avec le bon chemin Flutter

### Erreur : "Could not determine the dependencies"
**Solutions :**
1. Supprimer le dossier `build/` à la racine
2. Supprimer `android/.gradle/` et `android/build/`
3. Relancer : `flutter clean && flutter pub get`
4. Rebuild : `flutter run`

```bash
# Commande complète de nettoyage
flutter clean
rm -rf android/.gradle android/build build
flutter pub get
cd android
./gradlew clean
cd ..
flutter run
```

### Erreur : "Unsupported class file major version"
**Cause :** Version Java incorrecte
**Solution :** Installer Java JDK 17
- Windows : https://adoptium.net/
- macOS : `brew install openjdk@17`
- Linux : `sudo apt install openjdk-17-jdk`

### Erreur : "Execution failed for task ':app:processDebugGoogleServices'"
**Cause :** Fichier `google-services.json` manquant
**Solution :** Demander le fichier au chef de projet et le placer dans `android/app/`

### Erreur : Gradle trop lent ou bloqué
**Solution :** Augmenter la mémoire dans `android/gradle.properties`
```properties
org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G
```

---

## 📱 TESTER L'APPLICATION

### Avec un émulateur Android :
```bash
# Lister les émulateurs disponibles
flutter emulators

# Lancer un émulateur
flutter emulators --launch <emulator_id>

# Lancer l'app
flutter run
```

### Avec un appareil physique :
1. Activer le mode développeur sur votre téléphone
2. Activer le débogage USB
3. Connecter via USB
4. Vérifier : `flutter devices`
5. Lancer : `flutter run`

---

## 🔐 SÉCURITÉ - FICHIERS À NE JAMAIS COMMITTER

Ces fichiers sont dans `.gitignore` et **ne doivent JAMAIS être poussés sur Git** :

- ❌ `android/local.properties` (chemin Flutter spécifique à votre machine)
- ❌ `android/app/google-services.json` (configuration Firebase)
- ❌ `ios/Runner/GoogleService-Info.plist` (configuration Firebase iOS)
- ❌ `lib/firebase_options.dart` (clés API)
- ❌ `.env` (variables d'environnement)
- ❌ `*.key` (clés de signature)

**Pourquoi ?**
- Contiennent des chemins locaux différents sur chaque machine
- Contiennent des clés API et secrets
- Risque de sécurité si exposés publiquement

---

## 📚 COMMANDES UTILES

```bash
# Vérifier l'état de Flutter
flutter doctor -v

# Installer les dépendances
flutter pub get

# Nettoyer le projet
flutter clean

# Lister les appareils connectés
flutter devices

# Lancer en mode debug
flutter run

# Lancer en mode release
flutter run --release

# Build APK
flutter build apk

# Build App Bundle (pour Play Store)
flutter build appbundle

# Voir les logs
flutter logs

# Analyser le code
flutter analyze

# Formater le code
dart format .

# Lancer les tests
flutter test
```

---

## 🆘 BESOIN D'AIDE ?

1. **Vérifier la documentation :**
   - README.md
   - FIREBASE_SETUP.md
   - BACKEND_REQUIREMENTS.md

2. **Problèmes Firebase :**
   - Consulter FIREBASE_SETUP.md
   - Vérifier que les services Firebase sont activés

3. **Problèmes de build :**
   - Exécuter `flutter clean`
   - Supprimer les caches Gradle
   - Vérifier Java JDK version

4. **Contacter l'équipe :**
   - Créer une issue sur Git
   - Demander au chef de projet

---

## ✅ CHECKLIST AVANT DE COMMENCER À CODER

- [ ] Flutter SDK installé et configuré
- [ ] Java JDK 17 installé
- [ ] Projet cloné depuis Git
- [ ] `flutter pub get` exécuté sans erreur
- [ ] `android/local.properties` créé avec le bon chemin Flutter
- [ ] `android/app/google-services.json` présent
- [ ] `flutter doctor` ne montre aucune erreur critique
- [ ] `flutter run` lance l'application avec succès
- [ ] Émulateur/Appareil détecté
- [ ] Application se lance sans crash

---

**Bon développement ! 🚀**

Si vous rencontrez un problème non listé ici, documentez-le et ajoutez la solution à ce fichier pour aider les futurs développeurs.
