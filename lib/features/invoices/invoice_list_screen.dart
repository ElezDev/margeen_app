import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/list_tile_icon.dart';
import '../../shared/widgets/margeen_card.dart';
import '../../shared/widgets/screen_header.dart';
import '../../shared/widgets/subtle_fab.dart';
import '../../shared/widgets/status_badge.dart';
import 'invoice_providers.dart';

class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(invoiceListProvider.notifier).refresh());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(invoiceListProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoiceListProvider);
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final canCreate = user.can('invoices.create');

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(
              title: 'Facturas',
              showDrawerButton: true,
              subtitle: 'Historial y estado de tus ventas',
              action: canCreate
                  ? IconButton(
                      onPressed: () => context.push('/invoices/new'),
                      icon: const Icon(Icons.add_rounded),
                      tooltip: 'Nueva factura',
                      style: IconButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(invoiceListProvider.notifier).refresh(),
                child: _buildBody(context, state, canCreate),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: canCreate
          ? SubtleExtendedFab(
              heroTag: 'invoice_new',
              label: 'Nueva',
              onPressed: () => context.push('/invoices/new'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildBody(
    BuildContext context,
    InvoiceListState state,
    bool canCreate,
  ) {
    if (state.isLoading && state.invoices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.invoices.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: ErrorState(
              message: state.error!,
              onRetry: () => ref.read(invoiceListProvider.notifier).refresh(),
            ),
          ),
        ],
      );
    }

    if (state.invoices.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Sin facturas',
              subtitle: 'Crea tu primera factura para empezar',
              action: canCreate
                  ? FilledButton.icon(
                      onPressed: () => context.push('/invoices/new'),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Nueva factura'),
                    )
                  : null,
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        4,
        AppSpacing.page,
        AppSpacing.fabClearance,
      ),
      itemCount: state.invoices.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.invoices.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final invoice = state.invoices[index];
        final theme = Theme.of(context);

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.card),
          child: MargeenCard(
            onTap: () => context.push('/invoices/${invoice.id}'),
            child: Row(
              children: [
                ListTileIcon(
                  icon: Icons.receipt_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.number,
                        style: theme.textTheme.titleSmall,
                      ),
                      if (invoice.client != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          invoice.client!.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (invoice.issuedAt != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          formatDateTime(invoice.issuedAt)!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatCurrency(invoice.total),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    StatusBadge(status: invoice.status),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
