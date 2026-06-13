import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/user_repository.dart';
import '../../shared/models/managed_user.dart';

class UserListState {
  const UserListState({
    this.users = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.currentPage = 0,
    this.hasMore = true,
    this.error,
  });

  final List<ManagedUser> users;
  final bool isLoading;
  final bool isLoadingMore;
  final int currentPage;
  final bool hasMore;
  final String? error;

  UserListState copyWith({
    List<ManagedUser>? users,
    bool? isLoading,
    bool? isLoadingMore,
    int? currentPage,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) {
    return UserListState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class UserListNotifier extends StateNotifier<UserListState> {
  UserListNotifier(this._repository) : super(const UserListState());

  final UserRepository _repository;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final page = await _repository.list(page: 1);
      state = state.copyWith(
        users: page.data,
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
      final page = await _repository.list(page: state.currentPage + 1);
      state = state.copyWith(
        users: [...state.users, ...page.data],
        isLoadingMore: false,
        currentPage: page.currentPage,
        hasMore: page.hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }
}

final userListProvider =
    StateNotifierProvider<UserListNotifier, UserListState>((ref) {
  return UserListNotifier(ref.read(userRepositoryProvider));
});

final managedUserProvider =
    FutureProvider.family<ManagedUser, int>((ref, id) async {
  return ref.read(userRepositoryProvider).getById(id);
});
