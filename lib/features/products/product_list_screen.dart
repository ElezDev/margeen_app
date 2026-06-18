import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../shared/utils/formatters.dart';
import '../../shared/widgets/app_loading_indicator.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/margeen_card.dart';
import 'product_providers.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(productListProvider.notifier).refresh());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(productListProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(productListProvider.notifier).refresh(query: value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productListProvider);
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final canCreate = user?.can('products.create') ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Productos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar producto',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref
                  .read(productListProvider.notifier)
                  .refresh(query: _searchController.text),
              child: _buildBody(context, state, theme, canCreate),
            ),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/products/new'),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo'),
            )
          : null,
    );
  }

  Widget _buildBody(
    BuildContext context,
    ProductListState state,
    ThemeData theme,
    bool canCreate,
  ) {
    if (state.isLoading && state.products.isEmpty) {
      return const AppLoadingPage();
    }

    if (state.error != null && state.products.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: ErrorState(
              message: state.error!,
              onRetry: () => ref.read(productListProvider.notifier).refresh(),
            ),
          ),
        ],
      );
    }

    if (state.products.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Sin productos',
              subtitle: 'Agrega productos al catálogo',
              action: canCreate
                  ? FilledButton.icon(
                      onPressed: () => context.push('/products/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('Nuevo producto'),
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 88),
      itemCount: state.products.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.products.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: const AppLoadingPage(),
          );
        }

        final product = state.products[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MargeenCard(
            onTap: () => context.push('/products/${product.id}/edit'),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: product.isActive
                              ? null
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${product.unit} · Costo ${formatCurrency(product.costPrice)}',
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
                      formatCurrency(product.salePrice),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (!product.isActive)
                      const Text('Inactivo', style: TextStyle(fontSize: 11)),
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
