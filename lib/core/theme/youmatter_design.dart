import 'package:flutter/material.dart';

/// YouMatter design system constants for consistent styling.
class YouMatterColors {
  YouMatterColors._();

  // Brand colors (consistent across themes)
  static const Color purple = Color(0xFF6C63FF);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color blue = Color(0xFF3B82F6);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color green = Color(0xFF10B981);
  static const Color red = Color(0xFFEF4444);
  static const Color orange = Color(0xFFF59E0B);

  // Light theme specific
  static const Color lightBackground = Color(0xFFF7F9FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSecondary = Color(0xFFF0F0F7);
  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Dark theme specific
  static const Color darkBackground = Color(0xFF080D1C);
  static const Color darkSurface = Color(0xFF11182B);
  static const Color darkSurfaceSecondary = Color(0xFF17213A);
  static const Color darkTextPrimary = Color(0xFFF5F7FF);
  static const Color darkTextSecondary = Color(0xFFA8B2C7);
  static const Color darkBorder = Color(0xFF2D3748);
}

/// Gradient definitions for YouMatter interactive elements.
class YouMatterGradients {
  YouMatterGradients._();

  /// Purple to violet gradient for "I want to talk" action.
  static const LinearGradient talkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [YouMatterColors.purple, YouMatterColors.violet],
  );

  /// Blue to cyan gradient for "I'm available to listen" action.
  static const LinearGradient listenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [YouMatterColors.blue, YouMatterColors.cyan],
  );

  /// Subtle background gradient for cards.
  static const LinearGradient subtleGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00000000), Color(0x08000000)],
  );
}

/// Consistent spacing values throughout the app.
class YouMatterSpacing {
  YouMatterSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Consistent border radius values.
class YouMatterRadius {
  YouMatterRadius._();

  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 999.0;
}

/// Consistent shadow definitions.
class YouMatterShadows {
  YouMatterShadows._();

  static List<BoxShadow> get card => [
        BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get elevated => [
        BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get button => [
        BoxShadow(
                    color: YouMatterColors.purple.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}