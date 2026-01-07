# 🔐 Guide de Sécurité - Fichiers Sensibles

## ⚠️ FICHIERS À NE JAMAIS RENDRE PUBLICS

### 1. Configuration Firebase Android
**Fichier :** `android/app/google-services.json`

**Pourquoi ?**
- Contient les clés API Firebase pour Android
- Permet l'accès à votre projet Firebase
- Peut être utilisé pour faire des requêtes en votre nom

**Solution :**
- ✅ Ajouté au `.gitignore`
- ✅ Fichier d'exemple créé : `google-services.json.example`
- ✅ Instructions fournies dans le README pour que le professeur crée le sien

---

### 2. Options Firebase Flutter
**Fichier :** `lib/firebase_options.dart`

**Pourquoi ?**
- Contient toutes les clés API Firebase (Android, iOS, Web)
- Expose les identifiants du projet
- Permet l'accès non autorisé aux services Firebase

**Solution :**
- ✅ Ajouté au `.gitignore`
- ✅ Fichier d'exemple créé : `firebase_options.dart.example`
- ✅ Instructions pour générer avec `flutterfire configure`

---

### 3. Propriétés locales Android
**Fichier :** `android/local.properties`

**Pourquoi ?**
- Contient les chemins locaux vers les SDK Android
- Spécifique à chaque machine
- Peut exposer la structure de votre système

**Solution :**
- ✅ Ajouté au `.gitignore` (déjà géré par Flutter)

---

### 4. Fichiers de signature APK
**Fichiers :** `*.keystore`, `*.jks`, `*.key`

**Pourquoi ?**
- Clés de signature pour publier sur Google Play Store
- Si compromises, quelqu'un pourrait publier des apps en votre nom
- Impossible à récupérer si perdues

**Solution :**
- ✅ Ajouté au `.gitignore`
- ⚠️ À conserver dans un endroit sécurisé (pas sur GitHub)

---

### 5. Variables d'environnement
**Fichiers :** `.env`, `.env.local`, `.env.production`

**Pourquoi ?**
- Contiennent souvent des secrets, tokens, clés API
- Utilisés pour la configuration sensible

**Solution :**
- ✅ Ajouté au `.gitignore`
- ✅ Pattern `*.env*` pour exclure toutes les variantes

---

### 6. APK de production
**Fichier :** `JOINMEFINALVERSION.apk`, `*.apk`, `*.aab`

**Pourquoi ?**
- Fichiers volumineux (63 MB+)
- Peuvent être régénérés facilement
- Alourdissent le repository Git

**Solution :**
- ✅ Ajouté au `.gitignore`
- ✅ APK à partager via d'autres moyens (Google Drive, releases GitHub)

---

## ✅ CE QUI EST INCLUS DANS LE REPOSITORY PUBLIC

### Fichiers de structure (exemples)
- ✅ `google-services.json.example` - Structure sans vraies clés
- ✅ `firebase_options.dart.example` - Template de configuration
- ✅ Instructions complètes dans README.md

### Code source
- ✅ Tout le code Dart de l'application
- ✅ Fichiers de configuration Flutter (pubspec.yaml, etc.)
- ✅ Assets publics (images, icônes)
- ✅ Documentation complète

### Configuration build
- ✅ Fichiers Gradle (android/build.gradle, etc.)
- ✅ Configuration iOS (ios/)
- ✅ Manifests Android et iOS

---

## 📤 COMMENT PARTAGER LE PROJET AVEC LE PROFESSEUR

### Option 1 : Repository GitHub Public ✅ (Recommandé)
```bash
# 1. Vérifier que les fichiers sensibles sont ignorés
git status

# 2. Commit et push
git add .
git commit -m "Préparation pour évaluation - fichiers sensibles exclus"
git push origin main

# 3. Partager le lien avec le professeur
```

**Avantages :**
- ✅ Historique de commits visible
- ✅ Code bien organisé et navigable
- ✅ README professionnel

---

### Option 2 : Fichiers séparés pour le professeur

**Partager PUBLIQUEMENT :**
- Le lien GitHub du repository public
- Le fichier `README.md` (instructions complètes)
- Le fichier `INSTRUCTIONS_PROFESSEUR.md`

**Partager EN PRIVÉ (email, message direct) :**
- L'APK : `JOINMEFINALVERSION.apk`
- Si nécessaire pour tests : `google-services.json` ET `firebase_options.dart`
  ⚠️ Dans un ZIP protégé par mot de passe ou via un lien sécurisé

**Ne PAS partager publiquement :**
- ❌ Les clés API Firebase
- ❌ Les fichiers de signature (.keystore, .jks)
- ❌ Les tokens d'accès ou secrets

---

## 🔍 VÉRIFICATION AVANT PUBLICATION

Avant de rendre le repository public, vérifiez :

```bash
# 1. Vérifier qu'aucun fichier sensible n'est tracké
git ls-files | grep -E "(google-services\.json|firebase_options\.dart|\.keystore|\.jks|\.env)"

# Si cette commande renvoie des résultats, ces fichiers sont trackés !
# Il faut les retirer :
git rm --cached android/app/google-services.json
git rm --cached lib/firebase_options.dart
git commit -m "Remove sensitive files"
```

```bash
# 2. Vérifier le .gitignore
cat .gitignore | grep -E "(google-services|firebase_options|keystore|apk)"
```

```bash
# 3. Vérifier que l'APK n'est pas dans Git
git ls-files | grep "\.apk$"
# Doit être vide !
```

---

## 📚 RESSOURCES SUPPLÉMENTAIRES

### Documentation Firebase
- [Sécurité Firebase](https://firebase.google.com/docs/projects/learn-more#config-files-objects)
- [Règles de sécurité Firestore](https://firebase.google.com/docs/firestore/security/get-started)

### Bonnes pratiques Git
- [Gitignore templates](https://github.com/github/gitignore)
- [Supprimer des secrets du Git history](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)

---

## ⚠️ EN CAS DE FUITE ACCIDENTELLE

Si vous avez déjà poussé des fichiers sensibles sur GitHub :

1. **Régénérer TOUTES les clés API** dans Firebase Console
2. **Supprimer l'historique Git** (BFG Repo-Cleaner ou git filter-branch)
3. **Révoquer les accès compromis**
4. **Forcer un nouveau push**

```bash
# Exemple pour retirer un fichier de l'historique
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch android/app/google-services.json" \
  --prune-empty --tag-name-filter cat -- --all

git push origin --force --all
```

**⚠️ Puis régénérez vos clés dans Firebase !**

---

## ✅ CHECKLIST FINALE

Avant de soumettre le projet au professeur :

- [ ] `.gitignore` correctement configuré
- [ ] Fichiers sensibles retirés du tracking Git
- [ ] Fichiers `.example` créés et documentés
- [ ] README.md complet avec instructions de configuration
- [ ] INSTRUCTIONS_PROFESSEUR.md créé
- [ ] APK généré et disponible (hors Git)
- [ ] Repository testé en local après un clone frais
- [ ] Aucune clé API visible dans le code public

---

**🎓 Votre projet est maintenant prêt à être partagé en toute sécurité !**
