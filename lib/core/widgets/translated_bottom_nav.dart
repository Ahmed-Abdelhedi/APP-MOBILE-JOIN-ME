import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/providers/language_provider.dart';

class TranslatedBottomNav extends ConsumerWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const TranslatedBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = ref.watch(localizationProvider);

    return BottomNavigationBar(
      currentIndex: selectedIndex,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      onTap: onTap,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: loc.home,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.map),
          label: loc.map,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.chat),
          label: loc.messages,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person),
          label: loc.profile,
        ),
      ],
    );
  }
}
