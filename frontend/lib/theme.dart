import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color _darkBackgroundColor = Color(0xFF1A1A2E); // Slightly lighter for glassmorphism
  static const Color _darkPrimaryColor = Color(0xFF00BCD4); // Cyan
  static const Color _darkAccentColor = Color(0xFFE91E63); // Pink
  static const Color _darkTextColor = Colors.white;
  static const Color _darkHintColor = Colors.white54;
  static const Color _darkCardColor = Color(0x441a237e); // More translucent
  static const Color _glassyColor = Color(0x33FFFFFF); // More translucent white
  static const Color _lightTextColor = Colors.black;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkBackgroundColor,
      primaryColor: _darkPrimaryColor,
      colorScheme: const ColorScheme.dark(
        primary: _darkPrimaryColor,
        secondary: _darkAccentColor,
        surface: _darkCardColor,
        background: _darkBackgroundColor,
        onPrimary: _darkTextColor,
        onSecondary: _darkTextColor,
        onSurface: _darkTextColor,
        onBackground: _darkTextColor,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: _darkTextColor,
        displayColor: _darkTextColor,
      ),
      appBarTheme: const AppBarTheme(
        color: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _darkTextColor),
        titleTextStyle: TextStyle(
          color: _darkTextColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static ThemeData get glassTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.transparent,
      primaryColor: _darkPrimaryColor,
      colorScheme: const ColorScheme.light(
        primary: _darkPrimaryColor,
        secondary: _darkAccentColor,
        surface: _glassyColor,
        background: Colors.transparent,
        onPrimary: _lightTextColor,
        onSecondary: _lightTextColor,
        onSurface: _lightTextColor,
        onBackground: _lightTextColor,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: _darkTextColor,
        displayColor: _darkTextColor,
      ),
      appBarTheme: const AppBarTheme(
        color: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _darkTextColor),
        titleTextStyle: TextStyle(
          color: _darkTextColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

