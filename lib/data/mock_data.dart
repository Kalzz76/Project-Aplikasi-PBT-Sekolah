import '../models/user.dart';
import '../models/student.dart';
import '../models/teacher.dart';
import '../models/school_class.dart';
import '../models/room.dart';
import '../models/subject.dart';
import '../models/schedule.dart';

class MockData {
  static final Map<String, UserProfile> users = {
    'admin': UserProfile(
      id: 'A01',
      name: 'Administrator',
      username: 'admin',
      password: 'password',
      role: UserRole.admin,
      avatar: 'https://i.pravatar.cc/150?u=admin',
    ),
    'ela2005': UserProfile(
      id: 'G01',
      name: 'Ela Nurlaila, S.Pd',
      username: 'ela2005',
      password: 'guru123',
      role: UserRole.guru,
      subject: 'Sejarah',
      avatar: 'https://i.pravatar.cc/150?u=ela',
      nipNis: '198205052012062005',
    ),
    'sekretaris1': UserProfile(
      id: 'S5',
      name: 'Budi Wijaya',
      username: 'sekretaris1',
      password: 'siswa123',
      role: UserRole.siswa,
      avatar: 'https://i.pravatar.cc/150?u=sekretaris',
      kelas: 'XI RPL 1',
      nipNis: '100005',
      position: 'Sekretaris 1',
    ),
  };

  static final List<Student> students = [];

  static final List<Teacher> teachers = [
    Teacher(id: 'G01', nip: '198205052012062005', name: 'Ela Nurlaila, S.Pd', position: 'Guru Tetap', subjects: ['Sejarah', 'Ppan'], avatar: 'https://i.pravatar.cc/150?u=ela'),
    Teacher(id: 'G02', nip: '197806062008071006', name: 'Rukmana, S.Pd.I', position: 'Guru Tetap', subjects: ['PABP'], avatar: 'https://i.pravatar.cc/150?u=rukmana'),
    Teacher(id: 'G03', nip: '199207072018082007', name: 'Pratiwi, S.Si', position: 'Guru Tetap', subjects: ['Basis Data', 'CLOUD'], avatar: 'https://i.pravatar.cc/150?u=pratiwi'),
    Teacher(id: 'G04', nip: '198808082014091008', name: 'Jaya Sumpena, S.ST, M.Kom', position: 'Guru Tetap', subjects: ['PPB'], avatar: 'https://i.pravatar.cc/150?u=jaya'),
    Teacher(id: 'G05', nip: '198409092011102009', name: 'Meli Novita, S.Pd', position: 'Guru Tetap', subjects: ['Bahasa Indonesia'], avatar: 'https://i.pravatar.cc/150?u=meli'),
    Teacher(id: 'G06', nip: '198110102009112010', name: 'Indira Sari Paputungan, M.Ed', position: 'Guru Tetap', subjects: ['Bahasa Inggris'], avatar: 'https://i.pravatar.cc/150?u=indira'),
    Teacher(id: 'G07', nip: '199511112020121011', name: 'Maspuri Andewi, S.Kom', position: 'Guru Tetap', subjects: ['PBT Pemrograman Berbasis Teks'], avatar: 'https://i.pravatar.cc/150?u=maspuri'),
    Teacher(id: 'G08', nip: '198712122016012012', name: 'Annisa Intikarusdiansari, S.Pd', position: 'Guru Tetap', subjects: ['PKK'], avatar: 'https://i.pravatar.cc/150?u=annisa'),
    Teacher(id: 'G09', nip: '198301012013021013', name: 'Taufik Hidayat, M.M.Pd', position: 'Guru Tetap', subjects: ['PJOK'], avatar: 'https://i.pravatar.cc/150?u=taufik'),
    Teacher(id: 'G10', nip: '198902022017032014', name: 'Desta Mulyanti, S.Sn', position: 'Guru Tetap', subjects: ['Bahasa Sunda'], avatar: 'https://i.pravatar.cc/150?u=desta'),
    Teacher(id: 'G11', nip: '197603032002042015', name: 'Hazar Nurbani, M.Pd', position: 'Guru Tetap', subjects: ['BPBK'], avatar: 'https://i.pravatar.cc/150?u=hazar'),
    Teacher(id: 'G12', nip: '198004042006052016', name: 'Nofa Nirawati, S.Pd, M.T', position: 'Guru Tetap', subjects: ['Matematika'], avatar: 'https://i.pravatar.cc/150?u=nofa'),
    Teacher(id: 'G13', nip: '198605052015061017', name: 'Dena Handriana, M.Pd', position: 'Guru Tetap', subjects: ['STA'], avatar: 'https://i.pravatar.cc/150?u=dena'),
    Teacher(id: 'G14', nip: '199106062019071018', name: 'Ariantonius Sagala, S.Kom', position: 'Guru Tetap', subjects: ['PWP'], avatar: 'https://i.pravatar.cc/150?u=sagala'),
  ];

  static final List<Subject> subjects = [
    Subject(id: 'M1', name: 'Sejarah', teacherIds: ['G01']),
    Subject(id: 'M2', name: 'PABP', teacherIds: ['G02']),
    Subject(id: 'M3', name: 'Basis Data', teacherIds: ['G03']),
    Subject(id: 'M4', name: 'CLOUD', teacherIds: ['G03']),
    Subject(id: 'M5', name: 'PPB', teacherIds: ['G04']),
    Subject(id: 'M6', name: 'Bahasa Indonesia', teacherIds: ['G05']),
    Subject(id: 'M7', name: 'Bahasa Inggris', teacherIds: ['G06']),
    Subject(id: 'M8', name: 'PBT Pemrograman Berbasis Teks', teacherIds: ['G07']),
    Subject(id: 'M9', name: 'PKK', teacherIds: ['G08']),
    Subject(id: 'M10', name: 'PJOK', teacherIds: ['G09']),
    Subject(id: 'M11', name: 'Bahasa Sunda', teacherIds: ['G10']),
    Subject(id: 'M12', name: 'BPBK', teacherIds: ['G11']),
    Subject(id: 'M13', name: 'Matematika', teacherIds: ['G12']),
    Subject(id: 'M14', name: 'STA', teacherIds: ['G13']),
    Subject(id: 'M15', name: 'PWP', teacherIds: ['G14']),
    Subject(id: 'M16', name: 'Ppan', teacherIds: ['G01']),
  ];

  static final List<SchoolClass> classes = [
    SchoolClass(id: 'K1', name: 'XI RPL 1', homeroomTeacherId: 'G03', homeroomTeacherName: 'Pratiwi, S.Si', roomName: 'R.57', totalStudents: 32),
    SchoolClass(id: 'K2', name: 'XI RPL 2', homeroomTeacherId: 'G01', homeroomTeacherName: 'Ela Nurlaila, S.Pd', roomName: 'R.102', totalStudents: 30),
    SchoolClass(id: 'K3', name: 'XII TKJ 1', homeroomTeacherId: 'G04', homeroomTeacherName: 'Jaya Sumpena, S.ST, M.Kom', roomName: 'R.201', totalStudents: 28),
  ];

  static final List<Room> rooms = [
    Room(id: 'R1', name: 'R.57', category: 'Kelas'),
    Room(id: 'R2', name: 'R.42', category: 'Lab RPL'),
    Room(id: 'R3', name: 'R.SAM2', category: 'Lab RPL'),
    Room(id: 'R4', name: 'LAP', category: 'Lapangan'),
    Room(id: 'R5', name: 'R.41', category: 'Lab RPL'),
    Room(id: 'R6', name: 'R.101', category: 'Kelas'),
    Room(id: 'R7', name: 'R.102', category: 'Kelas'),
  ];

  static final List<ScheduleEntry> _initialSchedules = [
    // XI RPL 1 (K1) Updated Lessons
    // Senin
    ScheduleEntry(id: '1', day: 'Senin', slotLabel: 'Jam 2', classId: 'K1', subjectId: 'Sejarah', roomId: 'R1', teacherId: 'G01'),
    ScheduleEntry(id: '2', day: 'Senin', slotLabel: 'Jam 3', classId: 'K1', subjectId: 'Sejarah', roomId: 'R1', teacherId: 'G01'),
    ScheduleEntry(id: 'e_selasa_ela', day: 'Selasa', slotLabel: 'Jam 11', classId: 'K1', subjectId: 'Sejarah', roomId: 'R1', teacherId: 'G01'),
    ScheduleEntry(id: 'e_rabu_ela', day: 'Rabu', slotLabel: 'Jam 2', classId: 'K2', subjectId: 'Ppan', roomId: 'R7', teacherId: 'G01'),
    ScheduleEntry(id: 'e_rabu_ela2', day: 'Rabu', slotLabel: 'Jam 3', classId: 'K2', subjectId: 'Ppan', roomId: 'R7', teacherId: 'G01'),
    ScheduleEntry(id: 'e_kamis_ela', day: 'Kamis', slotLabel: 'Jam 4', classId: 'K1', subjectId: 'Sejarah', roomId: 'R1', teacherId: 'G01'),
    ScheduleEntry(id: '3', day: 'Senin', slotLabel: 'Jam 4', classId: 'K1', subjectId: 'PABP', roomId: 'R1', teacherId: 'G02'),
    ScheduleEntry(id: '4', day: 'Senin', slotLabel: 'Jam 5', classId: 'K1', subjectId: 'PABP', roomId: 'R1', teacherId: 'G02'),
    ScheduleEntry(id: '5', day: 'Senin', slotLabel: 'Jam 6', classId: 'K1', subjectId: 'PABP', roomId: 'R1', teacherId: 'G02'),
    ScheduleEntry(id: '6', day: 'Senin', slotLabel: 'Jam 7', classId: 'K1', subjectId: 'Basis Data', roomId: 'R2', teacherId: 'G03'),
    ScheduleEntry(id: '7', day: 'Senin', slotLabel: 'Jam 8', classId: 'K1', isEvent: true, customTitle: 'Istirahat'),
    ScheduleEntry(id: '8', day: 'Senin', slotLabel: 'Jam 9', classId: 'K1', subjectId: 'Basis Data', roomId: 'R2', teacherId: 'G03'),
    ScheduleEntry(id: '9', day: 'Senin', slotLabel: 'Jam 10', classId: 'K1', subjectId: 'Basis Data', roomId: 'R2', teacherId: 'G03'),
    ScheduleEntry(id: '10', day: 'Senin', slotLabel: 'Jam 11', classId: 'K1', subjectId: 'Basis Data', roomId: 'R2', teacherId: 'G03'),
    ScheduleEntry(id: '11', day: 'Senin', slotLabel: 'Jam 12', classId: 'K1', subjectId: 'Basis Data', roomId: 'R2', teacherId: 'G03'),

    // Selasa
    ScheduleEntry(id: '12', day: 'Selasa', slotLabel: 'Jam 1', classId: 'K1', subjectId: 'PPB', roomId: 'R2', teacherId: 'G04'),
    ScheduleEntry(id: '13', day: 'Selasa', slotLabel: 'Jam 2', classId: 'K1', subjectId: 'PPB', roomId: 'R2', teacherId: 'G04'),
    ScheduleEntry(id: '14', day: 'Selasa', slotLabel: 'Jam 3', classId: 'K1', subjectId: 'PPB', roomId: 'R2', teacherId: 'G04'),
    ScheduleEntry(id: '15', day: 'Selasa', slotLabel: 'Jam 4', classId: 'K1', subjectId: 'PPB', roomId: 'R2', teacherId: 'G04'),
    ScheduleEntry(id: '16', day: 'Selasa', slotLabel: 'Jam 5', classId: 'K1', subjectId: 'PPB', roomId: 'R2', teacherId: 'G04'),
    ScheduleEntry(id: '17', day: 'Selasa', slotLabel: 'Jam 6', classId: 'K1', subjectId: 'Bahasa Indonesia', roomId: 'R1', teacherId: 'G05'),
    ScheduleEntry(id: '18', day: 'Selasa', slotLabel: 'Jam 7', classId: 'K1', subjectId: 'Bahasa Indonesia', roomId: 'R1', teacherId: 'G05'),
    ScheduleEntry(id: '19', day: 'Selasa', slotLabel: 'Jam 8', classId: 'K1', subjectId: 'Bahasa Indonesia', roomId: 'R1', teacherId: 'G05'),
    ScheduleEntry(id: 'e_s2', day: 'Selasa', slotLabel: 'Jam 9', classId: 'K1', isEvent: true, customTitle: 'Istirahat'),
    ScheduleEntry(id: '20', day: 'Selasa', slotLabel: 'Jam 10', classId: 'K1', subjectId: 'Bahasa Inggris', roomId: 'R1', teacherId: 'G06'),
    ScheduleEntry(id: '21', day: 'Selasa', slotLabel: 'Jam 11', classId: 'K1', subjectId: 'Bahasa Inggris', roomId: 'R1', teacherId: 'G06'),
    ScheduleEntry(id: 'e_s3', day: 'Selasa', slotLabel: 'Jam 12', classId: 'K1', isEvent: true, customTitle: 'Tugas Mandiri'),

    // Rabu
    ScheduleEntry(id: '22', day: 'Rabu', slotLabel: 'Jam 2', classId: 'K1', subjectId: 'CLOUD', roomId: 'R2', teacherId: 'G03'),
    ScheduleEntry(id: '23', day: 'Rabu', slotLabel: 'Jam 3', classId: 'K1', subjectId: 'CLOUD', roomId: 'R2', teacherId: 'G03'),
    ScheduleEntry(id: '24', day: 'Rabu', slotLabel: 'Jam 4', classId: 'K1', subjectId: 'PBT Pemrograman Berbasis Teks', roomId: 'R3', teacherId: 'G07'),
    ScheduleEntry(id: '25', day: 'Rabu', slotLabel: 'Jam 5', classId: 'K1', subjectId: 'PBT Pemrograman Berbasis Teks', roomId: 'R3', teacherId: 'G07'),
    ScheduleEntry(id: '26', day: 'Rabu', slotLabel: 'Jam 6', classId: 'K1', subjectId: 'PBT Pemrograman Berbasis Teks', roomId: 'R3', teacherId: 'G07'),
    ScheduleEntry(id: '27', day: 'Rabu', slotLabel: 'Jam 7', classId: 'K1', subjectId: 'PBT Pemrograman Berbasis Teks', roomId: 'R3', teacherId: 'G07'),
    ScheduleEntry(id: 'e_r2', day: 'Rabu', slotLabel: 'Jam 8', classId: 'K1', isEvent: true, customTitle: 'Istirahat'),
    ScheduleEntry(id: '28', day: 'Rabu', slotLabel: 'Jam 9', classId: 'K1', subjectId: 'PBT Pemrograman Berbasis Teks', roomId: 'R3', teacherId: 'G07'),
    ScheduleEntry(id: '29', day: 'Rabu', slotLabel: 'Jam 10', classId: 'K1', subjectId: 'PBT Pemrograman Berbasis Teks', roomId: 'R3', teacherId: 'G07'),
    ScheduleEntry(id: '30', day: 'Rabu', slotLabel: 'Jam 11', classId: 'K1', subjectId: 'PKK', roomId: 'R1', teacherId: 'G08'),
    ScheduleEntry(id: '31', day: 'Rabu', slotLabel: 'Jam 12', classId: 'K1', subjectId: 'PKK', roomId: 'R1', teacherId: 'G08'),

    // Kamis
    ScheduleEntry(id: '32', day: 'Kamis', slotLabel: 'Jam 1', classId: 'K1', subjectId: 'PJOK', roomId: 'R4', teacherId: 'G09'),
    ScheduleEntry(id: '33', day: 'Kamis', slotLabel: 'Jam 2', classId: 'K1', subjectId: 'PJOK', roomId: 'R4', teacherId: 'G09'),
    ScheduleEntry(id: '34', day: 'Kamis', slotLabel: 'Jam 3', classId: 'K1', subjectId: 'Bahasa Sunda', roomId: 'R1', teacherId: 'G10'),
    ScheduleEntry(id: '35', day: 'Kamis', slotLabel: 'Jam 4', classId: 'K1', subjectId: 'Bahasa Sunda', roomId: 'R1', teacherId: 'G10'),
    ScheduleEntry(id: '36', day: 'Kamis', slotLabel: 'Jam 5', classId: 'K1', subjectId: 'BPBK', roomId: 'R1', teacherId: 'G11'),
    ScheduleEntry(id: 'e_k2', day: 'Kamis', slotLabel: 'Jam 6', classId: 'K1', isEvent: true, customTitle: 'TUGAS MANDIRI'),
    ScheduleEntry(id: '37', day: 'Kamis', slotLabel: 'Jam 7', classId: 'K1', subjectId: 'Bahasa Inggris', roomId: 'R1', teacherId: 'G06'),
    ScheduleEntry(id: '38', day: 'Kamis', slotLabel: 'Jam 8', classId: 'K1', subjectId: 'Bahasa Inggris', roomId: 'R1', teacherId: 'G06'),
    ScheduleEntry(id: '39', day: 'Kamis', slotLabel: 'Jam 9', classId: 'K1', subjectId: 'Matematika', roomId: 'R1', teacherId: 'G12'),
    ScheduleEntry(id: 'e_k3', day: 'Kamis', slotLabel: 'Jam 10', classId: 'K1', isEvent: true, customTitle: 'Istirahat'),
    ScheduleEntry(id: '40', day: 'Kamis', slotLabel: 'Jam 11', classId: 'K1', subjectId: 'Matematika', roomId: 'R1', teacherId: 'G12'),
    ScheduleEntry(id: '41', day: 'Kamis', slotLabel: 'Jam 12', classId: 'K1', subjectId: 'Matematika', roomId: 'R1', teacherId: 'G12'),

    // Jumat
    ScheduleEntry(id: '42', day: 'Jumat', slotLabel: 'Jam 2', classId: 'K1', subjectId: 'STA', roomId: 'R1', teacherId: 'G13'),
    ScheduleEntry(id: '43', day: 'Jumat', slotLabel: 'Jam 3', classId: 'K1', subjectId: 'STA', roomId: 'R1', teacherId: 'G13'),
    ScheduleEntry(id: '44', day: 'Jumat', slotLabel: 'Jam 4', classId: 'K1', subjectId: 'Ppan', roomId: 'R1', teacherId: 'G01'),
    ScheduleEntry(id: '45', day: 'Jumat', slotLabel: 'Jam 5', classId: 'K1', subjectId: 'Ppan', roomId: 'R1', teacherId: 'G01'),
    ScheduleEntry(id: '46', day: 'Jumat', slotLabel: 'Jam 6', classId: 'K1', subjectId: 'PWP', roomId: 'R5', teacherId: 'G14'),
    ScheduleEntry(id: '47', day: 'Jumat', slotLabel: 'Jam 7', classId: 'K1', subjectId: 'PWP', roomId: 'R5', teacherId: 'G14'),
    ScheduleEntry(id: '48', day: 'Jumat', slotLabel: 'Jam 8', classId: 'K1', subjectId: 'PWP', roomId: 'R5', teacherId: 'G14'),
    ScheduleEntry(id: '49', day: 'Jumat', slotLabel: 'Jam 9', classId: 'K1', subjectId: 'PWP', roomId: 'R5', teacherId: 'G14'),
    ScheduleEntry(id: '50', day: 'Jumat', slotLabel: 'Jam 10', classId: 'K1', subjectId: 'PWP', roomId: 'R5', teacherId: 'G14'),
    ScheduleEntry(id: 'e_j2', day: 'Jumat', slotLabel: 'Jam 11', classId: 'K1', isEvent: true, customTitle: 'Tugas Mandiri'),
  ];

  static List<ScheduleEntry> get schedules {
    final List<ScheduleEntry> result = List.from(_initialSchedules);
    final globalMandatoryEvents = [
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

    for (var cls in classes) {
      for (var ev in globalMandatoryEvents) {
        final exists = result.any((s) => s.classId == cls.id && s.day == ev['day'] && s.slotLabel == ev['slot']);
        if (!exists) {
          result.add(ScheduleEntry(
            id: 'global_${cls.id}_${ev['day']}_${ev['slot']}',
            day: ev['day']!,
            slotLabel: ev['slot']!,
            classId: cls.id,
            isEvent: true,
            customTitle: ev['title'],
          ));
        }
      }
    }
    return result;
  }
}
