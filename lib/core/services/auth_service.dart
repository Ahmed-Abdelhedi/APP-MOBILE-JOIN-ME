import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service d'authentification avec Firebase
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Utilisateur actuel
  User? get currentUser => _auth.currentUser;

  /// Stream de l'état d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Connexion avec email et mot de passe
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print('🔄 Début connexion pour: $email');
      
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ Connexion Firebase Auth réussie');

      // Mettre à jour le profil utilisateur (lastSeen, etc.)
      if (credential.user != null) {
        await _updateUserProfile(credential.user!);
      }

      return AuthResult.success(credential.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error('Erreur de connexion: $e');
    }
  }

  /// Mettre à jour le profil utilisateur dans Firestore lors de la connexion
  Future<void> _updateUserProfile(User user) async {
    try {
      print('🔄 Mise à jour du profil utilisateur...');
      
      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (docSnapshot.exists) {
        // Utilisateur existant : mettre à jour lastSeen
        await userDoc.update({
          'lastSeen': FieldValue.serverTimestamp(),
          'email': user.email, // Mettre à jour l'email au cas où il a changé
          'name': user.displayName ?? docSnapshot.data()?['name'] ?? 'Utilisateur',
        });
        print('✅ Profil mis à jour (lastSeen)');
      } else {
        // Nouvel utilisateur : créer le document
        await userDoc.set({
          'uid': user.uid,
          'name': user.displayName ?? 'Utilisateur',
          'email': user.email,
          'photoUrl': user.photoURL,
          'bio': '',
          'interests': [],
          'phoneNumber': user.phoneNumber,
          'createdAt': FieldValue.serverTimestamp(),
          'lastSeen': FieldValue.serverTimestamp(),
          'fcmToken': null,
          'favorites': [], // Initialiser les favoris
        });
        print('✅ Nouveau profil créé');
      }
    } catch (e) {
      print('⚠️ Erreur mise à jour profil: $e');
      // Ne pas bloquer la connexion si la mise à jour du profil échoue
    }
  }

  /// Inscription avec email, mot de passe et nom
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      print('🔄 Début création compte pour: $email');
      
      // Créer le compte Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ Compte Firebase Auth créé');

      final user = credential.user;
      if (user == null) {
        return AuthResult.error('Erreur lors de la création du compte');
      }

      // Mettre à jour le nom d'affichage
      await user.updateDisplayName(name);
      print('✅ Nom d\'affichage mis à jour');

      // Créer le document utilisateur dans Firestore avec timeout
      print('🔄 Création document Firestore...');
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'photoUrl': null,
        'bio': '',
        'interests': [],
        'phoneNumber': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'favorites': [], // Initialiser les favoris
        'fcmToken': null,
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: Vérifiez les Security Rules dans Firestore Console');
        },
      );

      print('✅ Document Firestore créé');
      return AuthResult.success(user);
    } on FirebaseAuthException catch (e) {
      print('❌ Erreur Firebase Auth: ${e.code}');
      return AuthResult.error(_getErrorMessage(e.code));
    } catch (e) {
      print('❌ Erreur: $e');
      return AuthResult.error('Erreur d\'inscription: $e');
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Réinitialiser le mot de passe
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult.success(null);
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getErrorMessage(e.code));
    } catch (e) {
      return AuthResult.error('Erreur: $e');
    }
  }

  /// Messages d'erreur en français
  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé';
      case 'invalid-email':
        return 'Format d\'email invalide';
      case 'operation-not-allowed':
        return 'Opération non autorisée';
      case 'weak-password':
        return 'Mot de passe trop faible (minimum 6 caractères)';
      case 'user-disabled':
        return 'Ce compte a été désactivé';
      case 'user-not-found':
        return 'Aucun compte trouvé avec cet email. Inscrivez-vous d\'abord.';
      case 'wrong-password':
        return 'Mot de passe incorrect. Vérifiez votre saisie.';
      case 'invalid-credential':
        return 'Identifiants incorrects. Vérifiez votre email et mot de passe.';
      case 'too-many-requests':
        return 'Trop de tentatives échouées. Réessayez dans quelques minutes.';
      case 'network-request-failed':
        return 'Erreur réseau. Vérifiez votre connexion Internet.';
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Email ou mot de passe incorrect. Vérifiez vos identifiants ou créez un compte.';
      default:
        return 'Erreur d\'authentification: $code';
    }
  }
}

/// Résultat d'une opération d'authentification
class AuthResult {
  final User? user;
  final String? error;
  final bool isSuccess;

  AuthResult.success(this.user)
      : error = null,
        isSuccess = true;

  AuthResult.error(this.error)
      : user = null,
        isSuccess = false;
}
