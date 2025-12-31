import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Model for notification preferences
class NotificationPreferences {
  final bool enabled;
  final int minutesBefore; // 15, 30, 60, 120, 1440 (24h)
  final bool notifyForParticipating;
  final bool notifyForInterested;
  final bool soundEnabled;
  final bool vibrationEnabled;

  const NotificationPreferences({
    this.enabled = true,
    this.minutesBefore = 30,
    this.notifyForParticipating = true,
    this.notifyForInterested = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  /// Available timing options (in minutes)
  static const List<int> timingOptions = [15, 30, 60, 120, 1440];

  /// Get human-readable label for timing
  static String getTimingLabel(int minutes) {
    switch (minutes) {
      case 15:
        return '15 minutes avant';
      case 30:
        return '30 minutes avant';
      case 60:
        return '1 heure avant';
      case 120:
        return '2 heures avant';
      case 1440:
        return '1 jour avant';
      default:
        return '$minutes minutes avant';
    }
  }

  NotificationPreferences copyWith({
    bool? enabled,
    int? minutesBefore,
    bool? notifyForParticipating,
    bool? notifyForInterested,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return NotificationPreferences(
      enabled: enabled ?? this.enabled,
      minutesBefore: minutesBefore ?? this.minutesBefore,
      notifyForParticipating: notifyForParticipating ?? this.notifyForParticipating,
      notifyForInterested: notifyForInterested ?? this.notifyForInterested,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'minutesBefore': minutesBefore,
      'notifyForParticipating': notifyForParticipating,
      'notifyForInterested': notifyForInterested,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
    };
  }

  factory NotificationPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const NotificationPreferences();
    return NotificationPreferences(
      enabled: map['enabled'] ?? true,
      minutesBefore: map['minutesBefore'] ?? 30,
      notifyForParticipating: map['notifyForParticipating'] ?? true,
      notifyForInterested: map['notifyForInterested'] ?? true,
      soundEnabled: map['soundEnabled'] ?? true,
      vibrationEnabled: map['vibrationEnabled'] ?? true,
    );
  }
}

/// Service for managing notification preferences
/// Stores preferences in both local storage (for quick access) and Firebase (for sync)
class NotificationPreferencesService {
  static final NotificationPreferencesService _instance =
      NotificationPreferencesService._internal();
  factory NotificationPreferencesService() => _instance;
  NotificationPreferencesService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  NotificationPreferences _preferences = const NotificationPreferences();
  NotificationPreferences get preferences => _preferences;

  // Local storage keys
  static const String _keyEnabled = 'notification_enabled';
  static const String _keyMinutesBefore = 'notification_minutes_before';
  static const String _keyNotifyParticipating = 'notification_participating';
  static const String _keyNotifyInterested = 'notification_interested';
  static const String _keySoundEnabled = 'notification_sound';
  static const String _keyVibrationEnabled = 'notification_vibration';

  /// Initialize preferences from local storage and sync with Firebase
  Future<void> initialize() async {
    try {
      // Load from local storage first (faster)
      await _loadFromLocalStorage();

      // Then sync with Firebase if user is logged in
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _syncFromFirebase(userId);
      }

      print('✅ NotificationPreferencesService initialized');
    } catch (e) {
      print('⚠️ Error initializing notification preferences: $e');
    }
  }

  /// Load preferences from local storage
  Future<void> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _preferences = NotificationPreferences(
        enabled: prefs.getBool(_keyEnabled) ?? true,
        minutesBefore: prefs.getInt(_keyMinutesBefore) ?? 30,
        notifyForParticipating: prefs.getBool(_keyNotifyParticipating) ?? true,
        notifyForInterested: prefs.getBool(_keyNotifyInterested) ?? true,
        soundEnabled: prefs.getBool(_keySoundEnabled) ?? true,
        vibrationEnabled: prefs.getBool(_keyVibrationEnabled) ?? true,
      );
    } catch (e) {
      print('⚠️ Error loading preferences from local storage: $e');
    }
  }

  /// Sync preferences from Firebase
  Future<void> _syncFromFirebase(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('notifications')
          .get();

      if (doc.exists) {
        _preferences = NotificationPreferences.fromMap(doc.data());
        // Update local storage with Firebase data
        await _saveToLocalStorage();
      } else {
        // Save current local preferences to Firebase
        await _saveToFirebase(userId);
      }
    } catch (e) {
      print('⚠️ Error syncing from Firebase: $e');
    }
  }

  /// Save preferences to local storage
  Future<void> _saveToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyEnabled, _preferences.enabled);
      await prefs.setInt(_keyMinutesBefore, _preferences.minutesBefore);
      await prefs.setBool(_keyNotifyParticipating, _preferences.notifyForParticipating);
      await prefs.setBool(_keyNotifyInterested, _preferences.notifyForInterested);
      await prefs.setBool(_keySoundEnabled, _preferences.soundEnabled);
      await prefs.setBool(_keyVibrationEnabled, _preferences.vibrationEnabled);
    } catch (e) {
      print('⚠️ Error saving to local storage: $e');
    }
  }

  /// Save preferences to Firebase
  Future<void> _saveToFirebase(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('notifications')
          .set(_preferences.toMap());
    } catch (e) {
      print('⚠️ Error saving to Firebase: $e');
    }
  }

  /// Update preferences
  Future<void> updatePreferences(NotificationPreferences newPreferences) async {
    _preferences = newPreferences;

    // Save to local storage
    await _saveToLocalStorage();

    // Save to Firebase if logged in
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      await _saveToFirebase(userId);
    }

    print('✅ Notification preferences updated');
  }

  // ==========================================
  // PER-EVENT NOTIFICATION TIMING METHODS
  // ==========================================
  
  /// Cache for per-event notification timings
  final Map<String, int> _eventTimings = {};

  /// Get notification timing for a specific event
  /// Returns the event-specific timing, or the global default if not set
  Future<int> getEventTiming(String activityId) async {
    // Check cache first
    if (_eventTimings.containsKey(activityId)) {
      return _eventTimings[activityId]!;
    }
    
    // Try to load from local storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final timing = prefs.getInt('notification_timing_$activityId');
      if (timing != null) {
        _eventTimings[activityId] = timing;
        return timing;
      }
    } catch (e) {
      print('⚠️ Error loading event timing from local storage: $e');
    }
    
    // Try to load from Firebase
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final doc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('event_notifications')
            .doc(activityId)
            .get();
        
        if (doc.exists && doc.data()?['minutesBefore'] != null) {
          final timing = doc.data()!['minutesBefore'] as int;
          _eventTimings[activityId] = timing;
          // Also save to local storage
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('notification_timing_$activityId', timing);
          return timing;
        }
      }
    } catch (e) {
      print('⚠️ Error loading event timing from Firebase: $e');
    }
    
    // Return global default
    return _preferences.minutesBefore;
  }

  /// Set notification timing for a specific event
  Future<void> setEventTiming(String activityId, int minutesBefore) async {
    // Update cache
    _eventTimings[activityId] = minutesBefore;
    
    // Save to local storage
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notification_timing_$activityId', minutesBefore);
    } catch (e) {
      print('⚠️ Error saving event timing to local storage: $e');
    }
    
    // Save to Firebase
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('event_notifications')
            .doc(activityId)
            .set({
          'minutesBefore': minutesBefore,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('⚠️ Error saving event timing to Firebase: $e');
    }
    
    print('✅ Event timing set for $activityId: $minutesBefore minutes');
  }

  /// Remove notification timing for a specific event (when user leaves)
  Future<void> removeEventTiming(String activityId) async {
    // Remove from cache
    _eventTimings.remove(activityId);
    
    // Remove from local storage
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('notification_timing_$activityId');
    } catch (e) {
      print('⚠️ Error removing event timing from local storage: $e');
    }
    
    // Remove from Firebase
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('event_notifications')
            .doc(activityId)
            .delete();
      }
    } catch (e) {
      print('⚠️ Error removing event timing from Firebase: $e');
    }
  }

  /// Enable/disable notifications
  Future<void> setEnabled(bool enabled) async {
    await updatePreferences(_preferences.copyWith(enabled: enabled));
  }

  /// Set notification timing
  Future<void> setMinutesBefore(int minutes) async {
    await updatePreferences(_preferences.copyWith(minutesBefore: minutes));
  }

  /// Set notify for participating events
  Future<void> setNotifyForParticipating(bool notify) async {
    await updatePreferences(_preferences.copyWith(notifyForParticipating: notify));
  }

  /// Set notify for interested events
  Future<void> setNotifyForInterested(bool notify) async {
    await updatePreferences(_preferences.copyWith(notifyForInterested: notify));
  }

  /// Set sound enabled
  Future<void> setSoundEnabled(bool enabled) async {
    await updatePreferences(_preferences.copyWith(soundEnabled: enabled));
  }

  /// Set vibration enabled
  Future<void> setVibrationEnabled(bool enabled) async {
    await updatePreferences(_preferences.copyWith(vibrationEnabled: enabled));
  }
}
