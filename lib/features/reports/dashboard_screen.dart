import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/dashboard_report.dart';
import '../../shared/models/user.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/app_loading_indicator.dart';
import '../../shared/widgets/app_navigation.dart';
import '../../shared/widgets/auth_guard.dart';
import '../../shared/widgets/error_state.dart';
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
    final canViewReports = user.can('reports.view');

    if (!canViewReports) {
      return _HomeShell(
        onRefresh: null,
        children: [
          _HomeTopBar(
            canCreateInvoice: user.can('invoices.create'),
          ),
          _HomeProfileHeader(user: user),
          _HomeQuickActions(user: user),
        ],
      );
    }

    final reportAsync = ref.watch(dashboardReportProvider);
    final scope = ref.watch(dashboardScopeProvider);
    final selectedDate = ref.watch(dashboardDateProvider);

    return reportAsync.when(
      loading: () => _HomeShell(
        onRefresh: null,
        children: [
          _HomeTopBar(canCreateInvoice: user.can('invoices.create')),
          _HomeProfileHeader(user: user),
          _HomeSalesCard(
            scope: scope,
            selectedDate: selectedDate,
            isLoading: true,
            onScopeChanged: (s) =>
                ref.read(dashboardScopeProvider.notifier).state = s,
            onPickDate: () => _pickDate(context, ref),
            onRefresh: () => ref.invalidate(dashboardReportProvider),
          ),
          _HomeQuickActions(user: user),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: AppLoadingPage(),
          ),
        ],
      ),
      error: (e, _) => _HomeShell(
        onRefresh: () async => ref.invalidate(dashboardReportProvider),
        children: [
          _HomeTopBar(canCreateInvoice: user.can('invoices.create')),
          _HomeProfileHeader(user: user),
          _HomeSalesCard(
            scope: scope,
            selectedDate: selectedDate,
            onScopeChanged: (s) =>
                ref.read(dashboardScopeProvider.notifier).state = s,
            onPickDate: () => _pickDate(context, ref),
            onRefresh: () => ref.invalidate(dashboardReportProvider),
          ),
          _HomeQuickActions(user: user),
          ErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(dashboardReportProvider),
          ),
        ],
      ),
      data: (report) => _HomeShell(
        onRefresh: () async => ref.invalidate(dashboardReportProvider),
        children: [
          _HomeTopBar(canCreateInvoice: user.can('invoices.create')),
          _HomeProfileHeader(user: user),
          _HomeSalesCard(
            scope: scope,
            selectedDate: selectedDate,
            summary: report.summary,
            onScopeChanged: (s) =>
                ref.read(dashboardScopeProvider.notifier).state = s,
            onPickDate: () => _pickDate(context, ref),
            onRefresh: () => ref.invalidate(dashboardReportProvider),
          ),
          _HomeQuickActions(user: user),
          _HomeMonthSummary(
            scope: scope,
            summary: report.summary,
            onSalesTap: user.can('invoices.view')
                ? () => context.go('/invoices')
                : null,
            onDocumentsTap: user.can('invoices.view')
                ? () => context.go('/invoices')
                : null,
          ),
        ],
      ),
    );
  }
}

class _HomeShell extends StatelessWidget {
  const _HomeShell({
    required this.children,
    this.onRefresh,
  });

  final List<Widget> children;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final listView = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: children,
    );

    return Scaffold(
      body: SafeArea(
        child: onRefresh == null
            ? listView
            : RefreshIndicator(onRefresh: onRefresh!, child: listView),
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({required this.canCreateInvoice});

  final bool canCreateInvoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, AppSpacing.page, 4),
      child: Row(
        children: [
          const DrawerMenuButton(),
          Expanded(
            child: Text(
              AppConfig.appName.toUpperCase(),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: canCreateInvoice
                  ? () => context.push('/invoices/new')
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  Icons.add_rounded,
                  color: canCreateInvoice
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.45),
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeProfileHeader extends StatelessWidget {
  const _HomeProfileHeader({required this.user});

  final AppUser user;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días,';
    if (hour < 18) return 'Buenas tardes,';
    return 'Buenas noches,';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        12,
        AppSpacing.page,
        20,
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.profit,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surfaceContainerLowest,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  user.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeSalesCard extends StatelessWidget {
  const _HomeSalesCard({
    required this.scope,
    required this.selectedDate,
    this.summary,
    this.isLoading = false,
    this.onScopeChanged,
    this.onPickDate,
    this.onRefresh,
  });

  final DashboardScope scope;
  final DateTime selectedDate;
  final DashboardSummary? summary;
  final bool isLoading;
  final ValueChanged<DashboardScope>? onScopeChanged;
  final VoidCallback? onPickDate;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppDecorations.brandGradient(theme.brightness),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppDecorations.heroShadow(theme.brightness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _ScopeToggle(
                  scope: scope,
                  onChanged: onScopeChanged,
                ),
              ),
              if (onRefresh != null)
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white,
                  ),
                  color: theme.colorScheme.surfaceContainerLow,
                  onSelected: (value) {
                    switch (value) {
                      case 'refresh':
                        onRefresh!();
                      case 'date':
                        onPickDate?.call();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'refresh',
                      child: Text('Actualizar'),
                    ),
                    const PopupMenuItem(
                      value: 'date',
                      child: Text('Cambiar fecha'),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (isLoading)
            Text(
              'Cargando resumen…',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 15,
              ),
            )
          else if (summary != null) ...[
            Row(
              children: [
                Icon(
                  Icons.show_chart_rounded,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 8),
                Text(
                  'Ventas totales',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formatCurrencyNum(summary!.totalSales),
              style: theme.textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _SalesStatBox(
                    label: 'GANANCIA',
                    value: formatCurrencyNum(summary!.totalProfit),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SalesStatBox(
                    label: 'MARGEN',
                    value: '${summary!.profitMarginPercent}%',
                  ),
                ),
              ],
            ),
          ] else
            Text(
              'Sin datos para este periodo',
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

class _ScopeToggle extends StatelessWidget {
  const _ScopeToggle({
    required this.scope,
    this.onChanged,
  });

  final DashboardScope scope;
  final ValueChanged<DashboardScope>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _ScopeChip(
            label: 'Hoy',
            selected: scope == DashboardScope.day,
            onTap: onChanged == null
                ? null
                : () => onChanged!(DashboardScope.day),
          ),
          _ScopeChip(
            label: 'Este Mes',
            selected: scope == DashboardScope.month,
            onTap: onChanged == null
                ? null
                : () => onChanged!(DashboardScope.month),
          ),
        ],
      ),
    );
  }
}

class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
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

class _SalesStatBox extends StatelessWidget {
  const _SalesStatBox({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeQuickActions extends StatelessWidget {
  const _HomeQuickActions({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.section,
        AppSpacing.page,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acciones rápidas',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _QuickActionTile(
                  icon: Icons.add_rounded,
                  label: 'Nueva Factura',
                  color: AppColors.primary,
                  enabled: user.can('invoices.create'),
                  onTap: () => context.push('/invoices/new'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _QuickActionTile(
                  icon: Icons.receipt_long_outlined,
                  label: 'Ver Historial',
                  color: AppColors.secondary,
                  enabled: user.can('invoices.view'),
                  onTap: () => context.go('/invoices'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor =
        enabled ? color : theme.colorScheme.onSurfaceVariant;

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 118,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: effectiveColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: effectiveColor, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: enabled
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeMonthSummary extends StatelessWidget {
  const _HomeMonthSummary({
    required this.scope,
    required this.summary,
    this.onSalesTap,
    this.onDocumentsTap,
  });

  final DashboardScope scope;
  final DashboardSummary summary;
  final VoidCallback? onSalesTap;
  final VoidCallback? onDocumentsTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = scope == DashboardScope.day
        ? 'Resumen de hoy'
        : 'Resumen del mes';
    final docLabel = summary.invoiceCount == 1
        ? '1 Factura'
        : '${summary.invoiceCount} Facturas';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.section,
        AppSpacing.page,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _SummaryRow(
            icon: Icons.payments_outlined,
            iconColor: AppColors.profit,
            title: 'Total Ventas',
            value: formatCurrencyNum(summary.totalSales),
            onTap: onSalesTap,
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            icon: Icons.description_outlined,
            iconColor: AppColors.secondary,
            title: 'Documentos Emitidos',
            value: docLabel,
            onTap: onDocumentsTap,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      value,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
