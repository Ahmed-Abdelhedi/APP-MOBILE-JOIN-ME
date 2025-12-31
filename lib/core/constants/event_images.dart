/// Predefined event images constants
class EventImages {
  // Sports category images
  static const String sportsFootball = 'assets/images/events/sports_football.jpg';
  static const String sportsBasketball = 'assets/images/events/sports_basketball.jpg';
  static const String sportsTennis = 'assets/images/events/sports_tennis.jpg';
  static const String sportsRunning = 'assets/images/events/sports_running.jpg';
  static const String sportsCycling = 'assets/images/events/sports_cycling.jpg';
  static const String sportsSwimming = 'assets/images/events/sports_swimming.jpg';

  // Gaming category images
  static const String gamingEsports = 'assets/images/events/gaming_esports.jpg';
  static const String gamingConsole = 'assets/images/events/gaming_console.jpg';
  static const String gamingPc = 'assets/images/events/gaming_pc.jpg';
  static const String gamingVr = 'assets/images/events/gaming_vr.jpg';
  static const String gamingBoard = 'assets/images/events/gaming_board.jpg';

  // Nature category images
  static const String natureHiking = 'assets/images/events/nature_hiking.jpg';
  static const String natureCamping = 'assets/images/events/nature_camping.jpg';
  static const String natureBeach = 'assets/images/events/nature_beach.jpg';
  static const String natureMountain = 'assets/images/events/nature_mountain.jpg';
  static const String natureForest = 'assets/images/events/nature_forest.jpg';
  static const String naturePicnic = 'assets/images/events/nature_picnic.jpg';

  // Fitness category images
  static const String fitnessGym = 'assets/images/events/fitness_gym.jpg';
  static const String fitnessYoga = 'assets/images/events/fitness_yoga.jpg';
  static const String fitnessCrossfit = 'assets/images/events/fitness_crossfit.jpg';
  static const String fitnessPilates = 'assets/images/events/fitness_pilates.jpg';
  static const String fitnessBoxing = 'assets/images/events/fitness_boxing.jpg';

  // Culture category images
  static const String cultureMuseum = 'assets/images/events/culture_museum.jpg';
  static const String cultureConcert = 'assets/images/events/culture_concert.jpg';
  static const String cultureCinema = 'assets/images/events/culture_cinema.jpg';
  static const String cultureTheater = 'assets/images/events/culture_theater.jpg';
  static const String cultureArt = 'assets/images/events/culture_art.jpg';
  static const String cultureBook = 'assets/images/events/culture_book.jpg';

  // Food category images
  static const String foodRestaurant = 'assets/images/events/food_restaurant.jpg';
  static const String foodBrunch = 'assets/images/events/food_brunch.jpg';
  static const String foodCooking = 'assets/images/events/food_cooking.jpg';
  static const String foodCoffee = 'assets/images/events/food_coffee.jpg';
  static const String foodBbq = 'assets/images/events/food_bbq.jpg';
  static const String foodWine = 'assets/images/events/food_wine.jpg';

  // General/Party images
  static const String partyCelebration = 'assets/images/events/party_celebration.jpg';
  static const String partyFriends = 'assets/images/events/party_friends.jpg';
  static const String meetupGroup = 'assets/images/events/meetup_group.jpg';
  static const String workshopLearning = 'assets/images/events/workshop_learning.jpg';

  /// Get all predefined images with their labels
  static List<EventImageOption> get allOptions => [
        // Sports
        const EventImageOption(
          path: sportsFootball,
          label: 'Football',
          icon: '⚽',
          category: 'Sports',
        ),
        const EventImageOption(
          path: sportsBasketball,
          label: 'Basketball',
          icon: '🏀',
          category: 'Sports',
        ),
        const EventImageOption(
          path: sportsTennis,
          label: 'Tennis',
          icon: '🎾',
          category: 'Sports',
        ),
        const EventImageOption(
          path: sportsRunning,
          label: 'Course',
          icon: '🏃',
          category: 'Sports',
        ),
        const EventImageOption(
          path: sportsCycling,
          label: 'Vélo',
          icon: '🚴',
          category: 'Sports',
        ),
        const EventImageOption(
          path: sportsSwimming,
          label: 'Natation',
          icon: '🏊',
          category: 'Sports',
        ),

        // Gaming
        const EventImageOption(
          path: gamingEsports,
          label: 'Esports',
          icon: '🎮',
          category: 'Gaming',
        ),
        const EventImageOption(
          path: gamingConsole,
          label: 'Console',
          icon: '🕹️',
          category: 'Gaming',
        ),
        const EventImageOption(
          path: gamingPc,
          label: 'PC Gaming',
          icon: '💻',
          category: 'Gaming',
        ),
        const EventImageOption(
          path: gamingVr,
          label: 'Réalité Virtuelle',
          icon: '🥽',
          category: 'Gaming',
        ),
        const EventImageOption(
          path: gamingBoard,
          label: 'Jeux de Société',
          icon: '🎲',
          category: 'Gaming',
        ),

        // Nature
        const EventImageOption(
          path: natureHiking,
          label: 'Randonnée',
          icon: '🥾',
          category: 'Nature',
        ),
        const EventImageOption(
          path: natureCamping,
          label: 'Camping',
          icon: '⛺',
          category: 'Nature',
        ),
        const EventImageOption(
          path: natureBeach,
          label: 'Plage',
          icon: '🏖️',
          category: 'Nature',
        ),
        const EventImageOption(
          path: natureMountain,
          label: 'Montagne',
          icon: '🏔️',
          category: 'Nature',
        ),
        const EventImageOption(
          path: natureForest,
          label: 'Forêt',
          icon: '🌲',
          category: 'Nature',
        ),
        const EventImageOption(
          path: naturePicnic,
          label: 'Pique-nique',
          icon: '🧺',
          category: 'Nature',
        ),

        // Fitness
        const EventImageOption(
          path: fitnessGym,
          label: 'Gym',
          icon: '💪',
          category: 'Fitness',
        ),
        const EventImageOption(
          path: fitnessYoga,
          label: 'Yoga',
          icon: '🧘',
          category: 'Fitness',
        ),
        const EventImageOption(
          path: fitnessCrossfit,
          label: 'CrossFit',
          icon: '🏋️',
          category: 'Fitness',
        ),
        const EventImageOption(
          path: fitnessPilates,
          label: 'Pilates',
          icon: '🤸',
          category: 'Fitness',
        ),
        const EventImageOption(
          path: fitnessBoxing,
          label: 'Boxe',
          icon: '🥊',
          category: 'Fitness',
        ),

        // Culture
        const EventImageOption(
          path: cultureMuseum,
          label: 'Musée',
          icon: '🏛️',
          category: 'Culture',
        ),
        const EventImageOption(
          path: cultureConcert,
          label: 'Concert',
          icon: '🎤',
          category: 'Culture',
        ),
        const EventImageOption(
          path: cultureCinema,
          label: 'Cinéma',
          icon: '🎬',
          category: 'Culture',
        ),
        const EventImageOption(
          path: cultureTheater,
          label: 'Théâtre',
          icon: '🎭',
          category: 'Culture',
        ),
        const EventImageOption(
          path: cultureArt,
          label: 'Art',
          icon: '🎨',
          category: 'Culture',
        ),
        const EventImageOption(
          path: cultureBook,
          label: 'Lecture',
          icon: '📚',
          category: 'Culture',
        ),

        // Food
        const EventImageOption(
          path: foodRestaurant,
          label: 'Restaurant',
          icon: '🍽️',
          category: 'Food',
        ),
        const EventImageOption(
          path: foodBrunch,
          label: 'Brunch',
          icon: '🥞',
          category: 'Food',
        ),
        const EventImageOption(
          path: foodCooking,
          label: 'Cuisine',
          icon: '👨‍🍳',
          category: 'Food',
        ),
        const EventImageOption(
          path: foodCoffee,
          label: 'Café',
          icon: '☕',
          category: 'Food',
        ),
        const EventImageOption(
          path: foodBbq,
          label: 'Barbecue',
          icon: '🍖',
          category: 'Food',
        ),
        const EventImageOption(
          path: foodWine,
          label: 'Dégustation',
          icon: '🍷',
          category: 'Food',
        ),

        // General
        const EventImageOption(
          path: partyCelebration,
          label: 'Fête',
          icon: '🎉',
          category: 'Général',
        ),
        const EventImageOption(
          path: partyFriends,
          label: 'Entre amis',
          icon: '👥',
          category: 'Général',
        ),
        const EventImageOption(
          path: meetupGroup,
          label: 'Meetup',
          icon: '🤝',
          category: 'Général',
        ),
        const EventImageOption(
          path: workshopLearning,
          label: 'Atelier',
          icon: '📝',
          category: 'Général',
        ),
      ];

  /// Get images by category
  static List<EventImageOption> getByCategory(String category) {
    return allOptions.where((option) => 
      option.category.toLowerCase() == category.toLowerCase()
    ).toList();
  }

  /// Get default image for a category
  static String getDefaultForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'sports':
        return sportsFootball;
      case 'gaming':
        return gamingEsports;
      case 'nature':
        return natureHiking;
      case 'fitness':
        return fitnessGym;
      case 'culture':
        return cultureConcert;
      case 'food':
        return foodRestaurant;
      default:
        return partyCelebration;
    }
  }
}

/// Model for event image option
class EventImageOption {
  final String path;
  final String label;
  final String icon;
  final String category;

  const EventImageOption({
    required this.path,
    required this.label,
    required this.icon,
    required this.category,
  });
}
