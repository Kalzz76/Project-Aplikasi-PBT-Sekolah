enum TeacherAttendanceStatus { hadir, tidakHadir }

enum TeacherAbsenceReason { terlambat, rapat, sakit, lainnya }

class TeacherAttendance {
  final String id;
  final String teacherId;
  final String classId;
  final String subjectId;
  final String slotLabel;   // Jam ke berapa, misal "Jam 3"
  final DateTime date;
  final TeacherAttendanceStatus status;
  final TeacherAbsenceReason? reason; // Wajib jika tidak hadir
  final String? notes;                // Keterangan bebas (opsional)
  final int amountOfLessons;         // Jumlah jam pelajaran (misal 2 jam)
  final String reportedBy;            // ID sekretaris yang mengisi

  TeacherAttendance({
    required this.id,
    required this.teacherId,
    required this.classId,
    required this.subjectId,
    required this.slotLabel,
    required this.date,
    required this.status,
    this.reason,
    this.notes,
    this.amountOfLessons = 1,
    required this.reportedBy,
  });

  String get statusLabel {
    switch (status) {
      case TeacherAttendanceStatus.hadir: return 'Hadir';
      case TeacherAttendanceStatus.tidakHadir: return 'Tidak Hadir';
    }
  }

  String get reasonLabel {
    if (reason == null) return '';
    switch (reason!) {
      case TeacherAbsenceReason.terlambat: return 'Terlambat';
      case TeacherAbsenceReason.rapat: return 'Rapat';
      case TeacherAbsenceReason.sakit: return 'Sakit';
      case TeacherAbsenceReason.lainnya: return 'Lainnya';
    }
  }

  static TeacherAbsenceReason? reasonFromString(String? s) {
    switch (s) {
      case 'terlambat': return TeacherAbsenceReason.terlambat;
      case 'rapat': return TeacherAbsenceReason.rapat;
      case 'sakit': return TeacherAbsenceReason.sakit;
      case 'lainnya': return TeacherAbsenceReason.lainnya;
      default: return null;
    }
  }

  static String reasonToString(TeacherAbsenceReason? r) {
    if (r == null) return '';
    switch (r) {
      case TeacherAbsenceReason.terlambat: return 'terlambat';
      case TeacherAbsenceReason.rapat: return 'rapat';
      case TeacherAbsenceReason.sakit: return 'sakit';
      case TeacherAbsenceReason.lainnya: return 'lainnya';
    }
  }
}
