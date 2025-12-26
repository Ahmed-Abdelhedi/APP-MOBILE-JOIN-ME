# 🔧 Configuration Manuelle Firebase (Sans Git)

## ⚠️ Problème Détecté

Git n'est pas installé sur votre système, donc `flutterfire configure` ne peut pas fonctionner.

**Solution** : Configuration manuelle des fichiers Firebase

---

## 📋 Étape 1 : Récupérer les Identifiants Firebase

### Android

1. Allez sur [Firebase Console](https://console.firebase.google.com)
2. Sélectionnez **"join-me-mobile"**
3. Cliquez sur l'icône **Android** (ou "Ajouter une application")
4. Nom du package : `com.joinme.mobile`
5. Cliquez **"Enregistrer l'application"**
6. **Téléchargez** `google-services.json`
7. **Copiez** ce fichier dans : `android/app/google-services.json`

### iOS (si vous compilez pour iOS)

1. Même console Firebase
2. Cliquez sur l'icône **iOS**
3. Identifiant du bundle : `com.joinme.mobile`
4. Téléchargez `GoogleService-Info.plist`
5. Copiez dans : `ios/Runner/GoogleService-Info.plist`

---

## 📋 Étape 2 : Mettre à Jour firebase_options.dart

Le fichier `lib/firebase_options.dart` a été créé, mais vous devez remplacer les valeurs.

### Récupérer les valeurs depuis Firebase Console

1. Firebase Console → **Paramètres du projet** (icône ⚙️)
2. Onglet **"Général"**
3. Descendez à **"Vos applications"**
4. Sélectionnez l'application **Android**

Vous verrez :
```
API Key: AIzaSy...
App ID: 1:123456789:android:...
Messaging Sender ID: 123456789
Project ID: join-me-mobile
Storage Bucket: join-me-mobile.appspot.com
```

### Mettre à jour le fichier

Ouvrez `lib/firebase_options.dart` et remplacez :

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'VOTRE_API_KEY_ANDROID',           // ← Remplacez
  appId: 'VOTRE_APP_ID_ANDROID',             // ← Remplacez
  messagingSenderId: 'VOTRE_SENDER_ID',      // ← Remplacez
  projectId: 'join-me-mobile',               // ✅ OK
  storageBucket: 'join-me-mobile.appspot.com', // ✅ OK
);
```

Par vos vraies valeurs depuis Firebase Console.

---

## 📋 Étape 3 : Vérifier les Fichiers Gradle

### android/build.gradle.kts

Vérifiez que ce fichier contient :

```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

### android/app/build.gradle.kts

À la fin du fichier, ajoutez (si pas déjà présent) :

```kotlin
apply(plugin = "com.google.gms.google-services")
```

---

## 📋 Étape 4 : Tester la Configuration

```powershell
# Compiler pour vérifier
flutter build apk --debug

# Ou lancer directement
flutter run
```

---

## ✅ Vérification Finale

Si tout est OK, vous devriez voir :

```
✓ Built build\app\outputs\flutter-apk\app-debug.apk
```

Et l'app démarre sans erreur Firebase !

---

## 🔴 Si Erreur "Default FirebaseApp not initialized"

Cela signifie que les valeurs dans `firebase_options.dart` ne sont pas correctes.

**Solution** :
1. Retournez dans Firebase Console
2. Copiez EXACTEMENT les valeurs
3. Remplacez dans `firebase_options.dart`
4. Relancez `flutter run`

---

## 📝 Fichiers à Vérifier

- [x] `lib/firebase_options.dart` - Créé ✅
- [x] `lib/main.dart` - Mis à jour ✅
- [ ] `android/app/google-services.json` - À télécharger depuis Firebase Console
- [ ] `android/build.gradle.kts` - Vérifier google-services plugin
- [ ] `android/app/build.gradle.kts` - Vérifier apply plugin

---

## 🎯 Prochaine Étape

1. **Télécharger** `google-services.json` depuis Firebase Console
2. **Copier** dans `android/app/`
3. **Mettre à jour** les valeurs dans `firebase_options.dart`
4. **Lancer** : `flutter run`

---

## 💡 Alternative : Installer Git

Si vous voulez utiliser `flutterfire configure` plus tard :

1. Télécharger Git : https://git-scm.com/download/win
2. Installer
3. Redémarrer PowerShell
4. Lancer : `flutterfire configure --project=join-me-mobile`

Mais la configuration manuelle fonctionne aussi parfaitement ! ✅
