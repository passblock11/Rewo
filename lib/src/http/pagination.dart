/// Pagination request params from query string.
class PageRequest {
  PageRequest({this.page = 1, this.limit = 20});

  factory PageRequest.fromQuery(Map<String, String> query) {
    return PageRequest(
      page: int.tryParse(query['page'] ?? '') ?? 1,
      limit: (int.tryParse(query['limit'] ?? '') ?? 20).clamp(1, 100),
    );
  }

  final int page;
  final int limit;

  int get offset => (page - 1) * limit;
}

/// Paginated response wrapper.
class Page<T> {
  Page(
      {required this.items,
      required this.page,
      required this.limit,
      required this.total});

  final List<T> items;
  final int page;
  final int limit;
  final int total;

  int get totalPages => (total / limit).ceil();
  bool get hasNext => page < totalPages;
  bool get hasPrev => page > 1;

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T item) toJson) => {
        'items': items.map(toJson).toList(),
        'page': page,
        'limit': limit,
        'total': total,
        'totalPages': totalPages,
        'hasNext': hasNext,
        'hasPrev': hasPrev,
      };
}

/// API version prefix helper.
String versioned(String version, String path) {
  final p = path.startsWith('/') ? path : '/$path';
  return '/v$version$p';
}
