# 🔴 ERREUR APRÈS CLONAGE - SOLUTION RAPIDE

## ❌ L'erreur que tu vois :
```
FAILURE: Build failed with an exception.
Could not determine the dependencies of task ':cloud_firestore:compileDebugJavaWithJavac'.
> Cannot query the value of this provider because it has no value available.
```

## ✅ SOLUTION EN 3 ÉTAPES

### 1️⃣ Utiliser le script automatique

**Windows (PowerShell) :**
```powershell
cd mobile
.\setup.ps1
```

**macOS/Linux :**
```bash
cd mobile
chmod +x setup.sh
./setup.sh
```

Le script va :
- ✅ Créer automatiquement `android/local.properties` avec le bon chemin Flutter
- ✅ Installer toutes les dépendances
- ✅ Nettoyer les caches
- ✅ Vérifier la configuration

---

### 2️⃣ Obtenir les fichiers Firebase (OBLIGATOIRE)

**Demander au chef de projet :**
- `android/app/google-services.json` (pour Android)
- `ios/Runner/GoogleService-Info.plist` (pour iOS)

**⚠️ Sans ces fichiers, le projet ne compilera pas !**

---

### 3️⃣ Lancer l'application

```bash
flutter run
```

---

## 🆘 Ça ne marche toujours pas ?

### Solution manuelle complète :

**1. Créer `android/local.properties` manuellement**

```bash
# Trouver le chemin Flutter
flutter doctor -v

# Le chemin s'affiche dans "Flutter version"
# Exemple : C:\src\flutter
```

Créer le fichier `android/local.properties` et ajouter :
```properties
flutter.sdk=TON_CHEMIN_FLUTTER_ICI
```

**OU avec une commande automatique :**

Windows PowerShell :
```powershell
cd android
$flutterPath = (Get-Command flutter).Source | Split-Path | Split-Path
"flutter.sdk=$flutterPath" | Out-File -FilePath local.properties -Encoding ASCII
cd ..
```

macOS/Linux :
```bash
cd android
echo "flutter.sdk=$(dirname $(dirname $(which flutter)))" > local.properties
cd ..
```

**2. Nettoyer complètement le projet**

```bash
flutter clean
rm -rf android/.gradle android/build build
flutter pub get
```

**3. Tester le build**

```bash
flutter run
```

---

## 📚 Documentation complète

Pour plus de détails, consulter :
- **[SETUP_POUR_NOUVEAUX_DEVELOPPEURS.md](SETUP_POUR_NOUVEAUX_DEVELOPPEURS.md)** - Guide complet
- **[README.md](README.md)** - Documentation générale
- **[FIREBASE_SETUP.md](FIREBASE_SETUP.md)** - Configuration Firebase

---

## 🔍 Pourquoi cette erreur ?

Le fichier `android/local.properties` contient des chemins spécifiques à chaque machine :
- Il contient le chemin vers Flutter SDK sur **MON** ordinateur
- Sur **TON** ordinateur, le chemin est différent
- C'est pourquoi il est dans `.gitignore` et n'est pas commité

**Chaque développeur doit créer son propre `local.properties` !**

---

## ✅ Checklist de vérification

Avant de lancer `flutter run`, vérifier :

- [ ] Flutter SDK installé (`flutter --version`)
- [ ] Java JDK 17 installé (`java -version`)
- [ ] Fichier `android/local.properties` créé avec bon chemin
- [ ] Fichier `android/app/google-services.json` présent
- [ ] `flutter pub get` exécuté sans erreur
- [ ] `flutter doctor` ne montre pas d'erreur critique
- [ ] Émulateur ou appareil connecté (`flutter devices`)

---

**Si tu as d'autres problèmes, contacte-moi ou crée une issue sur Git ! 🚀**
