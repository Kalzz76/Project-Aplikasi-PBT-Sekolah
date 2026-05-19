import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../providers/app_provider.dart';

class SupabaseSyncService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Sinkronisasi data lokal (Mata Pelajaran, Guru, Ruangan, Kelas, Jadwal, Siswa) ke Supabase
  static Future<void> syncAllData(AppProvider provider, {Function(String message, double progress)? onProgress}) async {
    try {
      onProgress?.call("Memulai sinkronisasi data...", 0.0);
      debugPrint("Memulai sinkronisasi data...");

      // 1. Sinkronisasi Mata Pelajaran (Subjects)
      onProgress?.call("Sinkronisasi Mata Pelajaran...", 0.1);
      debugPrint("Sinkronisasi Mata Pelajaran...");
      for (final subject in provider.subjects) {
        await _supabase.from('subjects').upsert({
          'name': subject.name,
        }, onConflict: 'name');
      }

      final dbSubjects = await _supabase.from('subjects').select();
      final mapelIdMap = {for (var s in dbSubjects) s['name'] as String: s['id'] as String};

      // 2. Sinkronisasi Profil & Guru (Teachers)
      onProgress?.call("Sinkronisasi Data Guru...", 0.3);
      debugPrint("Sinkronisasi Data Guru...");
      for (final teacher in provider.teachers) {
        String teacherId = teacher.id;
        if (teacherId.length < 36) {
          teacherId = _generateUuidFromText(teacher.nip);
        }

        final existingAccount = provider.accounts.where((a) => a.nipNis == teacher.nip).toList();
        final usernameToSave = existingAccount.isNotEmpty ? existingAccount.first.username : teacher.nip;

        await _supabase.from('profiles').upsert({
          'id': teacherId,
          'name': teacher.name,
          'role': 'guru',
          'username': usernameToSave,
        });

        await _supabase.from('teachers').upsert({
          'id': teacherId,
          'nip': teacher.nip,
        });

        for (final subName in teacher.subjects) {
          final subId = mapelIdMap[subName];
          if (subId != null) {
            await _supabase.from('teacher_subjects').upsert({
              'teacher_id': teacherId,
              'subject_id': subId,
            });
          }
        }
      }

      final dbTeachers = await _supabase.from('teachers').select('*, profiles(name)');
      final teacherIdMap = {
        for (var t in dbTeachers) 
          (t['profiles'] as Map)['name'] as String: t['id'] as String
      };

      // 3. Sinkronisasi Kelas (Classes)
      onProgress?.call("Sinkronisasi Data Kelas...", 0.5);
      debugPrint("Sinkronisasi Data Kelas...");
      for (final cls in provider.classes) {
        String classId = cls.id;
        if (classId.length < 36) {
          classId = _generateUuidFromText(cls.name);
        }

        final homeroomId = teacherIdMap[cls.homeroomTeacherName];

        await _supabase.from('classes').upsert({
          'id': classId,
          'name': cls.name,
          'room_name': cls.roomName,
          'homeroom_teacher_id': homeroomId,
        });
      }

      final dbClasses = await _supabase.from('classes').select();
      final classIdMap = {for (var c in dbClasses) c['name'] as String: c['id'] as String};

      // 4. Sinkronisasi Siswa (Students)
      onProgress?.call("Sinkronisasi Data Siswa...", 0.7);
      debugPrint("Sinkronisasi Data Siswa...");
      for (final student in provider.students) {
        String studentId = student.id;
        if (studentId.length < 36) {
          studentId = _generateUuidFromText(student.nis);
        }

        final classId = classIdMap[student.kelas];

        final existingAccount = provider.accounts.where((a) => a.nipNis == student.nis).toList();
        final usernameToSave = existingAccount.isNotEmpty ? existingAccount.first.username : student.nis;

        await _supabase.from('profiles').upsert({
          'id': studentId,
          'name': student.name,
          'role': 'siswa',
          'username': usernameToSave,
        });

        await _supabase.from('students').upsert({
          'id': studentId,
          'nis': student.nis,
          'nisn': student.nisn,
          'gender': student.gender == 'P' ? 'P' : 'L',
          'class_id': classId,
          'position': student.position,
        });
      }

      // 5. Sinkronisasi Jadwal (Schedules)
      onProgress?.call("Sinkronisasi Jadwal Pelajaran...", 0.9);
      debugPrint("Sinkronisasi Jadwal Pelajaran...");
      for (final schedule in provider.schedules) {
        final classId = classIdMap[schedule.classId];
        final subjectId = mapelIdMap[schedule.subjectId];
        final teacherId = teacherIdMap[schedule.teacherId];

        await _supabase.from('schedules').upsert({
          'class_id': classId,
          'subject_id': subjectId,
          'teacher_id': teacherId,
          'room_name': schedule.roomId, 
          'day_name': schedule.day,
          'slot_label': schedule.slotLabel,
          'is_event': schedule.isEvent,
          'custom_title': schedule.customTitle,
        });
      }

      onProgress?.call("Sinkronisasi Berhasil!", 1.0);
      debugPrint("Sinkronisasi Berhasil!");
    } catch (e) {
      onProgress?.call("Sinkronisasi Gagal: $e", 0.0);
      debugPrint("Kesalahan saat sinkronisasi: $e");
      rethrow;
    }
  }

  /// Helper untuk generate UUID v4 dummy yang konsisten berdasarkan teks (NIP/NIS/Nama)
  static String _generateUuidFromText(String text) {
    // Generate UUID v4 placeholder menggunakan string hash sederhana agar konsisten
    final hash = text.hashCode.abs().toString().padRight(12, '0');
    final section1 = hash.substring(0, 8);
    final section2 = hash.substring(8, 12);
    return "$section1-1234-4321-a1b2-${section2}abcdef00";
  }
}
