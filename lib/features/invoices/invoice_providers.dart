import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/invoice_repository.dart';
import '../../shared/models/invoice.dart';

class InvoiceListState {
  const InvoiceListState({
    this.invoices = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.currentPage = 0,
    this.hasMore = true,
    this.error,
    this.filters = const InvoiceFilters(),
  });

  final List<Invoice> invoices;
  final bool isLoading;
  final bool isLoadingMore;
  final int currentPage;
  final bool hasMore;
  final String? error;
  final InvoiceFilters filters;

  InvoiceListState copyWith({
    List<Invoice>? invoices,
    bool? isLoading,
    bool? isLoadingMore,
    int? currentPage,
    bool? hasMore,
    String? error,
    InvoiceFilters? filters,
    bool clearError = false,
  }) {
    return InvoiceListState(
      invoices: invoices ?? this.invoices,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      filters: filters ?? this.filters,
    );
  }
}

class InvoiceListNotifier extends StateNotifier<InvoiceListState> {
  InvoiceListNotifier(this._repository) : super(const InvoiceListState());

  final InvoiceRepository _repository;

  Future<void> refresh({InvoiceFilters? filters}) async {
    final nextFilters = filters ?? state.filters;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      filters: nextFilters,
    );

    try {
      final page = await _repository.list(page: 1, filters: nextFilters);
      state = state.copyWith(
        invoices: page.data,
        isLoading: false,
        currentPage: page.currentPage,
        hasMore: page.hasMore,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true, clearError: true);

    try {
      final page = await _repository.list(
        page: state.currentPage + 1,
        filters: state.filters,
      );
      state = state.copyWith(
        invoices: [...state.invoices, ...page.data],
        isLoadingMore: false,
        currentPage: page.currentPage,
        hasMore: page.hasMore,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }
}

final invoiceListProvider =
    StateNotifierProvider<InvoiceListNotifier, InvoiceListState>((ref) {
  return InvoiceListNotifier(ref.read(invoiceRepositoryProvider));
});

final invoiceDetailProvider =
    FutureProvider.family<Invoice, int>((ref, id) async {
  return ref.read(invoiceRepositoryProvider).getById(id);
});
