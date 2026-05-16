class ImportStudentRow {
  final String nis;
  final String nisn;
  final String name;
  final String gender;
  final String kelas;

  ImportStudentRow({
    required this.nis,
    required this.nisn,
    required this.name,
    required this.gender,
    required this.kelas,
  });
}

class ImportResult {
  final int success;
  final int skipped;
  final int classesCreated;
  final List<String> errors;

  ImportResult({
    required this.success,
    required this.skipped,
    required this.classesCreated,
    required this.errors,
  });
}
