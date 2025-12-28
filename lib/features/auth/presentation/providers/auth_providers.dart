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

  // Sign in with Google
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

  // Sign in with Email/Password
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    
    final result = await _repository.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
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

  // Sign up with Email/Password
  Future<bool> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    state = const AsyncValue.loading();
    
    final result = await _repository.signUpWithEmailAndPassword(
      email: email,
      password: password,
      name: name,
    );
    
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

  // Sign out
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    await _repository.signOut();
    state = const AsyncValue.data(null);
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    state = const AsyncValue.loading();
    
    final result = await _repository.resetPassword(email);
    
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return false;
      },
      (_) {
        state = const AsyncValue.data(null);
        return true;
      },
    );
  }

  // Get error message
  String? get errorMessage {
    return state.when(
      data: (_) => null,
      loading: () => null,
      error: (error, _) => error.toString(),
    );
  }
}

// Provider pour le controller
final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository);
});
