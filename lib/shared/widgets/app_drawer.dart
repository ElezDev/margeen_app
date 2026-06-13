import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_spacing.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    Navigator.pop(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que deseas salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  void _navigate(BuildContext context, String route) {
    Navigator.pop(context);
    context.push(route);
  }

  void _goTab(BuildContext context, String route) {
    Navigator.pop(context);
    context.go(route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    if (user == null) {
      return const Drawer(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.page),
              decoration: BoxDecoration(
                gradient: AppDecorations.brandGradient(theme.brightness),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    user.email,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user.company?.name ?? AppConfig.appName,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerSection(title: 'Módulos'),
                  if (user.can('clients.view'))
                    _DrawerTile(
                      icon: Icons.people_outline,
                      title: 'Clientes',
                      onTap: () => _navigate(context, '/clients'),
                    ),
                  if (user.can('products.view'))
                    _DrawerTile(
                      icon: Icons.inventory_2_outlined,
                      title: 'Productos',
                      onTap: () => _navigate(context, '/products'),
                    ),
                  if (user.can('users.manage'))
                    _DrawerTile(
                      icon: Icons.manage_accounts_outlined,
                      title: 'Usuarios',
                      onTap: () => _navigate(context, '/users'),
                    ),
                  if (user.can('invoices.create'))
                    _DrawerTile(
                      icon: Icons.add_circle_outline,
                      title: 'Nueva factura',
                      onTap: () => _navigate(context, '/invoices/new'),
                    ),
                  const Divider(height: 24),
                  _DrawerSection(title: 'Navegación'),
                  if (user.can('reports.view'))
                    _DrawerTile(
                      icon: Icons.bar_chart_rounded,
                      title: 'Reportes',
                      onTap: () => _goTab(context, '/'),
                    ),
                  if (user.can('invoices.view'))
                    _DrawerTile(
                      icon: Icons.receipt_long_outlined,
                      title: 'Facturas',
                      onTap: () => _goTab(context, '/invoices'),
                    ),
                  _DrawerTile(
                    icon: Icons.tune_outlined,
                    title: 'Ajustes',
                    onTap: () => _goTab(context, '/more'),
                  ),
                  const Divider(height: 24),
                  _DrawerTile(
                    icon: Icons.logout_rounded,
                    title: 'Cerrar sesión',
                    iconColor: AppColors.error,
                    titleColor: AppColors.error,
                    onTap: () => _logout(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  const _DrawerSection({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = iconColor ?? theme.colorScheme.primary;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(color: titleColor),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
