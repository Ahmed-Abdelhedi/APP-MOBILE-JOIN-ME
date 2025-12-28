import 'package:flutter/material.dart';
import 'package:mobile/core/models/activity_model.dart';

/// Widget to display event/activity images from multiple sources
/// Handles: Firebase Storage URLs, predefined assets, and placeholders
class ActivityImageWidget extends StatelessWidget {
  final ActivityModel? activity;
  final String? imageUrl;
  final String? imageAssetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const ActivityImageWidget({
    super.key,
    this.activity,
    this.imageUrl,
    this.imageAssetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    // Priority: explicit params > activity data
    final url = imageUrl ?? activity?.imageUrl;
    final assetPath = imageAssetPath ?? activity?.imageAssetPath;
    final category = activity?.category;

    Widget imageWidget;

    if (url != null && url.isNotEmpty) {
      // Display Firebase Storage image
      imageWidget = Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder(context);
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget(context);
        },
      );
    } else if (assetPath != null && assetPath.isNotEmpty) {
      // For predefined images, always show emoji placeholder
      // (since actual asset files don't exist yet)
      imageWidget = _buildAssetPlaceholder(context, assetPath);
    } else if (category != null && category.isNotEmpty) {
      // Fallback: use category to generate placeholder
      imageWidget = _buildCategoryPlaceholder(context, category);
    } else {
      // No image available
      imageWidget = _buildPlaceholder(context);
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildPlaceholder(BuildContext context) {
    if (placeholder != null) return placeholder!;

    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    if (errorWidget != null) return errorWidget!;

    return Container(
      width: width,
      height: height,
      color: Colors.grey[100],
      child: Center(
        child: Icon(
          Icons.broken_image,
          size: 48,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildAssetPlaceholder(BuildContext context, String assetPath) {
    // Extract emoji/icon from asset path as fallback
    final fileName = assetPath.split('/').last.replaceAll('.png', '');
    final iconMap = {
      'sports': '⚽',
      'football': '🏟️',
      'gym': '💪',
      'gaming': '🎮',
      'cafe': '☕',
      'cinema': '🎬',
      'music': '🎵',
      'food': '🍕',
      'art': '🎨',
      'study': '📚',
      'travel': '✈️',
      'party': '🎉',
      'work': '💼',
      'meeting': '👥',
      'birthday': '🎂',
      'default': '📅',
    };

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getColorForCategory(fileName),
            _getColorForCategory(fileName).withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Text(
          iconMap[fileName] ?? iconMap['default']!,
          style: TextStyle(
            fontSize: height != null ? height! * 0.4 : 60,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPlaceholder(BuildContext context, String category) {
    // Use category name directly (e.g., "Sports", "Gaming")
    final categoryLower = category.toLowerCase();
    final iconMap = {
      'sports': '⚽',
      'sport': '⚽',
      'football': '🏟️',
      'gym': '💪',
      'fitness': '💪',
      'gaming': '🎮',
      'jeux': '🎮',
      'cafe': '☕',
      'café': '☕',
      'coffee': '☕',
      'cinema': '🎬',
      'cinéma': '🎬',
      'film': '🎬',
      'music': '🎵',
      'musique': '🎵',
      'food': '🍕',
      'nourriture': '🍕',
      'restaurant': '🍽️',
      'art': '🎨',
      'study': '📚',
      'étude': '📚',
      'education': '📚',
      'travel': '✈️',
      'voyage': '✈️',
      'party': '🎉',
      'fête': '🎉',
      'work': '💼',
      'travail': '💼',
      'meeting': '👥',
      'réunion': '👥',
      'birthday': '🎂',
      'anniversaire': '🎂',
      'autre': '📅',
      'other': '📅',
    };

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getColorForCategory(categoryLower),
            _getColorForCategory(categoryLower).withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Text(
          iconMap[categoryLower] ?? '📅',
          style: TextStyle(
            fontSize: height != null ? height! * 0.4 : 60,
          ),
        ),
      ),
    );
  }

  Color _getColorForCategory(String category) {
    final colorMap = {
      'sports': Colors.blue,
      'football': Colors.green,
      'gym': Colors.orange,
      'gaming': Colors.purple,
      'cafe': Colors.brown,
      'cinema': Colors.red,
      'music': Colors.pink,
      'food': Colors.amber,
      'art': Colors.deepPurple,
      'study': Colors.indigo,
      'travel': Colors.teal,
      'party': Colors.deepOrange,
      'work': Colors.blueGrey,
      'meeting': Colors.cyan,
      'birthday': Colors.pinkAccent,
    };
    return colorMap[category] ?? Colors.grey;
  }
}
