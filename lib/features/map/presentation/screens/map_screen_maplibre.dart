import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/widgets/translated_bottom_nav.dart';
import 'package:mobile/core/providers/language_provider.dart';
import 'package:mobile/core/services/location_service.dart';
import '../../../activities/presentation/screens/home_screen.dart';
import '../../../activities/presentation/screens/activity_details_screen.dart';
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
  
  // Lieux réels avec vraies coordonnées GPS
  final List<Map<String, dynamic>> _locations = [
    {
      'name': 'Stade Municipal',
      'address': '15 Avenue de la Porte de Sèvres, Paris',
      'lat': 48.8422,
      'lng': 2.2886,
      'type': 'Sports',
      'icon': Icons.sports_soccer,
      'color': Colors.green,
      'activities': ['Football 5v5'],
    },
    {
      'name': 'Gaming Café',
      'address': '45 Rue Quincampoix, Paris',
      'lat': 48.8526,
      'lng': 2.3838,
      'type': 'Gaming',
      'icon': Icons.sports_esports,
      'color': Colors.purple,
      'activities': ['Soirée Gaming'],
    },
    {
      'name': 'Forêt de Fontainebleau',
      'address': 'Fontainebleau',
      'lat': 48.4084,
      'lng': 2.7002,
      'type': 'Nature',
      'icon': Icons.hiking,
      'color': Colors.orange,
      'activities': ['Randonnée en forêt'],
    },
    {
      'name': 'Studio Zen',
      'address': '23 Rue de la Roquette, Paris',
      'lat': 48.8534,
      'lng': 2.3765,
      'type': 'Fitness',
      'icon': Icons.self_improvement,
      'color': Colors.pink,
      'activities': ['Cours de Yoga'],
    },
    {
      'name': 'Parc des Buttes-Chaumont',
      'address': '1 Rue Botzaris, Paris',
      'lat': 48.8799,
      'lng': 2.3828,
      'type': 'Nature',
      'icon': Icons.park,
      'color': Colors.teal,
      'activities': [],
    },
    {
      'name': 'Centre Aquatique',
      'address': '34 Boulevard Vincent Auriol, Paris',
      'lat': 48.8315,
      'lng': 2.3661,
      'type': 'Sports',
      'icon': Icons.pool,
      'color': Colors.blue,
      'activities': [],
    },
  ];

  final List<String> _filters = ['Tous', 'Sports', 'Gaming', 'Nature', 'Fitness'];

  List<Map<String, dynamic>> get _filteredLocations {
    if (_selectedFilter == 'Tous') {
      return _locations;
    }
    return _locations.where((loc) => loc['type'] == _selectedFilter).toList();
  }

  void _centerOnLocation(double lat, double lng) {
    _mapController.move(LatLng(lat, lng), 15.0);
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(localizationProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.map),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () async {
              final position = await LocationService().getCurrentPosition();
              if (position != null) {
                _mapController.move(
                  LatLng(position.latitude, position.longitude),
                  14.0,
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
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
              
              // Markers personnalisés
              MarkerLayer(
                markers: _filteredLocations.map((location) {
                  return Marker(
                    point: LatLng(location['lat'], location['lng']),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () {
                        _showLocationDetails(location);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: location['color'],
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
                          location['icon'],
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Filtres en haut
          Positioned(
            top: 16,
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

          // Liste des lieux en bas
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
                      '${_filteredLocations.length} ${_filteredLocations.length > 1 ? 'lieux trouvés' : 'lieu trouvé'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredLocations.length,
                      itemBuilder: (context, index) {
                        final location = _filteredLocations[index];
                        return _buildLocationCard(location);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(loc),
    );
  }

  Widget _buildLocationCard(Map<String, dynamic> location) {
    return GestureDetector(
      onTap: () {
        _centerOnLocation(location['lat'], location['lng']);
        _showLocationDetails(location);
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: location['color'].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  location['icon'],
                  color: location['color'],
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      location['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location['address'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (location['activities'].isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${location['activities'].length} activité(s)',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLocationDetails(Map<String, dynamic> location) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
                    color: location['color'].withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    location['icon'],
                    color: location['color'],
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location['name'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        location['type'],
                        style: TextStyle(
                          color: location['color'],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location['address'],
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            if (location['activities'].isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Activités disponibles',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...location['activities'].map<Widget>((activityId) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Icon(
                        Icons.event,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      activityId.toString(),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                );
              }).toList(),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _centerOnLocation(location['lat'], location['lng']);
                },
                icon: const Icon(Icons.directions),
                label: const Text('Voir sur la carte'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(dynamic loc) {
    return TranslatedBottomNav(
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
    );
  }
}
