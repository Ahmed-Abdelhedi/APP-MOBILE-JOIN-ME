import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/providers/theme_provider.dart';
import 'package:mobile/core/providers/language_provider.dart';
import 'package:mobile/core/services/notification_service.dart';
import 'package:mobile/core/services/notification_preferences_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _soundEffects = true;
  bool _vibration = true;
  
  // Notification preferences
  final NotificationPreferencesService _notifPrefs = NotificationPreferencesService();
  final NotificationService _notifService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    await _notifPrefs.initialize();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = ref.read(themeProvider.notifier);
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    final loc = ref.watch(localizationProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(loc.appearance),
          _buildSettingCard(
            loc.darkMode,
            loc.enableDarkTheme,
            Icons.dark_mode,
            trailing: Switch(
              value: isDarkMode,
              onChanged: (value) {
                themeNotifier.setTheme(value);
              },
              activeThumbColor: AppColors.primary,
            ),
          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2, end: 0),

          const SizedBox(height: 24),
          _buildSection(loc.language),
          _buildSettingCard(
            loc.appLanguage,
            ref.watch(languageProvider.notifier).currentLanguageName,
            Icons.language,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(),
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0),

          const SizedBox(height: 24),
          _buildSection('🔔 Notifications'),
          _buildNotificationSettings(),

          const SizedBox(height: 24),
          _buildSection('Sons et Vibrations'),
          _buildSettingCard(
            'Effets sonores',
            'Activer les sons de l\'application',
            Icons.volume_up,
            trailing: Switch(
              value: _soundEffects,
              onChanged: (value) => setState(() => _soundEffects = value),
              activeThumbColor: AppColors.primary,
            ),
          ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2, end: 0),

          _buildSettingCard(
            'Vibration',
            'Activer les vibrations',
            Icons.vibration,
            trailing: Switch(
              value: _vibration,
              onChanged: (value) => setState(() => _vibration = value),
              activeThumbColor: AppColors.primary,
            ),
          ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2, end: 0),

          const SizedBox(height: 24),
          _buildSection('Confidentialité'),
          _buildSettingCard(
            'Confidentialité',
            'Gérer vos données personnelles',
            Icons.privacy_tip,
            trailing: const Icon(Icons.chevron_right),
          ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.2, end: 0),

          _buildSettingCard(
            'Conditions d\'utilisation',
            'Lire les conditions',
            Icons.description,
            trailing: const Icon(Icons.chevron_right),
          ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.2, end: 0),

          const SizedBox(height: 24),
          _buildSection('Stockage'),
          _buildSettingCard(
            'Vider le cache',
            'Libérer de l\'espace de stockage',
            Icons.delete_outline,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showClearCacheDialog(),
          ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSettingCard(
    String title,
    String subtitle,
    IconData icon, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: trailing,
      ),
    );
  }

  /// Build notification settings section
  Widget _buildNotificationSettings() {
    final prefs = _notifPrefs.preferences;
    
    return Column(
      children: [
        // Master toggle
        _buildSettingCard(
          'Notifications activées',
          prefs.enabled ? 'Recevoir des rappels d\'événements' : 'Notifications désactivées',
          Icons.notifications_active,
          trailing: Switch(
            value: prefs.enabled,
            onChanged: (value) async {
              await _notifPrefs.setEnabled(value);
              if (value) {
                await _notifService.rescheduleAllNotifications();
              } else {
                await _notifService.cancelAllNotifications();
              }
              setState(() {});
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value 
                        ? '🔔 Notifications activées' 
                        : '🔕 Notifications désactivées'),
                    backgroundColor: value ? Colors.green : Colors.orange,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            activeThumbColor: AppColors.primary,
          ),
        ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.2, end: 0),

        // Timing selector
        if (prefs.enabled) ...[
          _buildSettingCard(
            'Rappel avant l\'événement',
            NotificationPreferences.getTimingLabel(prefs.minutesBefore),
            Icons.timer,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showTimingDialog(),
          ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2, end: 0),

          // Notify for participating
          _buildSettingCard(
            'Événements rejoints',
            'Rappels pour les événements auxquels vous participez',
            Icons.group,
            trailing: Switch(
              value: prefs.notifyForParticipating,
              onChanged: (value) async {
                await _notifPrefs.setNotifyForParticipating(value);
                await _notifService.rescheduleAllNotifications();
                setState(() {});
              },
              activeThumbColor: AppColors.primary,
            ),
          ).animate().fadeIn(delay: 350.ms).slideX(begin: -0.2, end: 0),

          // Notify for interested
          _buildSettingCard(
            'Événements intéressants',
            'Rappels pour les événements qui vous intéressent',
            Icons.star,
            trailing: Switch(
              value: prefs.notifyForInterested,
              onChanged: (value) async {
                await _notifPrefs.setNotifyForInterested(value);
                await _notifService.rescheduleAllNotifications();
                setState(() {});
              },
              activeThumbColor: AppColors.primary,
            ),
          ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2, end: 0),

          // Sound
          _buildSettingCard(
            'Son des notifications',
            prefs.soundEnabled ? 'Activé' : 'Désactivé',
            Icons.volume_up,
            trailing: Switch(
              value: prefs.soundEnabled,
              onChanged: (value) async {
                await _notifPrefs.setSoundEnabled(value);
                setState(() {});
              },
              activeThumbColor: AppColors.primary,
            ),
          ).animate().fadeIn(delay: 450.ms).slideX(begin: -0.2, end: 0),

          // Vibration
          _buildSettingCard(
            'Vibration des notifications',
            prefs.vibrationEnabled ? 'Activée' : 'Désactivée',
            Icons.vibration,
            trailing: Switch(
              value: prefs.vibrationEnabled,
              onChanged: (value) async {
                await _notifPrefs.setVibrationEnabled(value);
                setState(() {});
              },
              activeThumbColor: AppColors.primary,
            ),
          ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.2, end: 0),
        ],
      ],
    );
  }

  /// Show timing selection dialog
  void _showTimingDialog() {
    final currentMinutes = _notifPrefs.preferences.minutesBefore;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.timer, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Rappel avant l\'événement'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: NotificationPreferences.timingOptions.map((minutes) {
            return RadioListTile<int>(
              value: minutes,
              groupValue: currentMinutes,
              title: Text(NotificationPreferences.getTimingLabel(minutes)),
              activeColor: AppColors.primary,
              onChanged: (value) async {
                if (value != null) {
                  await _notifPrefs.setMinutesBefore(value);
                  await _notifService.rescheduleAllNotifications();
                  setState(() {});
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('⏰ Rappel: ${NotificationPreferences.getTimingLabel(value)}'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    final languageNotifier = ref.read(languageProvider.notifier);
    final currentLanguage = ref.read(languageProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir la langue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              value: 'fr',
              groupValue: currentLanguage.languageCode,
              title: const Text('🇫🇷 Français'),
              activeColor: AppColors.primary,
              onChanged: (value) {
                languageNotifier.setLanguage(value!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Langue changée en Français'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            RadioListTile<String>(
              value: 'en',
              groupValue: currentLanguage.languageCode,
              title: const Text('🇬🇧 English'),
              activeColor: AppColors.primary,
              onChanged: (value) {
                languageNotifier.setLanguage(value!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Language changed to English'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            RadioListTile<String>(
              value: 'es',
              groupValue: currentLanguage.languageCode,
              title: const Text('🇪🇸 Español'),
              activeColor: AppColors.primary,
              onChanged: (value) {
                languageNotifier.setLanguage(value!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Idioma cambiado a Español'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vider le cache'),
        content: const Text('Voulez-vous vraiment vider le cache ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache vidé avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Vider'),
          ),
        ],
      ),
    );
  }
}
