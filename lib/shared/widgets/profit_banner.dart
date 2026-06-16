import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../utils/formatters.dart';

class ProfitBanner extends StatelessWidget {
  const ProfitBanner({
    super.key,
    required this.totalProfit,
    required this.marginPercent,
  });

  final num totalProfit;
  final int marginPercent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profitColor = isDark ? AppColors.profitDark : AppColors.profit;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.page),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            profitColor.withValues(alpha: isDark ? 0.22 : 0.12),
            profitColor.withValues(alpha: isDark ? 0.1 : 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: profitColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: profitColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              Icons.trending_up_rounded,
              color: profitColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ganancia',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: profitColor,
                  ),
                ),
                Text(
                  formatCurrencyNum(totalProfit),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: profitColor,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Margen',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: profitColor.withValues(alpha: 0.85),
                ),
              ),
              Text(
                '$marginPercent%',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: profitColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
