class PaginationState {
  const PaginationState({
    this.page = 1,
    this.limit = 20,
    this.total = 0,
  });

  final int page;
  final int limit;
  final int total;

  int get totalPages => total == 0 ? 1 : ((total + limit - 1) ~/ limit);
  bool get hasNextPage => page < totalPages;
  bool get hasPrevPage => page > 1;

  PaginationState copyWith({
    int? page,
    int? limit,
    int? total,
  }) {
    return PaginationState(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
    );
  }
}
