import 'package:material_ui/material_ui.dart';

class AppColors {
  AppColors._();

  // Brand & Semantic (Light)
  static const Color primary = Color(0xFF1F6FEB);
  static const Color primaryDark = Color(0xFF0B3D91);
  static const Color success = Color(0xFF1E9E5A);
  static const Color warning = Color(0xFFF5A524);
  static const Color danger = Color(0xFFD64545);

  // Light Surfaces & Text
  static const Color backgroundLight = Color(0xFFF6F8FB);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color borderLight = Color(0xFFE5E7EB);

  // Dark Surfaces & Slightly Lightened Accents
  static const Color primaryDarkMode = Color(0xFF4C8EFF);
  static const Color successDarkMode = Color(0xFF34C176);
  static const Color warningDarkMode = Color(0xFFFFB74D);
  static const Color dangerDarkMode = Color(0xFFEF6B6B);
  static const Color backgroundDark = Color(0xFF0E1116);
  static const Color surfaceDark = Color(0xFF171B22);
  static const Color textPrimaryDark = Color(0xFFF3F4F6);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color borderDark = Color(0xFF282E38);
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double cardRadius = 16;
  static const double buttonRadius = 12;
  static const double minTapTarget = 48;
}

class AppLimits {
  AppLimits._();

  static const int freeTierItemLimit = 5;
  static const int expiringSoonDays = 30;
  static const int expiringTabDays = 90;
  static const int maxImageLongSide = 1600;
  static const int imageQuality = 80;
  static const Duration draftRetention = Duration(hours: 24);
}
