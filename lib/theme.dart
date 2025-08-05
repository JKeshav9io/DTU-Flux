import 'package:flutter/material.dart';

// DTU Connect: Enhanced Light & Dark Themes for Accessibility & Harmony

class AppThemes {
  static const Color _maroon = Color(0xFF8B0000);
  static const Color _maroonDark = Color(0xFFB71C1C);
  static const Color _mint = Color(0xFF14B8A6);
  static const Color _mintLight = Color(0xFF2DD4BF);

  /// Light Theme
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: _maroon,
      onPrimary: Colors.white,
      secondary: _maroonDark,
      onSecondary: Colors.white,
      background: Colors.white,
      onBackground: Colors.black87,
      surface: Color(0xFFF7F7F7),
      onSurface: Colors.black87,
      error: Color(0xFFD32F2F),
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.white,

    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: _maroon,
      foregroundColor: Colors.white,
      elevation: 1,
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 20,
        color: Colors.white,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),

    // Iconography
    iconTheme: const IconThemeData(color: _maroon),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith((s) {
          if (s.contains(MaterialState.pressed)) return _maroonDark;
          if (s.contains(MaterialState.hovered)) return _maroon.withOpacity(0.9);
          return _maroon;
        }),
        foregroundColor: MaterialStateProperty.all(Colors.white),
        elevation: MaterialStateProperty.all(2),
        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 14, horizontal: 24)),
        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.resolveWith((s) => s.contains(MaterialState.pressed) ? _maroonDark : _maroon),
        overlayColor: MaterialStateProperty.all(_maroon.withOpacity(0.1)),
        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 12, horizontal: 20)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        side: MaterialStateProperty.resolveWith((s) => BorderSide(color: _maroon, width: 1.5)),
        foregroundColor: MaterialStateProperty.all(_maroon),
        overlayColor: MaterialStateProperty.all(_maroon.withOpacity(0.1)),
        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 12, horizontal: 20)),
        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      ),
    ),

    // Dropdowns
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
      ),
      textStyle: const TextStyle(color: Colors.black87),
      menuStyle: MenuStyle(
        backgroundColor: MaterialStateProperty.all(Color(0xFFF7F7F7)),
        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      ),
    ),

    // Chips
    chipTheme: ChipThemeData(
      brightness: Brightness.light,
      backgroundColor: const Color(0xFFF2F2F2),
      disabledColor: const Color(0xFFE0E0E0),
      selectedColor: _maroon,
      secondarySelectedColor: _maroonDark,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      labelStyle: const TextStyle(color: Colors.black87),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),

    // Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: _maroon,
      unselectedItemColor: Colors.black54,
      elevation: 8,
    ),

    // Cards & Dialogs
    cardTheme: const CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      margin: EdgeInsets.all(8),
      color: Color(0xFFF7F7F7),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Color(0xFFF7F7F7),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
      contentTextStyle: TextStyle(fontSize: 16, color: Colors.black87),
    ),

    // Text Styles
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _maroon),
      headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: _maroon),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _maroonDark),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _maroon),
    ),
  );

  /// Dark Theme
  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: _mint,
      onPrimary: Colors.black,
      secondary: _mintLight,
      onSecondary: Colors.black,
      background: Color(0xFF0F172A),
      onBackground: Color(0xFFE2E8F0),
      surface: Color(0xFF1E293B),
      onSurface: Color(0xFFE2E8F0),
      error: Color(0xFFEF4444),
      onError: Colors.black,
    ),
    scaffoldBackgroundColor: const Color(0xFF0F172A),

    appBarTheme: const AppBarTheme(
      backgroundColor: _mint,
      foregroundColor: Colors.black,
      elevation: 1,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black),
      iconTheme: IconThemeData(color: Colors.black),
    ),
    iconTheme: const IconThemeData(color: _mintLight),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith((s) {
          if (s.contains(MaterialState.pressed)) return _mintLight;
          if (s.contains(MaterialState.hovered)) return _mint.withOpacity(0.9);
          return _mint;
        }),
        foregroundColor: MaterialStateProperty.all(Colors.black),
        elevation: MaterialStateProperty.all(2),
        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 14, horizontal: 24)),
        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.resolveWith((s) => s.contains(MaterialState.pressed) ? _mintLight : _mint),
        overlayColor: MaterialStateProperty.all(_mint.withOpacity(0.1)),
        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 12, horizontal: 20)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        side: MaterialStateProperty.all(BorderSide(color: _mintLight, width: 1.5)),
        foregroundColor: MaterialStateProperty.all(_mintLight),
        overlayColor: MaterialStateProperty.all(_mint.withOpacity(0.1)),
        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 12, horizontal: 20)),
        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      ),
    ),

    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF1E293B),
        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
      ),
      textStyle: const TextStyle(color: Color(0xFFE2E8F0)),
      menuStyle: MenuStyle(
        backgroundColor: MaterialStateProperty.all(Color(0xFF1E293B)),
        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      ),
    ),

    chipTheme: ChipThemeData(
      brightness: Brightness.dark,
      backgroundColor: const Color(0xFF1E293B),
      disabledColor: const Color(0xFF374151),
      selectedColor: _mintLight,
      secondarySelectedColor: _mint,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      labelStyle: const TextStyle(color: Color(0xFFE2E8F0)),
      secondaryLabelStyle: const TextStyle(color: Colors.black),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E293B),
      selectedItemColor: _mintLight,
      unselectedItemColor: Colors.white60,
      elevation: 8,
    ),

    cardTheme: const CardThemeData(
      color: Color(0xFF1E293B),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      margin: EdgeInsets.all(8),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Color(0xFF1E293B),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFE2E8F0)),
      contentTextStyle: TextStyle(fontSize: 16, color: Color(0xFFE2E8F0)),
    ),

    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _mintLight),
      headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: _mintLight),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _mint),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFFE2E8F0), height: 1.4),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _mintLight),
    ),
  );
}

/// Search Theme Helper (used in SearchDelegate)
ThemeData searchAppBarTheme(BuildContext context) {
  final base = Theme.of(context);
  return base.copyWith(
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: base.colorScheme.primary,
      foregroundColor: base.colorScheme.onPrimary,
      elevation: 1,
      iconTheme: IconThemeData(color: base.colorScheme.onPrimary),
      titleTextStyle: base.textTheme.headlineSmall?.copyWith(color: base.colorScheme.onPrimary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: TextStyle(color: base.colorScheme.onPrimary.withOpacity(0.7)),
      border: InputBorder.none,
    ),
    textTheme: base.textTheme.copyWith(
      titleLarge: TextStyle(color: base.colorScheme.onPrimary),
    ),
  );
}
