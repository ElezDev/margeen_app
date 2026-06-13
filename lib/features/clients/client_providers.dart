import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/client_repository.dart';
import '../../shared/models/client.dart';

class ClientListState {
  const ClientListState({
    this.clients = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.currentPage = 0,
    this.hasMore = true,
    this.error,
    this.query = '',
  });

  final List<Client> clients;
  final bool isLoading;
  final bool isLoadingMore;
  final int currentPage;
  final bool hasMore;
  final String? error;
  final String query;

  ClientListState copyWith({
    List<Client>? clients,
    bool? isLoading,
    bool? isLoadingMore,
    int? currentPage,
    bool? hasMore,
    String? error,
    String? query,
    bool clearError = false,
  }) {
    return ClientListState(
      clients: clients ?? this.clients,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
      query: query ?? this.query,
    );
  }
}

class ClientListNotifier extends StateNotifier<ClientListState> {
  ClientListNotifier(this._repository) : super(const ClientListState());

  final ClientRepository _repository;

  Future<void> refresh({String? query}) async {
    final nextQuery = query ?? state.query;
    state = state.copyWith(isLoading: true, clearError: true, query: nextQuery);

    try {
      final page = await _repository.list(page: 1, query: nextQuery);
      state = state.copyWith(
        clients: page.data,
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
        clients: [...state.clients, ...page.data],
        isLoadingMore: false,
        currentPage: page.currentPage,
        hasMore: page.hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }
}

final clientListProvider =
    StateNotifierProvider<ClientListNotifier, ClientListState>((ref) {
  return ClientListNotifier(ref.read(clientRepositoryProvider));
});

final clientDetailProvider = FutureProvider.family<Client, int>((ref, id) {
  return ref.read(clientRepositoryProvider).getById(id);
});

final clientSearchProvider =
    FutureProvider.family<List<Client>, String>((ref, query) async {
  if (query.trim().length < 2) return [];
  final page = await ref.read(clientRepositoryProvider).list(query: query);
  return page.data;
});
