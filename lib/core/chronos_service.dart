/// Chronos - Layanan pengaturan waktu untuk testing.
/// Override hari dan jam yang dibaca oleh seluruh sistem.
class ChronosService {
  static final ChronosService _instance = ChronosService._internal();
  static ChronosService get instance => _instance;
  ChronosService._internal() {
    final n = DateTime.now();
    _simulatedDate = DateTime(n.year, n.month, n.day, 8, 0);
  }

  bool _enabled = false;
  late DateTime _simulatedDate;

  bool get enabled => _enabled;
  DateTime get simulatedDate => _simulatedDate;

  static const dayLabels = {
    1: 'Senin',
    2: 'Selasa',
    3: 'Rabu',
    4: 'Kamis',
    5: 'Jumat',
    6: 'Sabtu',
    7: 'Minggu',
  };

  String get dayName => dayLabels[_simulatedDate.weekday] ?? 'Senin';

  /// Waktu yang dibaca sistem. Jika Chronos aktif, return waktu override.
  DateTime now() {
    if (!_enabled) return DateTime.now();
    return _simulatedDate;
  }

  void setEnabled(bool value) => _enabled = value;
  
  void setDate(DateTime date) {
    _simulatedDate = DateTime(
      date.year, date.month, date.day,
      _simulatedDate.hour, _simulatedDate.minute,
    );
  }

  void setHour(int h) {
    _simulatedDate = DateTime(
      _simulatedDate.year, _simulatedDate.month, _simulatedDate.day,
      h.clamp(0, 23), _simulatedDate.minute,
    );
  }

  void setMinute(int m) {
    _simulatedDate = DateTime(
      _simulatedDate.year, _simulatedDate.month, _simulatedDate.day,
      _simulatedDate.hour, m.clamp(0, 59), _simulatedDate.second,
    );
  }

  void setDay(int day) {
    final diff = day - _simulatedDate.weekday;
    _simulatedDate = _simulatedDate.add(Duration(days: diff));
  }

  int get dayOfWeek => _simulatedDate.weekday;
  int get hour => _simulatedDate.hour;
  int get minute => _simulatedDate.minute;
  int get second => _simulatedDate.second;

  void tick() {
    if (!_enabled) return;
    _simulatedDate = _simulatedDate.add(const Duration(seconds: 1));
  }
}
