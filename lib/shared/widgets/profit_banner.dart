import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../utils/formatters.dart';

class ProfitBanner extends StatelessWidget {
  const ProfitBanner({
    super.key,
    required this.totalProfit,
    required this.marginPercent,
  });

  final String totalProfit;
  final int marginPercent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profitColor = isDark ? AppColors.profitDark : AppColors.profit;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            profitColor.withValues(alpha: isDark ? 0.25 : 0.15),
            profitColor.withValues(alpha: isDark ? 0.12 : 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: profitColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: profitColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.trending_up_rounded, color: profitColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ganancia',
                  style: TextStyle(
                    color: profitColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                Text(
                  formatCurrency(totalProfit),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: profitColor,
                    letterSpacing: -0.5,
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
                style: TextStyle(color: profitColor.withValues(alpha: 0.8)),
              ),
              Text(
                '$marginPercent%',
                style: TextStyle(
                  fontSize: 22,
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
