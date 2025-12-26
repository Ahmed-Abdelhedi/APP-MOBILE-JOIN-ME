class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'Server error occurred']);
}

class CacheException implements Exception {
  final String message;
  CacheException([this.message = 'Cache error occurred']);
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'No internet connection']);
}

class AuthException implements Exception {
  final String message;
  AuthException([this.message = 'Authentication failed']);
}

class ValidationException implements Exception {
  final String message;
  ValidationException([this.message = 'Validation failed']);
}

class PermissionException implements Exception {
  final String message;
  PermissionException([this.message = 'Permission denied']);
}

class FirebaseException implements Exception {
  final String message;
  FirebaseException([this.message = 'Firebase error occurred']);
}

class LocationException implements Exception {
  final String message;
  LocationException([this.message = 'Location error occurred']);
}
