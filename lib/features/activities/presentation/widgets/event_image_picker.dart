import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/constants/event_images.dart';

/// Result of image selection
class ImageSelectionResult {
  final String? imageUrl; // For uploaded images
  final String? assetPath; // For predefined images
  final File? imageFile; // For gallery images before upload

  const ImageSelectionResult({
    this.imageUrl,
    this.assetPath,
    this.imageFile,
  });

  bool get hasImage => imageUrl != null || assetPath != null || imageFile != null;
  bool get isAsset => assetPath != null;
  bool get isUploaded => imageUrl != null;
  bool get needsUpload => imageFile != null && imageUrl == null;
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImageSelectionResult &&
        other.imageUrl == imageUrl &&
        other.assetPath == assetPath &&
        other.imageFile?.path == imageFile?.path;
  }

  @override
  int get hashCode => Object.hash(imageUrl, assetPath, imageFile?.path);
}

/// Widget for selecting event images (gallery or predefined)
class EventImagePicker extends StatefulWidget {
  final Function(ImageSelectionResult) onImageSelected;
  final ImageSelectionResult? initialImage;

  const EventImagePicker({
    super.key,
    required this.onImageSelected,
    this.initialImage,
  });

  @override
  State<EventImagePicker> createState() => _EventImagePickerState();
}

class _EventImagePickerState extends State<EventImagePicker> {
  final ImagePicker _imagePicker = ImagePicker();
  ImageSelectionResult? _selectedImage;

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.initialImage;
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        debugPrint('📷 Image picked from gallery: ${image.path}');
        debugPrint('📷 File exists: ${file.existsSync()}');
        
        final result = ImageSelectionResult(
          imageFile: file,
        );
        
        if (mounted) {
          setState(() {
            _selectedImage = result;
          });
          widget.onImageSelected(result);
          debugPrint('📷 Image selection updated, hasImage: ${_selectedImage?.hasImage}');
        }
      }
    } catch (e) {
      debugPrint('❌ Error picking image from gallery: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPredefinedImagesDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Choisir une image prédéfinie',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Grid of predefined images
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: EventImages.allOptions.length,
                itemBuilder: (context, index) {
                  final option = EventImages.allOptions[index];
                  final isSelected = _selectedImage?.assetPath == option.path;

                  return GestureDetector(
                    onTap: () {
                      final result = ImageSelectionResult(
                        assetPath: option.path,
                      );
                      setState(() => _selectedImage = result);
                      widget.onImageSelected(result);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey[300]!,
                          width: isSelected ? 3 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Real image from assets
                            Image.asset(
                              option.path,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback to emoji if image not found
                                return Container(
                                  color: Colors.grey[200],
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        option.icon,
                                        style: const TextStyle(fontSize: 40),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        option.label,
                                        style: const TextStyle(fontSize: 10),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            // Label overlay at bottom
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                                child: Text(
                                  '${option.icon} ${option.label}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            // Selection indicator
                            if (isSelected)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔄 EventImagePicker build - hasImage: ${_selectedImage?.hasImage}, imageFile: ${_selectedImage?.imageFile?.path}');
    
    return Container(
      key: ValueKey(_selectedImage?.imageFile?.path ?? _selectedImage?.assetPath ?? _selectedImage?.imageUrl ?? 'empty'),
      height: 220,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: _selectedImage?.hasImage == true
          ? _buildSelectedImage()
          : _buildEmptyState(),
    );
  }

  Widget _buildSelectedImage() {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _buildImageWidget(),
        ),
        // Actions overlay
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              _buildActionButton(
                icon: Icons.edit,
                onPressed: _showOptionsDialog,
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.delete,
                onPressed: () {
                  setState(() => _selectedImage = null);
                  widget.onImageSelected(const ImageSelectionResult());
                },
              ),
            ],
          ),
        ),
        // Type badge
        if (_selectedImage?.isAsset == true)
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Image prédéfinie',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageWidget() {
    debugPrint('🖼️ _buildImageWidget called - imageFile: ${_selectedImage?.imageFile}, assetPath: ${_selectedImage?.assetPath}, imageUrl: ${_selectedImage?.imageUrl}');
    
    if (_selectedImage?.imageFile != null) {
      debugPrint('🖼️ Rendering Image.file with path: ${_selectedImage!.imageFile!.path}');
      return Image.file(
        _selectedImage!.imageFile!,
        key: ValueKey(_selectedImage!.imageFile!.path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ Error loading file image: $error');
          return _buildPlaceholder();
        },
      );
    } else if (_selectedImage?.assetPath != null) {
      debugPrint('🖼️ Rendering Image.asset');
      return Image.asset(
        _selectedImage!.assetPath!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else if (_selectedImage?.imageUrl != null) {
      return Image.network(
        _selectedImage!.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return InkWell(
      onTap: _showOptionsDialog,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Ajouter une photo',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Galerie ou images prédéfinies',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Choisir depuis la galerie'),
                subtitle: const Text('Sélectionner une photo de votre appareil'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.collections, color: Colors.green),
                title: const Text('Images prédéfinies'),
                subtitle: const Text('Choisir parmi nos images thématiques'),
                onTap: () {
                  Navigator.pop(context);
                  _showPredefinedImagesDialog();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
