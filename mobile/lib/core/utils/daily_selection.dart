/// Dar es Salaam is UTC+3, with no daylight-saving clock changes.
DateTime darCalendarDay(DateTime instant) {
  final dar = instant.toUtc().add(const Duration(hours: 3));
  return DateTime.utc(dar.year, dar.month, dar.day);
}

/// Stable across restarts, list ordering, locale and month/year boundaries.
/// Content changes can change selection; this is not a persisted assignment.
T? selectDaily<T>(Iterable<T> items, DateTime instant, String Function(T) id) {
  final sorted = items.toList()..sort((a, b) => id(a).compareTo(id(b)));
  if (sorted.isEmpty) return null;
  final day = darCalendarDay(instant).difference(DateTime.utc(2024)).inDays;
  return sorted[day % sorted.length];
}
