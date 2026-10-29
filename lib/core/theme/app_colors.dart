import 'package:flutter/material.dart';

/**
 * ResQAI Design System Color Tokens
 * Brights, Greenish & Pink Modern Theme Palette
 */
class AppColors {
  // ==========================================================================
  // Core Greenish & Pink Palette Tokens
  // ==========================================================================
  static const Color primaryGreen = Color(0xFF059669);    // Core primary emerald
  static const Color emeraldGreen = Color(0xFF10B981);    // Bright vibrant mint/emerald
  static const Color mintGreen = Color(0xFF34D399);       // Fresh accent
  static const Color lightGreen = Color(0xFFECFDF5);      // Soft green background wash
  static const Color deepGreen = Color(0xFF064E3B);       // High-contrast forest green

  static const Color primaryPink = Color(0xFFEC4899);     // Radiant energetic pink
  static const Color brightPink = Color(0xFFF43F5E);      // Punchy coral-pink / emergency
  static const Color deepPink = Color(0xFFBE185D);        // Deep berry pink
  static const Color softPink = Color(0xFFFDF2F8);        // Soft pink background wash
  static const Color magenta = Color(0xFFDB2777);         // Bold magenta accent
  static const Color neonPink = Color(0xFFFF2E93);        // High-visibility pink

  // ==========================================================================
  // PRD v3.0 Dark Theme Tokens (Refined with Emerald & Pink Accents)
  // ==========================================================================
  static const Color darkBg = Color(0xFF071A14);          // Deep obsidian forest canvas
  static const Color darkSurface = Color(0xFF0F2820);     // Elevated deep emerald surface
  static const Color darkSurface2 = Color(0xFF16382C);    // Inputs, table rows
  static const Color darkSurfaceElevated = Color(0xFF16382C);
  static const Color darkSurfaceCard = Color(0xFF0F2820);
  static const Color darkBorder = Color(0xFF1F4A3B);      // Subtle emerald dividers
  static const Color darkText = Color(0xFFF0FDF4);        // Main text (>= 4.5:1)
  static const Color darkTextPrimary = Color(0xFFF0FDF4);
  static const Color darkTextMuted = Color(0xFF94BAA8);   // Secondary text
  static const Color darkTextSecondary = Color(0xFF94BAA8);
  static const Color darkPrimary = Color(0xFF10B981);     // Emerald green primary
  static const Color darkSuccess = Color(0xFF34D399);     // Verified, safe
  static const Color darkWarning = Color(0xFFFBBF24);     // Warnings
  static const Color darkDanger = Color(0xFFF43F5E);      // Critical, SOS, delete
  static const Color darkMl = Color(0xFFEC4899);          // ML / AI assessment pink

  // ==========================================================================
  // PRD v3.0 Light Theme Tokens (Brights, Greenish & Pink Theme)
  // ==========================================================================
  static const Color lightBg = Color(0xFFF6FAF7);         // Fresh crisp bright canvas
  static const Color lightBackground = Color(0xFFF6FAF7);
  static const Color lightSurface = Color(0xFFFFFFFF);    // Pure white cards and panels
  static const Color lightSurface2 = Color(0xFFF0FDF4);   // Fresh mint tinted inputs/rows
  static const Color lightSurfaceCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);     // Subtle clean border
  static const Color lightText = Color(0xFF0F2419);       // Deep pine/slate high contrast
  static const Color lightTextPrimary = Color(0xFF0F2419);
  static const Color lightTextMuted = Color(0xFF4B6358);  // Clean readable secondary
  static const Color lightTextSecondary = Color(0xFF4B6358);
  static const Color lightPrimary = Color(0xFF059669);    // Buttons and links (vibrant emerald)
  static const Color lightSuccess = Color(0xFF10B981);    // Verified, safe
  static const Color lightWarning = Color(0xFFF59E0B);    // Warnings
  static const Color lightDanger = Color(0xFFE11D48);     // Rose/Pink red
  static const Color lightMl = Color(0xFFDB2777);         // Pink/Magenta
  static const Color lightPink = Color(0xFFEC4899);       // Bright pink token

  // ==========================================================================
  // Canonical Semantic Colors
  // ==========================================================================
  static const Color emergencyRed = Color(0xFFEF4444);
  static const Color emergencyPink = Color(0xFFF43F5E);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color mlPurple = Color(0xFFDB2777);        // Magenta/Pink for AI
  static const Color deepNavy = Color(0xFF0F2419);        // High-contrast heading slate
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color primaryText = Color(0xFF0F2419);
  static const Color mutedText = Color(0xFF4B6358);

  // Backward-compatibility aliases (routed to green & pink palette)
  static const Color primaryBlue = Color(0xFF059669);    // Powers the 45 existing screens with Emerald Green!
  static const Color realBlue = Color(0xFF2563EB);       // Fallback pure blue
  static const Color primary = primaryGreen;
  static const Color primaryDark = Color(0xFF047857);
  static const Color primaryLight = Color(0xFF34D399);
  static const Color accent = primaryPink;
  static const Color criticalRed = emergencyRed;
  static const Color warningAmber = warningOrange;
  static const Color verifiedGreen = successGreen;
  static const Color infoBlue = primaryGreen;
  static const Color unverifiedPurple = primaryPink;
  static const Color darkBackground = darkBg;
  static const Color navyBlue = deepGreen;

  // ==========================================================================
  // Premium Gradients
  // ==========================================================================
  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pinkGradient = LinearGradient(
    colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenPinkGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF047857), Color(0xFF059669), Color(0xFFDB2777)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradientLight = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF0FDF4)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
