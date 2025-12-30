import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/widgets/translated_bottom_nav.dart';
import 'package:mobile/core/services/activity_service.dart';
import 'package:mobile/core/providers/firebase_providers.dart';
import 'package:mobile/core/models/activity_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'activity_details_screen.dart';
import 'create_activity_screen.dart';
import '../../../map/presentation/screens/map_screen.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../profile/presentation/screens/notifications_screen.dart';
import '../../../profile/presentation/screens/payment_methods_screen.dart';
import '../widgets/activity_image_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final int _selectedIndex = 0;
  String _selectedCategory = 'Tout';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSearch = false;

  final List<String> _categories = [
    'Tout',
    'Sports',
    'Gaming',
    'Nature',
    'Fitness',
    'Culture',
    'Food',
  ];

  void _joinActivity(ActivityModel activity) {
    final hasFee = activity.cost != null && activity.cost! > 0;
    final feeAmount = activity.cost ?? 0.0;

    if (hasFee) {
      // Show payment dialog
      _showPaymentDialog(activity, feeAmount);
    } else {
      // Join directly
      _confirmJoin(activity);
    }
  }

  Future<void> _confirmJoin(ActivityModel activity) async {
    try {
      final activityService = ref.read(activityServiceProvider);
      await activityService.joinActivity(activity.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Vous avez rejoint "${activity.title}" !'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _leaveActivity(ActivityModel activity) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitter l\'activité'),
        content: Text('Voulez-vous vraiment quitter "${activity.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitter', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final activityService = ref.read(activityServiceProvider);
        await activityService.leaveActivity(activity.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vous avez quitté "${activity.title}"'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showPaymentDialog(ActivityModel activity, double amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('💳 Paiement requis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Activité: ${activity.title}'),
            const SizedBox(height: 8),
            Text(
              'Montant: ${amount.toStringAsFixed(2)}€',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cette activité nécessite une cotisation. Confirmez-vous le paiement ?',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processPayment(activity, amount);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Confirmer le paiement'),
          ),
        ],
      ),
    );
  }

  void _processPayment(ActivityModel activity, double amount) {
    // Navigate to payment screen with amount and title
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentMethodsScreen(
          paymentAmount: amount,
          activityTitle: activity.title,
        ),
      ),
    ).then((paymentSuccess) {
      if (paymentSuccess == true) {
        _confirmJoin(activity);
      }
    });
  }

  void _toggleFavorite(ActivityModel activity) async {
    try {
      final userService = ref.read(userServiceProvider);
      final isFavorite = await userService.isFavorite(activity.id);

      if (isFavorite) {
        await userService.removeFromFavorites(activity.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Retiré des favoris'),
              backgroundColor: Colors.grey[700],
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        await userService.addToFavorites(activity.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.favorite, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Ajouté aux favoris'),
                ],
              ),
              backgroundColor: Colors.pink,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openChat(ActivityModel activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(activityId: activity.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Charger les activités depuis Firebase
    final activitiesStream = ref.watch(activitiesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Rechercher une activité...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(fontSize: 16),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : const Text(
                'Activités près de vous',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
        leading: _showSearch
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _showSearch = false;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
              )
            : null,
        actions: [
          if (!_showSearch) ...[
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
            ).animate().scale(delay: 100.ms, duration: 300.ms),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _showSearch = true;
                });
              },
            ).animate().scale(delay: 200.ms, duration: 300.ms),
          ],
        ],
      ),
      body: activitiesStream.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Erreur de chargement',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Force refresh
                  ref.invalidate(activitiesStreamProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (activities) {
          // Filter activities based on search and category
          var filteredActivities = activities.where((activity) {
            final matchesCategory =
                _selectedCategory == 'Tout' ||
                activity.category == _selectedCategory;
            final matchesSearch = _searchQuery.isEmpty ||
                activity.title
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                activity.location
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase());
            return matchesCategory && matchesSearch;
          }).toList();

          // Sort: upcoming events first, past events at bottom
          filteredActivities.sort((a, b) {
            // If both past or both upcoming, sort by date
            if (a.isPast == b.isPast) {
              return a.dateTime.compareTo(b.dateTime);
            }
            // Past events go to bottom
            return a.isPast ? 1 : -1;
          });

          return Column(
            children: [
              // Categories
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedCategory == _categories[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: isSelected
                          ? Container(
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory = _categories[index];
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      _categories[index],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : FilterChip(
                              label: Text(_categories[index]),
                              selected: false,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory = _categories[index];
                                });
                              },
                              backgroundColor: Colors.grey.shade200,
                              labelStyle: const TextStyle(
                                color: Colors.black87,
                              ),
                            ),
                    );
                  },
                ),
              ),

              // Activities List
              Expanded(
                child: filteredActivities.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              activities.isEmpty ? Icons.event_busy : Icons.search_off,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              activities.isEmpty
                                  ? 'Aucune activité disponible'
                                  : 'Aucune activité trouvée',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (activities.isEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Créez la première activité !',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredActivities.length,
                        itemBuilder: (context, index) {
                          final activity = filteredActivities[index];
                          return _buildActivityCard(activity)
                              .animate()
                              .fadeIn(
                                delay: Duration(milliseconds: 100 * index),
                                duration: 400.ms,
                              )
                              .slideX(
                                begin: 0.2,
                                end: 0,
                                delay: Duration(milliseconds: 100 * index),
                                duration: 400.ms,
                                curve: Curves.easeOutQuad,
                              );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CreateActivityScreen(),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Créer'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      )
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .shimmer(delay: 2000.ms, duration: 1500.ms)
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.05, 1.05),
            duration: 1500.ms,
          ),
      bottomNavigationBar: TranslatedBottomNav(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          if (index == _selectedIndex) return;
          
          Widget screen;
          switch (index) {
            case 0:
              return;
            case 1:
              screen = const MapScreen();
              break;
            case 2:
              screen = const ChatScreen();
              break;
            case 3:
              screen = const ProfileScreen();
              break;
            default:
              return;
          }
          
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => screen),
          );
        },
      ),
    );
  }

  Widget _buildActivityCard(ActivityModel activity) {
    final isFull = activity.currentParticipants >= activity.maxParticipants;
    final isPast = activity.isPast;
    
    return Opacity(
      opacity: isPast ? 0.6 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: isPast ? 1 : 2,
        color: isPast ? Colors.grey.shade100 : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isPast ? BorderSide(color: Colors.grey.shade300, width: 1) : BorderSide.none,
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ActivityDetailsScreen(activity: activity.toMap()),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Header with Gradient Overlay
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    Hero(
                      tag: 'activity_${activity.title}',
                      child: ColorFiltered(
                        colorFilter: isPast
                            ? ColorFilter.mode(
                                Colors.grey.shade400,
                                BlendMode.saturation,
                              )
                            : const ColorFilter.mode(
                                Colors.transparent,
                                BlendMode.multiply,
                              ),
                        child: ActivityImageWidget(
                          activity: activity,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Gradient Overlay
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(isPast ? 0.5 : 0.3),
                          ],
                        ),
                      ),
                    ),
                    // Past Event Badge
                    if (isPast)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.history,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Événement passé',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isPast
                          ? Colors.grey.shade300
                          : AppColors.secondary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      activity.category,
                      style: TextStyle(
                        color: isPast ? Colors.grey.shade700 : AppColors.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Title
                  Text(
                    activity.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isPast ? Colors.grey.shade600 : Colors.black,
                      decoration: isPast ? TextDecoration.lineThrough : null,
                      decorationColor: Colors.grey.shade400,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: isPast ? Colors.grey.shade400 : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          activity.location,
                          style: TextStyle(
                            color: isPast ? Colors.grey.shade500 : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Date & Time
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: isPast ? Colors.grey.shade400 : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${activity.dateTime.day}/${activity.dateTime.month}/${activity.dateTime.year} à ${activity.dateTime.hour}:${activity.dateTime.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: isPast ? Colors.grey.shade500 : Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Participants & Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 20,
                            color: isFull ? Colors.red : AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${activity.currentParticipants}/${activity.maxParticipants}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isFull ? Colors.red : AppColors.primary,
                            ),
                          ),
                          if (isFull) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'COMPLET',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          activity.cost != null && activity.cost! > 0 ? '${activity.cost!.toStringAsFixed(2)}€' : 'Gratuit',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Action Buttons Row
                  Row(
                    children: [
                      // Favorite Button
                      Consumer(
                        builder: (context, ref, child) {
                          final userProfile = ref.watch(currentUserProfileProvider);
                          
                          return userProfile.when(
                            loading: () => IconButton(
                              onPressed: null,
                              icon: const Icon(Icons.favorite_border),
                              color: Colors.grey,
                            ),
                            error: (_, __) => IconButton(
                              onPressed: () => _toggleFavorite(activity),
                              icon: const Icon(Icons.favorite_border),
                              color: Colors.grey,
                            ),
                            data: (profile) {
                              final isFavorite = profile?.favorites.contains(activity.id) ?? false;
                              
                              return IconButton(
                                onPressed: () => _toggleFavorite(activity),
                                icon: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                ),
                                color: isFavorite
                                    ? Colors.red
                                    : Colors.grey,
                                style: IconButton.styleFrom(
                                  backgroundColor: isFavorite
                                      ? Colors.pink.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      
                      // Main Action Button (Join/Leave/Chat)
                      Expanded(
                        child: StreamBuilder<bool>(
                          stream: ref.read(activityServiceProvider).hasJoinedStream(activity.id),
                          builder: (context, snapshot) {
                            final hasJoined = snapshot.data ?? false;
                            
                            // Past event - show disabled state
                            if (isPast) {
                              if (hasJoined) {
                                return ElevatedButton.icon(
                                  onPressed: null,
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text('Vous avez participé'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade400,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    disabledBackgroundColor: Colors.grey.shade400,
                                    disabledForegroundColor: Colors.white,
                                  ),
                                );
                              }
                              return ElevatedButton.icon(
                                onPressed: null,
                                icon: const Icon(Icons.block),
                                label: const Text('Événement terminé'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade400,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  disabledBackgroundColor: Colors.grey.shade400,
                                  disabledForegroundColor: Colors.white,
                                ),
                              );
                            }
                            
                            // Active event logic
                            if (hasJoined) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _openChat(activity),
                                      icon: const Icon(Icons.chat_bubble_outline),
                                      label: const Text('Chat'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        side: BorderSide(color: AppColors.primary),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: () => _leaveActivity(activity),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Icon(Icons.close),
                                  ),
                                ],
                              );
                            }
                            
                            return ElevatedButton.icon(
                              onPressed: isFull ? null : () => _joinActivity(activity),
                              icon: Icon(isFull ? Icons.block : Icons.check_circle_outline),
                              label: Text(isFull ? 'Complet' : 'Rejoindre'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFull ? Colors.grey : AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                disabledBackgroundColor: Colors.grey,
                                disabledForegroundColor: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // Details Button
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ActivityDetailsScreen(activity: activity.toMap()),
                            ),
                          );
                        },
                        icon: const Icon(Icons.info_outline),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
