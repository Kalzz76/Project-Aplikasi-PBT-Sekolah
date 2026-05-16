import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../models/import_student_row.dart';

class StudentImportService {
  /// Membaca file .xlsx atau .csv menjadi baris siswa.
  static List<ImportStudentRow> parseFile(Uint8List bytes, String extension) {
    final ext = extension.toLowerCase().replaceAll('.', '');
    if (ext == 'csv') {
      return _parseCsv(String.fromCharCodes(bytes));
    }
    if (ext == 'xlsx') {
      return _parseExcel(bytes);
    }
    throw FormatException('Format tidak didukung. Gunakan file .xlsx atau .csv');
  }

  static List<ImportStudentRow> _parseExcel(Uint8List bytes) {
    final workbook = Excel.decodeBytes(bytes);
    if (workbook.tables.isEmpty) {
      throw FormatException('File Excel kosong atau tidak memiliki sheet.');
    }

    // Get the first available sheet safely
    final sheetName = workbook.tables.keys.first;
    final sheet = workbook.tables[sheetName];
    
    if (sheet == null || sheet.rows.isEmpty) {
      throw FormatException('Sheet "$sheetName" tidak berisi data.');
    }

    final tableRows = sheet.rows
        .where((row) => row != null) // Safety check for null rows
        .map((row) => row!.map(_cellText).toList())
        .where((row) => row.any((c) => c.isNotEmpty))
        .toList();

    return _rowsFromTable(tableRows);
  }

  static String _cellText(Data? cell) {
    // Handling based on excel package Data structure
    if (cell == null) return '';
    final val = cell.value;
    if (val == null) return '';
    return val.toString().trim();
  }

  static List<ImportStudentRow> _parseCsv(String content) {
    final lines = content.split(RegExp(r'\r?\n'));
    final tableRows = <List<String>>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      tableRows.add(_splitCsvLine(trimmed));
    }
    return _rowsFromTable(tableRows);
  }

  static List<String> _splitCsvLine(String line) {
    if (!line.contains(';')) {
      return line.split(',').map((e) => e.trim()).toList();
    }
    return line.split(';').map((e) => e.trim()).toList();
  }

  static List<ImportStudentRow> _rowsFromTable(List<List<String>> tableRows) {
    if (tableRows.isEmpty) return [];

    var startIndex = 0;
    Map<String, int> columns = {};

    if (_looksLikeHeader(tableRows.first)) {
      columns = _mapHeaderColumns(tableRows.first);
      startIndex = 1;
    } else {
      columns = _defaultColumns(tableRows.first.length);
    }

    final result = <ImportStudentRow>[];
    for (var i = startIndex; i < tableRows.length; i++) {
      final row = tableRows[i];
      if (row.every((c) => c.isEmpty)) continue;

      final nis = _valueAt(row, columns['nis']);
      final name = _valueAt(row, columns['name']);
      final kelas = _valueAt(row, columns['kelas']);

      if (nis.isEmpty && name.isEmpty) continue;
      if (nis.isEmpty || name.isEmpty || kelas.isEmpty) continue;

      result.add(ImportStudentRow(
        nis: nis,
        nisn: _valueAt(row, columns['nisn']),
        name: name,
        gender: _normalizeGender(_valueAt(row, columns['gender'])),
        kelas: kelas,
      ));
    }
    return result;
  }

  static bool _looksLikeHeader(List<String> row) {
    final joined = row.join(' ').toLowerCase();
    return joined.contains('nis') ||
        joined.contains('nama') ||
        joined.contains('kelas') ||
        joined.contains('jenis');
  }

  static Map<String, int> _mapHeaderColumns(List<String> header) {
    final map = <String, int>{};
    for (var i = 0; i < header.length; i++) {
      final h = header[i].toLowerCase();
      if (h.contains('nisn')) {
        map['nisn'] = i;
      } else if (h.contains('nis')) {
        map['nis'] = i;
      } else if (h.contains('nama')) {
        map['name'] = i;
      } else if (h.contains('jenis') || h == 'jk' || h.contains('kelamin') || h == 'l/p') {
        map['gender'] = i;
      } else if (h.contains('kelas')) {
        map['kelas'] = i;
      }
    }
    if (!map.containsKey('nis') || !map.containsKey('name') || !map.containsKey('kelas')) {
      return _defaultColumns(header.length);
    }
    map.putIfAbsent('nisn', () => -1);
    map.putIfAbsent('gender', () => -1);
    return map;
  }

  static Map<String, int> _defaultColumns(int colCount) {
    if (colCount >= 5) {
      return {'nis': 0, 'nisn': 1, 'name': 2, 'gender': 3, 'kelas': 4};
    }
    return {'nis': 0, 'name': 1, 'gender': 2, 'kelas': 3, 'nisn': -1};
  }

  static String _valueAt(List<String> row, int? index) {
    if (index == null || index < 0 || index >= row.length) return '';
    return row[index].trim();
  }

  static String _normalizeGender(String raw) {
    final g = raw.trim().toUpperCase();
    if (g.startsWith('P') || g.contains('PEREMPUAN')) return 'P';
    return 'L';
  }
}
