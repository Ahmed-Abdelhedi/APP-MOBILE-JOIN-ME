import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile/core/config/supabase_config.dart';
import 'package:path/path.dart' as path;

/// Service for handling image storage with Supabase
/// 
/// This service is used ONLY for image storage.
/// The rest of the app uses Firebase (Auth, Firestore, etc.)
class SupabaseStorageService {
  static SupabaseStorageService? _instance;
  late final SupabaseClient _client;
  bool _isInitialized = false;

  SupabaseStorageService._();

  static SupabaseStorageService get instance {
    _instance ??= SupabaseStorageService._();
    return _instance!;
  }

  /// Initialize Supabase client
  /// Call this once in main.dart AFTER Firebase initialization
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    if (!SupabaseConfig.isConfigured) {
      print('⚠️ Supabase not configured. Image uploads will use Firebase Storage as fallback.');
      return;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
        debug: false,
      );
      _client = Supabase.instance.client;
      _isInitialized = true;
      print('✅ Supabase Storage initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize Supabase: $e');
      _isInitialized = false;
    }
  }

  /// Check if Supabase is ready to use
  bool get isReady => _isInitialized && SupabaseConfig.isConfigured;

  // ============================================================================
  // EVENT IMAGES
  // ============================================================================

  /// Upload an event image to Supabase Storage
  /// 
  /// [imageFile] - The image file to upload
  /// [activityId] - The activity ID for organizing the file
  /// [userId] - The user ID for the file path
  /// 
  /// Returns the public URL of the uploaded image
  Future<String> uploadEventImage({
    required File imageFile,
    required String activityId,
    required String userId,
  }) async {
    if (!isReady) {
      throw Exception('Supabase Storage not initialized. Please configure Supabase first.');
    }

    try {
      // Generate unique filename
      final String extension = path.extension(imageFile.path).toLowerCase();
      final String fileName = 'event_${activityId}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final String filePath = '$userId/$activityId/$fileName';

      // Read file bytes
      final Uint8List fileBytes = await imageFile.readAsBytes();

      // Upload to Supabase Storage
      await _client.storage
          .from(SupabaseConfig.eventImagesBucket)
          .uploadBinary(
            filePath,
            fileBytes,
            fileOptions: FileOptions(
              contentType: _getContentType(extension),
              upsert: true,
            ),
          );

      // Get public URL
      final String publicUrl = _client.storage
          .from(SupabaseConfig.eventImagesBucket)
          .getPublicUrl(filePath);

      print('✅ Event image uploaded to Supabase: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('❌ Error uploading event image to Supabase: $e');
      rethrow;
    }
  }

  /// Delete an event image from Supabase Storage
  Future<void> deleteEventImage(String imageUrl) async {
    if (!isReady) return;

    try {
      // Extract file path from URL
      final String filePath = _extractFilePath(imageUrl, SupabaseConfig.eventImagesBucket);
      if (filePath.isEmpty) return;

      await _client.storage
          .from(SupabaseConfig.eventImagesBucket)
          .remove([filePath]);

      print('✅ Event image deleted from Supabase');
    } catch (e) {
      print('❌ Error deleting event image from Supabase: $e');
    }
  }

  // ============================================================================
  // PROFILE IMAGES
  // ============================================================================

  /// Upload a profile image to Supabase Storage
  /// 
  /// [imageFile] - The image file to upload
  /// [userId] - The user ID
  /// 
  /// Returns the public URL of the uploaded image
  Future<String> uploadProfileImage({
    required File imageFile,
    required String userId,
  }) async {
    if (!isReady) {
      throw Exception('Supabase Storage not initialized. Please configure Supabase first.');
    }

    try {
      // Generate filename
      final String extension = path.extension(imageFile.path).toLowerCase();
      final String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}$extension';
      final String filePath = '$userId/$fileName';

      // Read file bytes
      final Uint8List fileBytes = await imageFile.readAsBytes();

      // Upload to Supabase Storage
      await _client.storage
          .from(SupabaseConfig.profileImagesBucket)
          .uploadBinary(
            filePath,
            fileBytes,
            fileOptions: FileOptions(
              contentType: _getContentType(extension),
              upsert: true,
            ),
          );

      // Get public URL
      final String publicUrl = _client.storage
          .from(SupabaseConfig.profileImagesBucket)
          .getPublicUrl(filePath);

      print('✅ Profile image uploaded to Supabase: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('❌ Error uploading profile image to Supabase: $e');
      rethrow;
    }
  }

  /// Delete a profile image from Supabase Storage
  Future<void> deleteProfileImage(String imageUrl) async {
    if (!isReady) return;

    try {
      // Extract file path from URL
      final String filePath = _extractFilePath(imageUrl, SupabaseConfig.profileImagesBucket);
      if (filePath.isEmpty) return;

      await _client.storage
          .from(SupabaseConfig.profileImagesBucket)
          .remove([filePath]);

      print('✅ Profile image deleted from Supabase');
    } catch (e) {
      print('❌ Error deleting profile image from Supabase: $e');
    }
  }

  /// Delete old profile images for a user (cleanup)
  Future<void> deleteOldProfileImages(String userId) async {
    if (!isReady) return;

    try {
      final List<FileObject> files = await _client.storage
          .from(SupabaseConfig.profileImagesBucket)
          .list(path: userId);

      if (files.length > 1) {
        // Keep only the most recent file
        files.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
        final filesToDelete = files.skip(1).map((f) => '$userId/${f.name}').toList();
        
        if (filesToDelete.isNotEmpty) {
          await _client.storage
              .from(SupabaseConfig.profileImagesBucket)
              .remove(filesToDelete);
          print('✅ Cleaned up ${filesToDelete.length} old profile images');
        }
      }
    } catch (e) {
      print('⚠️ Error cleaning up old profile images: $e');
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get content type from file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Extract file path from public URL
  String _extractFilePath(String url, String bucket) {
    try {
      final Uri uri = Uri.parse(url);
      final String path = uri.path;
      final String bucketPrefix = '/storage/v1/object/public/$bucket/';
      if (path.contains(bucketPrefix)) {
        return path.substring(path.indexOf(bucketPrefix) + bucketPrefix.length);
      }
      return '';
    } catch (e) {
      return '';
    }
  }
}
