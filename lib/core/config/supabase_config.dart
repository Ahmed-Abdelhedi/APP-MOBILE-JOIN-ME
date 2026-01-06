/// Supabase Configuration
/// 
/// This file contains the Supabase configuration for image storage only.
/// The rest of the app (Auth, Database, etc.) uses Firebase.
/// 
/// IMPORTANT: Replace these values with your Supabase project credentials
/// from https://supabase.com/dashboard/project/YOUR_PROJECT/settings/api
class SupabaseConfig {
  // ============================================================================
  // ✅ SUPABASE CREDENTIALS CONFIGURED
  // ============================================================================
  
  /// Your Supabase project URL
  static const String supabaseUrl = 'https://skyioniggjiozphwzuvb.supabase.co';
  
  /// Your Supabase anon (public) key
  /// This is the public key, safe to include in client apps
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNreWlvbmlnZ2ppb3pwaHd6dXZiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc3MTk2OTEsImV4cCI6MjA4MzI5NTY5MX0.KfYrfubI0RpyxYWFwyOqUrmUwrZPu03O7CjyYUIzgfA';
  
  // ============================================================================
  // Storage Bucket Names (must match what you created in Supabase Dashboard)
  // ============================================================================
  
  /// Bucket for event/activity images
  static const String eventImagesBucket = 'event-images';
  
  /// Bucket for profile pictures
  static const String profileImagesBucket = 'profile-images';
  
  // ============================================================================
  // Helper Methods
  // ============================================================================
  
  /// Check if Supabase is configured
  static bool get isConfigured => 
      supabaseUrl != 'YOUR_SUPABASE_URL' && 
      supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY';
  
  /// Get public URL for an event image
  static String getEventImageUrl(String fileName) {
    return '$supabaseUrl/storage/v1/object/public/$eventImagesBucket/$fileName';
  }
  
  /// Get public URL for a profile image
  static String getProfileImageUrl(String fileName) {
    return '$supabaseUrl/storage/v1/object/public/$profileImagesBucket/$fileName';
  }
}
