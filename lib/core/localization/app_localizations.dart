class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

  static AppLocalizations of(String languageCode) {
    return AppLocalizations(languageCode);
  }

  // Navigation
  String get home => _localize({
        'fr': 'Accueil',
        'en': 'Home',
        'es': 'Inicio',
      });

  String get map => _localize({
        'fr': 'Carte',
        'en': 'Map',
        'es': 'Mapa',
      });

  String get messages => _localize({
        'fr': 'Messages',
        'en': 'Messages',
        'es': 'Mensajes',
      });

  String get profile => _localize({
        'fr': 'Profil',
        'en': 'Profile',
        'es': 'Perfil',
      });

  // Activities
  String get exploreActivities => _localize({
        'fr': 'Explorer les activités',
        'en': 'Explore activities',
        'es': 'Explorar actividades',
      });

  String get joinActivity => _localize({
        'fr': 'Rejoindre l\'activité',
        'en': 'Join activity',
        'es': 'Unirse a la actividad',
      });

  String get leaveActivity => _localize({
        'fr': 'Quitter l\'activité',
        'en': 'Leave activity',
        'es': 'Salir de la actividad',
      });

  String get createActivity => _localize({
        'fr': 'Créer une activité',
        'en': 'Create activity',
        'es': 'Crear actividad',
      });

  String get participants => _localize({
        'fr': 'Participants',
        'en': 'Participants',
        'es': 'Participantes',
      });

  String get chatGroup => _localize({
        'fr': 'Chat Groupe',
        'en': 'Group Chat',
        'es': 'Chat Grupal',
      });

  // Categories
  String get all => _localize({
        'fr': 'Tout',
        'en': 'All',
        'es': 'Todo',
      });

  String get sports => _localize({
        'fr': 'Sports',
        'en': 'Sports',
        'es': 'Deportes',
      });

  String get gaming => _localize({
        'fr': 'Gaming',
        'en': 'Gaming',
        'es': 'Videojuegos',
      });

  String get nature => _localize({
        'fr': 'Nature',
        'en': 'Nature',
        'es': 'Naturaleza',
      });

  String get fitness => _localize({
        'fr': 'Fitness',
        'en': 'Fitness',
        'es': 'Fitness',
      });

  String get culture => _localize({
        'fr': 'Culture',
        'en': 'Culture',
        'es': 'Cultura',
      });

  String get food => _localize({
        'fr': 'Food',
        'en': 'Food',
        'es': 'Comida',
      });

  // Profile
  String get myActivities => _localize({
        'fr': 'Mes activités',
        'en': 'My activities',
        'es': 'Mis actividades',
      });

  String get favorites => _localize({
        'fr': 'Favoris',
        'en': 'Favorites',
        'es': 'Favoritos',
      });

  String get notifications => _localize({
        'fr': 'Notifications',
        'en': 'Notifications',
        'es': 'Notificaciones',
      });

  String get settings => _localize({
        'fr': 'Paramètres',
        'en': 'Settings',
        'es': 'Configuración',
      });

  String get helpSupport => _localize({
        'fr': 'Aide & Support',
        'en': 'Help & Support',
        'es': 'Ayuda y Soporte',
      });

  String get about => _localize({
        'fr': 'À propos',
        'en': 'About',
        'es': 'Acerca de',
      });

  String get logout => _localize({
        'fr': 'Déconnexion',
        'en': 'Logout',
        'es': 'Cerrar sesión',
      });

  String get editProfile => _localize({
        'fr': 'Modifier le profil',
        'en': 'Edit profile',
        'es': 'Editar perfil',
      });

  // Settings
  String get appearance => _localize({
        'fr': 'Apparence',
        'en': 'Appearance',
        'es': 'Apariencia',
      });

  String get darkMode => _localize({
        'fr': 'Mode sombre',
        'en': 'Dark mode',
        'es': 'Modo oscuro',
      });

  String get enableDarkTheme => _localize({
        'fr': 'Activer le thème sombre',
        'en': 'Enable dark theme',
        'es': 'Activar tema oscuro',
      });

  String get language => _localize({
        'fr': 'Langue',
        'en': 'Language',
        'es': 'Idioma',
      });

  String get appLanguage => _localize({
        'fr': 'Langue de l\'application',
        'en': 'App language',
        'es': 'Idioma de la aplicación',
      });

  // Chat
  String get noConversation => _localize({
        'fr': 'Aucune conversation',
        'en': 'No conversation',
        'es': 'Sin conversaciones',
      });

  String get joinActivityToChat => _localize({
        'fr': 'Rejoignez une activité pour\ncommencer à discuter',
        'en': 'Join an activity to\nstart chatting',
        'es': 'Únete a una actividad para\ncomenzar a chatear',
      });

  String get groupCreated => _localize({
        'fr': 'Groupe créé',
        'en': 'Group created',
        'es': 'Grupo creado',
      });

  String get now => _localize({
        'fr': 'Maintenant',
        'en': 'Now',
        'es': 'Ahora',
      });

  // Common
  String get search => _localize({
        'fr': 'Rechercher',
        'en': 'Search',
        'es': 'Buscar',
      });

  String get free => _localize({
        'fr': 'Gratuit',
        'en': 'Free',
        'es': 'Gratis',
      });

  String get full => _localize({
        'fr': 'Complet',
        'en': 'Full',
        'es': 'Completo',
      });

  String get cancel => _localize({
        'fr': 'Annuler',
        'en': 'Cancel',
        'es': 'Cancelar',
      });

  String get confirm => _localize({
        'fr': 'Confirmer',
        'en': 'Confirm',
        'es': 'Confirmar',
      });

  String get save => _localize({
        'fr': 'Enregistrer',
        'en': 'Save',
        'es': 'Guardar',
      });

  // Snackbar messages
  String get activityJoined => _localize({
        'fr': 'Vous avez rejoint l\'activité !',
        'en': 'You joined the activity!',
        'es': '¡Te has unido a la actividad!',
      });

  String get activityLeft => _localize({
        'fr': 'Vous avez quitté l\'activité',
        'en': 'You left the activity',
        'es': 'Has salido de la actividad',
      });

  String get locationSelected => _localize({
        'fr': 'Lieu sélectionné',
        'en': 'Location selected',
        'es': 'Ubicación seleccionada',
      });

  String get languageChanged => _localize({
        'fr': 'Langue changée',
        'en': 'Language changed',
        'es': 'Idioma cambiado',
      });

  // Helper method
  String _localize(Map<String, String> translations) {
    return translations[languageCode] ?? translations['fr'] ?? '';
  }
}
