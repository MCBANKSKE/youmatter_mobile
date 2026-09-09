import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF5651D6);
  static const Color secondaryColor = Color(0xFF4DD0E1);
  static const Color accentColor = Color(0xFFFF6584);
  static const Color backgroundColor = Color(0xFFF7F9FF);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFAFAFF);
  static const Color errorColor = Color(0xFFFF5252);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFFB0B0C0);
  static const Color dividerColor = Color(0xFFE2E8F0);

  // Dark theme colors
  static const Color darkBackground = Color(0xFF080D1C);
  static const Color darkSurface = Color(0xFF11182B);
  static const Color darkSurfaceSecondary = Color(0xFF17213A);
  static const Color darkTextPrimary = Color(0xFFF5F7FF);
  static const Color darkTextSecondary = Color(0xFFA8B2C7);
  static const Color darkDividerColor = Color(0xFF2D3748);

  // Welcome page branded gradient
  static const Color welcomeBackgroundStart = Color(0xFFFBF5EC);
  static const Color welcomeBackgroundEnd = Color(0xFFF0E7D8);
  static const Color welcomeCardColor = Color(0xFFFEFAF2);

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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: dividerColor, width: 1),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Color(0xFFFFFFFF),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surfaceColor,
      shape: null,
    ),
    dialogTheme: const DialogThemeData(backgroundColor: surfaceColor),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surfaceColor,
            indicatorColor: primaryColor.withValues(alpha: 0.1),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(color: textPrimary, fontSize: 12),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: primaryColor);
        }
        return IconThemeData(color: textSecondary);
      }),
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
      surface: darkSurface,
      surfaceContainer: darkSurfaceSecondary,
      surfaceContainerHigh: Color(0xFF1E293B),
      surfaceContainerHighest: Color(0xFF334155),
      error: errorColor,
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFF000000),
      onSurface: darkTextPrimary,
      onError: Color(0xFFFFFFFF),
    ),
    scaffoldBackgroundColor: darkBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkSurface,
      foregroundColor: darkTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 1,
      titleTextStyle: TextStyle(
        color: darkTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: darkDividerColor, width: 1),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Color(0xFFFFFFFF),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: darkSurface,
      shape: null,
    ),
    dialogTheme: const DialogThemeData(backgroundColor: darkSurface),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkSurface,
            indicatorColor: primaryColor.withValues(alpha: 0.2),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(color: darkTextPrimary, fontSize: 12),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: primaryColor);
        }
        return IconThemeData(color: darkTextSecondary);
      }),
    ),
  );
}
