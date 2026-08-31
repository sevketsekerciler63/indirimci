import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Gradient
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFF9F67FF);
  static const Color primaryDark = Color(0xFF5B21B6);

  // Accent / Secondary
  static const Color accent = Color(0xFFF97316);
  static const Color accentLight = Color(0xFFFBBF24);
  static const Color accentDark = Color(0xFFEA580C);

  // Success / Green for savings
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color successDark = Color(0xFF059669);

  // Error / Red
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);

  // Warning
  static const Color warning = Color(0xFFF59E0B);

  // Background - Dark Theme
  static const Color bgDark = Color(0xFF0F0F1A);
  static const Color bgDarkSecondary = Color(0xFF1A1A2E);
  static const Color bgDarkTertiary = Color(0xFF16213E);
  static const Color cardDark = Color(0xFF1E1E32);
  static const Color cardDarkElevated = Color(0xFF252540);

  // Text - Dark Theme
  static const Color textPrimary = Color(0xFFF1F1F6);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textTertiary = Color(0xFF6B7280);

  // Borders
  static const Color borderDark = Color(0xFF2D2D44);
  static const Color borderLight = Color(0xFF3D3D5C);

  // Glassmorphism
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  // Platform colors
  static const Color trendyol = Color(0xFFFF6000);
  static const Color hepsiburada = Color(0xFFFF6600);
  static const Color amazonTR = Color(0xFFFF9900);
  static const Color migros = Color(0xFFE31E24);
  static const Color a101 = Color(0xFFED1C24);
  static const Color bim = Color(0xFFE30613);
  static const Color yemeksepeti = Color(0xFFFA0050);
  static const Color getir = Color(0xFF5D3EBC);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF9333EA), accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [cardDark, cardDarkElevated],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient savingsGradient = LinearGradient(
    colors: [success, Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient fireGradient = LinearGradient(
    colors: [Color(0xFFEF4444), accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
