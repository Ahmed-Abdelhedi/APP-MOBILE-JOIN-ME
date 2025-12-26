import 'package:intl/intl.dart';

/// Formateurs pour affichage
class Formatters {
  /// Formater une date (ex: "23 déc. 2025")
  static String formatDate(DateTime date) {
    return DateFormat('d MMM yyyy', 'fr_FR').format(date);
  }

  /// Formater une heure (ex: "14:30")
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// Formater date + heure (ex: "23 déc. 2025 à 14:30")
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} à ${formatTime(date)}';
  }

  /// Formater un prix (ex: "15,50 €")
  static String formatPrice(double? price) {
    if (price == null || price == 0) {
      return 'Gratuit';
    }
    return '${price.toStringAsFixed(2)} €';
  }

  /// Formater un temps relatif (ex: "Il y a 2 heures")
  static String formatRelativeTime(DateTime date) {
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
      return formatDate(date);
    }
  }

  /// Formater un nombre de participants (ex: "15 / 20")
  static String formatParticipants(int current, int max) {
    return '$current / $max';
  }

  /// Formater une distance (ex: "2,5 km")
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  /// Tronquer un texte long
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Capitaliser la première lettre
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
