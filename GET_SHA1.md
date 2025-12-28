# 🔥 ERREUR GOOGLE SIGN-IN - CODE 10

## ❌ Problème
```
PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10)
```

**Code 10 = DEVELOPER_ERROR** : Votre app n'est pas correctement configurée dans Firebase Console.

---

## ✅ SOLUTION RAPIDE

### Option 1 : Obtenir SHA-1 avec Android Studio (RECOMMANDÉ)

1. **Ouvrir Android Studio**
2. **Ouvrir le dossier** `C:\Users\LENOVO\Desktop\mobile\android` dans Android Studio
3. **Cliquer sur** `Gradle` (panneau droit)
4. **Naviguer vers :** `mobile > android > Tasks > android > signingReport`
5. **Double-cliquer sur** `signingReport`
6. **Copier le SHA-1** qui s'affiche (ressemble à : `A1:B2:C3:...`)

### Option 2 : Méthode manuelle (si Java 11+ disponible)

```powershell
cd C:\Users\LENOVO\Desktop\mobile\android
.\gradlew signingReport
```

**⚠️ Problème actuel :** Vous avez Java 8, mais Gradle nécessite Java 11+.

**Solution temporaire :** Télécharger Java 11+ depuis https://adoptium.net/ ou utiliser Android Studio (Option 1).

---

## 📱 Étapes dans Firebase Console

### 1. Aller sur Firebase Console
- https://console.firebase.google.com
- Sélectionner votre projet

### 2. Ajouter le SHA-1

1. **Cliquer sur** ⚙️ (Settings) → **Project Settings**
2. **Scroller vers le bas** jusqu'à "Your apps"
3. **Cliquer sur votre app Android** (com.example.mobile)
4. **Scroller vers** "SHA certificate fingerprints"
5. **Cliquer sur** "Add fingerprint"
6. **Coller votre SHA-1**
7. **Sauvegarder**

### 3. Télécharger le nouveau google-services.json

1. **Dans les mêmes paramètres**, cliquer sur "Download google-services.json"
2. **Remplacer** le fichier dans `android/app/google-services.json`

---

## 🧪 Vérifications supplémentaires

### Vérifier le Package Name

Dans `android/app/build.gradle.kts`, vérifier que :
```kotlin
applicationId = "com.example.mobile"
```

Ce package DOIT correspondre au package dans Firebase Console.

### Vérifier que Google Sign-In est activé

1. Firebase Console → **Authentication** → **Sign-in method**
2. **Google** doit être **Enabled** (Activé)
3. Si non activé, cliquez dessus et activez-le

---

## 🔄 Après configuration Firebase

### 1. Clean et rebuild
```powershell
cd C:\Users\LENOVO\Desktop\mobile
flutter clean
flutter pub get
cd android
# Si vous avez Java 11+ :
.\gradlew clean
cd ..
```

### 2. Relancer l'app
```powershell
flutter run
```

### 3. Tester Google Sign-In
- Cliquez sur "Continue with Google"
- Sélectionnez un compte Google
- ✅ Devrait fonctionner !

---

## 📋 Checklist finale

- [ ] SHA-1 obtenu (via Android Studio ou gradlew)
- [ ] SHA-1 ajouté dans Firebase Console > Project Settings > Your apps
- [ ] google-services.json téléchargé et remplacé dans `android/app/`
- [ ] Package name vérifié (com.example.mobile)
- [ ] Google Sign-In activé dans Firebase Authentication
- [ ] flutter clean && flutter pub get exécuté
- [ ] App relancée avec flutter run
- [ ] Test de connexion Google effectué

---

## ⚠️ Erreurs courantes

### "API not enabled"
**Solution :** Aller sur https://console.cloud.google.com → APIs & Services → Enable "Google Sign-In API"

### "The package name must match"
**Solution :** Vérifier que le package dans `build.gradle.kts` correspond EXACTEMENT à celui dans Firebase Console

### "Invalid SHA-1"
**Solution :** Assurez-vous de copier le SHA-1 du **debug keystore** (pas release) pour les tests

---

## 🎯 Résumé ultra-rapide

1. **Obtenir SHA-1** (Android Studio > Gradle > signingReport)
2. **Firebase Console** > Settings > Add SHA-1 fingerprint
3. **Télécharger nouveau** google-services.json
4. **Remplacer** dans android/app/
5. **flutter clean && flutter pub get**
6. **flutter run**
7. **Tester !** 🎉

---

**Note :** L'erreur Code 10 est presque TOUJOURS causée par un SHA-1 manquant. Une fois ajouté, Google Sign-In devrait fonctionner immédiatement.
