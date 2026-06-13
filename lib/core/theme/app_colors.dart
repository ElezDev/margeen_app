import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF146356);
  static const primaryDark = Color(0xFF0F4C3A);
  static const primaryLight = Color(0xFF1A8A6E);
  static const secondary = Color(0xFF2563EB);
  static const accent = Color(0xFF6366F1);

  static const lightBackground = Color(0xFFF7F9FC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceVariant = Color(0xFFEEF2F6);

  static const darkBackground = Color(0xFF0A0F1A);
  static const darkSurface = Color(0xFF121826);
  static const darkSurfaceVariant = Color(0xFF1A2234);

  static const profit = Color(0xFF059669);
  static const profitDark = Color(0xFF34D399);
  static const error = Color(0xFFDC2626);
  static const warning = Color(0xFFD97706);
  static const info = Color(0xFF2563EB);

  static const gradientStart = Color(0xFF0F4C3A);
  static const gradientEnd = Color(0xFF146356);

  static const gradientLight = [gradientStart, gradientEnd];
  static const gradientDark = [Color(0xFF0A2E24), Color(0xFF0F4C3A)];
}
