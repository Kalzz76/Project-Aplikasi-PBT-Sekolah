import 'package:flutter/material.dart';

class AppColors {
  // Primary & Neutrals
  static const Color primary = Color(0xFF4F46E5); // Indigo 600
  static const Color primaryDark = Color(0xFF4338CA); // Indigo 700
  static const Color primaryLight = Color(0xFFEEF2FF); // Indigo 50
  
  static const Color background = Color(0xFFF1F5F9); // Slate 100
  static const Color card = Colors.white;
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  
  // Sidebar
  static const Color sidebarBg = Color(0xFF0F172A); // Slate 900
  static const Color sidebarHeader = Color(0xFF020617); // Slate 950
  static const Color sidebarText = Color(0xFF94A3B8); // Slate 400
  static const Color sidebarTextActive = Color(0xFF818CF8); // Indigo 400
  
  // Semantic
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color successBg = Color(0xFFECFDF5); // Emerald 50
  
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningBg = Color(0xFFFFFBEB); // Amber 50
  
  static const Color danger = Color(0xFFEF4444); // Red 500
  static const Color dangerBg = Color(0xFFFEF2F2); // Red 50
  
  static const Color info = Color(0xFF3B82F6); // Blue 500
  static const Color infoBg = Color(0xFFEFF6FF); // Blue 50
  
  // Text
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  // Dark Mode Variants
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkText = Colors.white;
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  static Color getBgColor(bool isDark) => isDark ? darkBg : background;
  static Color getCardColor(bool isDark) => isDark ? darkCard : card;
  static Color getBorderColor(bool isDark) => isDark ? darkBorder : border;
  static Color getTextColor(bool isDark) => isDark ? darkText : textPrimary;
}
