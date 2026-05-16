class Student {
  final String id;
  final String nis;
  final String nisn;
  final String name;
  final String gender; // 'L' or 'P'
  final String kelas;
  final String position; // 'Ketua Murid', 'Wakil Ketua', 'Anggota', etc.

  Student({
    required this.id,
    required this.nis,
    required this.nisn,
    required this.name,
    required this.gender,
    required this.kelas,
    required this.position,
  });
}
