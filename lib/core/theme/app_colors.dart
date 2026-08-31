import 'package:flutter/material.dart';

/// The single light palette. There is no dark theme: the app pins
/// `ThemeMode.light` so the OS setting cannot change these values.
///
/// Blues are taken from the brand mark; the remaining tones from the approved
/// designs.
abstract final class AppColors {
  const AppColors._();

  // Brand. Two blues by design: the deep brand blue identifies (avatars,
  // selected chips, the logo), the brighter one calls to action (buttons).
  static const Color primary = Color(0xFF0B2FD6);
  static const Color primaryBright = Color(0xFF3B82F6);
  static const Color primarySoft = Color(0xFFEEF0FF);

  // Surfaces.
  static const Color background = Color(0xFFF5F6F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF3F4F6);

  /// Fill for a selected neutral control — the active tab in a filter bar.
  /// Dark enough to read as chosen against [surfaceMuted] beside it.
  static const Color surfaceSelected = Color(0xFFC9CCD1);

  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFEDEFF2);

  // Text.
  static const Color textPrimary = Color(0xFF0B0B0F);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status.
  static const Color success = Color(0xFF16A34A);
  static const Color successSoft = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFDF0DC);
  static const Color info = Color(0xFF2563EB);
  static const Color infoSoft = Color(0xFFEEF0FF);

  /// Teal, for a status that is neither a warning nor a completion — currently
  /// a case whose payment has cleared. Added because the pairs above were all
  /// spoken for and two statuses sharing a colour is a status pill that does
  /// not tell you anything.
  static const Color accent = Color(0xFF0F766E);
  static const Color accentSoft = Color(0xFFCCFBF1);

  // Destructive. The strong red is the confirm button, the lighter one the
  // trash icon, and the soft tint the icon backdrop.
  static const Color destructive = Color(0xFFE30613);
  static const Color destructiveIcon = Color(0xFFEF4444);
  static const Color destructiveSoft = Color(0xFFFEE2E2);

  // Interaction.
  static const Color disabled = Color(0xFFD1D5DB);
  static const Color disabledText = Color(0xFF9CA3AF);
  static const Color overlay = Color(0x66000000);
  static const Color shadow = Color(0x14000000);
}
