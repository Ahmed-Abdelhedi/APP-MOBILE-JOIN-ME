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

  // Sign in with email and password
  Future<firebase_auth.User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Failed to sign in');
      }

      await _updateLastSeen(userCredential.user!.uid);

      return userCredential.user!;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Sign in failed');
    }
  }

  // Sign up with email and password
  Future<firebase_auth.User> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Failed to create account');
      }

      // Mettre à jour le displayName
      await userCredential.user!.updateDisplayName(name);

      // Créer le profil dans Firestore
      await _createUserProfile(userCredential.user!, name);

      return userCredential.user!;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Sign up failed');
    }
  }

  // Créer un nouveau profil utilisateur
  Future<void> _createUserProfile(firebase_auth.User firebaseUser, String name) async {
    await _firestore.collection('users').doc(firebaseUser.uid).set({
      'userId': firebaseUser.uid,
      'email': firebaseUser.email,
      'name': name,
      'photoUrl': null,
      'bio': null,
      'interests': [],
      'phoneNumber': null,
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
  }

  // Mettre à jour lastSeen
  Future<void> _updateLastSeen(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'lastSeen': FieldValue.serverTimestamp(),
    });
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

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Failed to send reset email');
    }
  }
}
