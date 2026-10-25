/// The backend stores UTC but serialises it without a zone suffix
/// (`2026-10-16T08:41:00`). `DateTime.parse` would read that as *local* time
/// and show the wrong clock time, so a missing zone is treated as UTC.
DateTime parseBackendTime(String value) {
  final hasZone = value.endsWith('Z') || RegExp(r'[+-]\d\d:?\d\d$').hasMatch(value);
  return DateTime.parse(hasZone ? value : '${value}Z').toLocal();
}
