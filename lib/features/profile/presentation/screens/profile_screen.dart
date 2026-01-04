import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/providers/firebase_providers.dart';
import 'package:mobile/features/auth/presentation/providers/auth_providers.dart' show authControllerProvider;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../activities/presentation/screens/home_screen.dart';
import '../../../map/presentation/screens/map_screen.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../../auth/presentation/screens/modern_login_screen.dart';
import 'edit_profile_screen.dart';
import 'my_activities_screen.dart';
import 'favorites_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';
import 'location_settings_screen.dart';
import 'payment_methods_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final int _selectedIndex = 3;

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final currentUser = ref.watch(currentUserProvider);
    final activitiesCountAsync = ref.watch(userActivitiesCountProvider);
    final friendsCountAsync = ref.watch(userFriendsCountProvider);
    final averageRatingAsync = ref.watch(userAverageRatingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: userProfileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(currentUserProfileProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (userProfile) {
          // Utiliser les données Firebase ou par défaut les données de FirebaseAuth
          final displayName = userProfile?.name ?? currentUser?.displayName ?? 'Utilisateur';
          final email = userProfile?.email ?? currentUser?.email ?? '';
          final photoUrl = userProfile?.photoUrl ?? currentUser?.photoURL;
          final bio = userProfile?.bio ?? '';
          final initials = displayName.isNotEmpty 
              ? displayName.substring(0, 1).toUpperCase() 
              : 'U';

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.secondary,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: photoUrl != null
                            ? (photoUrl.startsWith('assets/')
                                ? AssetImage(photoUrl)
                                : NetworkImage(photoUrl)) as ImageProvider
                            : null,
                        child: photoUrl == null ? Text(
                          initials,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ) : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        email,
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                      if (bio.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          bio,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Modifier le profil'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Stats Cards
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: activitiesCountAsync.when(
                          data: (count) => _buildStatCard(
                            count.toString(),
                            'Activités',
                            Icons.event,
                          ),
                          loading: () => _buildStatCard('...', 'Activités', Icons.event),
                          error: (_, __) => _buildStatCard('0', 'Activités', Icons.event),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: friendsCountAsync.when(
                          data: (count) => _buildStatCard(
                            count.toString(),
                            'Amis',
                            Icons.people,
                          ),
                          loading: () => _buildStatCard('...', 'Amis', Icons.people),
                          error: (_, __) => _buildStatCard('0', 'Amis', Icons.people),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: averageRatingAsync.when(
                          data: (rating) => _buildStatCard(
                            rating.toStringAsFixed(1),
                            'Note',
                            Icons.star,
                          ),
                          loading: () => _buildStatCard('...', 'Note', Icons.star),
                          error: (_, __) => _buildStatCard('4.8', 'Note', Icons.star),
                        ),
                      ),
                    ],
                  ),
                ),

            // Menu Items
            _buildMenuItem(
              Icons.history,
              'Mes activités',
              'Voir toutes mes activités',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyActivitiesScreen(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              Icons.favorite_outline,
              'Favoris',
              'Activités sauvegardées',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FavoritesScreen(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              Icons.notifications_outlined,
              'Notifications',
              'Gérer les notifications',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              Icons.location_on_outlined,
              'Localisation',
              'Modifier votre position',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LocationSettingsScreen(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              Icons.payment,
              'Paiements',
              'Méthodes de paiement',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PaymentMethodsScreen(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              Icons.help_outline,
              'Aide & Support',
              'Besoin d\'aide?',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpSupportScreen(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              Icons.info_outline,
              'À propos',
              'Version 1.0.0',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AboutScreen(),
                  ),
                );
              },
            ),
            _buildMenuItem(
              Icons.logout,
              'Déconnexion',
              'Se déconnecter de l\'application',
              () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Déconnexion'),
                    content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () async {
                          // Sign out from Firebase
                          final authController = ref.read(authControllerProvider.notifier);
                          await authController.signOut();
                          
                          // Effacer les préférences utilisateur
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear();
                          
                          Navigator.pop(context);
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ModernLoginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        child: const Text(
                          'Déconnexion',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
              isDestructive: true,
            ),

            const SizedBox(height: 32),
          ],
        ),
      );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : AppColors.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        if (index != _selectedIndex) {
          Widget screen;
          switch (index) {
            case 0:
              screen = const HomeScreen();
              break;
            case 1:
              screen = const MapScreen();
              break;
            case 2:
              screen = const ChatScreen();
              break;
            case 3:
              return;
            default:
              return;
          }
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => screen),
          );
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map),
          label: 'Carte',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    );
  }
}
