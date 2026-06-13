import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/product_repository.dart';
import '../../shared/models/product.dart';

class ProductListState {
  const ProductListState({
    this.products = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.currentPage = 0,
    this.hasMore = true,
    this.error,
    this.query = '',
  });

  final List<Product> products;
  final bool isLoading;
  final bool isLoadingMore;
  final int currentPage;
  final bool hasMore;
  final String? error;
  final String query;

  ProductListState copyWith({
    List<Product>? products,
    bool? isLoading,
    bool? isLoadingMore,
    int? currentPage,
    bool? hasMore,
    String? error,
    String? query,
    bool clearError = false,
  }) {
    return ProductListState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      query: query ?? this.query,
    );
  }
}

class ProductListNotifier extends StateNotifier<ProductListState> {
  ProductListNotifier(this._repository) : super(const ProductListState());

  final ProductRepository _repository;

  Future<void> refresh({String? query}) async {
    final nextQuery = query ?? state.query;
    state = state.copyWith(isLoading: true, clearError: true, query: nextQuery);

    try {
      final page = await _repository.list(page: 1, query: nextQuery);
      state = state.copyWith(
        products: page.data,
        isLoading: false,
        currentPage: page.currentPage,
        hasMore: page.hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true, clearError: true);

    try {
      final page = await _repository.list(
        page: state.currentPage + 1,
        query: state.query,
      );
      state = state.copyWith(
        products: [...state.products, ...page.data],
        isLoadingMore: false,
        currentPage: page.currentPage,
        hasMore: page.hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }
}

final productListProvider =
    StateNotifierProvider<ProductListNotifier, ProductListState>((ref) {
  return ProductListNotifier(ref.read(productRepositoryProvider));
});

final productDetailProvider = FutureProvider.family<Product, int>((ref, id) {
  return ref.read(productRepositoryProvider).getById(id);
});

final productSearchProvider =
    FutureProvider.family<List<Product>, String>((ref, query) async {
  if (query.trim().length < 2) return [];
  final page = await ref
      .read(productRepositoryProvider)
      .list(query: query, activeOnly: true);
  return page.data;
});
