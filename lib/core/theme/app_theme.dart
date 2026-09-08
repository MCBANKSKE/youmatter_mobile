import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF5651D6);
  static const Color secondaryColor = Color(0xFF4DD0E1);
  static const Color accentColor = Color(0xFFFF6584);
  static const Color backgroundColor = Color(0xFFF7F7FC);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFAFAFF);
  static const Color errorColor = Color(0xFFFF5252);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color textPrimary = Color(0xFF2D2D3A);
  static const Color textSecondary = Color(0xFF8A8A9E);
  static const Color textHint = Color(0xFFB0B0C0);
  static const Color dividerColor = Color(0xFFE8E8F0);

  // Welcome page branded gradient — always light so the logo's dark-blue
  // elements remain visible regardless of the device's theme setting.
  static const Color welcomeBackgroundStart = Color(0xFFF7F7FC);
  static const Color welcomeBackgroundEnd = Color(0xFFE8F0FF);

  static const ColorScheme colorScheme = ColorScheme(
    primary: primaryColor,
    primaryContainer: Color(0xFFE1E0FF),
    secondary: secondaryColor,
    secondaryContainer: Color(0xFFB2EBF2),
    surface: surfaceColor,
    surfaceContainer: Color(0xFFF0F0F7),
    surfaceContainerHigh: Color(0xFFE8E8F0),
    surfaceContainerHighest: Color(0xFFD8D8E6),
    error: errorColor,
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFF000000),
    onSurface: textPrimary,
    onError: Color(0xFFFFFFFF),
    brightness: Brightness.light,
  );

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: backgroundColor,
    brightness: Brightness.light,
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceColor,
      foregroundColor: textPrimary,
      elevation: 0,
      scrolledUnderElevation: 1,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 0,
      shape: const ContinuousRectangleBorder(),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Color(0xFFFFFFFF),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surfaceColor,
      shape: null,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: surfaceColor,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      primaryContainer: Color(0xFF3A3899),
      secondary: secondaryColor,
      secondaryContainer: Color(0xFF006978),
      surface: Color(0xFF121212),
      surfaceContainer: Color(0xFF1E1E1E),
      surfaceContainerHigh: Color(0xFF2A2A2A),
      surfaceContainerHighest: Color(0xFF333333),
      error: errorColor,
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFF000000),
      onSurface: Color(0xFFE0E0E0),
      onError: Color(0xFFFFFFFF),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
  );
}