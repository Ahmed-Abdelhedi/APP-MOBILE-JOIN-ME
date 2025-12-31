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
  final String? activityId;
  final Map<String, dynamic>? activity;

  const CreateActivityScreen({
    super.key,
    this.activityId,
    this.activity,
  });

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
  void initState() {
    super.initState();
    
    // If editing an existing activity, populate the form
    if (widget.activityId != null && widget.activity != null) {
      _titleController.text = widget.activity!['title'] ?? '';
      _descriptionController.text = widget.activity!['description'] ?? '';
      _locationController.text = widget.activity!['location'] ?? '';
      _priceController.text = widget.activity!['price']?.toString() ?? '';
      _selectedCategory = widget.activity!['category'] ?? 'Sports';
      _maxParticipants = widget.activity!['maxParticipants'] ?? 10;
      
      // Parse date and time
      if (widget.activity!['dateTime'] != null) {
        final dateTimeValue = widget.activity!['dateTime'];
        final DateTime dateTime;
        
        // Check if it's a Timestamp or DateTime
        if (dateTimeValue is Timestamp) {
          dateTime = dateTimeValue.toDate();
        } else if (dateTimeValue is DateTime) {
          dateTime = dateTimeValue;
        } else {
          dateTime = DateTime.now();
        }
        
        _selectedDate = dateTime;
        _selectedTime = TimeOfDay.fromDateTime(dateTime);
      }
      
      // Parse coordinates
      if (widget.activity!['coordinates'] != null) {
        final coords = widget.activity!['coordinates'] as Map<String, dynamic>;
        _selectedCoordinates = LatLng(coords['latitude'], coords['longitude']);
      }
      
      // Parse image
      if (widget.activity!['imageUrl'] != null) {
        _selectedImage = ImageSelectionResult(
          imageUrl: widget.activity!['imageUrl'],
        );
      } else if (widget.activity!['imageAssetPath'] != null) {
        _selectedImage = ImageSelectionResult(
          assetPath: widget.activity!['imageAssetPath'],
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.activityId != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier l\'activité' : 'Créer une activité'),
        actions: [
          TextButton(
            onPressed: _handleSubmit,
            child: Text(
              isEditing ? 'Enregistrer les modifications' : 'Publier l\'événement',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
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
    try {
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
          _locationController.text = result['address']?.toString() ?? '';
          if (result['coordinates'] != null) {
            _selectedCoordinates = result['coordinates'] as LatLng;
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lieu sélectionné avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error in location picker: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection du lieu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    final isEditing = widget.activityId != null;
    
    // En mode édition, la validation est plus souple
    if (!isEditing) {
      // En mode création, tous les champs sont obligatoires
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
    } else {
      // En mode édition, au moins un champ doit avoir une valeur
      if (_formKey.currentState!.validate()) {
        // Validation OK, on continue
      }
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

      final firestore = ref.read(firestoreProvider);
      
      // Prepare image data
      String? imageUrl;
      String? imageAssetPath;
      
      if (_selectedImage != null && _selectedImage!.hasImage) {
        if (_selectedImage!.isAsset) {
          imageAssetPath = _selectedImage!.assetPath;
        } else if (_selectedImage!.needsUpload && _selectedImage!.imageFile != null) {
          // Mark as pending upload
        }
      }
      
      // En mode édition, ne mettre à jour que les champs modifiés
      final Map<String, dynamic> activityData = {};
      
      if (isEditing) {
        // En mode édition : mettre à jour seulement les champs remplis
        if (_titleController.text.trim().isNotEmpty) {
          activityData['title'] = _titleController.text.trim();
        }
        if (_descriptionController.text.trim().isNotEmpty) {
          activityData['description'] = _descriptionController.text.trim();
        }
        if (_locationController.text.trim().isNotEmpty) {
          activityData['location'] = _locationController.text.trim();
        }
        if (_selectedCoordinates != null) {
          activityData['latitude'] = _selectedCoordinates!.latitude;
          activityData['longitude'] = _selectedCoordinates!.longitude;
        }
        activityData['category'] = _selectedCategory;
        activityData['dateTime'] = Timestamp.fromDate(dateTime);
        activityData['maxParticipants'] = _maxParticipants;
        if (_priceController.text.isNotEmpty) {
          activityData['cost'] = double.tryParse(_priceController.text);
        }
        if (imageUrl != null) activityData['imageUrl'] = imageUrl;
        if (imageAssetPath != null) activityData['imageAssetPath'] = imageAssetPath;
      } else {
        // En mode création : tous les champs sont requis
        activityData['title'] = _titleController.text.trim();
        activityData['description'] = _descriptionController.text.trim();
        activityData['category'] = _selectedCategory;
        activityData['location'] = _locationController.text.trim();
        activityData['latitude'] = _selectedCoordinates!.latitude;
        activityData['longitude'] = _selectedCoordinates!.longitude;
        activityData['dateTime'] = Timestamp.fromDate(dateTime);
        activityData['maxParticipants'] = _maxParticipants;
        activityData['cost'] = _priceController.text.isEmpty 
            ? null 
            : double.tryParse(_priceController.text);
        activityData['imageUrl'] = imageUrl;
        activityData['imageAssetPath'] = imageAssetPath;
      }

      if (isEditing) {
        // UPDATE existing activity
        await firestore.collection('activities').doc(widget.activityId).update(activityData);
        
        // Notify all participants about the change
        final activityDoc = await firestore.collection('activities').doc(widget.activityId).get();
        final participants = List<String>.from(activityDoc.data()?['participants'] ?? []);
        final activityTitle = _titleController.text.trim();
        
        for (final participantId in participants) {
          if (participantId != currentUser.uid) {
            await firestore
                .collection('users')
                .doc(participantId)
                .collection('notifications')
                .add({
              'type': 'event_updated',
              'title': 'Événement modifié',
              'body': 'L\'événement "$activityTitle" a été mis à jour par l\'organisateur.',
              'activityId': widget.activityId,
              'activityTitle': activityTitle,
              'read': false,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        }

        // Upload image if needed
        if (_selectedImage != null && _selectedImage!.needsUpload && _selectedImage!.imageFile != null) {
          try {
            final activityService = ref.read(activityServiceProvider);
            final uploadedImageUrl = await activityService.uploadActivityImage(
              _selectedImage!.imageFile!,
              widget.activityId!,
            );
            await activityService.updateActivityImage(widget.activityId!, uploadedImageUrl);
          } catch (uploadError) {
            print('❌ Error uploading image: $uploadError');
          }
        }

        if (mounted) Navigator.of(context).pop();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Événement modifié avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } else {
        // CREATE new activity
        activityData['currentParticipants'] = 1;
        activityData['creatorId'] = currentUser.uid;
        activityData['creatorName'] = currentUser.displayName ?? currentUser.email ?? 'Utilisateur';
        activityData['participants'] = [currentUser.uid];
        activityData['createdAt'] = FieldValue.serverTimestamp();
        activityData['status'] = 'upcoming';

        final activityDocRef = await firestore.collection('activities').add(activityData);
        final newActivityId = activityDocRef.id;

        // Upload image if needed
        if (_selectedImage != null && _selectedImage!.needsUpload && _selectedImage!.imageFile != null) {
          try {
            final activityService = ref.read(activityServiceProvider);
            final uploadedImageUrl = await activityService.uploadActivityImage(
              _selectedImage!.imageFile!,
              newActivityId,
            );
            await activityService.updateActivityImage(newActivityId, uploadedImageUrl);
          } catch (uploadError) {
            print('❌ Error uploading image: $uploadError');
          }
        }

        if (mounted) Navigator.of(context).pop();

        // Create chat
        try {
          final chatService = ref.read(chatServiceProvider);
          await chatService.createChatForActivity(
            activityId: newActivityId,
            activityTitle: _titleController.text.trim(),
            creatorId: currentUser.uid,
            creatorName: currentUser.displayName ?? currentUser.email ?? 'Utilisateur',
          );
        } catch (chatError) {
          print('❌ ERREUR CRÉATION CHAT: $chatError');
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
          Navigator.of(context).pop();
        }
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
