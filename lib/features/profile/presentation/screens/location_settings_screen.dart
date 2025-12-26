import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_colors.dart';

class LocationSettingsScreen extends StatefulWidget {
  const LocationSettingsScreen({super.key});

  @override
  State<LocationSettingsScreen> createState() => _LocationSettingsScreenState();
}

class _LocationSettingsScreenState extends State<LocationSettingsScreen> {
  bool _shareLocation = true;
  bool _showPreciseLocation = false;
  String _currentCity = 'Paris, France';
  double _searchRadius = 10.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Localisation'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.location_on,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Gérez votre localisation',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Contrôlez comment votre position est utilisée',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Partage de localisation
          _buildSection(
            title: 'Partage de localisation',
            children: [
              SwitchListTile(
                value: _shareLocation,
                onChanged: (value) {
                  setState(() {
                    _shareLocation = value;
                  });
                },
                title: const Text('Partager ma position'),
                subtitle: const Text(
                  'Permet aux autres utilisateurs de voir votre position approximative',
                ),
                secondary: Icon(
                  Icons.share_location,
                  color: AppColors.primary,
                ),
                activeThumbColor: AppColors.primary,
              ),
              SwitchListTile(
                value: _showPreciseLocation,
                onChanged: _shareLocation
                    ? (value) {
                        setState(() {
                          _showPreciseLocation = value;
                        });
                      }
                    : null,
                title: const Text('Position précise'),
                subtitle: const Text(
                  'Afficher votre position exacte plutôt que votre ville',
                ),
                secondary: Icon(
                  Icons.my_location,
                  color: _shareLocation ? AppColors.primary : Colors.grey,
                ),
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),

          // Position actuelle
          _buildSection(
            title: 'Position actuelle',
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Icon(Icons.location_city, color: AppColors.primary),
                ),
                title: const Text('Ville actuelle'),
                subtitle: Text(_currentCity),
                trailing: TextButton(
                  onPressed: _updateLocation,
                  child: const Text('Modifier'),
                ),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Icon(Icons.gps_fixed, color: AppColors.primary),
                ),
                title: const Text('Utiliser ma position GPS'),
                subtitle: const Text('Détecter automatiquement'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _useGPSLocation,
              ),
            ],
          ),

          // Rayon de recherche
          _buildSection(
            title: 'Rayon de recherche',
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Distance maximale',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_searchRadius.toStringAsFixed(0)} km',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _searchRadius,
                      min: 1,
                      max: 50,
                      divisions: 49,
                      label: '${_searchRadius.toStringAsFixed(0)} km',
                      onChanged: (value) {
                        setState(() {
                          _searchRadius = value;
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                    Text(
                      'Les activités dans un rayon de ${_searchRadius.toStringAsFixed(0)} km seront affichées',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Historique des lieux
          _buildSection(
            title: 'Historique',
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Icon(Icons.history, color: AppColors.primary),
                ),
                title: const Text('Lieux récents'),
                subtitle: const Text('3 lieux visités'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Afficher l'historique des lieux
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fonctionnalité à venir'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  child: const Icon(Icons.delete_outline, color: Colors.red),
                ),
                title: const Text(
                  'Effacer l\'historique',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: _clearHistory,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Votre position n\'est jamais partagée sans votre permission.',
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(children: children),
        ),
      ],
    );
  }

  void _updateLocation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la ville'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Ville',
                hintText: 'Ex: Paris, Lyon, Marseille',
                prefixIcon: Icon(Icons.location_city),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  setState(() {
                    _currentCity = value;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ville mise à jour: $value'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _useGPSLocation() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(width: 16),
            Text('Détection de votre position...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    // Simuler la détection GPS
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _currentCity = 'Paris, France (GPS)';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Position GPS détectée'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer l\'historique'),
        content: const Text(
          'Voulez-vous vraiment effacer l\'historique de vos lieux ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Historique effacé'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              'Effacer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
