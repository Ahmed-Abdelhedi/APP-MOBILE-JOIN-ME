import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _activityUpdates = true;
  bool _chatMessages = true;
  bool _newFollowers = false;
  bool _eventReminders = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Paramètres de notification',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ).animate().fadeIn().slideX(begin: -0.2, end: 0),
          const SizedBox(height: 16),

          _buildNotificationCard(
            'Notifications push',
            'Recevoir des notifications sur votre appareil',
            Icons.notifications_active,
            _pushNotifications,
            (value) => setState(() => _pushNotifications = value),
          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2, end: 0),

          _buildNotificationCard(
            'Notifications email',
            'Recevoir des emails pour les mises à jour importantes',
            Icons.email,
            _emailNotifications,
            (value) => setState(() => _emailNotifications = value),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0),

          const SizedBox(height: 24),
          Text(
            'Type de notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2, end: 0),
          const SizedBox(height: 16),

          _buildNotificationCard(
            'Mises à jour d\'activités',
            'Changements dans les activités auxquelles vous participez',
            Icons.event_note,
            _activityUpdates,
            (value) => setState(() => _activityUpdates = value),
          ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2, end: 0),

          _buildNotificationCard(
            'Messages de chat',
            'Nouveaux messages dans vos conversations',
            Icons.chat_bubble,
            _chatMessages,
            (value) => setState(() => _chatMessages = value),
          ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.2, end: 0),

          _buildNotificationCard(
            'Nouveaux abonnés',
            'Quelqu\'un commence à vous suivre',
            Icons.person_add,
            _newFollowers,
            (value) => setState(() => _newFollowers = value),
          ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.2, end: 0),

          _buildNotificationCard(
            'Rappels d\'événements',
            'Rappels avant le début d\'une activité',
            Icons.alarm,
            _eventReminders,
            (value) => setState(() => _eventReminders = value),
          ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.2, end: 0),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Paramètres sauvegardés'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Enregistrer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 800.ms).scale(),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
