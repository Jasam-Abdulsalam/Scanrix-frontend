const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "Today, 2:11 PM" / "Yesterday, 9:05 AM" / "12 Oct" / "12 Oct 2025".
/// [scannedAt] and [now] are compared in local time. [now] is injectable for tests.
String formatScanTime(DateTime scannedAt, {DateTime? now}) {
  final t = scannedAt.toLocal();
  final today = now ?? DateTime.now();
  final days = DateTime(today.year, today.month, today.day).difference(DateTime(t.year, t.month, t.day)).inDays;
  final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final clock = '$hour12:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
  if (days == 0) return 'Today, $clock';
  if (days == 1) return 'Yesterday, $clock';
  final date = '${t.day} ${_months[t.month - 1]}';
  return t.year == today.year ? date : '$date ${t.year}';
}
