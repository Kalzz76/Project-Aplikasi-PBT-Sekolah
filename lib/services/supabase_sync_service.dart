import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../providers/app_provider.dart';

class SupabaseSyncService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Sinkronisasi data lokal (Mata Pelajaran, Guru, Ruangan, Kelas, Jadwal, Siswa) ke Supabase
  static Future<void> syncAllData(AppProvider provider) async {
    try {
      debugPrint("Memulai sinkronisasi data...");

      // 1. Sinkronisasi Mata Pelajaran (Subjects)
      debugPrint("Sinkronisasi Mata Pelajaran...");
      for (final subject in provider.subjects) {
        await _supabase.from('subjects').upsert({
          'name': subject.name,
        }, onConflict: 'name');
      }

      // Ambil data mapel dari Supabase untuk mencocokkan ID
      final dbSubjects = await _supabase.from('subjects').select();
      final mapelIdMap = {for (var s in dbSubjects) s['name'] as String: s['id'] as String};

      // 2. Sinkronisasi Profil & Guru (Teachers)
      debugPrint("Sinkronisasi Data Guru...");
      for (final teacher in provider.teachers) {
        // Karena profiles.id mereferensikan auth.users(id), untuk testing
        // kita buat dummy profile di public.profiles terlebih dahulu.
        // Jika terdapat kendala constraint FK auth.users, kita bisa me-relax constraint tersebut.
        // Di sini kita coba upsert profile & teacher.
        
        // Kita gunakan ID guru yang ada (pastikan berformat UUID jika RLS / FK aktif,
        // jika tidak berformat UUID, kita generate UUID baru atau bypass)
        String teacherId = teacher.id;
        if (teacherId.length < 36) {
          // Jika ID mock bukan UUID, kita buat UUID dummy konsisten dari nama/NIP
          teacherId = _generateUuidFromText(teacher.nip);
        }

        // Upsert profile
        await _supabase.from('profiles').upsert({
          'id': teacherId,
          'name': teacher.name,
          'role': 'guru',
          'username': teacher.nip,
        });

        // Upsert teacher
        await _supabase.from('teachers').upsert({
          'id': teacherId,
          'nip': teacher.nip,
        });

        // Hubungkan guru dengan mata pelajaran (teacher_subjects)
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

      // Ambil data guru dari Supabase untuk pencocokan kelas
      final dbTeachers = await _supabase.from('teachers').select('*, profiles(name)');
      final teacherIdMap = {
        for (var t in dbTeachers) 
          (t['profiles'] as Map)['name'] as String: t['id'] as String
      };

      // 3. Sinkronisasi Kelas (Classes)
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

      // Ambil data kelas dari Supabase untuk pencocokan siswa & jadwal
      final dbClasses = await _supabase.from('classes').select();
      final classIdMap = {for (var c in dbClasses) c['name'] as String: c['id'] as String};

      // 4. Sinkronisasi Siswa (Students)
      debugPrint("Sinkronisasi Data Siswa...");
      for (final student in provider.students) {
        String studentId = student.id;
        if (studentId.length < 36) {
          studentId = _generateUuidFromText(student.nis);
        }

        final classId = classIdMap[student.kelas];

        // Upsert profile
        await _supabase.from('profiles').upsert({
          'id': studentId,
          'name': student.name,
          'role': 'siswa',
          'username': student.nis,
        });

        // Upsert student
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
      debugPrint("Sinkronisasi Jadwal Pelajaran...");
      for (final schedule in provider.schedules) {
        final classId = classIdMap[schedule.classId];
        final subjectId = mapelIdMap[schedule.subjectId]; // scheduler.subjectId stores subject name or id
        final teacherId = teacherIdMap[schedule.teacherId]; // scheduler.teacherId stores teacher name or id

        await _supabase.from('schedules').upsert({
          'class_id': classId,
          'subject_id': subjectId,
          'teacher_id': teacherId,
          'room_name': schedule.roomId, // stores room name/id
          'day_name': schedule.day,
          'slot_label': schedule.slotLabel,
          'is_event': schedule.isEvent,
          'custom_title': schedule.customTitle,
        });
      }

      debugPrint("Sinkronisasi Berhasil!");
    } catch (e) {
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
