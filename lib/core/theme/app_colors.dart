import 'package:flutter/material.dart';

/**
 * ResQAI Design System Color Tokens
 * Aligned strictly with PRD v3.0 Section 12.2 (no hardcoded hex in components)
 */
class AppColors {
  // ==========================================================================
  // PRD v3.0 Dark Theme Tokens
  // ==========================================================================
  static const Color darkBg = Color(0xFF0B1F3A);          // Page background
  static const Color darkSurface = Color(0xFF14233B);     // Cards and panels
  static const Color darkSurface2 = Color(0xFF1C2D49);
  static const Color darkSurfaceElevated = Color(0xFF1C2D49);    // Inputs, table rows
  static const Color darkSurfaceCard = Color(0xFF14233B); // Backward compatibility
  static const Color darkBorder = Color(0xFF2B3C58);      // Dividers and outlines
  static const Color darkText = Color(0xFFF1F5F9);        // Main text (>= 4.5:1)
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextMuted = Color(0xFFB6C2D4);   // Secondary text
  static const Color darkTextSecondary = Color(0xFFB6C2D4);
  static const Color darkPrimary = Color(0xFF3B82F6);     // Buttons and links
  static const Color darkSuccess = Color(0xFF10B981);     // Verified, safe
  static const Color darkWarning = Color(0xFFFBBF24);     // Warnings
  static const Color darkDanger = Color(0xFFEF4444);      // Critical, SOS, delete
  static const Color darkMl = Color(0xFFA78BFA);          // ML assessment only

  // ==========================================================================
  // PRD v3.0 Light Theme Tokens
  // ==========================================================================
  static const Color lightBg = Color(0xFFF5F7FB);         // Page background
  static const Color lightBackground = Color(0xFFF5F7FB);
  static const Color lightSurface = Color(0xFFFFFFFF);    // Cards and panels
  static const Color lightSurface2 = Color(0xFFEEF2F8);   // Inputs, table rows
  static const Color lightSurfaceCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFD5DDEA);     // Dividers and outlines
  static const Color lightText = Color(0xFF0F172A);       // Main text
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextMuted = Color(0xFF475569);  // Secondary text
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightPrimary = Color(0xFF1D4ED8);    // Buttons and links
  static const Color lightSuccess = Color(0xFF047857);    // Verified, safe
  static const Color lightWarning = Color(0xFFB45309);    // Warnings
  static const Color lightDanger = Color(0xFFB91C1C);     // Critical, SOS, delete
  static const Color lightMl = Color(0xFF6D28D9);         // ML assessment only

  // ==========================================================================
  // Canonical Semantic Colors
  // ==========================================================================
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color emergencyRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFFBBF24);
  static const Color mlPurple = Color(0xFFA78BFA);
  static const Color deepNavy = Color(0xFF0B1F3A);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color primaryText = Color(0xFF0F172A);
  static const Color mutedText = Color(0xFF475569);

  // Backward-compatibility aliases
  static const Color primary = primaryBlue;
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color accent = warningOrange;
  static const Color criticalRed = emergencyRed;
  static const Color warningAmber = warningOrange;
  static const Color verifiedGreen = successGreen;
  static const Color infoBlue = primaryBlue;
  static const Color unverifiedPurple = mlPurple;
  static const Color darkBackground = darkBg;
  static const Color navyBlue = deepNavy;
}
