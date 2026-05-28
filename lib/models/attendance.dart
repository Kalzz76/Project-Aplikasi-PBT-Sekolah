enum AttendanceStatus { hadir, izin, sakit, alpa, pulang }

/// Status validasi absensi oleh guru
enum ValidationStatus { pending, validated, rejected }

class Attendance {
  final String id;
  final String studentId;
  final String classId;
  final String subjectId;
  final String slotLabel; // Jam ke berapa, misal "Jam 1"
  final DateTime date;
  final AttendanceStatus status;
  final String markedBy;
  final String markedByRole; // 'guru', 'siswa', 'admin'
  final String markedByName;
  final String? reason;
  final String? notes;
  final ValidationStatus validationStatus;
  final String? validatedBy;   // ID guru yang validasi
  final DateTime? validatedAt; // Waktu validasi

  Attendance({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.subjectId,
    this.slotLabel = '',
    required this.date,
    required this.status,
    required this.markedBy,
    required this.markedByRole,
    this.markedByName = '',
    this.reason,
    this.notes,
    this.validationStatus = ValidationStatus.pending,
    this.validatedBy,
    this.validatedAt,
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

  String get validationLabel {
    switch (validationStatus) {
      case ValidationStatus.pending: return 'Menunggu Validasi';
      case ValidationStatus.validated: return 'Tervalidasi';
      case ValidationStatus.rejected: return 'Ditolak';
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

  /// Buat salinan dengan field tertentu diubah
  Attendance copyWith({
    ValidationStatus? validationStatus,
    String? validatedBy,
    DateTime? validatedAt,
  }) {
    return Attendance(
      id: id,
      studentId: studentId,
      classId: classId,
      subjectId: subjectId,
      slotLabel: slotLabel,
      date: date,
      status: status,
      markedBy: markedBy,
      markedByRole: markedByRole,
      markedByName: markedByName,
      reason: reason,
      notes: notes,
      validationStatus: validationStatus ?? this.validationStatus,
      validatedBy: validatedBy ?? this.validatedBy,
      validatedAt: validatedAt ?? this.validatedAt,
    );
  }
}
