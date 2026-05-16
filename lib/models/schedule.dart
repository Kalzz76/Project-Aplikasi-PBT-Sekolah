class ScheduleEntry {
  final String id;
  final String day; // Senin, Selasa, etc.
  final String slotLabel; // Jam 1, Jam 2, Istirahat, etc.
  final String classId;
  final String? subjectId;
  final String? roomId;
  final String? teacherId;
  final String? customTitle; // For Istirahat, Upacara, Tadarus, etc.
  final bool isEvent;

  ScheduleEntry({
    required this.id,
    required this.day,
    required this.slotLabel,
    required this.classId,
    this.subjectId,
    this.roomId,
    this.teacherId,
    this.customTitle,
    this.isEvent = false,
  });
}

class TimeSlot {
  final String label;
  final String timeRange;
  final bool isBreak;

  TimeSlot({required this.label, required this.timeRange, this.isBreak = false});
}
