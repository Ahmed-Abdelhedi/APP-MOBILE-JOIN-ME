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
  final double? focusLatitude;
  final double? focusLongitude;
  final String? focusEventTitle;
  final String? focusEventId;

  const MapScreen({
    super.key,
    this.focusLatitude,
    this.focusLongitude,
    this.focusEventTitle,
    this.focusEventId,
  });

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final int _selectedIndex = 1;
  String _selectedFilter = 'Tous';
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final LocationService _locationService = LocationService();
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  bool _isSearching = false;
  bool _isLoadingLocation = false;
  LatLng? _myPosition;
  bool _hasFocusedOnEvent = false;

  final List<String> _filters = ['Tous', 'Sports', 'Gaming', 'Nature', 'Fitness'];

  /// Check if we have a focused event location
  bool get _hasFocusLocation =>
      widget.focusLatitude != null && widget.focusLongitude != null;

  LatLng? get _focusLatLng => _hasFocusLocation
      ? LatLng(widget.focusLatitude!, widget.focusLongitude!)
      : null;

  @override
  void initState() {
    super.initState();
    // Vérification optionnelle et non bloquante
    _checkConnection();
    
    // Center on focused event after map is ready
    if (_hasFocusLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerOnFocusedEvent();
      });
    }
  }

  /// Center map on the focused event location
  void _centerOnFocusedEvent() {
    if (_focusLatLng != null && !_hasFocusedOnEvent) {
      _mapController.move(_focusLatLng!, 16.0);
      _hasFocusedOnEvent = true;
      
      if (mounted && widget.focusEventTitle != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('📍 ${widget.focusEventTitle}'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
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
    final now = DateTime.now();
    
    // Filtrer d'abord les événements passés
    final futureActivities = activities.where((activity) {
      return activity.dateTime.isAfter(now);
    }).toList();
    
    // Ensuite filtrer par catégorie
    if (_selectedFilter == 'Tous') {
      return futureActivities;
    }
    return futureActivities.where((activity) {
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
                  initialCenter: _focusLatLng ?? const LatLng(48.8566, 2.3522), // Focus event or Paris
                  initialZoom: _hasFocusLocation ? 16.0 : 12.0,
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
                              _centerOnLocation(activity.latitude, activity.longitude);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ActivityDetailsScreen(
                                    activity: activity.toMap(),
                                  ),
                                ),
                              );
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
                      
                      // 🎯 FOCUSED EVENT MARKER - Highlighted marker for the event being viewed
                      if (_focusLatLng != null)
                        Marker(
                          point: _focusLatLng!,
                          width: 160,
                          height: 100,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Pulsing outer ring
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red.withOpacity(0.2),
                                  border: Border.all(color: Colors.red, width: 3),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Colors.red, Colors.deepOrange],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red,
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.place,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Event title badge
                              if (widget.focusEventTitle != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.red, Colors.deepOrange],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.event, color: Colors.white, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.focusEventTitle!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
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

          // Bottom sheet glissable
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.1,
            minChildSize: 0.1,
            maxChildSize: 0.7,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle pour indiquer que c'est draggable
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Expand/collapse le sheet
                        if (_sheetController.size < 0.5) {
                          _sheetController.animateTo(
                            0.7,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        } else {
                          _sheetController.animateTo(
                            0.1,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${filteredActivities.length} ${filteredActivities.length > 1 ? 'lieux trouvés' : 'lieu trouvé'}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_up,
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: filteredActivities.isEmpty
                          ? const Center(
                              child: Text(
                                'Aucune activité à venir avec localisation',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filteredActivities.length,
                              itemBuilder: (context, index) {
                                final activity = filteredActivities[index];
                                return _buildActivityListItem(activity);
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActivityDetailsScreen(
              activity: activity.toMap(),
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(right: 12),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SizedBox(
          width: 300,
          height: 180, // Hauteur fixe pour éviter l'overflow
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
                      height: 90,
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title
                      Text(
                        activity.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              activity.location,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      // Date & Time
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${activity.dateTime.day}/${activity.dateTime.month}/${activity.dateTime.year}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${activity.dateTime.hour}:${activity.dateTime.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      
                      // Participants and Price row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Participants
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isFull 
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 14,
                                  color: isFull ? Colors.red : Colors.green,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${activity.currentParticipants}/${activity.maxParticipants}',
                                  style: TextStyle(
                                    color: isFull ? Colors.red : Colors.green,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                          // Price
                          Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: (activity.cost != null && activity.cost! > 0)
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
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
                              const SizedBox(width: 2),
                              Text(
                                (activity.cost != null && activity.cost! > 0)
                                    ? '${activity.cost!.toStringAsFixed(0)}'
                                    : 'Gratuit',
                                style: TextStyle(
                                  color: (activity.cost != null && activity.cost! > 0)
                                      ? Colors.orange
                                      : Colors.blue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityListItem(ActivityModel activity) {
    final color = _getCategoryColor(activity.category);
    final icon = _getCategoryIcon(activity.category);
    final isFull = activity.currentParticipants >= activity.maxParticipants;

    return GestureDetector(
      onTap: () {
        _centerOnLocation(activity.latitude, activity.longitude);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActivityDetailsScreen(
              activity: activity.toMap(),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
              ),
              child: ActivityImageWidget(
                activity: activity,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      activity.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
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
                    const SizedBox(height: 4),
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
                          '${activity.dateTime.day}/${activity.dateTime.month}/${activity.dateTime.year} ${activity.dateTime.hour}:${activity.dateTime.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Badges
                    Row(
                      children: [
                        // Category
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 12, color: color),
                              const SizedBox(width: 4),
                              Text(
                                activity.category,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
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
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people,
                                size: 14,
                                color: isFull ? Colors.red : Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${activity.currentParticipants}/${activity.maxParticipants}',
                                style: TextStyle(
                                  color: isFull ? Colors.red : Colors.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
