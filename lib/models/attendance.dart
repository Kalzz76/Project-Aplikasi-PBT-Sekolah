enum AttendanceStatus { hadir, izin, sakit, alpa, pulang }

class Attendance {
  final String id;
  final String studentId;
  final String classId;
  final String subjectId;
  final DateTime date;
  final AttendanceStatus status;
  final String markedBy;
  final String markedByRole; // 'guru', 'siswa', 'admin'
  final String markedByName;
  final String? reason;
  final String? notes;

  Attendance({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.subjectId,
    required this.date,
    required this.status,
    required this.markedBy,
    required this.markedByRole,
    this.markedByName = '',
    this.reason,
    this.notes,
  });

  String get statusLabel {
    switch (status) {
      case AttendanceStatus.hadir: return 'Hadir';
      case AttendanceStatus.izin: return 'Izin';
      case AttendanceStatus.sakit: return 'Sakit';
      case AttendanceStatus.alpa: return 'Alpa';
      case AttendanceStatus.pulang: return 'Pulang';
    }
  }

  String get markedByLabel {
    if (markedByRole == 'siswa') {
      return 'Sekretaris: $markedByName${reason != null ? " (${reason!})" : ""}';
    } else if (markedByRole == 'guru') {
      return 'Guru: $markedByName';
    }
    return 'Admin: $markedByName';
  }
}
