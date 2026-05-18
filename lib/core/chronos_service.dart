/// Chronos - Layanan pengaturan waktu untuk testing.
/// Override hari dan jam yang dibaca oleh seluruh sistem.
class ChronosService {
  static final ChronosService _instance = ChronosService._internal();
  static ChronosService get instance => _instance;
  ChronosService._internal();

  bool _enabled = false;
  int _dayOfWeek = 1; // 1=Senin ... 5=Jumat
  int _hour = 8;
  int _minute = 0;

  bool get enabled => _enabled;
  int get dayOfWeek => _dayOfWeek;
  int get hour => _hour;
  int get minute => _minute;

  static const dayLabels = {
    1: 'Senin',
    2: 'Selasa',
    3: 'Rabu',
    4: 'Kamis',
    5: 'Jumat',
  };

  String get dayName => dayLabels[_dayOfWeek] ?? 'Senin';

  /// Waktu yang dibaca sistem. Jika Chronos aktif, return waktu override.
  DateTime now() {
    if (!_enabled) return DateTime.now();
    final real = DateTime.now();
    final currentWeekday = real.weekday;
    final diff = _dayOfWeek - currentWeekday;
    final targetDate = real.add(Duration(days: diff));
    return DateTime(
      targetDate.year, targetDate.month, targetDate.day,
      _hour, _minute, real.second,
    );
  }

  void setEnabled(bool value) => _enabled = value;
  void setDay(int day) => _dayOfWeek = day.clamp(1, 5);
  void setHour(int h) => _hour = h.clamp(6, 17);
  void setMinute(int m) => _minute = m.clamp(0, 59);
}
