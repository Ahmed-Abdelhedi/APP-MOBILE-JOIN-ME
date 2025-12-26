import 'package:dartz/dartz.dart';
import 'package:mobile/core/errors/failures.dart';
import 'package:mobile/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<Either<Failure, User>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  });

  Future<Either<Failure, User>> signInWithGoogle();

  Future<Either<Failure, void>> signOut();

  Future<Either<Failure, void>> resetPassword(String email);

  Future<Either<Failure, User?>> getCurrentUser();

  Stream<User?> get authStateChanges;

  Future<Either<Failure, void>> updateProfile({
    String? name,
    String? photoUrl,
    String? bio,
    List<String>? interests,
    String? phoneNumber,
  });

  Future<Either<Failure, String>> uploadProfileImage(String imagePath);
}
