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
      return Left(ServerFailure(e.message ?? 'Google sign-in failed'));
    } catch (e) {
      return Left(ServerFailure('An error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final firebaseUser = await dataSource.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = _mapFirebaseUserToUser(firebaseUser);
      return Right(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(ServerFailure(e.message ?? 'Sign in failed'));
    } catch (e) {
      return Left(ServerFailure('An error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final firebaseUser = await dataSource.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
      );
      final user = _mapFirebaseUserToUser(firebaseUser);
      return Right(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(ServerFailure(e.message ?? 'Sign up failed'));
    } catch (e) {
      return Left(ServerFailure('An error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await dataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Sign out failed: $e'));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final firebaseUser = dataSource.getCurrentUser();
      if (firebaseUser == null) return const Right(null);
      return Right(_mapFirebaseUserToUser(firebaseUser));
    } catch (e) {
      return Left(ServerFailure('Failed to get current user: $e'));
    }
  }

  @override
  Stream<User?> get authStateChanges {
    return dataSource.authStateChanges.map((firebaseUser) {
      if (firebaseUser == null) return null;
      return _mapFirebaseUserToUser(firebaseUser);
    });
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await dataSource.resetPassword(email);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to reset password: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateProfile({
    String? name,
    String? photoUrl,
    String? bio,
    List<String>? interests,
    String? phoneNumber,
  }) async {
    // TODO: Implémenter la mise à jour du profil
    return Left(ServerFailure('Not implemented yet'));
  }

  @override
  Future<Either<Failure, String>> uploadProfileImage(String imagePath) async {
    // TODO: Implémenter l'upload d'image
    return Left(ServerFailure('Not implemented yet'));
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
}
