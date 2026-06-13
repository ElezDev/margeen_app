import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/dashboard_report.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/models/user.dart';
import '../../shared/widgets/auth_guard.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/margeen_card.dart';
import '../../shared/widgets/profit_banner.dart';
import '../../shared/widgets/screen_header.dart';
import 'report_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuthGuard(
      builder: (context, user) {
        if (!user.can('reports.view')) {
          return _NoAccessHome(user: user);
        }
        return const _DashboardContent();
      },
    );
  }
}

class _NoAccessHome extends StatelessWidget {
  const _NoAccessHome({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: 16),
                Text(
                  'No tienes acceso a reportes',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go('/invoices'),
                  child: const Text('Ir a facturas'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent();

  Future<void> _pickDate(BuildContext context, WidgetRef ref) async {
    final current = ref.read(dashboardDateProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('es', 'CO'),
    );
    if (picked != null) {
      ref.read(dashboardDateProvider.notifier).state = picked;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(dashboardScopeProvider);
    final selectedDate = ref.watch(dashboardDateProvider);
    final reportAsync = ref.watch(dashboardReportProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: reportAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(dashboardReportProvider),
          ),
          data: (report) {
            final stats =
                scope == DashboardScope.day ? report.dayStats : report.monthStats;

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(dashboardReportProvider),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  ScreenHeader(
                    title: 'Reportes',
                    showDrawerButton: true,
                    subtitle: scope == DashboardScope.day
                        ? 'Resumen del ${report.period.day.isNotEmpty ? report.period.day : DateFormat('yyyy-MM-dd').format(selectedDate)}'
                        : report.period.monthLabel,
                    action: IconButton(
                      onPressed: () => ref.invalidate(dashboardReportProvider),
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Actualizar',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.page,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SegmentedButton<DashboardScope>(
                          segments: const [
                            ButtonSegment(
                              value: DashboardScope.day,
                              label: Text('Hoy'),
                              icon: Icon(Icons.today_outlined, size: 18),
                            ),
                            ButtonSegment(
                              value: DashboardScope.month,
                              label: Text('Mes'),
                              icon: Icon(Icons.calendar_month_outlined, size: 18),
                            ),
                          ],
                          selected: {scope},
                          onSelectionChanged: (s) => ref
                              .read(dashboardScopeProvider.notifier)
                              .state = s.first,
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () => _pickDate(context, ref),
                          icon: const Icon(Icons.event_outlined, size: 18),
                          label: Text(
                            DateFormat('d MMM yyyy', 'es_CO')
                                .format(selectedDate),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.section),
                        ProfitBanner(
                          totalProfit: stats.totalProfit.toString(),
                          marginPercent: stats.profitMarginPercent,
                        ),
                        const SizedBox(height: AppSpacing.card),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'Ventas',
                                value: formatCurrencyNum(stats.totalSales),
                                icon: Icons.payments_outlined,
                                color: AppColors.secondary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.card),
                            Expanded(
                              child: _StatCard(
                                label: 'Facturas',
                                value: '${stats.invoiceCount}',
                                icon: Icons.receipt_long_outlined,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.card),
                        _StatCard(
                          label: 'Pendiente por cobrar',
                          value: formatCurrencyNum(stats.pendingCollection),
                          icon: Icons.schedule_outlined,
                          color: AppColors.warning,
                          fullWidth: true,
                        ),
                        const SizedBox(height: AppSpacing.section),
                        Text(
                          'Ventas vs ganancia',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        _ComparisonChart(stats: stats),
                        const SizedBox(height: AppSpacing.section),
                        Text(
                          'Top clientes del mes',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        if (report.topClients.isEmpty)
                          const MargeenCard(
                            child: Text('Sin clientes en el período'),
                          )
                        else
                          _TopClientsChart(clients: report.topClients),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MargeenCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonChart extends StatelessWidget {
  const _ComparisonChart({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final maxValue = [
      stats.totalSales,
      stats.totalProfit,
    ].reduce((a, b) => a > b ? a : b);

    return MargeenCard(
      padding: const EdgeInsets.all(AppSpacing.page),
      child: SizedBox(
        height: 180,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _BarColumn(
                label: 'Ventas',
                value: stats.totalSales,
                maxValue: maxValue,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _BarColumn(
                label: 'Ganancia',
                value: stats.totalProfit,
                maxValue: maxValue,
                color: AppColors.profit,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _BarColumn(
                label: 'Por cobrar',
                value: stats.pendingCollection,
                maxValue: maxValue,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarColumn extends StatelessWidget {
  const _BarColumn({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final String label;
  final num value;
  final num maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          formatCurrencyNum(value),
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: ratio <= 0 ? 0.04 : ratio,
              widthFactor: 0.55,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _TopClientsChart extends StatelessWidget {
  const _TopClientsChart({required this.clients});

  final List<DashboardTopClient> clients;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxValue = clients
        .map((c) => c.totalPurchased)
        .reduce((a, b) => a > b ? a : b);

    return MargeenCard(
      padding: const EdgeInsets.all(AppSpacing.page),
      child: Column(
        children: [
          for (var i = 0; i < clients.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _ClientBarRow(
              rank: i + 1,
              client: clients[i],
              maxValue: maxValue,
              theme: theme,
            ),
          ],
        ],
      ),
    );
  }
}

class _ClientBarRow extends StatelessWidget {
  const _ClientBarRow({
    required this.rank,
    required this.client,
    required this.maxValue,
    required this.theme,
  });

  final int rank;
  final DashboardTopClient client;
  final num maxValue;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final ratio =
        maxValue > 0 ? (client.totalPurchased / maxValue).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                '$rank',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                client.clientName,
                style: theme.textTheme.titleSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              formatCurrencyNum(client.totalPurchased),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
