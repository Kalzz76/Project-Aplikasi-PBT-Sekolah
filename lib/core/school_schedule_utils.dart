import 'chronos_service.dart';

/// Utilitas jadwal & waktu pelajaran (hari kerja, jam ke, rentang waktu).
class SchoolScheduleUtils {
  static const weekdayNames = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

  static String currentDayName() {
    final w = ChronosService.instance.now().weekday;
    if (w >= 1 && w <= 7) return weekdayNames[w - 1];
    return 'Senin';
  }

  static bool isSchoolDay(String day) =>
      ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'].contains(day);

  /// Parse "06.30 - 07.15" atau "06:30 - 07:15"
  static ({DateTime start, DateTime end})? parseTimeRange(String timeRange, [DateTime? base]) {
    final parts = timeRange.split(' - ');
    if (parts.length != 2) return null;
    final start = _parseClock(parts[0].trim(), base);
    final end = _parseClock(parts[1].trim(), base);
    if (start == null || end == null) return null;
    return (start: start, end: end);
  }

  static DateTime? _parseClock(String raw, DateTime? base) {
    final b = base ?? ChronosService.instance.now();
    final normalized = raw.replaceAll('.', ':');
    final seg = normalized.split(':');
    if (seg.length < 2) return null;
    final h = int.tryParse(seg[0]);
    final m = int.tryParse(seg[1]);
    if (h == null || m == null) return null;
    return DateTime(b.year, b.month, b.day, h, m);
  }

  static bool isNowWithinRange(String timeRange) {
    final range = parseTimeRange(timeRange);
    if (range == null) return false;
    final now = ChronosService.instance.now();
    return !now.isBefore(range.start) && now.isBefore(range.end);
  }

  static String normalizeClassName(String name) =>
      name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  static bool classNamesMatch(String a, String b) =>
      normalizeClassName(a) == normalizeClassName(b);
}
