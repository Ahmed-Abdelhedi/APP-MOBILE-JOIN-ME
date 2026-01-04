import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/services/activity_service.dart';
import 'package:mobile/core/services/notification_service.dart';
import 'package:mobile/core/services/notification_preferences_service.dart';
import 'package:mobile/core/services/event_share_service.dart';
import 'package:mobile/core/models/activity_model.dart';
import 'package:mobile/core/providers/firebase_providers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../../map/presentation/screens/map_screen.dart';
import '../../../profile/presentation/screens/payment_methods_screen.dart';
import '../widgets/activity_image_widget.dart';
import '../../../../shared/widgets/feedback_widget.dart';
import 'create_activity_screen.dart';

class ActivityDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> activity;

  const ActivityDetailsScreen({
    super.key,
    required this.activity,
  });

  @override
  ConsumerState<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends ConsumerState<ActivityDetailsScreen> {
  
  /// Safely get DateTime from activity map
  DateTime _getDateTime() {
    final dt = widget.activity['dateTime'];
    if (dt is DateTime) return dt;
    if (dt is Timestamp) return dt.toDate();
    return DateTime.now();
  }
  
  /// Format date string (e.g., "Lun 15 Jan 2025")
  String _getFormattedDate() {
    final dt = _getDateTime();
    final weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${weekdays[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
  
  /// Format time string
  String _getFormattedTime() {
    final dt = _getDateTime();
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
  
  /// Get coordinates for display
  String _getCoordinates() {
    final lat = widget.activity['latitude'];
    final lng = widget.activity['longitude'];
    if (lat != null && lng != null) {
      return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    }
    return 'Coordonnées non disponibles';
  }
  
  /// Get participants list safely
  List<String> _getParticipants() {
    final participants = widget.activity['participants'];
    if (participants is List) {
      return List<String>.from(participants);
    }
    return [];
  }
  
  /// Navigate to map showing event location
  void _openInMap() {
    // Extract coordinates from activity
    final latitude = widget.activity['latitude'] as double?;
    final longitude = widget.activity['longitude'] as double?;
    final title = widget.activity['title']?.toString() ?? 'Événement';
    final activityId = widget.activity['id']?.toString();
    
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => MapScreen(
          focusLatitude: latitude,
          focusLongitude: longitude,
          focusEventTitle: title,
          focusEventId: activityId,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  /// Navigate to group chat with proper back navigation
  void _openGroupChat(String activityId) {
    // Navigate directly to ConversationScreen (not ChatScreen)
    // This ensures back button returns to this Info Page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationScreen(activityId: activityId),
      ),
    );
  }

  /// Cancel/Delete event and notify all participants
  Future<void> _cancelEvent(String activityId, Map<String, dynamic> activity) async {
    // Show confirmation dialog
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 28),
            const SizedBox(width: 12),
            const Text('Annuler l\'événement'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Êtes-vous sûr de vouloir annuler cet événement ?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.notifications_active, color: Colors.red.shade400, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Tous les participants seront notifiés de l\'annulation.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cette action est irréversible.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Garder'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Annuler l\'événement'),
          ),
        ],
      ),
    );

    if (shouldCancel != true) return;

    try {
      print('🔴 Starting event cancellation...');
      
      // Get the latest event data from Firestore to ensure we have current participants
      final eventDoc = await FirebaseFirestore.instance
          .collection('activities')
          .doc(activityId)
          .get();
      
      if (!eventDoc.exists) {
        throw Exception('L\'événement n\'existe plus');
      }
      
      final eventData = eventDoc.data() as Map<String, dynamic>;
      final participants = eventData['participants'] as List<dynamic>? ?? [];
      final eventTitle = activity['title'] ?? 'Événement';
      final notificationService = NotificationService();
      
      print('🔴 Found ${participants.length} participants');
      
      // Send cancellation notification to all participants
      for (final participantId in participants) {
        // Skip the creator (they're cancelling it)
        final currentUser = ref.read(currentUserProvider);
        if (participantId == currentUser?.uid) continue;
        
        try {
          // Store notification in Firestore for each participant
          await FirebaseFirestore.instance
              .collection('users')
              .doc(participantId.toString())
              .collection('notifications')
              .add({
            'type': 'event_cancelled',
            'title': '❌ Événement annulé',
            'body': 'L\'événement "$eventTitle" a été annulé par l\'organisateur.',
            'activityId': activityId,
            'activityTitle': eventTitle,
            'createdAt': FieldValue.serverTimestamp(),
            'read': false,
          });
          print('🔴 Notification sent to $participantId');
        } catch (notifError) {
          print('⚠️ Failed to notify $participantId: $notifError');
        }
      }
      
      // Cancel all scheduled notifications for this event
      try {
        await notificationService.cancelEventNotification(activityId);
        print('🔴 Cancelled scheduled notifications');
      } catch (e) {
        print('⚠️ Failed to cancel notifications: $e');
      }
      
      // Delete chat messages associated with this event
      try {
        final chatMessages = await FirebaseFirestore.instance
            .collection('activities')
            .doc(activityId)
            .collection('messages')
            .get();
        
        print('🔴 Found ${chatMessages.docs.length} chat messages to delete');
        
        for (final doc in chatMessages.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        print('⚠️ Failed to delete chat messages: $e');
      }
      
      // Delete the event from Firestore
      print('🔴 Deleting event document...');
      await FirebaseFirestore.instance
          .collection('activities')
          .doc(activityId)
          .delete();
      
      print('✅ Event deleted successfully');
      
      if (mounted) {
        FeedbackWidget.showInfo(
          context,
          message: 'Événement annulé',
          subtitle: '${participants.length > 1 ? participants.length - 1 : 0} participant(s) notifié(s)',
        );
        
        // Go back to home
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('❌ Error cancelling event: $e');
      if (mounted) {
        FeedbackWidget.showError(
          context,
          message: 'Erreur lors de l\'annulation',
          subtitle: e.toString(),
        );
      }
    }
  }

  /// Build the "Interested" button with real-time Firebase state
  Widget _buildInterestedButton(String activityId, Map<String, dynamic> activity) {
    final activityService = ref.read(activityServiceProvider);
    final notificationService = NotificationService();

    return StreamBuilder<bool>(
      stream: activityService.isInterestedStream(activityId),
      builder: (context, snapshot) {
        final isInterested = snapshot.data ?? false;

        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () async {
                try {
                  if (isInterested) {
                    // Remove interest
                    await activityService.removeInterested(activityId);
                    await notificationService.cancelEventNotification(activityId);
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('⭐ Intérêt retiré'),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  } else {
                    // Mark interested
                    await activityService.markInterested(activityId);
                    
                    // Schedule notification
                    final eventDateTime = activity['dateTime'] is DateTime
                        ? activity['dateTime'] as DateTime
                        : (activity['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now();
                    
                    await notificationService.scheduleEventNotification(
                      activityId: activityId,
                      activityTitle: activity['title'] ?? 'Activité',
                      eventDateTime: eventDateTime,
                      description: activity['description'],
                      isInterested: true,
                    );
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.star, color: Colors.white),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Ajouté aux intérêts!\nVous serez notifié ${notificationService.preferences.minutesBefore} min avant',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.amber.shade700,
                          duration: const Duration(seconds: 3),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: Icon(
                isInterested ? Icons.star : Icons.star_border,
                color: isInterested ? Colors.amber.shade700 : Colors.grey[600],
              ),
              label: Text(
                isInterested ? 'Intéressé ✓' : 'Ça m\'intéresse',
                style: TextStyle(
                  color: isInterested ? Colors.amber.shade700 : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: isInterested ? Colors.amber.withOpacity(0.1) : null,
                side: BorderSide(
                  color: isInterested ? Colors.amber.shade600 : Colors.grey.shade400,
                  width: isInterested ? 2 : 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
        );
      },
    );
  }

  /// Build notification settings button for joined users
  /// Shows the per-event timing, loading it asynchronously
  Widget _buildNotificationSettingsButton(String activityId, Map<String, dynamic> activity) {
    final preferencesService = NotificationPreferencesService();
    
    return FutureBuilder<int>(
      future: preferencesService.getEventTiming(activityId),
      builder: (context, snapshot) {
        final eventTiming = snapshot.data ?? preferencesService.preferences.minutesBefore;
        
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () => _showNotificationSettingsDialog(activityId, activity),
            icon: const Icon(Icons.notifications_active, size: 22),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Rappel'),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    NotificationPreferences.getTimingLabel(eventTiming),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
      },
    );
  }

  /// Show notification settings dialog for this specific event
  void _showNotificationSettingsDialog(String activityId, Map<String, dynamic> activity) async {
    final preferencesService = NotificationPreferencesService();
    final notificationService = NotificationService();
    
    // Get the current timing for THIS event
    int selectedMinutes = await preferencesService.getEventTiming(activityId);
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.notifications, color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Rappel pour cet événement',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show event name
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          activity['title'] ?? 'Événement',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Quand souhaitez-vous être notifié ?',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                ...NotificationPreferences.timingOptions.map((minutes) {
                  return RadioListTile<int>(
                    title: Text(NotificationPreferences.getTimingLabel(minutes)),
                    value: minutes,
                    groupValue: selectedMinutes,
                    activeColor: AppColors.primary,
                    dense: true,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedMinutes = value!;
                      });
                    },
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                
                // Save per-event timing (NOT global preferences)
                await preferencesService.setEventTiming(activityId, selectedMinutes);
                
                // Reschedule notification with new timing for THIS event
                final eventDateTime = activity['dateTime'] is DateTime
                    ? activity['dateTime'] as DateTime
                    : (activity['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now();
                
                // Cancel old notification and schedule new one with specific timing
                await notificationService.cancelEventNotification(activityId, removeEventTiming: false);
                await notificationService.scheduleEventNotification(
                  activityId: activityId,
                  activityTitle: activity['title'] ?? 'Activité',
                  eventDateTime: eventDateTime,
                  description: activity['description'],
                  minutesBefore: selectedMinutes,
                );
                
                if (mounted) {
                  setState(() {}); // Refresh the button label
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Rappel mis à jour: ${NotificationPreferences.getTimingLabel(selectedMinutes)}',
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('Confirmer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activity = widget.activity;
    final activityId = activity['id'] as String?;
    
    // Check if event is in the past
    final eventDateTime = _getDateTime();
    final isPastEvent = eventDateTime.isBefore(DateTime.now());
    
    // Check if current user is the creator
    final currentUser = ref.watch(currentUserProvider);
    final creatorId = activity['creatorId'] as String?;
    final isCreator = currentUser != null && creatorId != null && creatorId == currentUser.uid;
    
    // Debug print
    print('🔍 DEBUG: currentUser=${currentUser?.uid}, creatorId=$creatorId, isCreator=$isCreator');

    if (activityId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: const Center(
          child: Text('ID d\'activité manquant'),
        ),
      );
    }

    return Scaffold(
      body: StreamBuilder<bool>(
        stream: ref.read(activityServiceProvider).hasJoinedStream(activityId),
        builder: (context, snapshot) {
          final isJoined = snapshot.data ?? false;
          
          return CustomScrollView(
        slivers: [
          // Hero App Bar with Real Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            // Action buttons in app bar
            actions: [
              // Share button
              IconButton(
                onPressed: () => _shareEvent(),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share, color: Colors.white, size: 20),
                ),
                tooltip: 'Partager',
              ),
              // Calendar button
              IconButton(
                onPressed: () => _addToCalendar(),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.calendar_month, color: Colors.white, size: 20),
                ),
                tooltip: 'Ajouter au calendrier',
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'activity_${activity['title']}',
                    child: ActivityImageWidget(
                      imageUrl: activity['imageUrl'] as String?,
                      imageAssetPath: activity['imageAssetPath'] as String?,
                      width: double.infinity,
                      height: 350,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Enhanced Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: const [0.0, 0.4, 0.7, 1.0],
                      ),
                    ),
                  ),
                  // Title and category overlay at bottom
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            activity['category']?.toString() ?? 'Autre',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Event Title
                        Text(
                          activity['title']?.toString() ?? 'Sans titre',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 2)),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Status badge (if joined)
                  if (isJoined)
                    Positioned(
                      top: 100,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 8),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('Inscrit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ).animate().fadeIn(delay: 300.ms).scale(),
                    ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Info Cards - Date & Time
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          Icons.calendar_today,
                          'Date',
                          _getFormattedDate(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          Icons.access_time,
                          'Heure',
                          _getFormattedTime(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 4️⃣ LOCATION SECTION with coordinates and map button
                  _buildLocationCard(
                    activity['location']?.toString() ?? 'Non spécifié',
                    _getCoordinates(),
                  ),

                  const SizedBox(height: 12),

                  // Participants & Price with real-time participant count
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('activities')
                        .doc(activityId)
                        .snapshots(),
                    builder: (context, activitySnapshot) {
                      // Get real-time participant count
                      int currentParticipants = activity['currentParticipants'] ?? 0;
                      if (activitySnapshot.hasData && activitySnapshot.data!.exists) {
                        final data = activitySnapshot.data!.data() as Map<String, dynamic>?;
                        if (data != null) {
                          // Try to get from participants array length or currentParticipants field
                          if (data['participants'] is List) {
                            currentParticipants = (data['participants'] as List).length;
                          } else if (data['currentParticipants'] != null) {
                            currentParticipants = data['currentParticipants'] as int;
                          }
                        }
                      }
                      
                      final maxParticipants = activity['maxParticipants'] ?? 0;
                      final isFull = currentParticipants >= maxParticipants;
                      
                      return Row(
                        children: [
                          Expanded(
                            child: _buildInfoCard(
                              Icons.people,
                              'Participants',
                              '$currentParticipants/$maxParticipants',
                              highlight: isFull,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInfoCard(
                              Icons.euro,
                              'Prix',
                              (activity['cost'] != null && activity['cost'] > 0) 
                                  ? '${activity['cost'].toStringAsFixed(2)}€'
                                  : 'Gratuit',
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Description Section
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Rejoignez-nous pour une super activité ! C\'est l\'occasion parfaite de rencontrer de nouvelles personnes et de passer un bon moment ensemble. Tous les niveaux sont les bienvenus !',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Organizer Section - Real Firebase data
                  _buildSectionTitle('Organisateur'),
                  const SizedBox(height: 12),
                  _buildOrganizerCard(activity),

                  const SizedBox(height: 24),

                  // 2️⃣ Participants Section - Real Firebase data with real-time updates
                  _buildSectionTitle('Participants'),
                  const SizedBox(height: 12),
                  _buildParticipantsSection(activityId),

                  const SizedBox(height: 32),

                  // ⏰ PAST EVENT BANNER
                  if (isPastEvent)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.history, color: Colors.grey.shade700, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Événement terminé',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                Text(
                                  'Cet événement a déjà eu lieu',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Join/Leave/Cancel Button - Only show for future events
                  if (!isPastEvent && isCreator) ...[
                    // Creator sees Edit and Cancel buttons
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreateActivityScreen(
                                      activityId: activityId,
                                      activity: activity,
                                    ),
                                  ),
                                );
                                // Refresh if activity was updated
                                if (result == true && mounted) {
                                  Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text(
                                    'Modifier',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                print('🔴 CANCEL BUTTON PRESSED');
                                _cancelEvent(activityId, activity);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cancel_outlined),
                                  SizedBox(width: 8),
                                  Text(
                                    'Annuler',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Join/Leave Button for non-creators - Only show for future events
                  if (!isPastEvent && !isCreator)
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('activities')
                          .doc(activityId)
                          .snapshots(),
                      builder: (context, activitySnapshot) {
                        // Get real-time participant count for isFull check
                        int currentParticipants = activity['currentParticipants'] ?? 0;
                        if (activitySnapshot.hasData && activitySnapshot.data!.exists) {
                          final data = activitySnapshot.data!.data() as Map<String, dynamic>?;
                          if (data != null) {
                            if (data['participants'] is List) {
                              currentParticipants = (data['participants'] as List).length;
                            } else if (data['currentParticipants'] != null) {
                              currentParticipants = data['currentParticipants'] as int;
                            }
                          }
                        }
                        
                        final maxParticipants = activity['maxParticipants'] ?? 0;
                        final isFull = currentParticipants >= maxParticipants;
                        
                        return SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isFull && !isJoined
                                ? null
                                : () async {
                                    // Check if payment is required
                                    final cost = activity['cost'];
                                    final hasCost = cost != null && cost > 0;
                                        
                                        if (hasCost && !isJoined) {
                                          // Show payment confirmation dialog
                                          final shouldProceed = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Row(
                                                children: [
                                                  Icon(Icons.payment, color: AppColors.primary),
                                                  const SizedBox(width: 8),
                                                  const Text('Paiement requis'),
                                                ],
                                              ),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Cette activité nécessite un paiement:',
                                                    style: TextStyle(fontWeight: FontWeight.w500),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Container(
                                                    padding: const EdgeInsets.all(16),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            activity['title'] ?? 'Activité',
                                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        Text(
                                                          '${cost.toStringAsFixed(2)}€',
                                                          style: TextStyle(
                                                            fontSize: 20,
                                                            fontWeight: FontWeight.bold,
                                                            color: AppColors.primary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  const Text(
                                                    'Souhaitez-vous procéder au paiement?',
                                                    style: TextStyle(fontSize: 14),
                                                  ),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(false),
                                                  child: const Text('Annuler'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () => Navigator.of(context).pop(true),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppColors.primary,
                                                    foregroundColor: Colors.white,
                                                  ),
                                                  child: const Text('Continuer'),
                                                ),
                                              ],
                                            ),
                                          );
                                          
                                          if (shouldProceed != true) return;
                                          
                                          // Navigate to payment screen
                                          if (mounted) {
                                            final paymentSuccess = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => PaymentMethodsScreen(
                                                  paymentAmount: cost.toDouble(),
                                                  activityTitle: activity['title'],
                                                ),
                                              ),
                                            );
                                            
                                            if (paymentSuccess != true) return;
                                          }
                                        }
                                        
                                        try {
                                          final activityService = ref.read(activityServiceProvider);
                                          final notificationService = NotificationService();
                                          
                                          if (isJoined) {
                                            // Leave activity
                                            await activityService.leaveActivity(activityId);
                                            // Cancel notification
                                            await notificationService.cancelEventNotification(activityId);
                                            
                                            if (mounted) {
                                              FeedbackWidget.showInfo(
                                                context,
                                                message: 'Vous avez quitté l\'activité',
                                                subtitle: 'Votre notification a été annulée',
                                              );
                                            }
                                          } else {
                                            // Join activity
                                            await activityService.joinActivity(activityId);
                                            
                                            // Schedule notification
                                            final eventDateTime = activity['dateTime'] is DateTime
                                                ? activity['dateTime'] as DateTime
                                                : (activity['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now();
                                            
                                            await notificationService.scheduleEventNotification(
                                              activityId: activityId,
                                              activityTitle: activity['title'] ?? 'Activité',
                                              eventDateTime: eventDateTime,
                                              description: activity['description'],
                                            );
                                            
                                            if (mounted) {
                                              // Show success with confetti
                                              FeedbackWidget.showSuccess(
                                                context,
                                                message: '🎉 Vous avez rejoint !',
                                                subtitle: 'Notification programmée',
                                                showConfetti: true,
                                                duration: const Duration(seconds: 3),
                                              );
                                            }
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            // Show error with details
                                            String errorMessage = 'Une erreur est survenue';
                                            if (e.toString().contains('full')) {
                                              errorMessage = 'L\'événement est complet';
                                            } else if (e.toString().contains('network')) {
                                              errorMessage = 'Problème de connexion';
                                            } else if (e.toString().contains('already')) {
                                              errorMessage = 'Vous avez déjà rejoint';
                                            }
                                            
                                            FeedbackWidget.showError(
                                              context,
                                              message: errorMessage,
                                              subtitle: 'Veuillez réessayer',
                                            );
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isJoined
                                      ? Colors.red
                                      : isFull
                                          ? Colors.grey
                                          : AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isJoined
                                          ? Icons.exit_to_app
                                          : isFull
                                              ? Icons.block
                                              : (activity['cost'] != null && activity['cost'] > 0)
                                                  ? Icons.payment
                                                  : Icons.check_circle_outline,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isJoined
                                          ? 'Quitter l\'activité'
                                          : isFull
                                              ? 'Complet'
                                              : (activity['cost'] != null && activity['cost'] > 0)
                                                  ? 'Payer et rejoindre (${activity['cost'].toStringAsFixed(2)}€)'
                                                  : 'Rejoindre l\'activité',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                  // 3️⃣ Chat Group Button - Returns to this page on back (only for joined users on non-past events)
                  if (isJoined && !isPastEvent) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () => _openGroupChat(activityId),
                        icon: const Icon(Icons.chat_bubble),
                        label: const Text('Accéder au Chat Groupe'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          side: BorderSide(color: AppColors.secondary, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                    
                    // 🔔 Notification Settings Button
                    const SizedBox(height: 12),
                    _buildNotificationSettingsButton(activityId, activity),
                  ],

                  // ⭐ INTERESTED BUTTON - For users who haven't joined but want to be notified (only for future events)
                  if (!isJoined && !isPastEvent)
                    _buildInterestedButton(activityId, activity),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
          );
        },
      ),
    );
  }

  /// Convert activity map to ActivityModel for sharing
  ActivityModel _getActivityModel() {
    final activity = widget.activity;
    return ActivityModel(
      id: activity['id'] ?? '',
      title: activity['title'] ?? '',
      description: activity['description'] ?? '',
      category: activity['category'] ?? '',
      location: activity['location'] ?? '',
      latitude: (activity['latitude'] ?? 0.0).toDouble(),
      longitude: (activity['longitude'] ?? 0.0).toDouble(),
      dateTime: activity['dateTime'] is DateTime
          ? activity['dateTime'] as DateTime
          : (activity['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      maxParticipants: activity['maxParticipants'] ?? 0,
      currentParticipants: activity['currentParticipants'] ?? 0,
      cost: activity['cost']?.toDouble(),
      imageUrl: activity['imageUrl'],
      imageAssetPath: activity['imageAssetPath'],
      creatorId: activity['creatorId'] ?? '',
      creatorName: activity['creatorName'] ?? '',
      participants: List<String>.from(activity['participants'] ?? []),
      createdAt: activity['createdAt'] is DateTime
          ? activity['createdAt'] as DateTime
          : (activity['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: ActivityStatus.upcoming,
    );
  }

  /// Share event
  void _shareEvent() {
    final activityModel = _getActivityModel();
    EventShareService.shareEvent(context, activityModel);
  }

  /// Add to calendar
  void _addToCalendar() {
    final activityModel = _getActivityModel();
    EventShareService.showCalendarOptions(context, activityModel);
  }

  Widget _buildInfoCard(IconData icon, String label, String value, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: highlight 
            ? [Colors.red.shade50, Colors.red.shade100]
            : [Colors.white, AppColors.primary.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? Colors.red.withOpacity(0.3) : AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: highlight ? Colors.red.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: highlight 
                ? LinearGradient(colors: [Colors.red.shade400, Colors.red.shade600])
                : AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: highlight ? Colors.red.shade700 : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: highlight ? Colors.red.shade700 : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (highlight) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'COMPLET',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(delay: 100.ms, duration: 300.ms);
  }

  /// Section title with accent bar
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  /// 4️⃣ Location card with place name, coordinates and map button
  Widget _buildLocationCard(String location, String coordinates) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.red.withOpacity(0.03)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.red.shade600],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_on, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lieu',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      location,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      coordinates,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 5️⃣ MAP NAVIGATION BUTTON
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openInMap,
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('Voir sur la carte'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                side: BorderSide(color: Colors.red.shade300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.05);
  }

  /// Organizer card with real Firebase data
  Widget _buildOrganizerCard(Map<String, dynamic> activity) {
    final creatorId = activity['creatorId'] as String?;
    final creatorName = activity['creatorName']?.toString() ?? 'Organisateur';

    return StreamBuilder<DocumentSnapshot>(
      stream: creatorId != null
          ? FirebaseFirestore.instance.collection('users').doc(creatorId).snapshots()
          : null,
      builder: (context, snapshot) {
        String name = creatorName;
        String? photoUrl;
        String initials = 'O';

        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          name = userData?['name'] ?? creatorName;
          photoUrl = userData?['photoUrl'];
          initials = name.isNotEmpty ? name[0].toUpperCase() : 'O';
        } else {
          initials = creatorName.isNotEmpty ? creatorName[0].toUpperCase() : 'O';
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5)),
            ],
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: photoUrl != null
                      ? (photoUrl.startsWith('assets/')
                          ? AssetImage(photoUrl)
                          : NetworkImage(photoUrl)) as ImageProvider
                      : null,
                  child: photoUrl == null
                      ? Text(initials, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20))
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.verified, size: 14, color: Colors.blue.shade400),
                        const SizedBox(width: 4),
                        Text('Organisateur', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.chat_bubble_outline, color: AppColors.secondary, size: 20),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Messagerie privée - En développement'), behavior: SnackBarBehavior.floating),
                  );
                },
              ),
            ],
          ),
        ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.05);
      },
    );
  }

  /// 2️⃣ Participants section with real Firebase data and real-time updates
  Widget _buildParticipantsSection(String activityId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('activities').doc(activityId).snapshots(),
      builder: (context, activitySnapshot) {
        if (activitySnapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15)],
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!activitySnapshot.hasData || !activitySnapshot.data!.exists) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: Text('Aucun participant', style: TextStyle(color: Colors.grey[600]))),
          );
        }

        final activityData = activitySnapshot.data!.data() as Map<String, dynamic>;
        final participantIds = List<String>.from(activityData['participants'] ?? []);

        if (participantIds.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15)],
            ),
            child: Column(
              children: [
                Icon(Icons.people_outline, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text('Aucun participant pour le moment', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 8),
                Text('Soyez le premier à rejoindre !', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${participantIds.length} participant${participantIds.length > 1 ? 's' : ''}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  if (participantIds.length > 5)
                    Text('Voir tous >', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: participantIds.length > 10 ? 10 : participantIds.length,
                  itemBuilder: (context, index) => _buildParticipantAvatar(participantIds[index], index),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms);
      },
    );
  }

  /// Build individual participant avatar with Firebase user data
  Widget _buildParticipantAvatar(String participantId, int index) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(participantId).snapshots(),
      builder: (context, snapshot) {
        String name = 'Utilisateur';
        String? photoUrl;
        String? email;
        String? description;

        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          name = userData?['name'] ?? 'Utilisateur';
          photoUrl = userData?['photoUrl'];
          email = userData?['email'];
          description = userData?['description'] ?? userData?['bio'];
        }

        final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';
        final colors = [AppColors.primary, AppColors.secondary, AppColors.accent, Colors.orange, Colors.teal];
        final bgColor = colors[index % colors.length];

        return Padding(
          padding: const EdgeInsets.only(right: 14),
          child: GestureDetector(
            onTap: () => _showParticipantProfile(
              name: name,
              email: email,
              photoUrl: photoUrl,
              description: description,
              bgColor: bgColor,
            ),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: bgColor.withOpacity(0.3), width: 2),
                    boxShadow: [BoxShadow(color: bgColor.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: bgColor.withOpacity(0.1),
                    backgroundImage: photoUrl != null
                        ? (photoUrl.startsWith('assets/')
                            ? AssetImage(photoUrl)
                            : NetworkImage(photoUrl)) as ImageProvider
                        : null,
                    child: photoUrl == null
                        ? Text(initials, style: TextStyle(color: bgColor, fontWeight: FontWeight.bold, fontSize: 16))
                        : null,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 56,
                  child: Text(
                    name.split(' ').first,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: 80 * index)).fadeIn().scale();
      },
    );
  }

  /// Show participant profile popup
  void _showParticipantProfile({
    required String name,
    String? email,
    String? photoUrl,
    String? description,
    required Color bgColor,
  }) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Profile photo
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: bgColor.withOpacity(0.3), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: bgColor.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: bgColor.withOpacity(0.1),
                backgroundImage: photoUrl != null
                    ? (photoUrl.startsWith('assets/')
                        ? AssetImage(photoUrl)
                        : NetworkImage(photoUrl)) as ImageProvider
                    : null,
                child: photoUrl == null
                    ? Text(
                        initials,
                        style: TextStyle(
                          color: bgColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 36,
                        ),
                      )
                    : null,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Name
            Text(
              name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Email
            if (email != null && email.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.email_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            
            const SizedBox(height: 16),
            
            // Description/Bio
            if (description != null && description.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: bgColor),
                        const SizedBox(width: 6),
                        Text(
                          'À propos',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: bgColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_outline, size: 18, color: Colors.grey[400]),
                    const SizedBox(width: 8),
                    Text(
                      'Aucune description',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Close button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bgColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Fermer',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
}
