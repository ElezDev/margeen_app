import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/dashboard_report.dart';
import '../../shared/models/user.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/app_loading_indicator.dart';
import '../../shared/widgets/auth_guard.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/margeen_card.dart';
import '../../shared/widgets/quick_action_card.dart';
import '../../shared/widgets/screen_header.dart';
import '../../shared/widgets/app_navigation.dart';
import 'report_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuthGuard(
      builder: (context, user) => _HomeDashboard(user: user),
    );
  }
}

class _HomeDashboard extends ConsumerWidget {
  const _HomeDashboard({required this.user});

  final AppUser user;

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
    if (!user.can('reports.view')) {
      return _HomeShell(
        user: user,
        onRefresh: null,
        slivers: [
          SliverToBoxAdapter(child: _HomeHero(user: user)),
          _quickActionsSliver(context, user),
        ],
      );
    }

    final reportAsync = ref.watch(dashboardReportProvider);

    return reportAsync.when(
      loading: () => _HomeShell(
        user: user,
        onRefresh: null,
        slivers: [
          SliverToBoxAdapter(
            child: _HomeHero(
              user: user,
              isLoading: true,
              scope: ref.watch(dashboardScopeProvider),
              selectedDate: ref.watch(dashboardDateProvider),
              onScopeChanged: (s) =>
                  ref.read(dashboardScopeProvider.notifier).state = s,
              onPickDate: () => _pickDate(context, ref),
            ),
          ),
          _quickActionsSliver(context, user),
          const SliverFillRemaining(
            hasScrollBody: false,
            child: const AppLoadingPage(),
          ),
        ],
      ),
      error: (e, _) => _HomeShell(
        user: user,
        onRefresh: () async => ref.invalidate(dashboardReportProvider),
        slivers: [
          SliverToBoxAdapter(child: _HomeHero(user: user)),
          _quickActionsSliver(context, user),
          SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorState(
              message: e.toString(),
              onRetry: () => ref.invalidate(dashboardReportProvider),
            ),
          ),
        ],
      ),
      data: (report) => _HomeShell(
        user: user,
        onRefresh: () async => ref.invalidate(dashboardReportProvider),
        slivers: _reportSlivers(
          context,
          ref,
          user,
          report,
          () => _pickDate(context, ref),
        ),
      ),
    );
  }

  List<Widget> _reportSlivers(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
    DashboardReport report,
    VoidCallback onPickDate,
  ) {
    final summary = report.summary;
    final scope = ref.watch(dashboardScopeProvider);
    final selectedDate = ref.watch(dashboardDateProvider);
    final theme = Theme.of(context);

    return [
      SliverToBoxAdapter(
        child: _HomeHero(
          user: user,
          scope: scope,
          selectedDate: selectedDate,
          summary: summary,
          periodFrom: report.periodFrom,
          periodTo: report.periodTo,
          onScopeChanged: (s) =>
              ref.read(dashboardScopeProvider.notifier).state = s,
          onPickDate: onPickDate,
          onRefresh: () => ref.invalidate(dashboardReportProvider),
        ),
      ),
      _quickActionsSliver(context, user),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.section,
          AppSpacing.page,
          0,
        ),
        sliver: SliverToBoxAdapter(
          child: SectionHeader(
            title: scope == DashboardScope.day
                ? 'Resumen de hoy'
                : 'Resumen del mes',
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.card,
          AppSpacing.page,
          0,
        ),
        sliver: SliverToBoxAdapter(
          child: Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.payments_outlined,
                  label: 'Ventas',
                  value: formatCurrencyNum(summary.totalSales),
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: AppSpacing.card),
              Expanded(
                child: _MetricTile(
                  icon: Icons.receipt_long_outlined,
                  label: 'Facturas',
                  value: '${summary.invoiceCount}',
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
      if (summary.pendingCollection > 0)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.card,
            AppSpacing.page,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: _MetricTile(
              icon: Icons.schedule_outlined,
              label: 'Por cobrar',
              value: formatCurrencyNum(summary.pendingCollection),
              color: AppColors.warning,
              fullWidth: true,
            ),
          ),
        ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.section,
          AppSpacing.page,
          0,
        ),
        sliver: SliverToBoxAdapter(
          child: SectionHeader(title: 'Mejores clientes'),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.card,
          AppSpacing.page,
          0,
        ),
        sliver: SliverToBoxAdapter(
          child: report.topClients.isEmpty
              ? const MargeenCard(child: Text('Sin ventas de clientes aún'))
              : _TopClientsSection(clients: report.topClients),
        ),
      ),
      if (report.topProducts.isNotEmpty) ...[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.section,
            AppSpacing.page,
            0,
          ),
          sliver: const SliverToBoxAdapter(
            child: SectionHeader(title: 'Productos destacados'),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.card,
            AppSpacing.page,
            0,
          ),
          sliver: SliverList.separated(
            itemCount: report.topProducts.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.card),
            itemBuilder: (context, index) {
              final product = report.topProducts[index];
              return MargeenCard(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.accent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.description,
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            '${formatQuantity(product.totalQuantity)} vendidos',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatCurrencyNum(product.totalSales),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '+${formatCurrencyNum(product.totalProfit)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.profit,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.section,
          AppSpacing.page,
          32,
        ),
        sliver: SliverToBoxAdapter(
          child: SectionHeader(
            title: 'Actividad reciente',
            action: TextButton(
              onPressed: user.can('invoices.view')
                  ? () => context.go('/invoices')
                  : null,
              child: const Text('Ver todas'),
            ),
          ),
        ),
      ),
      if (report.recentInvoices.isEmpty)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            32,
          ),
          sliver: const SliverToBoxAdapter(
            child: MargeenCard(child: Text('Sin facturas recientes')),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            32,
          ),
          sliver: SliverList.separated(
            itemCount: report.recentInvoices.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.card),
            itemBuilder: (context, index) {
              final invoice = report.recentInvoices[index];
              return MargeenCard(
                onTap: () => context.push('/invoices/${invoice.id}'),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(
                        Icons.receipt_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice.number,
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            invoice.clientName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatCurrencyNum(invoice.total),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '+${formatCurrencyNum(invoice.totalProfit)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.profit,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
    ];
  }

  Widget _quickActionsSliver(BuildContext context, AppUser user) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.section,
        AppSpacing.page,
        0,
      ),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Acciones rápidas'),
            const SizedBox(height: AppSpacing.card),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 100,
                    child: QuickActionCard(
                      icon: Icons.add_circle_outline,
                      label: 'Nueva factura',
                      color: AppColors.primary,
                      enabled: user.can('invoices.create'),
                      onTap: () => context.push('/invoices/new'),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.card),
                Expanded(
                  child: SizedBox(
                    height: 100,
                    child: QuickActionCard(
                      icon: Icons.receipt_long_outlined,
                      label: 'Facturas',
                      color: AppColors.secondary,
                      enabled: user.can('invoices.view'),
                      onTap: () => context.go('/invoices'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeShell extends StatelessWidget {
  const _HomeShell({
    required this.user,
    required this.slivers,
    this.onRefresh,
  });

  final AppUser user;
  final List<Widget> slivers;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final scrollView = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: slivers,
    );

    return Scaffold(
      body: SafeArea(
        child: onRefresh == null
            ? scrollView
            : RefreshIndicator(onRefresh: onRefresh!, child: scrollView),
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.user,
    this.summary,
    this.periodFrom,
    this.periodTo,
    this.scope,
    this.selectedDate,
    this.isLoading = false,
    this.onScopeChanged,
    this.onPickDate,
    this.onRefresh,
  });

  final AppUser user;
  final DashboardSummary? summary;
  final String? periodFrom;
  final String? periodTo;
  final DashboardScope? scope;
  final DateTime? selectedDate;
  final bool isLoading;
  final ValueChanged<DashboardScope>? onScopeChanged;
  final VoidCallback? onPickDate;
  final VoidCallback? onRefresh;

  String _periodHint() {
    if (scope == DashboardScope.day && selectedDate != null) {
      return DateFormat('EEEE d MMM', 'es_CO').format(selectedDate!);
    }
    final from = formatDate(periodFrom);
    final to = formatDate(periodTo);
    if (from != null && to != null && from != to) {
      return '$from – $to';
    }
    if (selectedDate != null) {
      return DateFormat('MMMM yyyy', 'es_CO').format(selectedDate!);
    }
    return 'Tu negocio en un vistazo';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        12,
        AppSpacing.page,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.section),
      decoration: BoxDecoration(
        gradient: AppDecorations.brandGradient(theme.brightness),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppDecorations.heroShadow(theme.brightness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTheme(
                data: const IconThemeData(color: Colors.white),
                child: const DrawerMenuButton(),
              ),
              const Spacer(),
              if (onRefresh != null)
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  tooltip: 'Actualizar',
                ),
            ],
          ),
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, ${user.name.split(' ').first}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      user.company?.name ?? 'Margeen',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (scope != null && onScopeChanged != null) ...[
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  _HeroScopeChip(
                    label: 'Hoy',
                    selected: scope == DashboardScope.day,
                    onTap: () => onScopeChanged!(DashboardScope.day),
                  ),
                  _HeroScopeChip(
                    label: 'Mes',
                    selected: scope == DashboardScope.month,
                    onTap: () => onScopeChanged!(DashboardScope.month),
                  ),
                ],
              ),
            ),
            if (onPickDate != null && selectedDate != null) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: onPickDate,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _periodHint(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
          const SizedBox(height: 20),
          if (isLoading)
            Text(
              'Cargando resumen…',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            )
          else if (summary != null) ...[
            Text(
              scope == DashboardScope.day ? 'Ventas de hoy' : 'Ventas del mes',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatCurrencyNum(summary!.totalSales),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _HeroStatChip(
                  icon: Icons.trending_up_rounded,
                  label:
                      'Ganancia ${formatCurrencyNum(summary!.totalProfit)}',
                ),
                const SizedBox(width: 8),
                _HeroStatChip(
                  icon: Icons.percent_rounded,
                  label: 'Margen ${summary!.profitMarginPercent}%',
                ),
              ],
            ),
          ] else
            Text(
              'Bienvenido a tu panel',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 15,
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroScopeChip extends StatelessWidget {
  const _HeroScopeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected
            ? Colors.white.withValues(alpha: 0.22)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroStatChip extends StatelessWidget {
  const _HeroStatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.fullWidth = false,
  });

  final IconData icon;
  final String label;
  final String value;
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

class _TopClientsSection extends StatelessWidget {
  const _TopClientsSection({required this.clients});

  final List<DashboardTopClient> clients;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final top = clients.take(3).toList();
    final maxValue =
        top.map((c) => c.totalSales).reduce((a, b) => a > b ? a : b);

    return MargeenCard(
      padding: const EdgeInsets.all(AppSpacing.page),
      child: Column(
        children: [
          for (var i = 0; i < top.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            Row(
              children: [
                _RankBadge(rank: i + 1),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        top[i].clientName,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        '${top[i].invoiceCount} facturas · ${formatCurrencyNum(top[i].totalSales)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: maxValue > 0
                              ? (top[i].totalSales / maxValue)
                                  .clamp(0.0, 1.0)
                              : 0,
                          minHeight: 6,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.warning,
      AppColors.secondary,
      AppColors.accent,
    ];
    final color = colors[(rank - 1).clamp(0, colors.length - 1)];

    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$rank',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    );
  }
}
