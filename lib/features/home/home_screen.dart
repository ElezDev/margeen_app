import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/models/user.dart';
import '../../shared/widgets/auth_guard.dart';
import '../../shared/widgets/margeen_card.dart';
import '../../shared/widgets/quick_action_card.dart';
import '../../shared/widgets/screen_header.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuthGuard(
      builder: (context, user) => _HomeContent(user: user),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  16,
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
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white.withValues(alpha: 0.18),
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
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
                              const SizedBox(height: 2),
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
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        user.isAdmin ? 'Administrador' : 'Vendedor',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
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
              sliver: const SliverToBoxAdapter(
                child: SectionHeader(title: 'Acciones rápidas'),
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
                      child: SizedBox(
                        height: 108,
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
                        height: 108,
                        child: QuickActionCard(
                          icon: Icons.receipt_long_outlined,
                          label: 'Ver facturas',
                          color: AppColors.secondary,
                          enabled: user.can('invoices.view'),
                          onTap: () => context.go('/invoices'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                28,
                AppSpacing.page,
                0,
              ),
              sliver: const SliverToBoxAdapter(
                child: SectionHeader(title: 'Módulos'),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.card,
                AppSpacing.page,
                32,
              ),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.card,
                  crossAxisSpacing: AppSpacing.card,
                  childAspectRatio: 1.38,
                ),
                delegate: SliverChildListDelegate([
                  QuickActionCard(
                    icon: Icons.people_outline,
                    label: 'Clientes',
                    color: AppColors.accent,
                    enabled: user.can('clients.view'),
                    onTap: user.can('clients.view')
                        ? () => context.push('/clients')
                        : null,
                  ),
                  QuickActionCard(
                    icon: Icons.inventory_2_outlined,
                    label: 'Productos',
                    color: AppColors.warning,
                    enabled: user.can('products.view'),
                    onTap: user.can('products.view')
                        ? () => context.push('/products')
                        : null,
                  ),
                  QuickActionCard(
                    icon: Icons.bar_chart_rounded,
                    label: 'Reportes',
                    color: AppColors.secondary,
                    enabled: user.can('reports.view'),
                    onTap: user.can('reports.view')
                        ? () => context.push('/reports')
                        : null,
                  ),
                  if (user.can('users.manage'))
                    QuickActionCard(
                      icon: Icons.manage_accounts_outlined,
                      label: 'Usuarios',
                      color: AppColors.primary,
                      onTap: () => context.push('/users'),
                    ),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                0,
                AppSpacing.page,
                32,
              ),
              sliver: SliverToBoxAdapter(
                child: MargeenCard(
                  child: Row(
                    children: [
                      Icon(
                        Icons.insights_outlined,
                        color: theme.colorScheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Controla tu ganancia en cada factura con el margen en tiempo real.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
