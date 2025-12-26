import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Colors - Vibrant Purple & Teal
  static const Color primary = Color(0xFF7C3AED); // Vibrant Purple
  static const Color primaryLight = Color(0xFF9B8FEF);
  static const Color primaryDark = Color(0xFF5B21B6);
  
  // Secondary Colors - Vibrant Teal
  static const Color secondary = Color(0xFF06B6D4); // Vibrant Teal
  static const Color secondaryLight = Color(0xFF67E8F9);
  static const Color secondaryDark = Color(0xFF0891B2);
  
  // Accent Colors
  static const Color accent = Color(0xFF00D4AA);
  static const Color accentLight = Color(0xFF4DFFE0);
  static const Color accentDark = Color(0xFF00A88A);
  
  // Colorful Accents
  static const Color pink = Color(0xFFEC4899);
  static const Color orange = Color(0xFFF97316);
  static const Color yellow = Color(0xFFFBBF24);
  static const Color green = Color(0xFF10B981);
  static const Color blue = Color(0xFF3B82F6);
  static const Color purple = Color(0xFF8B5CF6);
  
  // Neutral Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3F5);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textTertiary = Color(0xFFB2BEC3);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  // Status Colors
  static const Color success = Color(0xFF00B894);
  static const Color error = Color(0xFFFF7675);
  static const Color warning = Color(0xFFFDCB6E);
  static const Color info = Color(0xFF74B9FF);
  
  // Dark Mode
  static const Color backgroundDark = Color(0xFF1A1A1A);
  static const Color surfaceDark = Color(0xFF2D2D2D);
  static const Color surfaceVariantDark = Color(0xFF3D3D3D);
  
  // Category Colors
  static const Map<String, Color> categoryColors = {
    'sport': Color(0xFFFF6348),
    'football': Color(0xFF2ECC71),
    'gym': Color(0xFFE74C3C),
    'cafe': Color(0xFF8E44AD),
    'cinema': Color(0xFFF39C12),
    'music': Color(0xFF3498DB),
    'gaming': Color(0xFF9B59B6),
    'food': Color(0xFFE67E22),
    'art': Color(0xFF1ABC9C),
    'study': Color(0xFF34495E),
    'other': Color(0xFF95A5A6),
  };
  
  // Gradient Colors
  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)], // Purple to Teal
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const Gradient accentGradient = LinearGradient(
    colors: [Color(0xFFEC4899), Color(0xFFF97316)], // Pink to Orange
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const Gradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF10B981)], // Teal to Green
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const Gradient warmGradient = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFF97316)], // Yellow to Orange
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
