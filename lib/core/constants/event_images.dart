/// Predefined event images constants
class EventImages {
  // Predefined asset images for common event categories
  static const String sports = 'assets/images/events/sports.png';
  static const String football = 'assets/images/events/football.png';
  static const String gym = 'assets/images/events/gym.png';
  static const String gaming = 'assets/images/events/gaming.png';
  static const String cafe = 'assets/images/events/cafe.png';
  static const String cinema = 'assets/images/events/cinema.png';
  static const String music = 'assets/images/events/music.png';
  static const String food = 'assets/images/events/food.png';
  static const String art = 'assets/images/events/art.png';
  static const String study = 'assets/images/events/study.png';
  static const String travel = 'assets/images/events/travel.png';
  static const String party = 'assets/images/events/party.png';
  static const String work = 'assets/images/events/work.png';
  static const String meeting = 'assets/images/events/meeting.png';
  static const String birthday = 'assets/images/events/birthday.png';
  static const String defaultEvent = 'assets/images/events/default.png';

  /// Get all predefined images with their labels
  static List<EventImageOption> get allOptions => [
        const EventImageOption(
          path: sports,
          label: 'Sport',
          icon: '⚽',
        ),
        const EventImageOption(
          path: football,
          label: 'Football',
          icon: '🏟️',
        ),
        const EventImageOption(
          path: gym,
          label: 'Gym',
          icon: '💪',
        ),
        const EventImageOption(
          path: gaming,
          label: 'Gaming',
          icon: '🎮',
        ),
        const EventImageOption(
          path: cafe,
          label: 'Café',
          icon: '☕',
        ),
        const EventImageOption(
          path: cinema,
          label: 'Cinéma',
          icon: '🎬',
        ),
        const EventImageOption(
          path: music,
          label: 'Musique',
          icon: '🎵',
        ),
        const EventImageOption(
          path: food,
          label: 'Nourriture',
          icon: '🍕',
        ),
        const EventImageOption(
          path: art,
          label: 'Art',
          icon: '🎨',
        ),
        const EventImageOption(
          path: study,
          label: 'Étude',
          icon: '📚',
        ),
        const EventImageOption(
          path: travel,
          label: 'Voyage',
          icon: '✈️',
        ),
        const EventImageOption(
          path: party,
          label: 'Fête',
          icon: '🎉',
        ),
        const EventImageOption(
          path: work,
          label: 'Travail',
          icon: '💼',
        ),
        const EventImageOption(
          path: meeting,
          label: 'Réunion',
          icon: '👥',
        ),
        const EventImageOption(
          path: birthday,
          label: 'Anniversaire',
          icon: '🎂',
        ),
      ];
}

/// Model for event image option
class EventImageOption {
  final String path;
  final String label;
  final String icon;

  const EventImageOption({
    required this.path,
    required this.label,
    required this.icon,
  });
}
