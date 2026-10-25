/// One page of a cursor-paginated list (`{items, next_cursor, has_more}`, see the
/// backend's API_CONTRACT.md section 5). The cursor is opaque: only ever passed back as-is.
class PageResult<T> {
  final List<T> items;
  final String? nextCursor;
  final bool hasMore;

  const PageResult({required this.items, this.nextCursor, this.hasMore = false});

  /// Parses the envelope; [parse] builds one item from its JSON.
  factory PageResult.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) parse) {
    final hasMore = json['has_more'] == true;
    return PageResult(
      items: (json['items'] as List).map((e) => parse(e as Map<String, dynamic>)).toList(),
      // Defensive: a missing cursor can't continue, so never claim there is more.
      nextCursor: hasMore ? json['next_cursor'] as String? : null,
      hasMore: hasMore && json['next_cursor'] != null,
    );
  }
}
