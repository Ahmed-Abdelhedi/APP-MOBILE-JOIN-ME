import 'dart:ui' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/activity_model.dart';
import 'notification_preferences_service.dart';

/// Service for managing event notifications
/// - Schedules notifications for participating/interested events
/// - Configurable timing (default 30 minutes before event)
/// - Avoids duplicate notifications
/// - Works even when app is backgrounded or closed
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationPreferencesService _preferencesService = 
      NotificationPreferencesService();

  bool _initialized = false;

  /// Get current notification preferences
  NotificationPreferences get preferences => _preferencesService.preferences;

  /// Initialize notification service
  /// Call this in main.dart before runApp()
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone database
    tz.initializeTimeZones();

    // Initialize notification preferences
    await _preferencesService.initialize();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _requestPermissions();

    _initialized = true;
    print('✅ NotificationService initialized');
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    // Android 13+ requires runtime permission
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    // iOS permissions
    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    print('📱 Notification tapped with payload: $payload');
    // TODO: Navigate to event detail screen using payload (activityId)
    // This can be implemented with a global navigator key or routing service
  }

  /// Schedule notification for an event
  /// @param activityId - The event ID
  /// @param activityTitle - Event title
  /// @param eventDateTime - When the event starts
  /// @param description - Optional event description
  /// @param minutesBefore - How many minutes before event to notify (uses per-event or global preferences if not specified)
  /// @param isInterested - Whether user is "interested" (vs participating)
  Future<void> scheduleEventNotification({
    required String activityId,
    required String activityTitle,
    required DateTime eventDateTime,
    String? description,
    int? minutesBefore,
    bool isInterested = false,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    // Check if notifications are enabled
    if (!preferences.enabled) {
      print('🔕 Notifications disabled, skipping: $activityTitle');
      return;
    }

    // Check if we should notify for this type of event
    if (isInterested && !preferences.notifyForInterested) {
      print('🔕 Notifications for interested events disabled, skipping: $activityTitle');
      return;
    }
    if (!isInterested && !preferences.notifyForParticipating) {
      print('🔕 Notifications for participating events disabled, skipping: $activityTitle');
      return;
    }

    try {
      // Use provided minutesBefore, or get per-event timing, or use global default
      int notifyMinutes;
      if (minutesBefore != null) {
        notifyMinutes = minutesBefore;
        // Save this as the event's timing
        await _preferencesService.setEventTiming(activityId, minutesBefore);
      } else {
        // Get per-event timing (falls back to global if not set)
        notifyMinutes = await _preferencesService.getEventTiming(activityId);
      }
      
      // Calculate notification time
      final notificationTime = eventDateTime.subtract(
        Duration(minutes: notifyMinutes),
      );

      // Don't schedule if notification time is in the past
      if (notificationTime.isBefore(DateTime.now())) {
        print('⏰ Notification time is in the past, skipping: $activityTitle');
        return;
      }

      // Create unique notification ID based on activity ID
      final notificationId = activityId.hashCode;

      // Cancel any existing notification for this event first (to allow rescheduling)
      await _notifications.cancel(notificationId);

      // Build notification title based on type
      final notificationTitle = isInterested 
          ? '⭐ Événement qui vous intéresse !'
          : '⏰ Événement bientôt !';
      
      // Build body with description if available
      String notificationBody = '$activityTitle commence dans ${_formatMinutes(notifyMinutes)}';
      if (description != null && description.isNotEmpty) {
        notificationBody += '\n📝 $description';
      }

      // Notification details with preferences
      final androidDetails = AndroidNotificationDetails(
        'event_reminders', // channel ID
        'Event Reminders', // channel name
        channelDescription: 'Notifications for upcoming events',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: preferences.vibrationEnabled,
        playSound: preferences.soundEnabled,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF7C3AED), // Primary purple color
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(notificationBody),
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: preferences.soundEnabled,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule notification
      await _notifications.zonedSchedule(
        notificationId,
        notificationTitle,
        notificationBody,
        tz.TZDateTime.from(notificationTime, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: activityId, // Pass activity ID for navigation
      );

      // Store notification info in Firestore for tracking
      await _storeNotificationInfo(activityId, notificationTime, isInterested);

      print('✅ Notification scheduled for: $activityTitle at $notificationTime (${isInterested ? "interested" : "participating"})');
    } catch (e) {
      print('❌ Error scheduling notification: $e');
    }
  }

  /// Format minutes into human-readable string
  String _formatMinutes(int minutes) {
    if (minutes < 60) {
      return '$minutes minutes';
    } else if (minutes == 60) {
      return '1 heure';
    } else if (minutes < 1440) {
      final hours = minutes ~/ 60;
      return '$hours heures';
    } else {
      final days = minutes ~/ 1440;
      return '$days jour${days > 1 ? 's' : ''}';
    }
  }

  /// Cancel notification for an event
  /// Call this when user leaves an event
  /// @param removeEventTiming - Whether to remove the per-event timing setting (default true)
  Future<void> cancelEventNotification(String activityId, {bool removeEventTiming = true}) async {
    try {
      final notificationId = activityId.hashCode;
      await _notifications.cancel(notificationId);
      
      // Remove per-event timing if requested
      if (removeEventTiming) {
        await _preferencesService.removeEventTiming(activityId);
      }
      
      // Remove from Firestore tracking
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc(activityId)
            .delete();
      }

      print('✅ Notification cancelled for activity: $activityId');
    } catch (e) {
      print('❌ Error cancelling notification: $e');
    }
  }

  /// Cancel all pending notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('✅ All notifications cancelled');
  }

  /// Get pending notifications count
  Future<int> getPendingNotificationsCount() async {
    final pending = await _notifications.pendingNotificationRequests();
    return pending.length;
  }

  /// Schedule notifications for all user's participating and interested events
  /// Call this after user joins an event or on app startup
  Future<void> scheduleNotificationsForUserEvents() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('⚠️ User not logged in, skipping notification scheduling');
        return;
      }

      // Check if notifications are enabled
      if (!preferences.enabled) {
        print('🔕 Notifications disabled globally');
        return;
      }

      int scheduledCount = 0;

      // Get participating events if enabled
      if (preferences.notifyForParticipating) {
        final participatingEvents = await _firestore
            .collection('activities')
            .where('participants', arrayContains: userId)
            .get();

        print('📅 Found ${participatingEvents.docs.length} participating events');

        for (final doc in participatingEvents.docs) {
          final activity = ActivityModel.fromFirestore(doc.data(), doc.id);
          
          if (activity.dateTime.isAfter(DateTime.now())) {
            await scheduleEventNotification(
              activityId: activity.id,
              activityTitle: activity.title,
              eventDateTime: activity.dateTime,
              description: activity.description,
              isInterested: false,
            );
            scheduledCount++;
          }
        }
      }

      // Get interested events if enabled
      if (preferences.notifyForInterested) {
        final interestedEvents = await _firestore
            .collection('activities')
            .where('interestedUsers', arrayContains: userId)
            .get();

        print('⭐ Found ${interestedEvents.docs.length} interested events');

        for (final doc in interestedEvents.docs) {
          final activity = ActivityModel.fromFirestore(doc.data(), doc.id);
          
          if (activity.dateTime.isAfter(DateTime.now())) {
            await scheduleEventNotification(
              activityId: activity.id,
              activityTitle: activity.title,
              eventDateTime: activity.dateTime,
              description: activity.description,
              isInterested: true,
            );
            scheduledCount++;
          }
        }
      }

      print('✅ Scheduled notifications for $scheduledCount events');
    } catch (e) {
      print('❌ Error scheduling notifications for user events: $e');
    }
  }

  /// Store notification info in Firestore for tracking
  Future<void> _storeNotificationInfo(
    String activityId,
    DateTime notificationTime,
    bool isInterested,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(activityId)
          .set({
        'activityId': activityId,
        'scheduledFor': Timestamp.fromDate(notificationTime),
        'isInterested': isInterested,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('⚠️ Error storing notification info: $e');
    }
  }

  /// Show immediate notification (for testing or instant feedback)
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    const androidDetails = AndroidNotificationDetails(
      'instant_notifications',
      'Instant Notifications',
      channelDescription: 'Immediate notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Re-schedule all notifications (useful after app restart)
  Future<void> rescheduleAllNotifications() async {
    await cancelAllNotifications();
    await scheduleNotificationsForUserEvents();
  }
}
