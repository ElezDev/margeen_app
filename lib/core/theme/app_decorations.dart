import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

abstract final class AppDecorations {
  static LinearGradient brandGradient(Brightness brightness) {
    return LinearGradient(
      colors: brightness == Brightness.dark
          ? AppColors.gradientDark
          : AppColors.gradientLight,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static List<BoxShadow> heroShadow(Brightness brightness) {
    if (brightness == Brightness.dark) return const [];

    return [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.18),
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
    ];
  }

  static List<BoxShadow> cardShadow(Brightness brightness) {
    if (brightness == Brightness.dark) return const [];

    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ];
  }

  static BoxDecoration card({
    required BuildContext context,
    Color? color,
    BorderRadius? borderRadius,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BoxDecoration(
      color: color ?? theme.colorScheme.surfaceContainerLow,
      borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.md),
      border: Border.all(
        color: theme.colorScheme.outlineVariant.withValues(
          alpha: isDark ? 0.35 : 0.45,
        ),
      ),
      boxShadow: cardShadow(theme.brightness),
    );
  }
}
