import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/widgets/translated_bottom_nav.dart';
import 'package:mobile/core/providers/language_provider.dart';
import 'package:mobile/core/providers/firebase_providers.dart';
import 'package:mobile/core/services/location_service.dart';
import 'package:mobile/core/utils/network_check.dart';
import 'package:mobile/core/models/activity_model.dart';
import '../../../activities/presentation/screens/home_screen.dart';
import '../../../activities/presentation/screens/activity_details_screen.dart';
import '../../../activities/presentation/widgets/activity_image_widget.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final int _selectedIndex = 1;
  String _selectedFilter = 'Tous';
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final LocationService _locationService = LocationService();
  bool _isSearching = false;
  bool _isLoadingLocation = false;
  LatLng? _myPosition;

  final List<String> _filters = ['Tous', 'Sports', 'Gaming', 'Nature', 'Fitness'];

  @override
  void initState() {
    super.initState();
    // Vérification optionnelle et non bloquante
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    try {
      final hasConnection = await NetworkCheck.hasInternetConnection();
      if (!hasConnection && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('⚠️ Connexion limitée\n\nLa carte peut ne pas se charger correctement'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      // Ignorer les erreurs de vérification
      print('Erreur vérification connexion: $e');
    }
  }

  List<ActivityModel> _getFilteredActivities(List<ActivityModel> activities) {
    if (_selectedFilter == 'Tous') {
      return activities;
    }
    return activities.where((activity) {
      return activity.category.toLowerCase() == _selectedFilter.toLowerCase();
    }).toList();
  }
  
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'sports':
        return Colors.green;
      case 'gaming':
        return Colors.purple;
      case 'nature':
        return Colors.orange;
      case 'fitness':
        return Colors.pink;
      default:
        return AppColors.primary;
    }
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'sports':
        return Icons.sports_soccer;
      case 'gaming':
        return Icons.sports_esports;
      case 'nature':
        return Icons.hiking;
      case 'fitness':
        return Icons.self_improvement;
      default:
        return Icons.event;
    }
  }

  void _centerOnLocation(double lat, double lng) {
    _mapController.move(LatLng(lat, lng), 15.0);
  }

  Future<void> _goToMyLocation() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        final myPos = LatLng(position.latitude, position.longitude);
        setState(() {
          _myPosition = myPos;
          _isLoadingLocation = false;
        });
        _mapController.move(myPos, 15.0);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📍 Position actuelle localisée'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() => _isLoadingLocation = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible d\'obtenir votre position'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoadingLocation = false);
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

  Future<void> _searchLocation() async {
    if (_searchController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer une adresse'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isSearching = true);

    try {
      final coords = await _locationService.getCoordinatesFromAddress(
        _searchController.text,
      );
      
      if (coords != null) {
        setState(() => _isSearching = false);
        _mapController.move(coords, 14.0);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📍 ${_searchController.text}'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() => _isSearching = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Adresse non trouvée. Essayez "Paris", "Lyon", etc.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur de recherche: Vérifiez votre connexion Internet'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(localizationProvider);
    final activitiesAsync = ref.watch(activitiesStreamProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.map),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: activitiesAsync.when(
        data: (activities) {
          // Filtrer les activités qui ont des coordonnées GPS valides
          final activitiesWithLocation = activities;
          final filteredActivities = _getFilteredActivities(activitiesWithLocation);
          
          return Stack(
            children: [
              // Carte OpenStreetMap avec flutter_map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(48.8566, 2.3522), // Paris
                  initialZoom: 12.0,
                  minZoom: 5.0,
                  maxZoom: 18.0,
                ),
                children: [
                  // Tuiles OpenStreetMap
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.joinme.mobile',
                    additionalOptions: const {
                      'attribution': 'OpenStreetMap contributors',
                    },
                  ),
                  
                  // Markers personnalisés pour les activités
                  MarkerLayer(
                    markers: [
                      // Markers des activités depuis Firebase
                      ...filteredActivities.map((activity) {
                        return Marker(
                          point: LatLng(activity.latitude, activity.longitude),
                          width: 120,
                          height: 70,
                          child: GestureDetector(
                            onTap: () {
                              _showActivityDetails(activity);
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Icône du marqueur
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(activity.category),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(activity.category),
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Nom de l'événement
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    activity.title,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      
                      // Marker de ma position
                      if (_myPosition != null)
                        Marker(
                          point: _myPosition!,
                          width: 50,
                          height: 50,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person_pin,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              // Barre de recherche en haut
              Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Rechercher un lieu...',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _searchLocation(),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                      ),
                    if (_isSearching)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        icon: Icon(Icons.search, color: AppColors.primary),
                        onPressed: _searchLocation,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Filtres en dessous de la recherche
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      elevation: 2,
                      shadowColor: Colors.black.withOpacity(0.3),
                    ),
                  );
                },
              ),
            ),
          ),

          // Bouton Ma Position (en bas à droite)
          Positioned(
            bottom: 200,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'my_location',
              backgroundColor: Colors.white,
              onPressed: _goToMyLocation,
              child: _isLoadingLocation
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      Icons.my_location,
                      color: _myPosition != null ? Colors.blue : AppColors.primary,
                    ),
            ),
          ),

              // Liste des activités en bas
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          '${filteredActivities.length} ${filteredActivities.length > 1 ? 'lieux trouvés' : 'lieu trouvé'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: filteredActivities.isEmpty
                            ? const Center(
                                child: Text(
                                  'Aucune activité avec localisation',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: filteredActivities.length,
                                itemBuilder: (context, index) {
                                  final activity = filteredActivities[index];
                                  return _buildActivityCard(activity);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur: $error'),
            ],
          ),
        ),
      ),
      bottomNavigationBar: TranslatedBottomNav(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          if (index != _selectedIndex) {
            Widget screen;
            switch (index) {
              case 0:
                screen = const HomeScreen();
                break;
              case 1:
                return;
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
          }
        },
      ),
    );
  }

  Widget _buildActivityCard(ActivityModel activity) {
    final color = _getCategoryColor(activity.category);
    final icon = _getCategoryIcon(activity.category);
    final isFull = activity.currentParticipants >= activity.maxParticipants;
    
    return GestureDetector(
      onTap: () {
        _centerOnLocation(activity.latitude, activity.longitude);
        _showActivityDetails(activity);
      },
      child: Card(
        margin: const EdgeInsets.only(right: 12),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Header
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: ActivityImageWidget(
                      activity: activity,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Category badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            activity.category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Status badge (if full)
                  if (isFull)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'COMPLET',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      activity.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            activity.location,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    // Date & Time
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${activity.dateTime.day}/${activity.dateTime.month}/${activity.dateTime.year}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${activity.dateTime.hour}:${activity.dateTime.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    
                    // Participants and Price row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Participants
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isFull 
                                ? Colors.red.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people,
                                size: 16,
                                color: isFull ? Colors.red : Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${activity.currentParticipants}/${activity.maxParticipants}',
                                style: TextStyle(
                                  color: isFull ? Colors.red : Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Price
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (activity.cost != null && activity.cost! > 0)
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                (activity.cost != null && activity.cost! > 0)
                                    ? Icons.euro
                                    : Icons.money_off,
                                size: 14,
                                color: (activity.cost != null && activity.cost! > 0)
                                    ? Colors.orange
                                    : Colors.blue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (activity.cost != null && activity.cost! > 0)
                                    ? '${activity.cost!.toStringAsFixed(2)}€'
                                    : 'Gratuit',
                                style: TextStyle(
                                  color: (activity.cost != null && activity.cost! > 0)
                                      ? Colors.orange
                                      : Colors.blue,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Action button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ActivityDetailsScreen(
                                activity: activity.toMap(),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Voir les détails',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward, size: 16),
                          ],
                        ),
                      ),
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

  void _showActivityDetails(ActivityModel activity) {
    final color = _getCategoryColor(activity.category);
    final icon = _getCategoryIcon(activity.category);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity.category,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailRow(Icons.location_on, activity.location),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.calendar_today,
              '${activity.dateTime.day}/${activity.dateTime.month}/${activity.dateTime.year}',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.access_time,
              '${activity.dateTime.hour}:${activity.dateTime.minute.toString().padLeft(2, '0')}',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.people,
              '${activity.currentParticipants}/${activity.maxParticipants} participants',
            ),
            if (activity.description.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                activity.description,
                style: TextStyle(
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Fermer',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ActivityDetailsScreen(
                            activity: activity.toMap(),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Voir les détails'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
