// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Palette
  static const Color primary = Color(0xFF0BA7AA);
  static const Color backButtonIconColor = Color(0xFFF6F6F6);
  static const Color primaryLight = Color(0xFF04C164);
  static const Color secondPrimaryLight = Color(0xFF87C526);
  static const Color primaryVariant = Color(0xFF3700B3);
  static const Color onPrimary = Colors.white;
  static const Color secondary = Color(0xFF03DAC6);
  static const Color onSecondary = Colors.black;
  static const Color background = Color(0xFFF6F6F6);

  static const Color onBackground = Colors.black;
  static const Color surface = Colors.white;
  static const Color onSurface = Colors.black;

  // Error Palette
  static const Color error = Color(0xFFB00020);
  static const Color onError = Colors.white;

  // Neutral Tones
  static const Color text = Color(0xFF333333);
  static const Color textLight = Color(0xFF757575);

  // Neutral Tones
  static const Color textDark = Color.fromARGB(255, 255, 255, 255);
  static const Color pureWhite = Color.fromARGB(255, 255, 255, 255);
  static const Color divider = Color(0xFFD9D9D9);

  static const Color transparent = Colors.transparent;

  static const Color attracColor = Color(0xFFF8CE44);
  static const Color iconColor = Color(0xFF87C526);
  static const Color hitGrey = Color(0xffAEAEB2);
  static Color? get primaryDark => null;
}