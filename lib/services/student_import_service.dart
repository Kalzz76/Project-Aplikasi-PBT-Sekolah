import 'dart:typed_data';
import 'package:excel/excel.dart';
import '../models/import_student_row.dart';

class StudentImportService {
  /// Membaca file .xlsx atau .csv menjadi baris siswa.
  static List<ImportStudentRow> parseFile(Uint8List bytes, String extension, String fileName) {
    final ext = extension.toLowerCase().replaceAll('.', '');
    if (ext == 'csv') {
      return _parseCsv(String.fromCharCodes(bytes), fileName);
    }
    if (ext == 'xlsx') {
      return _parseExcel(bytes, fileName);
    }
    throw FormatException('Format tidak didukung. Gunakan file .xlsx atau .csv');
  }

  static List<ImportStudentRow> _parseExcel(Uint8List bytes, String fileName) {
    final cleanBytes = Uint8List.fromList(bytes);
    final workbook = Excel.decodeBytes(cleanBytes);
    if (workbook.tables.isEmpty) {
      throw FormatException('File Excel kosong atau tidak memiliki sheet.');
    }

    // Get the first available sheet safely
    final sheetName = workbook.tables.keys.first;
    final sheet = workbook.tables[sheetName];
    
    final rows = sheet?.rows;
    if (sheet == null || rows == null || rows.isEmpty) {
      throw FormatException('Sheet "$sheetName" tidak berisi data.');
    }

    // Highly null-safe row parsing avoiding the bang (!) operator on potentially null rows
    final tableRows = rows
        .map((row) => row?.map(_cellText).toList() ?? <String>[])
        .where((row) => row.any((c) => c.isNotEmpty))
        .toList();

    return _rowsFromTable(tableRows, fileName);
  }

  static String _cellText(Data? cell) {
    if (cell == null) return '';
    final val = cell.value;
    if (val == null) return '';
    
    String str = val.toString().trim();
    // Clean up .0 from integers parsed as doubles (like NIS/NISN)
    if (RegExp(r'^\d+\.0$').hasMatch(str)) {
      str = str.substring(0, str.length - 2);
    }
    return str;
  }

  static List<ImportStudentRow> _parseCsv(String content, String fileName) {
    final lines = content.split(RegExp(r'\r?\n'));
    final tableRows = <List<String>>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      tableRows.add(_splitCsvLine(trimmed));
    }
    return _rowsFromTable(tableRows, fileName);
  }

  static List<String> _splitCsvLine(String line) {
    if (!line.contains(';')) {
      return line.split(',').map((e) => e.trim()).toList();
    }
    return line.split(';').map((e) => e.trim()).toList();
  }

  static String extractClassName(String fileName) {
    final cleanName = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
    final regex = RegExp(r'(X|XI|XII)[\s_]+[A-Za-z0-9]+[\s_]+\d+');
    final match = regex.firstMatch(cleanName);
    if (match != null) {
      return match.group(0)!.replaceAll('_', ' ').toUpperCase();
    }
    final regexSimple = RegExp(r'(X|XI|XII)[\s_]+[A-Za-z\s0-9]+');
    final matchSimple = regexSimple.firstMatch(cleanName);
    if (matchSimple != null) {
      return matchSimple.group(0)!.replaceAll('_', ' ').trim().toUpperCase();
    }
    return '';
  }

  static List<ImportStudentRow> _rowsFromTable(List<List<String>> tableRows, String fileName) {
    if (tableRows.isEmpty) return [];

    int headerIndex = -1;
    Map<String, int> columns = {};

    // Scan for a row that actually looks like a real header
    for (var i = 0; i < tableRows.length; i++) {
      final row = tableRows[i];
      // A header row must have at least 3 non-empty cells
      if (row.where((c) => c.isNotEmpty).length < 3) continue;

      if (_looksLikeHeader(row)) {
        headerIndex = i;
        columns = _mapHeaderColumns(row);
        break;
      }
    }

    int startIndex = 0;
    if (headerIndex != -1) {
      startIndex = headerIndex + 1;
    } else {
      // No header found, try to find the first row with at least 3 non-empty cells
      for (var i = 0; i < tableRows.length; i++) {
        if (tableRows[i].where((c) => c.isNotEmpty).length >= 3) {
          startIndex = i;
          columns = _defaultColumns(tableRows[i].length);
          break;
        }
      }
    }

    final extractedKelas = extractClassName(fileName);
    final result = <ImportStudentRow>[];

    for (var i = startIndex; i < tableRows.length; i++) {
      final row = tableRows[i];
      if (row.every((c) => c.isEmpty)) continue;

      var nis = _valueAt(row, columns['nis']);
      var nisn = _valueAt(row, columns['nisn']);
      final name = _valueAt(row, columns['name']);
      var kelas = _valueAt(row, columns['kelas']);

      // 1. Handle split NIS/NISN if they are merged in one column (e.g. "102419349 / 0089761823")
      if (nis.contains('/') || nisn.contains('/')) {
        final mergedVal = nis.contains('/') ? nis : nisn;
        final parts = mergedVal.split('/');
        if (parts.length >= 2) {
          nis = parts[0].trim();
          nisn = parts[1].trim();
        }
      }

      // 2. Handle fallback class name from file name if the 'kelas' column is missing or empty
      if (kelas.isEmpty && extractedKelas.isNotEmpty) {
        kelas = extractedKelas;
      }

      if (nis.isEmpty && name.isEmpty) continue;
      if (nis.isEmpty || name.isEmpty || kelas.isEmpty) continue;

      result.add(ImportStudentRow(
        nis: nis,
        nisn: nisn,
        name: name,
        gender: _normalizeGender(_valueAt(row, columns['gender'])),
        kelas: kelas,
      ));
    }
    return result;
  }

  static bool _looksLikeHeader(List<String> row) {
    int matchCount = 0;
    for (final cell in row) {
      final c = cell.toLowerCase().trim();
      if (c == 'no' || c == 'no.') continue;
      if (c.contains('nisn')) {
        matchCount++;
      } else if (c.contains('nis')) {
        matchCount++;
      } else if (c.contains('nama') || c.contains('name')) {
        matchCount++;
      } else if (c.contains('kelas') || c.contains('class')) {
        matchCount++;
      } else if (c.contains('jenis') || c == 'jk' || c.contains('kelamin') || c == 'l/p') {
        matchCount++;
      }
    }
    return matchCount >= 2;
  }

  static Map<String, int> _mapHeaderColumns(List<String> header) {
    final map = <String, int>{};
    for (var i = 0; i < header.length; i++) {
      final h = header[i].toLowerCase().trim();
      // Use individual ifs to capture if a column is both (e.g. "NIS / NISN")
      if (h.contains('nisn')) {
        map['nisn'] = i;
      }
      if (h.contains('nis')) {
        map['nis'] = i;
      }
      if (h.contains('nama') || h.contains('name')) {
        map['name'] = i;
      }
      if (h.contains('jenis') || h == 'jk' || h.contains('kelamin') || h == 'l/p') {
        map['gender'] = i;
      }
      if (h.contains('kelas') || h.contains('class')) {
        map['kelas'] = i;
      }
    }
    if (!map.containsKey('nis') || !map.containsKey('name') || !map.containsKey('kelas')) {
      final defs = _defaultColumns(header.length);
      map.putIfAbsent('nis', () => defs['nis'] ?? 0);
      map.putIfAbsent('name', () => defs['name'] ?? 1);
      map.putIfAbsent('kelas', () => defs['kelas'] ?? 3);
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
