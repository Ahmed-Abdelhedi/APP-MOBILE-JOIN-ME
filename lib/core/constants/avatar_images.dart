/// Predefined avatar images constants
class AvatarImages {
  static const String avatar1 = 'assets/images/avatars/avatar1.png';
  static const String avatar2 = 'assets/images/avatars/avatar2.png';
  static const String avatar3 = 'assets/images/avatars/avatar3.png';
  static const String avatar4 = 'assets/images/avatars/avatar4.png';
  static const String avatar5 = 'assets/images/avatars/avatar5.png';
  static const String avatar6 = 'assets/images/avatars/avatar6.png';
  static const String avatar7 = 'assets/images/avatars/avatar7.png';
  static const String avatar8 = 'assets/images/avatars/avatar8.png';

  /// Get all predefined avatars with their labels
  static List<AvatarOption> get allOptions => [
        const AvatarOption(path: avatar1, label: 'Avatar 1'),
        const AvatarOption(path: avatar2, label: 'Avatar 2'),
        const AvatarOption(path: avatar3, label: 'Avatar 3'),
        const AvatarOption(path: avatar4, label: 'Avatar 4'),
        const AvatarOption(path: avatar5, label: 'Avatar 5'),
        const AvatarOption(path: avatar6, label: 'Avatar 6'),
        const AvatarOption(path: avatar7, label: 'Avatar 7'),
        const AvatarOption(path: avatar8, label: 'Avatar 8'),
      ];
}

class AvatarOption {
  final String path;
  final String label;

  const AvatarOption({
    required this.path,
    required this.label,
  });
}
