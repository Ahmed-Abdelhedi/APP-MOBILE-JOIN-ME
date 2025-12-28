import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/models/activity_model.dart';
import 'package:mobile/core/providers/firebase_providers.dart';
import 'package:mobile/core/services/activity_service.dart';
import 'package:mobile/features/activities/presentation/screens/location_picker_screen.dart';
import 'package:mobile/features/activities/presentation/widgets/event_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateActivityScreen extends ConsumerStatefulWidget {
  const CreateActivityScreen({super.key});

  @override
  ConsumerState<CreateActivityScreen> createState() =>
      _CreateActivityScreenState();
}

class _CreateActivityScreenState extends ConsumerState<CreateActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  
  LatLng? _selectedCoordinates; // Stocker les coordonnées GPS du lieu
  ImageSelectionResult? _selectedImage; // Stocker l'image sélectionnée
  
  String _selectedCategory = 'Sports';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 0);
  int _maxParticipants = 10;

  final categories = [
    'Sports',
    'Gaming',
    'Nature',
    'Fitness',
    'Culture',
    'Food',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer une activité'),
        actions: [
          TextButton(
            onPressed: _handleSubmit,
            child: const Text('Publier'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            EventImagePicker(
              initialImage: _selectedImage,
              onImageSelected: (result) {
                setState(() => _selectedImage = result);
              },
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _titleController,
              label: 'Titre',
              hint: 'Ex: Match de football 5v5',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un titre';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildCategorySelector(),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Décrivez votre activité...',
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer une description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildLocationField(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildDatePicker()),
                const SizedBox(width: 16),
                Expanded(child: _buildTimePicker()),
              ],
            ),
            const SizedBox(height: 16),
            _buildParticipantsSlider(),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _priceController,
              label: 'Prix (€)',
              hint: '0',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (double.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Publier l\'activité',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catégorie',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: categories.map((category) {
            final isSelected = _selectedCategory == category;
            return ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategory = category);
                }
              },
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    return InkWell(
      onTap: _showLocationPicker,
      child: IgnorePointer(
        child: TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            labelText: 'Lieu',
            hintText: 'Appuyez pour choisir sur la carte',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: const Icon(Icons.map),
            prefixIcon: const Icon(Icons.location_on),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez sélectionner un lieu';
            }
            return null;
          },
        ),
      ),
    );
  }

  Future<void> _showLocationPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLocation: _locationController.text.isNotEmpty 
              ? _locationController.text 
              : null,
          initialCoordinates: _selectedCoordinates,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _locationController.text = result['address'] as String;
        _selectedCoordinates = result['coordinates'] as LatLng;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lieu sélectionné avec succès'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          setState(() => _selectedDate = date);
        }
      },
      child: IgnorePointer(
        child: TextFormField(
          decoration: InputDecoration(
            labelText: 'Date',
            hintText: 'Sélectionner',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          controller: TextEditingController(
            text:
                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: _selectedTime,
        );
        if (time != null) {
          setState(() => _selectedTime = time);
        }
      },
      child: IgnorePointer(
        child: TextFormField(
          decoration: InputDecoration(
            labelText: 'Heure',
            hintText: 'Sélectionner',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: const Icon(Icons.access_time),
          ),
          controller: TextEditingController(
            text: '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}',
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantsSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nombre maximum de participants',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _maxParticipants.toDouble(),
                min: 2,
                max: 50,
                divisions: 48,
                label: _maxParticipants.toString(),
                onChanged: (value) {
                  setState(() => _maxParticipants = value.toInt());
                },
              ),
            ),
            Container(
              width: 60,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_maxParticipants',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Vérifier que les coordonnées sont définies
    if (_selectedCoordinates == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un lieu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Afficher le loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Récupérer l'utilisateur actuel
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Combiner date et heure
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Créer l'activité dans Firestore
      final firestore = ref.read(firestoreProvider);
      
      // Prepare image data
      String? imageUrl;
      String? imageAssetPath;
      
      // Handle image based on selection type
      if (_selectedImage != null && _selectedImage!.hasImage) {
        if (_selectedImage!.isAsset) {
          // Use predefined asset path
          imageAssetPath = _selectedImage!.assetPath;
        } else if (_selectedImage!.needsUpload && _selectedImage!.imageFile != null) {
          // Upload gallery image first (we'll update after getting the activity ID)
          // For now, mark it as pending upload
        }
      }
      
      final activityData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'location': _locationController.text.trim(),
        'latitude': _selectedCoordinates!.latitude,
        'longitude': _selectedCoordinates!.longitude,
        'dateTime': Timestamp.fromDate(dateTime),
        'maxParticipants': _maxParticipants,
        'currentParticipants': 1, // Le créateur est le premier participant
        'cost': _priceController.text.isEmpty 
            ? null 
            : double.tryParse(_priceController.text),
        'imageUrl': imageUrl, // Will be updated after upload if needed
        'imageAssetPath': imageAssetPath, // Store asset path for predefined images
        'creatorId': currentUser.uid,
        'creatorName': currentUser.displayName ?? currentUser.email ?? 'Utilisateur',
        'participants': [currentUser.uid], // Le créateur est automatiquement participant
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'upcoming',
      };

      final activityDocRef = await firestore.collection('activities').add(activityData);
      final newActivityId = activityDocRef.id;

      // Upload gallery image to Firebase Storage if needed
      if (_selectedImage != null && _selectedImage!.needsUpload && _selectedImage!.imageFile != null) {
        try {
          final activityService = ref.read(activityServiceProvider);
          final uploadedImageUrl = await activityService.uploadActivityImage(
            _selectedImage!.imageFile!,
            newActivityId,
          );
          
          // Update activity with uploaded image URL
          await activityService.updateActivityImage(newActivityId, uploadedImageUrl);
          print('✅ Image uploaded and activity updated with URL: $uploadedImageUrl');
        } catch (uploadError) {
          print('❌ Error uploading image: $uploadError');
          // Don't block activity creation if image upload fails
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ Image non téléchargée: ${uploadError.toString()}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      // Fermer le loading
      if (mounted) Navigator.of(context).pop();

      // Créer un chat pour cette activité
      try {
        print('🔄 Tentative création chat pour activité: $newActivityId');
        print('📝 Titre: ${_titleController.text.trim()}');
        print('👤 Creator: ${currentUser.uid} - ${currentUser.displayName ?? currentUser.email}');
        
        final chatService = ref.read(chatServiceProvider);
        final chatId = await chatService.createChatForActivity(
          activityId: newActivityId,
          activityTitle: _titleController.text.trim(),
          creatorId: currentUser.uid,
          creatorName: currentUser.displayName ?? currentUser.email ?? 'Utilisateur',
        );
        print('✅ Chat créé avec succès! ID: $chatId pour activité: $newActivityId');
      } catch (chatError) {
        print('❌ ERREUR CRÉATION CHAT: $chatError');
        print('📍 ActivityId: $newActivityId');
        // Ne pas bloquer si le chat échoue, mais afficher un warning
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Chat non créé: ${chatError.toString()}'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }

      // Afficher message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Activité créée avec succès !'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Retourner à l'écran précédent
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Fermer le loading
      if (mounted) Navigator.of(context).pop();

      // Afficher l'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Erreur création activité: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}
