import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/attendance_export_row.dart';

class AttendanceExportService {
  static String _fileBaseName([String? suffix]) {
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    return suffix != null ? 'rekap_absensi_${suffix}_$stamp' : 'rekap_absensi_$stamp';
  }

  static Uint8List buildExcelBytes(List<AttendanceExportRow> rows) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? excel.sheets.keys.first;
    if (defaultSheet != 'Rekap Absensi') {
      excel.rename(defaultSheet, 'Rekap Absensi');
    }
    final sheet = excel['Rekap Absensi'];

    sheet.appendRow([
      'NIS/NISN',
      'Nama Lengkap',
      'Kehadiran',
      'Kelas',
      'Mata Pelajaran',
      'Tanggal',
      'Diisi Oleh',
    ]);

    for (final row in rows) {
      sheet.appendRow([
        row.nisNisn,
        row.name,
        row.kehadiran,
        row.kelas,
        row.mapel,
        row.tanggal,
        row.diisiOleh,
      ]);
    }

    final encoded = excel.encode();
    if (encoded == null) {
      throw Exception('Gagal membuat file Excel.');
    }
    return Uint8List.fromList(encoded);
  }

  static Future<Uint8List> buildPdfBytes(
    List<AttendanceExportRow> rows, {
    String title = 'Rekap Absensi Siswa',
  }) async {
    final pdf = pw.Document();
    final tableData = rows
        .map((r) => [r.nisNisn, r.name, r.kehadiran, r.kelas, r.mapel, r.tanggal])
        .toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Diekspor: ${DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          if (rows.isEmpty)
            pw.Text('Tidak ada data absensi pada filter ini.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['NIS/NISN', 'Nama Lengkap', 'Kehadiran', 'Kelas', 'Mapel', 'Tanggal'],
              data: tableData,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            ),
        ],
      ),
    );

    return Uint8List.fromList(await pdf.save());
  }

  static Future<String> downloadExcel(List<AttendanceExportRow> rows) async {
    final bytes = buildExcelBytes(rows);
    final name = _fileBaseName();
    return await FileSaver.instance.saveFile(
      name: name,
      bytes: bytes,
      ext: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }

  static Future<String> downloadPdf(
    List<AttendanceExportRow> rows, {
    String title = 'Rekap Absensi Siswa',
  }) async {
    final bytes = await buildPdfBytes(rows, title: title);
    final name = _fileBaseName('pdf');
    return await FileSaver.instance.saveFile(
      name: name,
      bytes: bytes,
      ext: 'pdf',
      mimeType: MimeType.pdf,
    );
  }
}
