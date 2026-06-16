import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class SubtleExtendedFab extends StatelessWidget {
  const SubtleExtendedFab({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.add_rounded,
    this.heroTag,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData icon;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FloatingActionButton.extended(
      heroTag: heroTag,
      elevation: 0,
      highlightElevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      foregroundColor: AppColors.primary,
      extendedPadding: const EdgeInsets.symmetric(horizontal: 18),
      extendedIconLabelSpacing: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
