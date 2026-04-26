import 'package:flutter/material.dart';

class AppTheme {
  // Clean color palette - minimalist and professional
  static const Color primaryColor = Color(0xFF1A1A1A); // Deep black
  static const Color secondaryColor = Color(0xFF6B6B6B); // Medium gray
  static const Color accentColor = Color(0xFF2196F3); // Clean blue
  static const Color backgroundColor = Color(0xFFFAFAFA); // Off-white
  static const Color surfaceColor = Color(0xFFFFFFFF); // Pure white
  static const Color errorColor = Color(0xFFE53935); // Clean red
  static const Color successColor = Color(0xFF43A047); // Clean green
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color dividerColor = Color(0xFFE0E0E0);

  // Dark theme colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);

  // ─── Preset Colors ───
  static const List<Map<String, dynamic>> presetColors = [
    {'name': 'Purple', 'color': Color(0xFFC084FC)},
    {'name': 'Blue', 'color': Color(0xFF3B82F6)},
    {'name': 'Pink', 'color': Color(0xFFEC4899)},
    {'name': 'Orange', 'color': Color(0xFFF97316)},
    {'name': 'Green', 'color': Color(0xFF22C55E)},
    {'name': 'Teal', 'color': Color(0xFF14B8A6)},
    {'name': 'Red', 'color': Color(0xFFEF4444)},
    {'name': 'Indigo', 'color': Color(0xFF6366F1)},
    {'name': 'Amber', 'color': Color(0xFFF59E0B)},
    {'name': 'Rose', 'color': Color(0xFFF43F5E)},
  ];

  static const Color _defaultPrimary = Color(0xFFC084FC);

  // ─── Color Helpers ───

  static Color getColorFromHex(String? hex) {
    if (hex == null || hex.isEmpty) return _defaultPrimary;
    try {
      final clean = hex.replaceFirst('#', '');
      if (clean.length != 6) return _defaultPrimary;
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return _defaultPrimary;
    }
  }

  static String colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  // ─── Static themes (backward compat, uses default white/black primary) ───

  static ThemeData lightTheme = _buildLight(primaryColor);
  static ThemeData darkTheme = _buildDark(Colors.white);

  // ─── Dynamic theme builders ───

  static ThemeData buildLightTheme(Color primary) => _buildLight(primary);
  static ThemeData buildDarkTheme(Color primary) => _buildDark(primary);

  static ThemeData _buildLight(Color primary) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),

      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: dividerColor, width: 1),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: dividerColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -1),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.5),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: textPrimary, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: textPrimary, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary, height: 1.5),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: textSecondary),
      ),

      dividerTheme: const DividerThemeData(color: dividerColor, thickness: 1, space: 1),
    );
  }

  static ThemeData _buildDark(Color primary) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: darkTextSecondary,
        surface: darkSurface,
        error: errorColor,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),

      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: darkBackground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: darkTextPrimary, letterSpacing: -1),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: darkTextPrimary, letterSpacing: -0.5),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: darkTextPrimary, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: darkTextPrimary),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: darkTextPrimary),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: darkTextPrimary, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: darkTextPrimary, height: 1.5),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: darkTextSecondary),
      ),

      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.1),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
