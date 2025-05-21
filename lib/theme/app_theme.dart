// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // --- Light Theme ---
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF007AFF), // Example: A standard blue
    scaffoldBackgroundColor: Colors.grey[100],
    cardColor: Colors.white,
    dividerColor: Colors.grey[300],
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF007AFF),
      elevation: 1,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20),
      titleMedium: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 16),
      bodyLarge: TextStyle(color: Colors.black87, fontSize: 16),
      bodyMedium: TextStyle(color: Colors.black54, fontSize: 14),
      bodySmall: TextStyle(color: Colors.grey[600], fontSize: 12),
      labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // For buttons
    ),
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF007AFF),
      secondary: const Color(0xFF5856D6), // Example: A complementary purple
      surface: Colors.white,
      background: Colors.grey[100]!,
      error: Colors.red.shade700,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black87,
      onBackground: Colors.black87,
      onError: Colors.white,
      brightness: Brightness.light,
      secondaryContainer: Colors.blue.withOpacity(0.1), // For 'You' tag background
    ),
    iconTheme: IconThemeData(color: Colors.grey[800]),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF007AFF),
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF007AFF),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[200],
      hintStyle: TextStyle(color: Colors.grey[500]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: const Color(0xFF007AFF), width: 2),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    dialogBackgroundColor: Colors.white,
  );

  // --- Dark Theme ---
  // Using colors from your AnnouncementCard as a base
  static const Color _darkPrimary = Color(0xFF131E2F);
  static const Color _darkSecondary = Color(0xFF24283B);
  static const Color _darkCard = Color(0xFF1C2F41);
  static const Color _darkAccent = Color(0xFF7AA2F7);
  static const Color _darkTextPrimary = Colors.white;
  static const Color _darkTextSecondary = Color(0xFFA9B1D6); // A light grey/blue for secondary text
  static const Color _darkModalBg = Color(0xFF1A1B26);


  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: _darkAccent, // Using your accent as primary for dark theme
    scaffoldBackgroundColor: _darkPrimary,
    cardColor: _darkCard,
    dividerColor: Colors.grey[700],
    appBarTheme: AppBarTheme(
      backgroundColor: _darkSecondary, // Slightly different from scaffold for depth
      elevation: 1,
      iconTheme: IconThemeData(color: _darkTextSecondary),
      titleTextStyle: TextStyle(
        color: _darkTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(color: _darkTextPrimary, fontWeight: FontWeight.bold, fontSize: 20),
      titleMedium: TextStyle(color: _darkTextPrimary, fontWeight: FontWeight.w600, fontSize: 16),
      bodyLarge: TextStyle(color: _darkTextPrimary.withOpacity(0.9), fontSize: 16),
      bodyMedium: TextStyle(color: _darkTextSecondary, fontSize: 14),
      bodySmall: TextStyle(color: Colors.grey[400], fontSize: 12),
      labelLarge: TextStyle(color: _darkTextPrimary, fontWeight: FontWeight.bold), // For buttons
    ),
    colorScheme: ColorScheme.dark(
      primary: _darkAccent,
      secondary: const Color(0xFFBB86FC), // A common dark theme secondary like Material Design
      surface: _darkCard,
      background: _darkPrimary,
      error: Colors.redAccent.shade100,
      onPrimary: Colors.black, // Text on accent color, adjust if accent is light
      onSecondary: Colors.black,
      onSurface: _darkTextPrimary,
      onBackground: _darkTextPrimary,
      onError: Colors.black,
      brightness: Brightness.dark,
      secondaryContainer: _darkAccent.withOpacity(0.2), // For 'You' tag background
    ),
    iconTheme: IconThemeData(color: _darkTextSecondary),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkAccent,
        foregroundColor: Colors.black, // Text color on accent button
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _darkAccent,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkSecondary,
      hintStyle: TextStyle(color: _darkTextSecondary.withOpacity(0.7)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _darkAccent, width: 2),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: _darkModalBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    dialogBackgroundColor: _darkModalBg,
  );
}
