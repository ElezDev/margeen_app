import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/models/dashboard_report.dart';
import '../../../shared/utils/formatters.dart';

class DashboardChartsSection extends StatelessWidget {
  const DashboardChartsSection({
    super.key,
    required this.report,
    this.onInvoiceTap,
  });

  final DashboardReport report;
  final void Function(int invoiceId)? onInvoiceTap;

  @override
  Widget build(BuildContext context) {
    final hasCharts = report.summary.totalSales > 0 ||
        report.topClients.isNotEmpty ||
        report.topProducts.isNotEmpty ||
        report.recentInvoices.isNotEmpty;

    if (!hasCharts) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: Text(
              'Gráficas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(height: 14),
          if (report.summary.totalSales > 0) ...[
            _ChartCard(
              title: 'Ventas vs ganancia',
              subtitle: 'Distribución del periodo',
              child: _SalesDonutChart(summary: report.summary),
            ),
            const SizedBox(height: 14),
          ],
          if (report.recentInvoices.isNotEmpty) ...[
            _ChartCard(
              title: 'Actividad reciente',
              subtitle: 'Últimas facturas emitidas',
              child: _RecentInvoicesChart(
                invoices: report.recentInvoices,
                onTap: onInvoiceTap,
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (report.topClients.isNotEmpty)
            _ChartCard(
              title: 'Top clientes',
              subtitle: 'Por ventas en el periodo',
              child: _RankedBarChart(
                items: report.topClients
                    .take(5)
                    .map(
                      (c) => _ChartBarItem(
                        label: c.clientName,
                        value: c.totalSales.toDouble(),
                        secondary: '${c.invoiceCount} facturas',
                      ),
                    )
                    .toList(),
                barColor: AppColors.primary,
              ),
            ),
          if (report.topClients.isNotEmpty && report.topProducts.isNotEmpty)
            const SizedBox(height: 14),
          if (report.topProducts.isNotEmpty)
            _ChartCard(
              title: 'Top productos',
              subtitle: 'Por ventas en el periodo',
              child: _RankedBarChart(
                items: report.topProducts
                    .take(5)
                    .map(
                      (p) => _ChartBarItem(
                        label: p.description,
                        value: p.totalSales.toDouble(),
                        secondary: formatCurrencyNum(p.totalProfit),
                      ),
                    )
                    .toList(),
                barColor: AppColors.secondary,
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: AppDecorations.card(context: context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _SalesDonutChart extends StatelessWidget {
  const _SalesDonutChart({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profit = summary.totalProfit.toDouble();
    final sales = summary.totalSales.toDouble();
    final cost = (sales - profit).clamp(0, double.infinity);

    if (sales <= 0) {
      return const _ChartEmpty(message: 'Sin ventas en este periodo');
    }

    final sections = <PieChartSectionData>[
        PieChartSectionData(
          value: profit > 0 ? profit.toDouble() : 0.001,
        color: AppColors.profit,
        radius: 22,
        title: '',
      ),
      if (cost > 0)
        PieChartSectionData(
          value: cost.toDouble(),
          color: AppColors.secondary.withValues(alpha: 0.75),
          radius: 22,
          title: '',
        ),
    ];

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 52,
                sections: sections,
                startDegreeOffset: -90,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${summary.profitMarginPercent}%',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.profit,
                  ),
                ),
                Text(
                  'Margen',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                _LegendDot(
                  color: AppColors.profit,
                  label: 'Ganancia',
                  value: formatCurrencyNum(profit),
                ),
                const SizedBox(height: 8),
                _LegendDot(
                  color: AppColors.secondary.withValues(alpha: 0.75),
                  label: 'Costo',
                  value: formatCurrencyNum(cost),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChartBarItem {
  const _ChartBarItem({
    required this.label,
    required this.value,
    this.secondary,
  });

  final String label;
  final double value;
  final String? secondary;
}

class _RankedBarChart extends StatelessWidget {
  const _RankedBarChart({
    required this.items,
    required this.barColor,
  });

  final List<_ChartBarItem> items;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _ChartEmpty(message: 'Sin datos');
    }

    final theme = Theme.of(context);
    final maxValue = items.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          _HorizontalBarRow(
            label: items[i].label,
            value: items[i].value,
            maxValue: maxValue,
            barColor: barColor,
            secondary: items[i].secondary,
            rank: i + 1,
            theme: theme,
          ),
        ],
      ],
    );
  }
}

class _HorizontalBarRow extends StatelessWidget {
  const _HorizontalBarRow({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.barColor,
    required this.rank,
    required this.theme,
    this.secondary,
  });

  final String label;
  final double value;
  final double maxValue;
  final Color barColor;
  final int rank;
  final ThemeData theme;
  final String? secondary;

  @override
  Widget build(BuildContext context) {
    final fraction = maxValue > 0 ? (value / maxValue).clamp(0.05, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$rank',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              formatCurrencyNum(value),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: barColor,
              ),
            ),
          ],
        ),
        if (secondary != null) ...[
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Text(
              secondary!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor:
                theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            color: barColor,
          ),
        ),
      ],
    );
  }
}

class _RecentInvoicesChart extends StatelessWidget {
  const _RecentInvoicesChart({
    required this.invoices,
    this.onTap,
  });

  final List<DashboardRecentInvoice> invoices;
  final void Function(int invoiceId)? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = invoices.take(5).toList();

    if (items.isEmpty) {
      return const _ChartEmpty(message: 'Sin facturas recientes');
    }

    final maxTotal = items
        .map((e) => e.total.toDouble())
        .reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxTotal * 1.15,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxTotal > 0 ? maxTotal / 4 : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (value, meta) {
                  if (value == meta.max || value == meta.min) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    _compactCurrency(value),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= items.length) {
                    return const SizedBox.shrink();
                  }
                  final label = items[index].number;
                  final short = label.length > 8
                      ? '${label.substring(0, 6)}…'
                      : label;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      short,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < items.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: items[i].total.toDouble(),
                    width: 18,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppColors.primary,
                        AppColors.primaryLight,
                      ],
                    ),
                  ),
                ],
              ),
          ],
          barTouchData: BarTouchData(
            enabled: onTap != null,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final invoice = items[group.x];
                return BarTooltipItem(
                  '${invoice.number}\n${formatCurrencyNum(invoice.total)}',
                  theme.textTheme.labelSmall!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
            touchCallback: (event, response) {
              if (!event.isInterestedForInteractions ||
                  response?.spot == null) {
                return;
              }
              final index = response!.spot!.touchedBarGroupIndex;
              if (index >= 0 && index < items.length) {
                onTap?.call(items[index].id);
              }
            },
          ),
        ),
      ),
    );
  }
}

class _ChartEmpty extends StatelessWidget {
  const _ChartEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}

String _compactCurrency(double value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(0)}K';
  }
  return value.toStringAsFixed(0);
}
