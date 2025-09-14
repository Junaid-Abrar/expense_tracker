import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF5A52E6);
  static const Color primaryLight = Color(0xFF8B84FF);

  // Secondary Colors
  static const Color secondary = Color(0xFF03DAC6);
  static const Color secondaryDark = Color(0xFF00B8A8);
  static const Color secondaryLight = Color(0xFF52E5D9);

  // Accent Colors
  static const Color accent = Color(0xFFFF6B6B);
  static const Color accentLight = Color(0xFFFF8E8E);

  // Background Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Text Colors
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textLight = Color(0xFFA0AEC0);
  static const Color textDark = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF48BB78);
  static const Color warning = Color(0xFFF6AD55);
  static const Color error = Color(0xFFF56565);
  static const Color info = Color(0xFF4299E1);

  // Category Colors
  static const List<Color> categoryColors = [
    Color(0xFF6C63FF), // Primary
    Color(0xFFFF6B6B), // Red
    Color(0xFF4ECDC4), // Teal
    Color(0xFFFFE66D), // Yellow
    Color(0xFFFF8B94), // Pink
    Color(0xFF95E1D3), // Mint
    Color(0xFFFCE38A), // Light Yellow
    Color(0xFFD6A2E8), // Purple
    Color(0xFF74B9FF), // Blue
    Color(0xFFFD79A8), // Hot Pink
    Color(0xFF81ECEC), // Cyan
    Color(0xFFFAB1A0), // Peach
  ];

  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF6C63FF),
    Color(0xFF03DAC6),
    Color(0xFFFF6B6B),
    Color(0xFFFFE66D),
    Color(0xFF4ECDC4),
    Color(0xFFFF8B94),
    Color(0xFF95E1D3),
    Color(0xFFFCE38A),
  ];

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient incomeGradient = LinearGradient(
    colors: [Color(0xFF48BB78), Color(0xFF68D391)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadow Colors
  static const Color shadow = Color(0x1A000000);
  static const Color shadowDark = Color(0x40000000);

  // Border Colors
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF2D3748);
}