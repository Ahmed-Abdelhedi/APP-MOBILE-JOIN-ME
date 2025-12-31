import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../activities/presentation/screens/activity_details_screen.dart';

class NotificationDetailScreen extends ConsumerWidget {
  final String notificationId;
  final String userId;
  final Map<String, dynamic> notification;

  const NotificationDetailScreen({
    super.key,
    required this.notificationId,
    required this.userId,
    required this.notification,
  });

  String _formatDateTime(DateTime date) {
    return DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR').format(date);
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'event_cancelled':
        return Icons.cancel;
      case 'event_reminder':
        return Icons.notifications_active;
      case 'event_joined':
        return Icons.person_add;
      case 'event_left':
        return Icons.person_remove;
      case 'event_updated':
        return Icons.edit;
      case 'chat_message':
        return Icons.chat_bubble;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'event_cancelled':
        return Colors.red;
      case 'event_reminder':
        return Colors.orange;
      case 'event_joined':
        return Colors.green;
      case 'event_left':
        return Colors.orange.shade700;
      case 'event_updated':
        return Colors.blue;
      case 'chat_message':
        return Colors.blue;
      default:
        return AppColors.primary;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'event_cancelled':
        return 'Événement annulé';
      case 'event_reminder':
        return 'Rappel';
      case 'event_joined':
        return 'Nouveau participant';
      case 'event_left':
        return 'Participant parti';
      case 'event_updated':
        return 'Événement modifié';
      case 'chat_message':
        return 'Nouveau message';
      default:
        return 'Notification';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = notification['type'] as String? ?? 'default';
    final title = notification['title'] as String? ?? 'Notification';
    final body = notification['body'] as String? ?? '';
    final read = notification['read'] as bool? ?? false;
    final createdAt = notification['createdAt'] as Timestamp?;
    final activityId = notification['activityId'] as String?;
    final activityTitle = notification['activityTitle'] as String?;
    final participantName = notification['participantName'] as String?;

    String dateText = 'Maintenant';
    if (createdAt != null) {
      final date = createdAt.toDate();
      dateText = _formatDateTime(date);
    }

    // Mark as read when opening
    if (!read) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Détails de la notification'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Supprimer'),
                  content: const Text('Voulez-vous supprimer cette notification ?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Supprimer'),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .collection('notifications')
                    .doc(notificationId)
                    .delete();
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with icon and type
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _getColorForType(type).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconForType(type),
                      color: _getColorForType(type),
                      size: 48,
                    ),
                  ).animate().scale(duration: 300.ms),
                  const SizedBox(height: 16),
                  Text(
                    _getTypeLabel(type),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _getColorForType(type),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        dateText,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 16),

            // Body message
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Message',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

            // Additional details
            if (activityTitle != null || participantName != null) ...[
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Détails',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (activityTitle != null) ...[
                      Row(
                        children: [
                          Icon(Icons.event, size: 20, color: Colors.grey.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Événement',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  activityTitle,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (participantName != null) ...[
                      if (activityTitle != null) const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.person, size: 20, color: Colors.grey.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Participant',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  participantName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
            ],

            // Action button to view event
            if (activityId != null && type != 'event_cancelled') ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Fetch the activity data from Firestore
                    try {
                      final activityDoc = await FirebaseFirestore.instance
                          .collection('activities')
                          .doc(activityId)
                          .get();
                      
                      if (activityDoc.exists && context.mounted) {
                        final activityData = activityDoc.data() as Map<String, dynamic>;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ActivityDetailsScreen(activity: activityData),
                          ),
                        );
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Événement introuvable')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('Voir l\'événement'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
