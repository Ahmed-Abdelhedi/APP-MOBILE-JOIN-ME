import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/models/activity_model.dart';
import 'package:mobile/core/constants/app_colors.dart';

/// Service for sharing and exporting event information
class EventShareService {
  /// Share event information using native share sheet
  static Future<void> shareEvent(BuildContext context, ActivityModel activity) async {
    final String shareText = '''
🎉 ${activity.title}

📅 Date: ${_formatDate(activity.dateTime)}
⏰ Heure: ${_formatTime(activity.dateTime)}
📍 Lieu: ${activity.location}
👥 Participants: ${activity.currentParticipants}/${activity.maxParticipants}
${activity.cost != null && activity.cost! > 0 ? '💰 Prix: ${activity.cost!.toStringAsFixed(2)}€' : '🆓 Gratuit'}

${activity.description.isNotEmpty ? '📝 ${activity.description}' : ''}

Rejoignez-moi sur JoinMe !
''';

    // Copy to clipboard (simplest approach without additional dependencies)
    await Clipboard.setData(ClipboardData(text: shareText));
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Copié dans le presse-papiers !'),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Generate calendar event URL (Google Calendar)
  static String generateGoogleCalendarUrl(ActivityModel activity) {
    final startTime = activity.dateTime;
    final endTime = startTime.add(const Duration(hours: 2)); // Default 2 hour duration

    final formattedStart = _formatDateTimeForCalendar(startTime);
    final formattedEnd = _formatDateTimeForCalendar(endTime);

    final details = activity.description.isNotEmpty
        ? activity.description
        : 'Événement JoinMe - ${activity.category}';

    final url = Uri.encodeFull(
      'https://calendar.google.com/calendar/render'
      '?action=TEMPLATE'
      '&text=${activity.title}'
      '&dates=$formattedStart/$formattedEnd'
      '&details=$details'
      '&location=${activity.location}'
      '&sf=true'
      '&output=xml',
    );

    return url;
  }

  /// Show calendar options dialog
  static void showCalendarOptions(BuildContext context, ActivityModel activity) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              '📅 Ajouter au calendrier',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              activity.title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Copy calendar link option
            _buildOption(
              context,
              icon: Icons.link,
              color: AppColors.primary,
              title: 'Copier le lien Google Calendar',
              subtitle: 'Ouvrir dans votre navigateur',
              onTap: () async {
                final url = generateGoogleCalendarUrl(activity);
                await Clipboard.setData(ClipboardData(text: url));
                Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lien calendrier copié !'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: 12),

            // Copy event details option
            _buildOption(
              context,
              icon: Icons.copy,
              color: AppColors.secondary,
              title: 'Copier les détails',
              subtitle: 'Texte complet de l\'événement',
              onTap: () async {
                await shareEvent(context, activity);
                Navigator.pop(context);
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  /// Format date for display
  static String _formatDate(DateTime dateTime) {
    final weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    
    return '${weekdays[dateTime.weekday - 1]} ${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  /// Format time for display
  static String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Format datetime for Google Calendar URL
  static String _formatDateTimeForCalendar(DateTime dateTime) {
    return '${dateTime.year}'
        '${dateTime.month.toString().padLeft(2, '0')}'
        '${dateTime.day.toString().padLeft(2, '0')}'
        'T'
        '${dateTime.hour.toString().padLeft(2, '0')}'
        '${dateTime.minute.toString().padLeft(2, '0')}'
        '00';
  }
}
