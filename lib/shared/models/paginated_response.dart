class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<T> data;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final items = (json['data'] as List<dynamic>)
        .map((e) => fromJsonT(e as Map<String, dynamic>))
        .toList();

    final meta = json['meta'] as Map<String, dynamic>?;
    if (meta == null) {
      return PaginatedResponse(
        data: items,
        currentPage: 1,
        lastPage: 1,
        total: items.length,
      );
    }

    return PaginatedResponse(
      data: items,
      currentPage: meta['current_page'] as int,
      lastPage: meta['last_page'] as int? ?? meta['current_page'] as int,
      total: meta['total'] as int,
    );
  }
}
