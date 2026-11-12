import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../core/constants.dart';

class AppTheme {
  AppTheme._();

  static TextStyle? _applyFont(
    TextStyle? Function({TextStyle? textStyle}) fontFn,
    TextStyle? style,
  ) {
    return style == null ? null : fontFn(textStyle: style);
  }

  static TextTheme _buildTextTheme(
    TextTheme base,
    Color primaryText,
    Color secondaryText,
    bool isHindi,
  ) {
    final fontFn = isHindi
        ? GoogleFonts.notoSansDevanagari
        : GoogleFonts.inter;

    final withFont = base.copyWith(
      displayLarge: _applyFont(fontFn, base.displayLarge),
      displayMedium: _applyFont(fontFn, base.displayMedium),
      displaySmall: _applyFont(fontFn, base.displaySmall),
      headlineLarge: _applyFont(fontFn, base.headlineLarge),
      headlineMedium: _applyFont(fontFn, base.headlineMedium),
      headlineSmall: _applyFont(fontFn, base.headlineSmall),
      titleLarge: _applyFont(fontFn, base.titleLarge),
      titleMedium: _applyFont(fontFn, base.titleMedium),
      titleSmall: _applyFont(fontFn, base.titleSmall),
      bodyLarge: _applyFont(fontFn, base.bodyLarge),
      bodyMedium: _applyFont(fontFn, base.bodyMedium),
      bodySmall: _applyFont(fontFn, base.bodySmall),
      labelLarge: _applyFont(fontFn, base.labelLarge),
      labelMedium: _applyFont(fontFn, base.labelMedium),
      labelSmall: _applyFont(fontFn, base.labelSmall),
    );

    return withFont.copyWith(
      headlineSmall: withFont.headlineSmall?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: primaryText,
            height: 1.25,
          ),
      titleLarge: withFont.titleLarge?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: primaryText,
            height: 1.25,
          ),
      titleMedium: withFont.titleMedium?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: primaryText,
            height: 1.3,
          ),
      bodyLarge: withFont.bodyLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: primaryText,
            height: 1.4,
          ),
      bodyMedium: withFont.bodyMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: primaryText,
            height: 1.4,
          ),
      bodySmall: withFont.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: secondaryText,
            height: 1.35,
          ),
      labelSmall: withFont.labelSmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: secondaryText,
          ),
    );
  }

  static ThemeData light({bool isHindi = false}) {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE8F0FE),
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.primaryDark,
      onSecondary: Colors.white,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
      error: AppColors.danger,
      onError: Colors.white,
      outline: AppColors.borderLight,
    );

    final base = ThemeData.light(useMaterial3: true);
    final textTheme = _buildTextTheme(
      base.textTheme,
      AppColors.textPrimaryLight,
      AppColors.textSecondaryLight,
      isHindi,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, AppSpacing.minTapTarget),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, AppSpacing.minTapTarget),
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.borderLight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedColor: AppColors.primary.withValues(alpha: 0.12),
        side: const BorderSide(color: AppColors.borderLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        labelStyle: textTheme.bodySmall?.copyWith(
          color: AppColors.textPrimaryLight,
          fontWeight: FontWeight.w500,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        indicatorColor: AppColors.primary.withValues(alpha: 0.14),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary);
          }
          return const IconThemeData(color: AppColors.textSecondaryLight);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return textTheme.bodySmall?.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondaryLight,
          );
        }),
      ),
    );
  }

  static ThemeData dark({bool isHindi = false}) {
    const scheme = ColorScheme.dark(
      primary: AppColors.primaryDarkMode,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF1A2B4B),
      onPrimaryContainer: Color(0xFFD6E4FF),
      secondary: AppColors.primaryDarkMode,
      onSecondary: Colors.white,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      error: AppColors.dangerDarkMode,
      onError: Colors.white,
      outline: AppColors.borderDark,
    );

    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = _buildTextTheme(
      base.textTheme,
      AppColors.textPrimaryDark,
      AppColors.textSecondaryDark,
      isHindi,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide:
              const BorderSide(color: AppColors.primaryDarkMode, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          borderSide: const BorderSide(color: AppColors.dangerDarkMode),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, AppSpacing.minTapTarget),
          backgroundColor: AppColors.primaryDarkMode,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, AppSpacing.minTapTarget),
          foregroundColor: AppColors.primaryDarkMode,
          side: const BorderSide(color: AppColors.borderDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedColor: AppColors.primaryDarkMode.withValues(alpha: 0.2),
        side: const BorderSide(color: AppColors.borderDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        labelStyle: textTheme.bodySmall?.copyWith(
          color: AppColors.textPrimaryDark,
          fontWeight: FontWeight.w500,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryDarkMode,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        indicatorColor: AppColors.primaryDarkMode.withValues(alpha: 0.22),
        elevation: 4,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primaryDarkMode);
          }
          return const IconThemeData(color: AppColors.textSecondaryDark);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return textTheme.bodySmall?.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.primaryDarkMode
                : AppColors.textSecondaryDark,
          );
        }),
      ),
    );
  }
}
