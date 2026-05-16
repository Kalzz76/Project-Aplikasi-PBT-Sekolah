import 'package:flutter/material.dart';
import '../core/school_schedule_utils.dart';
import '../models/user.dart';
import '../models/student.dart';
import '../models/teacher.dart';
import '../models/school_class.dart';
import '../models/subject.dart';
import '../models/room.dart';
import '../models/attendance.dart';
import '../models/schedule.dart';
import '../models/import_student_row.dart';
import '../models/attendance_export_row.dart';
import '../models/sort_option.dart';
import '../data/mock_data.dart';

class ResetRequest {
  final String id;
  final String email;
  final DateTime timestamp;
  bool isProcessed;

  ResetRequest({required this.id, required this.email, required this.timestamp, this.isProcessed = false});
}

class CallNotification {
  final String id;
  final String classId;
  final String className;
  final String senderName;
  final String teacherId;
  final String? subjectName;
  final DateTime timestamp;

  CallNotification({
    required this.id,
    required this.classId,
    required this.className,
    required this.senderName,
    required this.teacherId,
    this.subjectName,
    required this.timestamp,
  });
}

class ClassAttendanceMonitor {
  final String classId;
  final String className;
  final bool hasAttendance;
  final int studentCount;
  final String? filledByRole;
  final String? filledByLabel;
  final DateTime? lastUpdatedAt;

  ClassAttendanceMonitor({
    required this.classId,
    required this.className,
    required this.hasAttendance,
    required this.studentCount,
    this.filledByRole,
    this.filledByLabel,
    this.lastUpdatedAt,
  });
}

/// Peran struktur organisasi kelas (otomatis untuk siswa baru).
const kOrgStructureRoles = [
  'Ketua Murid',
  'Wakil Ketua Murid',
  'Bendahara 1',
  'Bendahara 2',
  'Sekretaris 1',
  'Sekretaris 2',
  'Pj Keagamaan',
  'Pj Keamanan',
  'Pj Kebersihan',
  'Pj Logistik',
];

class AppProvider with ChangeNotifier {
  UserProfile _currentUser = MockData.users['admin']!;
  String _activeMenu = 'dashboard';
  bool _isSidebarOpen = true;
  bool _isLoggedIn = false;
  bool _isDarkMode = false;
  
  List<CallNotification> _calls = [];
  List<CallNotification> get calls => _calls;

  void callTeacher(String classId, String className, String senderName, String teacherId, {String? subjectName}) {
    _calls.insert(0, CallNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      classId: classId,
      className: className,
      senderName: senderName,
      teacherId: teacherId,
      subjectName: subjectName,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  String get currentDayName => SchoolScheduleUtils.currentDayName();

  SchoolClass? findClassByIdOrName(String? idOrName) {
    if (idOrName == null || idOrName.isEmpty) return null;
    for (final c in _classes) {
      if (c.id == idOrName || SchoolScheduleUtils.classNamesMatch(c.name, idOrName)) {
        return c;
      }
    }
    return null;
  }

  Subject? findSubjectByIdOrName(String? idOrName) {
    if (idOrName == null || idOrName.isEmpty) return null;
    for (final s in _subjects) {
      if (s.id == idOrName || s.name == idOrName) return s;
    }
    return null;
  }

  String subjectDisplayName(String subjectId) =>
      findSubjectByIdOrName(subjectId)?.name ?? subjectId;

  Room? findRoomByIdOrName(String? idOrName) {
    if (idOrName == null) return null;
    for (final r in _rooms) {
      if (r.id == idOrName || r.name == idOrName) return r;
    }
    return null;
  }

  String roomDisplayName(ScheduleEntry entry, SchoolClass cls) {
    if (entry.roomId != null) {
      return findRoomByIdOrName(entry.roomId)?.name ?? entry.roomId!;
    }
    return cls.roomName;
  }

  bool isSameCalendarDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool isLessonTimeActive(String day, String slotLabel) {
    if (day != currentDayName) return false;
    final slots = getTimeSlots(day);
    final slot = slots.cast<TimeSlot?>().firstWhere(
      (s) => s!.label == slotLabel,
      orElse: () => null,
    );
    if (slot == null || slot.isBreak) return false;
    return SchoolScheduleUtils.isNowWithinRange(slot.timeRange);
  }

  bool isScheduleGroupActive(List<ScheduleEntry> entries, String day) {
    for (final e in entries) {
      if (isLessonTimeActive(day, e.slotLabel)) return true;
    }
    return false;
  }

  List<Attendance> getTodayAttendanceForSession({
    required String classId,
    required String subjectName,
  }) {
    final today = DateTime.now();
    return _attendance.where((a) {
      return a.classId == classId &&
          a.subjectId == subjectName &&
          isSameCalendarDay(a.date, today);
    }).toList();
  }

  bool isAttendanceFilledBySecretary(String classId, String subjectName) {
    final records = getTodayAttendanceForSession(classId: classId, subjectName: subjectName);
    return records.isNotEmpty && records.any((a) => a.markedByRole == 'siswa');
  }

  bool canGuruMarkAttendance(String classId, String subjectName) {
    if (isAttendanceFilledBySecretary(classId, subjectName)) return false;
    return true;
  }

  bool canMarkAttendanceNow(List<ScheduleEntry> entries, String day) =>
      isScheduleGroupActive(entries, day);

  Map<String, AttendanceStatus> loadAttendanceStateForSession({
    required String classId,
    required String subjectName,
    required List<Student> students,
  }) {
    final existing = getTodayAttendanceForSession(classId: classId, subjectName: subjectName);
    final map = <String, AttendanceStatus>{};
    for (final s in students) {
      final rec = existing.where((a) => a.studentId == s.id).toList();
      map[s.id] = rec.isNotEmpty ? rec.first.status : AttendanceStatus.hadir;
    }
    return map;
  }

  String assignOrgPositionForClass(String className) {
    final inClass = _students.where((s) => s.kelas == className).toList();
    final used = inClass.map((s) => s.position).toSet();
    for (final role in kOrgStructureRoles) {
      if (!used.contains(role)) return role;
    }
    return 'Anggota';
  }

  static bool isStructurePosition(String position) =>
      kOrgStructureRoles.contains(position) ||
      const {'Wakil Ketua', 'Bendahara', 'Sekretaris'}.contains(position);

  static bool positionMatchesRole(String position, String role) {
    if (position == role) return true;
    const legacyMap = {
      'Wakil Ketua': 'Wakil Ketua Murid',
      'Bendahara': 'Bendahara 1',
      'Sekretaris': 'Sekretaris 1',
    };
    return legacyMap[position] == role;
  }

  /// Jabatan struktur kelas diambil langsung dari field [Student.position].
  Map<String, String> getClassStructureFromStudents(SchoolClass cls) {
    final students = getStudentsByClass(cls.id);
    final result = <String, String>{};
    for (final role in kOrgStructureRoles) {
      Student? holder;
      for (final s in students) {
        if (positionMatchesRole(s.position, role)) {
          holder = s;
          break;
        }
      }
      result[role] = holder?.name ?? 'Belum Diatur';
    }
    return result;
  }

  void applyClassStructure(SchoolClass cls, Map<String, String?> roleToStudentName) {
    final className = cls.name;
    for (int i = 0; i < _students.length; i++) {
      final s = _students[i];
      if (s.kelas != className && s.kelas != cls.id) continue;
      if (isStructurePosition(s.position)) {
        _students[i] = Student(
          id: s.id,
          nis: s.nis,
          nisn: s.nisn,
          name: s.name,
          gender: s.gender,
          kelas: s.kelas,
          position: 'Anggota',
        );
      }
    }

    for (final role in kOrgStructureRoles) {
      final studentName = roleToStudentName[role];
      if (studentName == null || studentName.isEmpty || studentName == 'Belum Diatur') {
        continue;
      }
      final idx = _students.indexWhere((s) => s.kelas == className && s.name == studentName);
      if (idx == -1) continue;
      final s = _students[idx];
      _students[idx] = Student(
        id: s.id,
        nis: s.nis,
        nisn: s.nisn,
        name: s.name,
        gender: s.gender,
        kelas: s.kelas,
        position: role,
      );
    }
    notifyListeners();
  }

  void syncClassStructureFromStudents(SchoolClass cls) {
    getClassStructureFromStudents(cls);
    notifyListeners();
  }

  SchoolClass resolveOrCreateClass(String kelasName, {bool createIfMissing = true}) {
    final trimmed = kelasName.trim();
    final existing = findClassByIdOrName(trimmed);
    if (existing != null) return existing;

    if (!createIfMissing) {
      return SchoolClass(
        id: '_unknown',
        name: trimmed,
        homeroomTeacherId: '',
        homeroomTeacherName: 'Belum diatur',
        roomName: '-',
        totalStudents: 0,
      );
    }

    final newClass = SchoolClass(
      id: 'K_${DateTime.now().millisecondsSinceEpoch}',
      name: trimmed,
      homeroomTeacherId: '',
      homeroomTeacherName: 'Belum diatur',
      roomName: '-',
      totalStudents: 0,
    );
    addClass(newClass);
    return newClass;
  }

  ImportResult importStudents(List<ImportStudentRow> rows, {bool autoCreateClass = true}) {
    int success = 0;
    int skipped = 0;
    int classesCreated = 0;
    final errors = <String>[];

    for (final row in rows) {
      if (row.name.trim().isEmpty || row.nis.trim().isEmpty) {
        skipped++;
        errors.add('Baris dilewati: NIS/Nama kosong');
        continue;
      }

      if (isDuplicateNis(row.nis) || (row.nisn.isNotEmpty && isDuplicateNisn(row.nisn))) {
        skipped++;
        errors.add('${row.name}: NIS/NISN sudah ada');
        continue;
      }

      final beforeCount = _classes.length;
      final cls = resolveOrCreateClass(row.kelas, createIfMissing: autoCreateClass);
      if (_classes.length > beforeCount) classesCreated++;

      final gender = row.gender.toUpperCase().startsWith('P') ? 'P' : 'L';
      final position = assignOrgPositionForClass(cls.name);

      addStudent(Student(
        id: 'S_${DateTime.now().microsecondsSinceEpoch}_$success',
        nis: row.nis.trim(),
        nisn: row.nisn.trim(),
        name: row.name.trim(),
        gender: gender,
        kelas: cls.name,
        position: position,
      ));
      success++;
    }

    notifyListeners();
    return ImportResult(
      success: success,
      skipped: skipped,
      classesCreated: classesCreated,
      errors: errors,
    );
  }

  bool isDuplicateNis(String nis, {String? excludeStudentId}) =>
      _students.any((s) => s.nis == nis && s.id != excludeStudentId);

  bool isDuplicateNisn(String nisn, {String? excludeStudentId}) =>
      nisn.isNotEmpty && _students.any((s) => s.nisn == nisn && s.id != excludeStudentId);

  bool isDuplicateStudentName(String name, String kelas, {String? excludeStudentId}) =>
      _students.any((s) =>
          s.name.toLowerCase() == name.trim().toLowerCase() &&
          s.kelas == kelas &&
          s.id != excludeStudentId);

  bool isDuplicateTeacherNip(String nip, {String? excludeId}) =>
      _teachers.any((t) => t.nip == nip && t.id != excludeId);

  bool isDuplicateRoomName(String name, {String? excludeId}) =>
      _rooms.any((r) => r.name.toLowerCase() == name.trim().toLowerCase() && r.id != excludeId);

  bool isDuplicateSubjectName(String name, {String? excludeId}) =>
      _subjects.any((s) => s.name.toLowerCase() == name.trim().toLowerCase() && s.id != excludeId);

  bool isDuplicateClassName(String name, {String? excludeId}) =>
      _classes.any((c) =>
          SchoolScheduleUtils.classNamesMatch(c.name, name) && c.id != excludeId);

  bool isDuplicateAccountUsername(String username, {String? excludeId}) =>
      _accounts.any((a) =>
          a.username.toLowerCase() == username.trim().toLowerCase() && a.id != excludeId);

  List<ClassAttendanceMonitor> getTodayClassMonitoring() {
    final today = DateTime.now();
    final list = _classes.map((cls) {
      final todayRecords = _attendance.where((a) =>
          a.classId == cls.id && isSameCalendarDay(a.date, today)).toList();
      final has = todayRecords.isNotEmpty;
      String? role;
      String? label;
      DateTime? lastUpdate;
      
      if (has) {
        final first = todayRecords.first;
        role = first.markedByRole;
        label = first.markedByLabel;
        // Get the latest timestamp for sorting
        lastUpdate = todayRecords.map((a) => a.date).reduce((a, b) => a.isAfter(b) ? a : b);
      }
      
      return ClassAttendanceMonitor(
        classId: cls.id,
        className: cls.name,
        hasAttendance: has,
        studentCount: todayRecords.map((a) => a.studentId).toSet().length,
        filledByRole: role,
        filledByLabel: label,
        lastUpdatedAt: lastUpdate,
      );
    }).where((m) => m.hasAttendance).toList(); // Only show those with attendance

    // Sort by lastUpdatedAt descending (newest first)
    list.sort((a, b) {
      if (a.lastUpdatedAt == null) return 1;
      if (b.lastUpdatedAt == null) return -1;
      return b.lastUpdatedAt!.compareTo(a.lastUpdatedAt!);
    });

    return list;
  }

  List<AttendanceExportRow> buildAttendanceExportRows(List<Attendance> records) {
    return records.map((att) {
      final student = _students.firstWhere(
        (s) => s.id == att.studentId,
        orElse: () => Student(id: '', nis: '-', nisn: '-', name: '-', gender: '', kelas: '', position: ''),
      );
      final cls = findClassByIdOrName(att.classId);
      return AttendanceExportRow(
        nisNisn: '${student.nis} / ${student.nisn}',
        name: student.name,
        kehadiran: att.statusLabel,
        kelas: cls?.name ?? att.classId,
        mapel: att.subjectId,
        tanggal: '${att.date.day}/${att.date.month}/${att.date.year}',
        diisiOleh: att.markedByLabel,
      );
    }).toList();
  }

  void dismissCall(String id) {
    _calls.removeWhere((c) => c.id == id);
    notifyListeners();
  }
  
  // Attendance Session State
  SchoolClass? _selectedClassForAttendance;
  Subject? _selectedSubjectForAttendance;
  
  SchoolClass? get selectedClassForAttendance => _selectedClassForAttendance;
  Subject? get selectedSubjectForAttendance => _selectedSubjectForAttendance;

  void startAttendanceSession(SchoolClass cls, Subject sub, {bool forceSecretary = false}) {
    if (!forceSecretary &&
        _currentUser.role == UserRole.guru &&
        !canGuruMarkAttendance(cls.id, sub.name)) {
      return;
    }
    _selectedClassForAttendance = cls;
    _selectedSubjectForAttendance = sub;
    if (_currentUser.role == UserRole.guru || forceSecretary) {
      _activeMenu = 'isi_absensi';
    }
    notifyListeners();
  }

  List<Student> getStudentsByClass(String classIdOrName) {
    final cls = findClassByIdOrName(classIdOrName);
    final className = cls?.name ?? classIdOrName;
    return _students
        .where((s) => s.kelas == className || s.kelas == classIdOrName)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
  
  // Student Data
  List<Student> _students = MockData.students;
  // Class Data
  List<SchoolClass> _classes = MockData.classes;
  // Teacher Data
  List<Teacher> _teachers = MockData.teachers;
  // Subject Data
  List<Subject> _subjects = MockData.subjects;
  // Room Data
  List<Room> _rooms = MockData.rooms;
  // Attendance Data
  List<Attendance> _attendance = [];
  // Schedule Data
  List<ScheduleEntry> _schedules = MockData.schedules;
  // Accounts Data
  List<UserProfile> _accounts = MockData.users.values.toList();
  // Reset Requests
  List<ResetRequest> _resetRequests = [];
  
  List<ResetRequest> get resetRequests => _resetRequests.where((r) => !r.isProcessed).toList();

  void requestPasswordReset(String email) {
    _resetRequests.add(ResetRequest(
      id: DateTime.now().toString(),
      email: email,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  void processResetRequest(String id) {
    final index = _resetRequests.indexWhere((r) => r.id == id);
    if (index != -1) {
      _resetRequests[index].isProcessed = true;
      notifyListeners();
    }
  }

  void resetPassword(String accountId) {
    final index = _accounts.indexWhere((a) => a.id == accountId);
    if (index != -1) {
      final role = _accounts[index].role;
      final newPass = role == UserRole.guru ? 'guru123' : 'siswa123';
      
      _accounts[index] = UserProfile(
        id: _accounts[index].id,
        name: _accounts[index].name,
        username: _accounts[index].username,
        password: newPass,
        role: _accounts[index].role,
        avatar: _accounts[index].avatar,
        subject: _accounts[index].subject,
        kelas: _accounts[index].kelas,
        nipNis: _accounts[index].nipNis,
      );
      notifyListeners();
    }
  }
  
  Map<String, List<TimeSlot>> get timeSlotsByDay => {
    'Senin': [
      TimeSlot(label: 'Jam 1', timeRange: '06.30 - 07.15'),
      TimeSlot(label: 'Jam 2', timeRange: '07.15 - 08.00'),
      TimeSlot(label: 'Jam 3', timeRange: '08.00 - 08.45'),
      TimeSlot(label: 'Jam 4', timeRange: '08.45 - 09.30'),
      TimeSlot(label: 'Jam 5', timeRange: '09.30 - 10.15'),
      TimeSlot(label: 'Istirahat', timeRange: '10.15 - 10.30', isBreak: true),
      TimeSlot(label: 'Jam 6', timeRange: '10.30 - 11.15'),
      TimeSlot(label: 'Jam 7', timeRange: '11.15 - 12.00'),
      TimeSlot(label: 'Jam 8', timeRange: '12.00 - 12.45'),
      TimeSlot(label: 'Jam 9', timeRange: '12.45 - 13.30'),
      TimeSlot(label: 'Jam 10', timeRange: '13.30 - 14.15'),
      TimeSlot(label: 'Jam 11', timeRange: '14.15 - 15.00'),
      TimeSlot(label: 'Jam 12', timeRange: '15.00 - 15.45'),
    ],
    'Selasa': [
      TimeSlot(label: 'Pembiasaan', timeRange: '06.30 - 06.45', isBreak: true),
      TimeSlot(label: 'Jam 1', timeRange: '06.45 - 07.30'),
      TimeSlot(label: 'Jam 2', timeRange: '07.30 - 08.15'),
      TimeSlot(label: 'Jam 3', timeRange: '08.15 - 09.00'),
      TimeSlot(label: 'Jam 4', timeRange: '09.00 - 09.45'),
      TimeSlot(label: 'Jam 5', timeRange: '09.45 - 10.30'),
      TimeSlot(label: 'Istirahat', timeRange: '10.30 - 10.45', isBreak: true),
      TimeSlot(label: 'Jam 6', timeRange: '10.45 - 11.30'),
      TimeSlot(label: 'Jam 7', timeRange: '11.30 - 12.15'),
      TimeSlot(label: 'Jam 8', timeRange: '12.15 - 13.00'),
      TimeSlot(label: 'Jam 9', timeRange: '13.00 - 13.45'),
      TimeSlot(label: 'Jam 10', timeRange: '13.45 - 14.30'),
      TimeSlot(label: 'Jam 11', timeRange: '14.30 - 15.15'),
      TimeSlot(label: 'Jam 12', timeRange: '15.15 - 16.00'),
    ],
    'Rabu': [
      TimeSlot(label: 'Jam 1', timeRange: '06.30 - 07.15'),
      TimeSlot(label: 'Jam 2', timeRange: '07.15 - 08.00'),
      TimeSlot(label: 'Jam 3', timeRange: '08.00 - 08.45'),
      TimeSlot(label: 'Jam 4', timeRange: '08.45 - 09.30'),
      TimeSlot(label: 'Jam 5', timeRange: '09.30 - 10.15'),
      TimeSlot(label: 'Istirahat', timeRange: '10.15 - 10.30', isBreak: true),
      TimeSlot(label: 'Jam 6', timeRange: '10.30 - 11.15'),
      TimeSlot(label: 'Jam 7', timeRange: '11.15 - 12.00'),
      TimeSlot(label: 'Jam 8', timeRange: '12.00 - 12.45'),
      TimeSlot(label: 'Jam 9', timeRange: '12.45 - 13.30'),
      TimeSlot(label: 'Jam 10', timeRange: '13.30 - 14.15'),
      TimeSlot(label: 'Jam 11', timeRange: '14.15 - 15.00'),
      TimeSlot(label: 'Jam 12', timeRange: '15.00 - 15.45'),
    ],
    'Kamis': [
      TimeSlot(label: 'Pembiasaan', timeRange: '06.30 - 06.45', isBreak: true),
      TimeSlot(label: 'Jam 1', timeRange: '06.45 - 07.30'),
      TimeSlot(label: 'Jam 2', timeRange: '07.30 - 08.15'),
      TimeSlot(label: 'Jam 3', timeRange: '08.15 - 09.00'),
      TimeSlot(label: 'Jam 4', timeRange: '09.00 - 09.45'),
      TimeSlot(label: 'Jam 5', timeRange: '09.45 - 10.30'),
      TimeSlot(label: 'Istirahat', timeRange: '10.30 - 10.45', isBreak: true),
      TimeSlot(label: 'Jam 6', timeRange: '10.45 - 11.30'),
      TimeSlot(label: 'Jam 7', timeRange: '11.30 - 12.15'),
      TimeSlot(label: 'Jam 8', timeRange: '12.15 - 13.00'),
      TimeSlot(label: 'Jam 9', timeRange: '13.00 - 13.45'),
      TimeSlot(label: 'Jam 10', timeRange: '13.45 - 14.30'),
      TimeSlot(label: 'Jam 11', timeRange: '14.30 - 15.15'),
      TimeSlot(label: 'Jam 12', timeRange: '15.15 - 16.00'),
    ],
    'Jumat': [
      TimeSlot(label: 'Jam 1', timeRange: '06.30 - 07.15'),
      TimeSlot(label: 'Jam 2', timeRange: '07.15 - 08.00'),
      TimeSlot(label: 'Jam 3', timeRange: '08.00 - 08.45'),
      TimeSlot(label: 'Jam 4', timeRange: '08.45 - 09.30'),
      TimeSlot(label: 'Jam 5', timeRange: '09.30 - 10.15'),
      TimeSlot(label: 'Jam 6', timeRange: '10.15 - 11.00'),
      TimeSlot(label: 'Jam 7', timeRange: '11.00 - 11.45'),
      TimeSlot(label: 'Istirahat', timeRange: '11.45 - 13.00', isBreak: true),
      TimeSlot(label: 'Jam 8', timeRange: '13.00 - 13.45'),
      TimeSlot(label: 'Jam 9', timeRange: '13.45 - 14.30'),
      TimeSlot(label: 'Jam 10', timeRange: '14.30 - 15.15'),
      TimeSlot(label: 'Jam 11', timeRange: '15.15 - 16.00'),
    ],
  };

  UserProfile get currentUser => _currentUser;
  String get activeMenu => _activeMenu;
  bool get isSidebarOpen => _isSidebarOpen;
  bool get isLoggedIn => _isLoggedIn;
  bool get isDarkMode => _isDarkMode;
  List<Student> get students => _sortByName(_students, (s) => s.name);
  List<SchoolClass> get classes => _sortByName(_classes, (c) => c.name);
  List<Teacher> get teachers => _sortByName(_teachers, (t) => t.name);
  List<Subject> get subjects => _sortByName(_subjects, (s) => s.name);
  List<Room> get rooms => _sortByName(_rooms, (r) => r.name);
  List<Attendance> get attendance => _attendance; // Attendance usually sorted by date, keep as is for now
  List<ScheduleEntry> get schedules => _schedules;
  List<UserProfile> get accounts => _sortByName(_accounts, (u) => u.name);

  List<T> _sortByName<T>(List<T> data, String Function(T) nameSelector) {
    return List<T>.from(data)..sort((a, b) => nameSelector(a).toLowerCase().compareTo(nameSelector(b).toLowerCase()));
  }

  List<T> sortData<T>(List<T> data, DataSortOption option, String Function(T) nameSelector, String Function(T) idSelector) {
    List<T> sortedList = List.from(data);
    switch (option) {
      case DataSortOption.nameAsc:
        sortedList.sort((a, b) => nameSelector(a).toLowerCase().compareTo(nameSelector(b).toLowerCase()));
        break;
      case DataSortOption.nameDesc:
        sortedList.sort((a, b) => nameSelector(b).toLowerCase().compareTo(nameSelector(a).toLowerCase()));
        break;
      case DataSortOption.newest:
        sortedList.sort((a, b) => idSelector(b).compareTo(idSelector(a)));
        break;
      case DataSortOption.oldest:
        sortedList.sort((a, b) => idSelector(a).compareTo(idSelector(b)));
        break;
    }
    return sortedList;
  }

  List<TimeSlot> getTimeSlots(String day) => timeSlotsByDay[day] ?? timeSlotsByDay['Senin']!;

  bool login(String username, String password) {
    final cleanUsername = username.trim().toLowerCase();
    final cleanPassword = password.trim();
    
    try {
      final account = _accounts.firstWhere(
        (u) => u.username.toLowerCase() == cleanUsername && u.password == cleanPassword,
      );
      
      _currentUser = account;
      _isLoggedIn = true;
      _activeMenu = 'dashboard';
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }


  // Account Management Logic
  void generateTeacherAccounts() {
    for (var teacher in _teachers) {
      final exists = _accounts.any((a) => a.nipNis == teacher.nip);
      if (!exists) {
        final username = teacher.name.split(' ')[0].toLowerCase() + teacher.nip.substring(teacher.nip.length - 4);
        _accounts.add(UserProfile(
          id: DateTime.now().toString() + teacher.id,
          name: teacher.name,
          username: username,
          password: 'guru123',
          role: UserRole.guru,
          avatar: teacher.avatar,
          subject: teacher.subjects.isNotEmpty ? teacher.subjects[0] : null,
          nipNis: teacher.nip,
        ));
      }
    }
    notifyListeners();
  }

  void generateStudentAccounts() {
    final secretaries = _students.where((s) => s.position.contains('Sekretaris'));
    for (var student in secretaries) {
      final exists = _accounts.any((a) => a.nipNis == student.nis);
      if (!exists) {
        final username = student.name.split(' ')[0].toLowerCase() + student.nis.substring(student.nis.length - 2);
        _accounts.add(UserProfile(
          id: DateTime.now().toString() + student.id,
          name: student.name,
          username: username,
          password: 'siswa123',
          role: UserRole.siswa,
          avatar: 'https://i.pravatar.cc/150?u=${student.id}',
          kelas: student.kelas,
          nipNis: student.nis,
          position: student.position,
        ));
      }
    }
    notifyListeners();
  }

  void deleteAccount(String id) {
    _accounts.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  // Student CRUD
  void addStudent(Student student) {
    if (isDuplicateNis(student.nis)) return;
    if (student.nisn.isNotEmpty && isDuplicateNisn(student.nisn)) return;
    _students.insert(0, student);
    _syncClassStudentCount(student.kelas);
    notifyListeners();
  }

  void _syncClassStudentCount(String kelasName) {
    final cls = findClassByIdOrName(kelasName);
    if (cls == null) return;
    final count = getStudentsByClass(cls.id).length;
    final idx = _classes.indexWhere((c) => c.id == cls.id);
    if (idx != -1) {
      _classes[idx] = SchoolClass(
        id: cls.id,
        name: cls.name,
        homeroomTeacherId: cls.homeroomTeacherId,
        homeroomTeacherName: cls.homeroomTeacherName,
        roomName: cls.roomName,
        totalStudents: count,
      );
    }
  }

  void updateStudent(Student student) {
    final index = _students.indexWhere((s) => s.id == student.id);
    if (index != -1) {
      _students[index] = student;
      notifyListeners();
    }
  }

  void deleteStudent(String id) {
    _students.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  // Class CRUD
  void addClass(SchoolClass cls) {
    if (isDuplicateClassName(cls.name)) return;
    _classes.add(cls);
    
    // Automatically generate default events for the new class
    final defaultEvents = [
      {'day': 'Senin', 'slot': 'Jam 1', 'title': 'Upacara/Perwalian'},
      {'day': 'Senin', 'slot': 'Istirahat', 'title': 'Istirahat'},
      {'day': 'Selasa', 'slot': 'Pembiasaan', 'title': 'TADARUS & SARAPAN'},
      {'day': 'Selasa', 'slot': 'Istirahat', 'title': 'Istirahat'},
      {'day': 'Rabu', 'slot': 'Jam 1', 'title': 'Sholat Dhuha & Tadarus'},
      {'day': 'Rabu', 'slot': 'Istirahat', 'title': 'Istirahat'},
      {'day': 'Kamis', 'slot': 'Pembiasaan', 'title': 'TADARUS & LITERASI'},
      {'day': 'Kamis', 'slot': 'Istirahat', 'title': 'Istirahat'},
      {'day': 'Jumat', 'slot': 'Jam 1', 'title': 'Senam & Jumat Bersih'},
      {'day': 'Jumat', 'slot': 'Istirahat', 'title': 'Istirahat'},
    ];

    for (var ev in defaultEvents) {
      _schedules.add(ScheduleEntry(
        id: 'auto_${cls.id}_${ev['day']}_${ev['slot']}',
        day: ev['day']!,
        slotLabel: ev['slot']!,
        classId: cls.id,
        isEvent: true,
        customTitle: ev['title'],
      ));
    }
    
    notifyListeners();
  }

  void updateClass(SchoolClass cls) {
    final index = _classes.indexWhere((c) => c.id == cls.id);
    if (index != -1) {
      _classes[index] = cls;
      notifyListeners();
    }
  }

  void deleteClass(String id) {
    _classes.removeWhere((c) => c.id == id);
    _schedules.removeWhere((s) => s.classId == id); // Also cleanup schedules
    notifyListeners();
  }

  void setActiveMenu(String menu) {
    _activeMenu = menu;
    notifyListeners();
  }

  void toggleSidebar() {
    _isSidebarOpen = !_isSidebarOpen;
    notifyListeners();
  }

  // Subject CRUD
  void addSubject(Subject subject) {
    if (isDuplicateSubjectName(subject.name)) return;
    _subjects.insert(0, subject);
    notifyListeners();
  }

  void updateSubject(Subject subject) {
    final index = _subjects.indexWhere((s) => s.id == subject.id);
    if (index != -1) {
      _subjects[index] = subject;
      notifyListeners();
    }
  }

  void deleteSubject(String id) {
    _subjects.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  // Room CRUD
  void addRoom(Room room) {
    if (isDuplicateRoomName(room.name)) return;
    _rooms.insert(0, room);
    notifyListeners();
  }

  void updateRoom(Room room) {
    final index = _rooms.indexWhere((r) => r.id == room.id);
    if (index != -1) {
      _rooms[index] = room;
      notifyListeners();
    }
  }

  void deleteRoom(String id) {
    _rooms.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  // Teacher CRUD
  void addTeacher(Teacher teacher) {
    if (isDuplicateTeacherNip(teacher.nip)) return;
    _teachers.insert(0, teacher);
    notifyListeners();
  }

  void updateTeacher(Teacher teacher) {
    final index = _teachers.indexWhere((t) => t.id == teacher.id);
    if (index != -1) {
      _teachers[index] = teacher;
      notifyListeners();
    }
  }

  void deleteTeacher(String id) {
    _teachers.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  ScheduleEntry? _activeScheduleForSession;

  void setActiveScheduleForSession(ScheduleEntry? entry) {
    _activeScheduleForSession = entry;
  }

  bool canEditAttendanceNow() {
    if (_activeScheduleForSession == null) return true;
    return isScheduleGroupActive([_activeScheduleForSession!], currentDayName);
  }

  void updateProfile({required String name, String? username, String? password, String? avatar}) {
    final updatedUser = _currentUser!.copyWith(
      name: name,
      username: username ?? _currentUser!.username,
      password: password?.isNotEmpty == true ? password : _currentUser!.password,
      avatar: avatar ?? _currentUser!.avatar,
    );
    
    _currentUser = updatedUser;
    
    // Also update in accounts list
    final index = _accounts.indexWhere((a) => a.id == updatedUser.id);
    if (index != -1) {
      _accounts[index] = updatedUser;
    }
    
    notifyListeners();
  }

  void addAccount(UserProfile account) {
    _accounts.add(account);
    notifyListeners();
  }

  // Attendance Logic — per siswa + mapel + hari (mapel berbeda = status berbeda)
  void addAttendance(Attendance record) {
    _attendance.removeWhere((a) =>
        a.studentId == record.studentId &&
        a.subjectId == record.subjectId &&
        isSameCalendarDay(a.date, record.date));
    _attendance.add(record);
    notifyListeners();
  }

  void saveAttendanceBatch({
    required SchoolClass cls,
    required Subject sub,
    required Map<String, AttendanceStatus> statuses,
    required UserProfile user,
    String? reason,
    List<ScheduleEntry>? scheduleEntries,
  }) {
    if (user.role == UserRole.guru &&
        !canGuruMarkAttendance(cls.id, sub.name)) {
      return;
    }
    if (scheduleEntries != null &&
        scheduleEntries.isNotEmpty &&
        !canMarkAttendanceNow(scheduleEntries, currentDayName)) {
      return;
    }

    final now = DateTime.now();
    final role = user.role == UserRole.siswa ? 'siswa' : user.role.name;

    for (final entry in statuses.entries) {
      addAttendance(Attendance(
        id: 'at_${now.millisecondsSinceEpoch}_${entry.key}',
        studentId: entry.key,
        classId: cls.id,
        subjectId: sub.name,
        date: now,
        status: entry.value,
        markedBy: user.id,
        markedByRole: role,
        markedByName: user.name,
        reason: reason,
      ));
    }
  }

  // Schedule Logic
  List<ScheduleEntry> getTeacherSchedules(String teacherId, {String? day}) {
    return _schedules.where((s) => s.teacherId == teacherId && (day == null || s.day == day)).toList();
  }

  List<Attendance> getTeacherAttendanceRekap(String teacherId, {DateTime? filterDate}) {
    final teacherSchedules = _schedules.where((s) => s.teacherId == teacherId && !s.isEvent).toList();
    final classIds = teacherSchedules.map((s) => s.classId).toSet();
    final subjectNames = teacherSchedules
        .map((s) => subjectDisplayName(s.subjectId ?? ''))
        .where((n) => n.isNotEmpty)
        .toSet();

    return _attendance.where((a) {
      final classMatch = classIds.contains(a.classId);
      final subjectMatch = subjectNames.contains(a.subjectId);
      final secretaryMatch = a.markedByRole == 'siswa' && classMatch;
      if (!classMatch && !secretaryMatch) return false;
      if (a.markedByRole == 'guru' && !subjectMatch && !classMatch) return false;
      if (filterDate != null && !isSameCalendarDay(a.date, filterDate)) return false;
      return classMatch || (a.markedByRole == 'siswa' && subjectNames.contains(a.subjectId));
    }).toList();
  }

  Map<String, int> getStudentMonthlyTotals(String studentId, {DateTime? month}) {
    final ref = month ?? DateTime.now();
    final records = _attendance.where((a) =>
        a.studentId == studentId &&
        a.date.month == ref.month &&
        a.date.year == ref.year);
    return {
      'hadir': records.where((a) => a.status == AttendanceStatus.hadir).length,
      'sakit': records.where((a) => a.status == AttendanceStatus.sakit).length,
      'izin': records.where((a) => a.status == AttendanceStatus.izin).length,
      'alpa': records.where((a) => a.status == AttendanceStatus.alpa).length,
    };
  }

  List<Attendance> getAdminAttendanceReport({DateTime? date, int? lastMonths}) {
    final now = DateTime.now();
    return _attendance.where((a) {
      if (date != null) {
        return isSameCalendarDay(a.date, date);
      }
      if (lastMonths != null) {
        final cutoff = DateTime(now.year, now.month - lastMonths, now.day);
        return a.date.isAfter(cutoff);
      }
      return isSameCalendarDay(a.date, now);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  void addScheduleEntry(ScheduleEntry entry) {
    _schedules.add(entry);
    notifyListeners();
  }

  void deleteScheduleEntry(String id) {
    _schedules.removeWhere((s) => s.id == id);
    notifyListeners();
  }
}
