# 🔧 GUIDE: Activer l'authentification Google dans JoinMe

## ❌ Problème actuel
Le bouton "Continue with Google" est en **mode démo** et ne fait pas d'authentification réelle. Il vous connecte directement à l'app sans vérifier votre compte Google.

## ✅ Solution en 3 étapes

---

## ÉTAPE 1: Ajouter les dépendances nécessaires

### 1.1 Modifier `pubspec.yaml`

Ajouter ces packages après la ligne `firebase_messaging`:

```yaml
dependencies:
  # ... autres dépendances ...
  firebase_messaging: ^16.1.0
  google_sign_in: ^6.2.1        # ← AJOUTER CECI
```

### 1.2 Installer les dépendances

```bash
flutter pub get
```

---

## ÉTAPE 2: Configuration Firebase Console

### 2.1 Activer Google Sign-In dans Firebase

1. Allez sur https://console.firebase.google.com
2. Sélectionnez votre projet JoinMe
3. Allez dans **Authentication** > **Sign-in method**
4. Cliquez sur **Google**
5. **Activez** le fournisseur Google
6. Sélectionnez un **email de support** (votre email)
7. Cliquez sur **Enregistrer**

### 2.2 Configuration Android (Important!)

#### A. Obtenir le SHA-1 de votre machine

Ouvrez PowerShell dans le dossier `android/` et exécutez:

```powershell
.\gradlew signingReport
```

Vous verrez quelque chose comme:
```
SHA1: A1:B2:C3:D4:E5:F6:... (copier cette valeur)
```

#### B. Ajouter le SHA-1 dans Firebase

1. Dans Firebase Console, allez dans **Project Settings** ⚙️
2. Descendez à **Your apps** → votre app Android
3. Cliquez sur **Add fingerprint**
4. Collez votre **SHA-1**
5. Cliquez sur **Save**

#### C. Télécharger le nouveau google-services.json

1. Dans la même page, cliquez sur **Download google-services.json**
2. Remplacez le fichier `android/app/google-services.json` existant
3. **IMPORTANT**: Chaque développeur doit ajouter son propre SHA-1 et télécharger le fichier mis à jour!

### 2.3 Configuration iOS (si vous développez sur Mac)

1. Dans Firebase Console, allez dans **Project Settings** ⚙️
2. Descendez à **Your apps** → votre app iOS
3. Copiez le **iOS URL Scheme** (exemple: `com.googleusercontent.apps.123456-abc`)
4. Ouvrez `ios/Runner/Info.plist`
5. Ajoutez:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.VOTRE-CLIENT-ID</string>
        </array>
    </dict>
</array>
```

---

## ÉTAPE 3: Créer l'implémentation du code

### 3.1 Créer le Data Source Firebase

Créer le fichier: `lib/features/auth/data/datasources/firebase_auth_datasource.dart`

```dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthDataSource {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  FirebaseAuthDataSource({
    firebase_auth.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  // Sign in with Google
  Future<firebase_auth.User> signInWithGoogle() async {
    try {
      // Démarrer le processus de connexion Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Google sign-in cancelled by user');
      }

      // Obtenir les détails d'authentification
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Créer une nouvelle credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Se connecter à Firebase avec la credential
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      
      if (userCredential.user == null) {
        throw Exception('Failed to sign in with Google');
      }

      // Créer/mettre à jour le profil utilisateur dans Firestore
      await _createOrUpdateUserProfile(userCredential.user!);

      return userCredential.user!;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception('Firebase Auth Error: ${e.message}');
    } catch (e) {
      throw Exception('Google Sign-In Error: $e');
    }
  }

  // Créer ou mettre à jour le profil utilisateur dans Firestore
  Future<void> _createOrUpdateUserProfile(firebase_auth.User firebaseUser) async {
    final userDoc = _firestore.collection('users').doc(firebaseUser.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      // Créer un nouveau profil
      await userDoc.set({
        'userId': firebaseUser.uid,
        'email': firebaseUser.email,
        'name': firebaseUser.displayName ?? 'User',
        'photoUrl': firebaseUser.photoURL,
        'bio': null,
        'interests': [],
        'phoneNumber': firebaseUser.phoneNumber,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
        'fcmToken': null,
        'isActive': true,
        'stats': {
          'activitiesCreated': 0,
          'activitiesJoined': 0,
          'totalParticipations': 0,
        },
      });
    } else {
      // Mettre à jour lastSeen
      await userDoc.update({
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
  }

  // Sign out
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // Get current user
  firebase_auth.User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  // Auth state changes stream
  Stream<firebase_auth.User?> get authStateChanges {
    return _firebaseAuth.authStateChanges();
  }
}
```

### 3.2 Créer le Repository Implementation

Créer: `lib/features/auth/data/repositories/auth_repository_impl.dart`

```dart
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:mobile/core/errors/failures.dart';
import 'package:mobile/features/auth/domain/entities/user.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/data/datasources/firebase_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource dataSource;

  AuthRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    try {
      final firebaseUser = await dataSource.signInWithGoogle();
      final user = _mapFirebaseUserToUser(firebaseUser);
      return Right(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Google sign-in failed'));
    } catch (e) {
      return Left(ServerFailure(message: 'An error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await dataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Sign out failed: $e'));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final firebaseUser = dataSource.getCurrentUser();
      if (firebaseUser == null) return const Right(null);
      return Right(_mapFirebaseUserToUser(firebaseUser));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get current user: $e'));
    }
  }

  @override
  Stream<User?> get authStateChanges {
    return dataSource.authStateChanges.map((firebaseUser) {
      if (firebaseUser == null) return null;
      return _mapFirebaseUserToUser(firebaseUser);
    });
  }

  // Helper: Convertir FirebaseUser en User entity
  User _mapFirebaseUserToUser(firebase_auth.User firebaseUser) {
    return User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName ?? 'User',
      photoUrl: firebaseUser.photoURL,
      bio: null,
      interests: const [],
      phoneNumber: firebaseUser.phoneNumber,
      createdAt: DateTime.now(),
      lastSeen: DateTime.now(),
      fcmToken: null,
    );
  }

  // TODO: Implémenter les autres méthodes du repository
  @override
  Future<Either<Failure, User>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    // À implémenter
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, User>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) {
    // À implémenter
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) {
    // À implémenter
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, void>> updateProfile({
    String? name,
    String? photoUrl,
    String? bio,
    List<String>? interests,
    String? phoneNumber,
  }) {
    // À implémenter
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, String>> uploadProfileImage(String imagePath) {
    // À implémenter
    throw UnimplementedError();
  }
}
```

### 3.3 Créer le Provider Riverpod

Créer: `lib/features/auth/presentation/providers/auth_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/data/datasources/firebase_auth_datasource.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/domain/entities/user.dart';

// Provider pour le DataSource
final authDataSourceProvider = Provider<FirebaseAuthDataSource>((ref) {
  return FirebaseAuthDataSource();
});

// Provider pour le Repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = ref.watch(authDataSourceProvider);
  return AuthRepositoryImpl(dataSource: dataSource);
});

// Provider pour l'état de l'authentification
final authStateProvider = StreamProvider<User?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

// Provider pour le current user
final currentUserProvider = FutureProvider<User?>((ref) async {
  final repository = ref.watch(authRepositoryProvider);
  final result = await repository.getCurrentUser();
  return result.fold(
    (failure) => null,
    (user) => user,
  );
});

// Controller pour gérer les actions d'authentification
class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AsyncValue.data(null));

  Future<bool> signInWithGoogle() async {
    state = const AsyncValue.loading();
    
    final result = await _repository.signInWithGoogle();
    
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (user) {
        state = const AsyncValue.data(null);
        return true;
      },
    );
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    await _repository.signOut();
    state = const AsyncValue.data(null);
  }
}

// Provider pour le controller
final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository);
});
```

### 3.4 Modifier le LoginScreen

Dans `lib/features/auth/presentation/screens/modern_login_screen.dart`, remplacez le bouton Google (lignes 398-450 environ):

**ANCIEN CODE (à remplacer):**
```dart
// Google Sign In (Mode démo)
Container(
  width: double.infinity,
  height: 56,
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(28),
    border: Border.all(
      color: Colors.grey[300]!,
      width: 1.5,
    ),
  ),
  child: ElevatedButton.icon(
    onPressed: () {
      // Mode démo - connexion directe
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mode démo - Connexion rapide'),
          duration: Duration(seconds: 1),
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    },
    // ... reste du code
  ),
),
```

**NOUVEAU CODE (authentification réelle):**
```dart
// Google Sign In (Authentification réelle)
Container(
  width: double.infinity,
  height: 56,
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(28),
    border: Border.all(
      color: Colors.grey[300]!,
      width: 1.5,
    ),
  ),
  child: ElevatedButton.icon(
    onPressed: _isLoading ? null : _handleGoogleSignIn,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
    ),
    icon: Image.network(
      'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
      width: 24,
      height: 24,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.login, color: Colors.blue),
    ),
    label: const Text(
      'Continue with Google',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    ),
  ),
),
```

### 3.5 Ajouter la méthode _handleGoogleSignIn

Dans la classe `_ModernLoginScreenState`, ajoutez cette méthode:

```dart
Future<void> _handleGoogleSignIn() async {
  setState(() => _isLoading = true);

  try {
    final authController = ref.read(authControllerProvider.notifier);
    final success = await authController.signInWithGoogle();

    if (!mounted) return;

    if (success) {
      _showSuccess('Connexion réussie avec Google!');
      
      // Attendre un peu pour que l'utilisateur voie le message
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      // Naviguer vers la home screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    } else {
      _showError('Échec de la connexion avec Google');
    }
  } catch (e) {
    if (!mounted) return;
    _showError('Erreur: ${e.toString()}');
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

### 3.6 Ajouter l'import nécessaire

En haut du fichier `modern_login_screen.dart`, ajoutez:

```dart
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart';
```

---

## 🧪 ÉTAPE 4: Tester

### 4.1 Clean et rebuild

```bash
flutter clean
flutter pub get
cd android
.\gradlew clean
cd ..
flutter run
```

### 4.2 Tester la connexion

1. Lancez l'app
2. Cliquez sur "Continue with Google"
3. Sélectionnez un compte Google
4. Vous devriez être connecté et voir votre profil dans Firestore!

---

## 🔍 Dépannage

### Erreur: "PlatformException(sign_in_failed)"

**Solution**: Vérifiez que le SHA-1 est bien configuré dans Firebase Console.

### Erreur: "API not enabled"

**Solution**: Activez l'API Google Sign-In dans Google Cloud Console:
1. https://console.cloud.google.com
2. Sélectionnez votre projet
3. APIs & Services > Enable APIs
4. Cherchez "Google Sign-In API" et activez-la

### L'app crash au lancement

**Solution**: Vérifiez que `google-services.json` est bien dans `android/app/`

### "User cancelled the sign-in"

**Solution normale** - L'utilisateur a fermé la fenêtre de connexion Google.

---

## 📝 Pour les nouveaux développeurs

**Chaque nouveau développeur doit:**

1. Générer son propre SHA-1:
   ```bash
   cd android
   .\gradlew signingReport
   ```

2. Demander au chef de projet d'ajouter le SHA-1 dans Firebase Console

3. Télécharger le nouveau `google-services.json` et le placer dans `android/app/`

4. Faire `flutter pub get` et `flutter clean`

---

## ✅ Checklist finale

- [ ] Package `google_sign_in` ajouté dans pubspec.yaml
- [ ] `flutter pub get` exécuté
- [ ] Google Sign-In activé dans Firebase Console
- [ ] SHA-1 ajouté dans Firebase Console
- [ ] `google-services.json` mis à jour et placé dans `android/app/`
- [ ] Fichiers créés: `firebase_auth_datasource.dart`, `auth_repository_impl.dart`, `auth_providers.dart`
- [ ] LoginScreen modifié avec la vraie authentification
- [ ] App testée et connexion Google fonctionnelle ✅

---

**Bon développement! 🚀**
