import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../utils/formatters.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  (Color bg, Color fg) _colors() {
    switch (status) {
      case 'cancelled':
        return (
          AppColors.error.withValues(alpha: 0.1),
          AppColors.error,
        );
      case 'issued':
        return (
          AppColors.profit.withValues(alpha: 0.1),
          AppColors.profit,
        );
      case 'draft':
        return (
          AppColors.warning.withValues(alpha: 0.12),
          AppColors.warning,
        );
      default:
        return (
          AppColors.info.withValues(alpha: 0.1),
          AppColors.info,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (bg, fg) = _colors();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Text(
        statusLabel(status),
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: fg,
          letterSpacing: 0.15,
        ),
      ),
    );
  }
}
