import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/school_schedule_utils.dart';
import '../core/chronos_service.dart';
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
  AppProvider() {
    fetchEverything();
  }

  bool _isFetching = false;
  bool get isFetching => _isFetching;

  UserProfile _currentUser = MockData.users['admin']!;
  String _activeMenu = 'dashboard';
  bool _isSidebarOpen = true;
  bool _isLoggedIn = false;
  bool _isDarkMode = false;

  // --- Chronos ---
  bool get chronosEnabled => ChronosService.instance.enabled;
  int get chronosDay => ChronosService.instance.dayOfWeek;
  int get chronosHour => ChronosService.instance.hour;
  int get chronosMinute => ChronosService.instance.minute;
  String get chronosDayName => ChronosService.instance.dayName;

  void setChronosEnabled(bool v) { ChronosService.instance.setEnabled(v); notifyListeners(); }
  void setChronosDay(int d) { ChronosService.instance.setDay(d); notifyListeners(); }
  void setChronosHour(int h) { ChronosService.instance.setHour(h); notifyListeners(); }
  void setChronosMinute(int m) { ChronosService.instance.setMinute(m); notifyListeners(); }

  /// Waktu sistem (gunakan ini untuk semua fitur jadwal/absensi)
  DateTime systemNow() => ChronosService.instance.now();
  
  List<CallNotification> _calls = [];
  List<CallNotification> get calls => _calls;

  List<CallNotification> _callHistory = [];
  List<CallNotification> get callHistory => _callHistory;

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
    if (day != currentDayName || entries.isEmpty) return false;
    final slots = getTimeSlots(day);
    
    DateTime? minStart;
    DateTime? maxEnd;
    
    for (final e in entries) {
      final slot = slots.cast<TimeSlot?>().firstWhere(
        (s) => s!.label == e.slotLabel,
        orElse: () => null,
      );
      if (slot == null) continue;
      final range = SchoolScheduleUtils.parseTimeRange(slot.timeRange);
      if (range == null) continue;
      
      if (minStart == null || range.start.isBefore(minStart)) {
        minStart = range.start;
      }
      if (maxEnd == null || range.end.isAfter(maxEnd)) {
        maxEnd = range.end;
      }
    }
    
    if (minStart == null || maxEnd == null) return false;
    final now = systemNow();
    return !now.isBefore(minStart) && now.isBefore(maxEnd);
  }

  bool isLessonTimePassed(String day, String slotLabel) {
    if (day != currentDayName) return false;
    final slots = getTimeSlots(day);
    final slot = slots.cast<TimeSlot?>().firstWhere(
      (s) => s!.label == slotLabel,
      orElse: () => null,
    );
    if (slot == null || slot.isBreak) return false;
    return SchoolScheduleUtils.isNowAfterRange(slot.timeRange);
  }

  bool isScheduleGroupPassed(List<ScheduleEntry> entries, String day) {
    if (entries.isEmpty) return false;
    if (day != currentDayName) {
      final daysOfWeek = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
      final todayIdx = daysOfWeek.indexOf(currentDayName);
      final queryIdx = daysOfWeek.indexOf(day);
      if (queryIdx < todayIdx) return true;
      if (queryIdx > todayIdx) return false;
    }
    
    final slots = getTimeSlots(day);
    DateTime? maxEnd;
    
    for (final e in entries) {
      final slot = slots.cast<TimeSlot?>().firstWhere(
        (s) => s!.label == e.slotLabel,
        orElse: () => null,
      );
      if (slot == null) continue;
      final range = SchoolScheduleUtils.parseTimeRange(slot.timeRange);
      if (range == null) continue;
      
      if (maxEnd == null || range.end.isAfter(maxEnd)) {
        maxEnd = range.end;
      }
    }
    
    if (maxEnd == null) return false;
    final now = systemNow();
    return now.isAfter(maxEnd) || now.isAtSameMomentAs(maxEnd);
  }

  List<Attendance> getTodayAttendanceForSession({
    required String classId,
    required String subjectName,
  }) {
    final today = systemNow();
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

  Future<ImportResult> importStudents(List<ImportStudentRow> rows, {bool autoCreateClass = true}) async {
    int success = 0;
    int skipped = 0;
    int classesCreated = 0;
    final errors = <String>[];

    final supabase = Supabase.instance.client;
    final List<Map<String, dynamic>> profilesToInsert = [];
    final List<Map<String, dynamic>> studentsToInsert = [];
    final List<Student> studentsToInsertLocal = [];

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
      final position = 'Anggota';

      final studentId = _generateUuidFromText('S_${row.nis}_${DateTime.now().millisecondsSinceEpoch}');

      final cleanUsername = row.name.trim().split(' ')[0].toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') + (row.nis.trim().length >= 2 ? row.nis.trim().substring(row.nis.trim().length - 2) : '12');
      profilesToInsert.add({
        'id': studentId,
        'name': row.name.trim(),
        'role': 'siswa',
        'username': cleanUsername,
      });

      studentsToInsert.add({
        'id': studentId,
        'nis': row.nis.trim(),
        'nisn': row.nisn.trim(),
        'gender': gender,
        'class_id': cls.id,
        'position': position,
      });

      studentsToInsertLocal.add(Student(
        id: studentId,
        nis: row.nis.trim(),
        nisn: row.nisn.trim(),
        name: row.name.trim(),
        gender: gender,
        kelas: cls.name,
        position: position,
      ));

      success++;
    }

    if (profilesToInsert.isNotEmpty) {
      try {
        await supabase.from('profiles').insert(profilesToInsert);
        await supabase.from('students').insert(studentsToInsert);

        for (final s in studentsToInsertLocal) {
          _students.insert(0, s);
          _syncClassStudentCount(s.kelas);
        }
      } catch (e) {
        debugPrint("Error batch inserting students: $e");
        errors.add("Kesalahan database saat import batch: $e");
        success = 0;
        skipped = rows.length;
      }
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
    final today = systemNow();
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
    final call = _calls.cast<CallNotification?>().firstWhere((c) => c!.id == id, orElse: () => null);
    if (call != null) {
      _callHistory.insert(0, call);
    }
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
  List<Student> _students = [];
  // Class Data
  List<SchoolClass> _classes = [];
  // Teacher Data
  List<Teacher> _teachers = [];
  // Subject Data
  List<Subject> _subjects = [];
  // Room Data
  List<Room> _rooms = MockData.rooms;
  // Attendance Data
  List<Attendance> _attendance = [];
  // Schedule Data
  List<ScheduleEntry> _schedules = [];
  // Accounts Data
  List<UserProfile> _accounts = [];
  // Reset Requests
  List<ResetRequest> _resetRequests = [];

  Future<void> fetchEverything() async {
    _isFetching = true;
    notifyListeners();
    try {
      final supabase = Supabase.instance.client;

      // 1. Fetch Subjects
      final dbSubjects = await supabase.from('subjects').select();
      _subjects = dbSubjects.map<Subject>((s) => Subject(
        id: s['id'] as String,
        name: s['name'] as String,
        teacherIds: [],
      )).toList();

      // 2. Fetch Teachers
      final dbTeachers = await supabase.from('teachers').select('*, profiles(name, avatar_url), teacher_subjects(subject_id)');
      _teachers = dbTeachers.map<Teacher>((t) {
        final profile = t['profiles'] as Map?;
        final tSubjects = t['teacher_subjects'] as List?;
        
        final subjectsList = <String>[];
        if (tSubjects != null) {
          for (var ts in tSubjects) {
            final subId = ts['subject_id'] as String?;
            final matched = _subjects.firstWhere((sub) => sub.id == subId, orElse: () => Subject(id: '', name: '', teacherIds: []));
            if (matched.name.isNotEmpty) {
              subjectsList.add(matched.name);
            }
          }
        }

        return Teacher(
          id: t['id'] as String,
          nip: t['nip'] as String,
          name: profile?['name'] as String? ?? 'No Name',
          position: 'Guru Tetap',
          subjects: subjectsList,
          avatar: profile?['avatar_url'] as String? ?? 'https://i.pravatar.cc/150?u=${t['id']}',
        );
      }).toList();

      // Re-populate teacherIds in _subjects
      for (var i = 0; i < _subjects.length; i++) {
        final sub = _subjects[i];
        final teachersForSub = _teachers.where((t) => t.subjects.contains(sub.name)).map((t) => t.id).toList();
        _subjects[i] = Subject(
          id: sub.id,
          name: sub.name,
          teacherIds: teachersForSub,
        );
      }

      // 3. Fetch Classes
      final dbClasses = await supabase.from('classes').select('*, teachers(profiles(name))');
      _classes = dbClasses.map<SchoolClass>((c) {
        final teacher = c['teachers'] as Map?;
        final profile = teacher?['profiles'] as Map?;
        return SchoolClass(
          id: c['id'] as String,
          name: c['name'] as String,
          homeroomTeacherId: c['homeroom_teacher_id'] as String? ?? '',
          homeroomTeacherName: profile?['name'] as String? ?? 'Belum diatur',
          roomName: c['room_name'] as String? ?? '-',
          totalStudents: 0,
        );
      }).toList();

      // 4. Fetch Students
      final dbStudents = await supabase.from('students').select('*, profiles(name, avatar_url), classes(name)');
      _students = dbStudents.map<Student>((s) {
        final profile = s['profiles'] as Map?;
        final cls = s['classes'] as Map?;
        return Student(
          id: s['id'] as String,
          nis: s['nis'] as String,
          nisn: s['nisn'] as String? ?? '',
          name: profile?['name'] as String? ?? 'No Name',
          gender: s['gender'] as String? ?? 'L',
          kelas: cls?['name'] as String? ?? '',
          position: s['position'] as String? ?? 'Anggota',
        );
      }).toList();

      // Recompute totalStudents
      for (var i = 0; i < _classes.length; i++) {
        final count = _students.where((s) => s.kelas == _classes[i].name).length;
        _classes[i] = SchoolClass(
          id: _classes[i].id,
          name: _classes[i].name,
          homeroomTeacherId: _classes[i].homeroomTeacherId,
          homeroomTeacherName: _classes[i].homeroomTeacherName,
          roomName: _classes[i].roomName,
          totalStudents: count,
        );
      }

      // 5. Fetch Schedules
      final dbSchedules = await supabase.from('schedules').select('*, subjects(name)');
      _schedules = dbSchedules
          .where((s) => s['class_id'] != null && s['class_id'].toString().isNotEmpty)
          .map<ScheduleEntry>((s) {
        final subject = s['subjects'] as Map?;
        return ScheduleEntry(
          id: s['id'] as String,
          day: s['day_name'] as String,
          slotLabel: s['slot_label'] as String,
          classId: s['class_id'] as String,
          subjectId: s['subject_id'] as String? ?? '',
          roomId: s['room_name'] as String? ?? '',
          teacherId: s['teacher_id'] as String? ?? '',
          isEvent: s['is_event'] as bool? ?? false,
          customTitle: s['custom_title'] as String?,
        );
      }).toList();

      // 6. Fetch Accounts
      final dbProfiles = await supabase.from('profiles').select();
      final List<UserProfile> loadedAccounts = [];
      for (final p in dbProfiles) {
        final roleStr = p['role'] as String? ?? 'siswa';
        final role = UserRole.values.firstWhere((r) => r.name == roleStr, orElse: () => UserRole.siswa);
        
        if (role == UserRole.siswa) {
          final student = _students.firstWhere(
            (s) => s.id == p['id'],
            orElse: () => Student(id: '', nis: '', nisn: '', name: '', gender: '', kelas: '', position: ''),
          );
          if (student.id.isEmpty || !student.position.contains('Sekretaris')) {
            continue; // Skip regular students and dummy/orphaned student profiles
          }
        }
        
        final studentMatch = role == UserRole.siswa 
            ? _students.firstWhere((s) => s.id == p['id'], orElse: () => Student(id: '', nis: '', nisn: '', name: '', gender: '', kelas: '', position: ''))
            : null;
        final teacherMatch = role == UserRole.guru 
            ? _teachers.firstWhere((t) => t.id == p['id'], orElse: () => Teacher(id: '', nip: '', name: '', position: '', avatar: '', subjects: []))
            : null;

        loadedAccounts.add(UserProfile(
          id: p['id'] as String,
          name: p['name'] as String,
          username: p['username'] as String? ?? '',
          password: role == UserRole.admin ? 'password' : (role == UserRole.guru ? 'guru123' : 'siswa123'),
          role: role,
          avatar: p['avatar_url'] as String? ?? 'https://i.pravatar.cc/150?u=${p['id']}',
          kelas: studentMatch?.kelas,
          nipNis: role == UserRole.siswa ? studentMatch?.nis : (role == UserRole.guru ? teacherMatch?.nip : null),
          position: studentMatch?.position,
        ));
      }
      _accounts = loadedAccounts;

      // Fallback: Make sure there's at least one admin account
      if (!_accounts.any((a) => a.role == UserRole.admin)) {
        _accounts.add(MockData.users['admin']!);
      }

      // 7. Fetch Attendance
      try {
        final dbAttendance = await supabase.from('attendance').select('*, subjects(name)');
        _attendance = dbAttendance.map<Attendance>((a) {
          final subject = a['subjects'] as Map?;
          
          final statusStr = a['status'] as String? ?? 'hadir';
          final status = AttendanceStatus.values.firstWhere(
            (s) => s.name == statusStr,
            orElse: () => AttendanceStatus.hadir,
          );

          // marked_by column doesn't exist, marked_by_role does
          final markedBy = a.containsKey('marked_by') ? (a['marked_by'] as String? ?? '') : '';
          final markedByRole = a['marked_by_role'] as String? ?? 'admin';
          String markedByName = 'System';
          if (markedBy.isNotEmpty) {
            final accs = _accounts.where((acc) => acc.id == markedBy || acc.nipNis == markedBy).toList();
            if (accs.isNotEmpty) {
              markedByName = accs.first.name;
            } else {
              final tchs = _teachers.where((t) => t.id == markedBy || t.nip == markedBy).toList();
              if (tchs.isNotEmpty) {
                markedByName = tchs.first.name;
              } else {
                final stds = _students.where((s) => s.id == markedBy || s.nis == markedBy).toList();
                if (stds.isNotEmpty) {
                  markedByName = stds.first.name;
                }
              }
            }
          }

          return Attendance(
            id: a['id'] as String,
            studentId: a['student_id'] as String,
            classId: a['class_id'] as String,
            subjectId: subject?['name'] as String? ?? '',
            date: DateTime.parse(a['date'] as String).toLocal(),
            status: status,
            markedBy: markedBy,
            markedByRole: markedByRole,
            markedByName: markedByName,
            reason: a['reason'] as String?,
            notes: a.containsKey('notes') ? a['notes'] as String? : null,
          );
        }).toList();
      } catch (e) {
        debugPrint("Error fetching attendance: $e");
        _attendance = [];
      }

    } catch (e) {
      debugPrint("Error fetching Supabase data: $e");
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }
  
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

  bool login(String username, String password, UserRole requiredRole) {
    final cleanUsername = username.trim().toLowerCase();
    final cleanPassword = password.trim();
    
    try {
      final account = _accounts.firstWhere(
        (u) => u.username.toLowerCase() == cleanUsername && u.password == cleanPassword,
      );
      
      if (account.role != requiredRole) return false;

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
  Future<int> generateTeacherAccounts() async {
    int count = 0;
    try {
      final supabase = Supabase.instance.client;
      for (var teacher in _teachers) {
        final index = _accounts.indexWhere((a) => a.id == teacher.id || a.nipNis == teacher.nip);
        final username = teacher.name.split(' ')[0].toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') + teacher.nip.substring(teacher.nip.length - 4);
        
        await supabase.from('profiles').upsert({
          'id': teacher.id,
          'name': teacher.name,
          'role': 'guru',
          'username': username,
          'avatar_url': teacher.avatar,
        });

        if (index != -1) {
          _accounts[index] = UserProfile(
            id: teacher.id,
            name: teacher.name,
            username: username,
            password: _accounts[index].password,
            role: UserRole.guru,
            avatar: teacher.avatar,
            subject: teacher.subjects.isNotEmpty ? teacher.subjects[0] : null,
            nipNis: teacher.nip,
          );
        } else {
          _accounts.add(UserProfile(
            id: teacher.id,
            name: teacher.name,
            username: username,
            password: 'guru123',
            role: UserRole.guru,
            avatar: teacher.avatar,
            subject: teacher.subjects.isNotEmpty ? teacher.subjects[0] : null,
            nipNis: teacher.nip,
          ));
          count++;
        }
      }
      notifyListeners();
      return count;
    } catch (e) {
      debugPrint("Error generating teacher accounts: $e");
      return 0;
    }
  }

  Future<int> generateStudentAccounts() async {
    int count = 0;
    try {
      final supabase = Supabase.instance.client;
      final secretaries = _students.where((s) => s.position.contains('Sekretaris')).toList();
      if (secretaries.isEmpty) return -1; // Indication that no secretaries exist
      
      for (var student in secretaries) {
        final index = _accounts.indexWhere((a) => a.id == student.id || a.nipNis == student.nis);
        final username = student.name.split(' ')[0].toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') + student.nis.substring(student.nis.length - 2);
        
        await supabase.from('profiles').upsert({
          'id': student.id,
          'name': student.name,
          'role': 'siswa',
          'username': username,
        });

        if (index != -1) {
          _accounts[index] = UserProfile(
            id: student.id,
            name: student.name,
            username: username,
            password: _accounts[index].password,
            role: UserRole.siswa,
            avatar: 'https://i.pravatar.cc/150?u=${student.id}',
            kelas: student.kelas,
            nipNis: student.nis,
            position: student.position,
          );
        } else {
          _accounts.add(UserProfile(
            id: student.id,
            name: student.name,
            username: username,
            password: 'siswa123',
            role: UserRole.siswa,
            avatar: 'https://i.pravatar.cc/150?u=${student.id}',
            kelas: student.kelas,
            nipNis: student.nis,
            position: student.position,
          ));
          count++;
        }
      }
      notifyListeners();
      return count;
    } catch (e) {
      debugPrint("Error generating student accounts: $e");
      return 0;
    }
  }

  Future<void> deleteAccount(String id) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('profiles').delete().eq('id', id);
      _accounts.removeWhere((a) => a.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint("Error deleting account: $e");
    }
  }

  // Student CRUD
  Future<void> addStudent(Student student) async {
    if (isDuplicateNis(student.nis)) return;
    if (student.nisn.isNotEmpty && isDuplicateNisn(student.nisn)) return;

    try {
      final supabase = Supabase.instance.client;
      final cleanUsername = student.name.split(' ')[0].toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') + (student.nis.length >= 2 ? student.nis.substring(student.nis.length - 2) : '12');
      await supabase.from('profiles').upsert({
        'id': student.id,
        'name': student.name,
        'role': 'siswa',
        'username': cleanUsername,
      });

      final cls = findClassByIdOrName(student.kelas);

      await supabase.from('students').upsert({
        'id': student.id,
        'nis': student.nis,
        'nisn': student.nisn,
        'gender': student.gender,
        'class_id': cls?.id,
        'position': student.position,
      });

      _students.insert(0, student);
      _syncClassStudentCount(student.kelas);
      notifyListeners();
    } catch (e) {
      debugPrint("Error adding student: $e");
    }
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

  Future<void> updateStudent(Student student) async {
    try {
      final supabase = Supabase.instance.client;
      final cleanUsername = student.name.split(' ')[0].toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') + (student.nis.length >= 2 ? student.nis.substring(student.nis.length - 2) : '12');
      await supabase.from('profiles').upsert({
        'id': student.id,
        'name': student.name,
        'role': 'siswa',
        'username': cleanUsername,
      });

      final cls = findClassByIdOrName(student.kelas);

      await supabase.from('students').upsert({
        'id': student.id,
        'nis': student.nis,
        'nisn': student.nisn,
        'gender': student.gender,
        'class_id': cls?.id,
        'position': student.position,
      });

      final index = _students.indexWhere((s) => s.id == student.id);
      if (index != -1) {
        _students[index] = student;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error updating student: $e");
    }
  }

  Future<void> assignClassRole(String? studentId, String role, String className) async {
    try {
      // 1. Clear whoever has this role in this class currently
      final oldHolders = _students.where((s) => s.kelas == className && s.position == role).toList();
      for (final s in oldHolders) {
        final resetStudent = Student(
          id: s.id,
          nis: s.nis,
          nisn: s.nisn,
          name: s.name,
          gender: s.gender,
          kelas: s.kelas,
          position: 'Anggota',
        );
        await updateStudent(resetStudent);
      }

      // 2. If a studentId is provided, assign the new role to that student
      if (studentId != null && studentId.isNotEmpty) {
        final s = _students.firstWhere((st) => st.id == studentId);
        final updatedStudent = Student(
          id: s.id,
          nis: s.nis,
          nisn: s.nisn,
          name: s.name,
          gender: s.gender,
          kelas: s.kelas,
          position: role,
        );
        await updateStudent(updatedStudent);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint("Error assigning class role: $e");
    }
  }

  Future<void> deleteStudent(String id) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('students').delete().eq('id', id);
      await supabase.from('profiles').delete().eq('id', id);

      _students.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint("Error deleting student: $e");
    }
  }

  Future<void> clearAllStudents() async {
    try {
      final supabase = Supabase.instance.client;
      
      // Delete all attendance records first to avoid foreign key violations
      await supabase.from('attendance').delete().neq('id', 'dummy-id-to-delete-all');
      
      // Delete all records in students
      await supabase.from('students').delete().neq('id', 'dummy-id-to-delete-all');
      
      // Delete all profiles with role = 'siswa'
      await supabase.from('profiles').delete().eq('role', 'siswa');
      
      // Clear local states
      _students.clear();
      _attendance.clear();
      _accounts.removeWhere((a) => a.role == UserRole.siswa);
      
      // Recompute totalStudents for all classes
      for (var i = 0; i < _classes.length; i++) {
        _classes[i] = SchoolClass(
          id: _classes[i].id,
          name: _classes[i].name,
          homeroomTeacherId: _classes[i].homeroomTeacherId,
          homeroomTeacherName: _classes[i].homeroomTeacherName,
          roomName: _classes[i].roomName,
          totalStudents: 0,
        );
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint("Error clearing all students: $e");
    }
  }

  // Class CRUD
  Future<void> addClass(SchoolClass cls) async {
    if (isDuplicateClassName(cls.name)) return;
    
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('classes').upsert({
        'id': cls.id,
        'name': cls.name,
        'room_name': cls.roomName,
        'homeroom_teacher_id': cls.homeroomTeacherId.isEmpty ? null : cls.homeroomTeacherId,
      });

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
        final scheduleId = 'auto_${cls.id}_${ev['day']}_${ev['slot']}';
        final entry = ScheduleEntry(
          id: scheduleId,
          day: ev['day']!,
          slotLabel: ev['slot']!,
          classId: cls.id,
          isEvent: true,
          customTitle: ev['title'],
        );

        await supabase.from('schedules').upsert({
          'id': _generateUuidFromText(scheduleId),
          'class_id': cls.id,
          'day_name': ev['day'],
          'slot_label': ev['slot'],
          'is_event': true,
          'custom_title': ev['title'],
        });

        _schedules.add(entry);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint("Error adding class: $e");
    }
  }

  static String _generateUuidFromText(String text) {
    final hash = text.hashCode.abs().toString().padRight(12, '0');
    final section1 = hash.substring(0, 8);
    final section2 = hash.substring(8, 12);
    return "$section1-1234-4321-a1b2-${section2}abcdef00";
  }

  static String generateNewUuid() {
    final rand = "${DateTime.now().microsecondsSinceEpoch}_${DateTime.now().hashCode}";
    return _generateUuidFromText(rand);
  }

  Future<void> updateClass(SchoolClass cls) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('classes').upsert({
        'id': cls.id,
        'name': cls.name,
        'room_name': cls.roomName,
        'homeroom_teacher_id': cls.homeroomTeacherId.isEmpty ? null : cls.homeroomTeacherId,
      });

      final index = _classes.indexWhere((c) => c.id == cls.id);
      if (index != -1) {
        _classes[index] = cls;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error updating class: $e");
    }
  }

  Future<void> deleteClass(String id) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('schedules').delete().eq('class_id', id);
      await supabase.from('classes').delete().eq('id', id);

      _classes.removeWhere((c) => c.id == id);
      _schedules.removeWhere((s) => s.classId == id);
      notifyListeners();
    } catch (e) {
      debugPrint("Error deleting class: $e");
    }
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
  Future<void> addSubject(Subject subject) async {
    if (isDuplicateSubjectName(subject.name)) return;
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('subjects').upsert({
        'id': subject.id,
        'name': subject.name,
      });

      _subjects.insert(0, subject);
      notifyListeners();
    } catch (e) {
      debugPrint("Error adding subject: $e");
    }
  }

  Future<void> updateSubject(Subject subject) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('subjects').upsert({
        'id': subject.id,
        'name': subject.name,
      });

      final index = _subjects.indexWhere((s) => s.id == subject.id);
      if (index != -1) {
        _subjects[index] = subject;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error updating subject: $e");
    }
  }

  Future<void> deleteSubject(String id) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('teacher_subjects').delete().eq('subject_id', id);
      await supabase.from('schedules').delete().eq('subject_id', id);
      await supabase.from('subjects').delete().eq('id', id);

      _subjects.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint("Error deleting subject: $e");
    }
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
  Future<void> addTeacher(Teacher teacher) async {
    if (isDuplicateTeacherNip(teacher.nip)) return;
    try {
      final supabase = Supabase.instance.client;
      final cleanUsername = teacher.name.split(' ')[0].toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') + (teacher.nip.length >= 4 ? teacher.nip.substring(teacher.nip.length - 4) : '1234');
      await supabase.from('profiles').upsert({
        'id': teacher.id,
        'name': teacher.name,
        'role': 'guru',
        'username': cleanUsername,
        'avatar_url': teacher.avatar,
      });

      await supabase.from('teachers').upsert({
        'id': teacher.id,
        'nip': teacher.nip,
      });

      await supabase.from('teacher_subjects').delete().eq('teacher_id', teacher.id);
      for (final subName in teacher.subjects) {
        final sub = findSubjectByIdOrName(subName);
        if (sub != null) {
          await supabase.from('teacher_subjects').insert({
            'teacher_id': teacher.id,
            'subject_id': sub.id,
          });
        }
      }

      _teachers.insert(0, teacher);
      notifyListeners();
    } catch (e) {
      debugPrint("Error adding teacher: $e");
    }
  }

  Future<void> updateTeacher(Teacher teacher) async {
    try {
      final supabase = Supabase.instance.client;
      final cleanUsername = teacher.name.split(' ')[0].toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') + (teacher.nip.length >= 4 ? teacher.nip.substring(teacher.nip.length - 4) : '1234');
      await supabase.from('profiles').upsert({
        'id': teacher.id,
        'name': teacher.name,
        'role': 'guru',
        'username': cleanUsername,
        'avatar_url': teacher.avatar,
      });

      await supabase.from('teachers').upsert({
        'id': teacher.id,
        'nip': teacher.nip,
      });

      await supabase.from('teacher_subjects').delete().eq('teacher_id', teacher.id);
      for (final subName in teacher.subjects) {
        final sub = findSubjectByIdOrName(subName);
        if (sub != null) {
          await supabase.from('teacher_subjects').insert({
            'teacher_id': teacher.id,
            'subject_id': sub.id,
          });
        }
      }

      final index = _teachers.indexWhere((t) => t.id == teacher.id);
      if (index != -1) {
        _teachers[index] = teacher;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error updating teacher: $e");
    }
  }

  Future<void> deleteTeacher(String id) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('teacher_subjects').delete().eq('teacher_id', id);
      await supabase.from('schedules').delete().eq('teacher_id', id);
      await supabase.from('teachers').delete().eq('id', id);
      await supabase.from('profiles').delete().eq('id', id);

      _teachers.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint("Error deleting teacher: $e");
    }
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

  Future<void> saveAttendanceBatch({
    required SchoolClass cls,
    required Subject sub,
    required Map<String, AttendanceStatus> statuses,
    required UserProfile user,
    String? reason,
    List<ScheduleEntry>? scheduleEntries,
  }) async {
    if (user.role == UserRole.guru &&
        !canGuruMarkAttendance(cls.id, sub.name)) {
      return;
    }
    if (scheduleEntries != null &&
        scheduleEntries.isNotEmpty &&
        !canMarkAttendanceNow(scheduleEntries, currentDayName)) {
      return;
    }

    final now = systemNow();
    final role = user.role == UserRole.siswa ? 'siswa' : user.role.name;

    try {
      final supabase = Supabase.instance.client;
      final dateString = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final List<Map<String, dynamic>> attendanceInserts = [];
      final List<Attendance> localRecords = [];

      for (final entry in statuses.entries) {
        final studentId = entry.key;

        await supabase
            .from('attendance')
            .delete()
            .eq('student_id', studentId)
            .eq('subject_id', sub.id)
            .eq('date', dateString);

        _attendance.removeWhere((a) =>
            a.studentId == studentId &&
            a.subjectId == sub.name &&
            isSameCalendarDay(a.date, now));

        final attendanceId = 'at_${now.millisecondsSinceEpoch}_$studentId';
        final dbStatus = entry.value.name == 'pulang' ? 'hadir' : entry.value.name;

        attendanceInserts.add({
          'id': _generateUuidFromText(attendanceId),
          'student_id': studentId,
          'class_id': cls.id,
          'subject_id': sub.id,
          'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
          'status': dbStatus,
          'marked_by_role': role,
        });

        localRecords.add(Attendance(
          id: _generateUuidFromText(attendanceId),
          studentId: studentId,
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

      if (attendanceInserts.isNotEmpty) {
        await supabase.from('attendance').insert(attendanceInserts);
      }

      _attendance.addAll(localRecords);
      notifyListeners();
    } catch (e) {
      debugPrint("Error saving attendance batch: $e");
    }
  }

  // Schedule Logic
  List<ScheduleEntry> getTeacherSchedules(String teacherId, {String? day}) {
    return _schedules.where((s) => s.teacherId == teacherId && (day == null || s.day == day)).toList();
  }

  List<Attendance> getTeacherAttendanceRekap(String teacherId, {DateTime? filterDate}) {
    final teacherSchedules = _schedules.where((s) => s.teacherId == teacherId && !s.isEvent).toList();
    
    final teacherTeachings = teacherSchedules.map((s) {
      final subName = subjectDisplayName(s.subjectId ?? '');
      return '${s.classId}_$subName';
    }).toSet();

    return _attendance.where((a) {
      final teachingKey = '${a.classId}_${a.subjectId}';
      if (!teacherTeachings.contains(teachingKey)) return false;
      
      if (filterDate != null && !isSameCalendarDay(a.date, filterDate)) return false;
      return true;
    }).toList();
  }

  Map<String, int> getStudentMonthlyTotals(String studentId, {DateTime? month}) {
    final ref = month ?? systemNow();
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
    final now = systemNow();
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

  Future<void> addScheduleEntry(ScheduleEntry entry) async {
    _schedules.add(entry);
    notifyListeners();
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('schedules').upsert({
        'id': entry.id.length >= 36 ? entry.id : _generateUuidFromText(entry.id),
        'class_id': entry.classId,
        'day_name': entry.day,
        'slot_label': entry.slotLabel,
        'is_event': entry.isEvent,
        'custom_title': entry.customTitle,
        'subject_id': entry.subjectId,
        'room_name': entry.roomId, // Database column is room_name
        'teacher_id': entry.teacherId,
      });
    } catch (e) {
      debugPrint("Error saving schedule entry: $e");
    }
  }

  Future<void> deleteScheduleEntry(String id) async {
    _schedules.removeWhere((s) => s.id == id);
    notifyListeners();
    try {
      final supabase = Supabase.instance.client;
      final uuid = id.length >= 36 ? id : _generateUuidFromText(id);
      await supabase.from('schedules').delete().eq('id', uuid);
    } catch (e) {
      debugPrint("Error deleting schedule entry: $e");
    }
  }
}
