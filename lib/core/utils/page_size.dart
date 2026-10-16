import 'dart:math' as math;

/// Rows per request for a list that fills [viewportHeight]: two screens' worth, so the first page
/// fills the view and the next one is already there before the user reaches the end. Clamped to
/// the backend's allowed range (1-100); [min]/[max] keep tiny and huge screens sensible.
int pageSizeForViewport({
  required double viewportHeight,
  required double rowExtent,
  int min = 10,
  int max = 50,
}) {
  if (rowExtent <= 0 || viewportHeight <= 0) return min;
  final visibleRows = (viewportHeight / rowExtent).ceil();
  return math.min(math.max(visibleRows * 2, min), max);
}
