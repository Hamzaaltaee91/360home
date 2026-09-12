// Pagination Helpers
//
// A small, generic wrapper for paginated list responses so services and
// providers can share a single shape for "a page of items plus whether more
// exist".

/// A single page of [items] along with the offset to request the next page.
class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.offset,
    required this.limit,
    required this.hasMore,
  });

  /// The items in this page.
  final List<T> items;

  /// The offset this page was requested at.
  final int offset;

  /// The maximum number of items requested for this page.
  final int limit;

  /// Whether the backend may have more items beyond this page.
  ///
  /// Inferred from a full page being returned; a short page means the end
  /// has been reached.
  final bool hasMore;

  /// The offset to use when requesting the next page.
  int get nextOffset => offset + items.length;

  /// An empty page starting at [offset].
  factory PaginatedResult.empty({int offset = 0, int limit = 20}) {
    return PaginatedResult<T>(
      items: const [],
      offset: offset,
      limit: limit,
      hasMore: false,
    );
  }

  /// Builds a page from a raw [items] list, inferring [hasMore] from whether
  /// the page came back full.
  factory PaginatedResult.fromItems(
    List<T> items, {
    required int offset,
    required int limit,
  }) {
    return PaginatedResult<T>(
      items: items,
      offset: offset,
      limit: limit,
      hasMore: items.length >= limit,
    );
  }
}
