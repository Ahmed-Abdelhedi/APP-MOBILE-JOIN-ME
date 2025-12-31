import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/providers/firebase_providers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'notification_detail_screen.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
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

  Future<void> _markAsRead(BuildContext context, String notificationId, String userId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  Future<void> _deleteNotification(BuildContext context, String notificationId, String userId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  Future<void> _clearAllNotifications(BuildContext context, String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tout effacer'),
        content: const Text('Voulez-vous supprimer toutes les notifications ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Vous devez être connecté')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            onPressed: () => _clearAllNotifications(context, currentUser.uid),
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Tout effacer',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune notification',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vous serez notifié des événements importants',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notifDoc = notifications[index];
              final notif = notifDoc.data() as Map<String, dynamic>;
              final type = notif['type'] as String? ?? 'default';
              final title = notif['title'] as String? ?? 'Notification';
              final body = notif['body'] as String? ?? '';
              final read = notif['read'] as bool? ?? false;
              final createdAt = notif['createdAt'] as Timestamp?;
              
              String timeText = 'À l\'instant';
              if (createdAt != null) {
                final date = createdAt.toDate();
                timeText = _formatTimeAgo(date);
              }

              return Dismissible(
                key: Key(notifDoc.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => _deleteNotification(context, notifDoc.id, currentUser.uid),
                background: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: read ? Colors.white : AppColors.primary.withOpacity(0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: read ? Colors.grey.shade200 : AppColors.primary.withOpacity(0.2),
                      width: read ? 1 : 2,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      // Navigate to notification detail page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationDetailScreen(
                            notificationId: notifDoc.id,
                            userId: currentUser.uid,
                            notification: notif,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getColorForType(type).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getIconForType(type),
                              color: _getColorForType(type),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: read ? FontWeight.normal : FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    if (!read)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  body,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  timeText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: 0.2, end: 0),
              );
            },
          );
        },
      ),
    );
  }
}
