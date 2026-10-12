import 'package:flutter/material.dart';

/// CampusBites palette, matching the web dashboard and landing page.
class Brand {
  static const tomato = Color(0xFFE3472B); // primary actions, accents
  static const tomatoDeep = Color(0xFFC2361D); // pressed states, emphasis
  static const tomatoTint = Color(0xFFFDEDE8); // selected / soft backgrounds
  static const basil = Color(0xFF1F9E65); // prices, success
  static const saffron = Color(0xFFF5A824); // ratings, highlights
  static const grill = Color(0xFF2B211B); // headings, dark surfaces
  static const cream = Color(0xFFFFF9F0); // page background

  /// "EGP 25" for whole amounts, "EGP 27.50" otherwise.
  static String egp(num value) => value == value.roundToDouble()
      ? 'EGP ${value.toStringAsFixed(0)}'
      : 'EGP ${value.toStringAsFixed(2)}';

  static ThemeData theme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: tomato,
      primary: tomato,
      secondary: basil,
      tertiary: saffron,
      surface: Colors.white,
      brightness: Brightness.light,
    );
    final rounded =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      primaryColor: tomato,
      scaffoldBackgroundColor: cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: cream,
        surfaceTintColor: Colors.transparent,
        foregroundColor: grill,
        elevation: 0,
        titleTextStyle:
            TextStyle(color: grill, fontSize: 20, fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: tomato, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: tomato,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: rounded,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tomatoDeep,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          side: const BorderSide(color: tomato, width: 1.4),
          shape: rounded,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: tomatoDeep),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: tomatoTint,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: tomato,
        unselectedItemColor: Color(0xFF8A817B),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: grill,
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: tomato),
    );
  }
}
