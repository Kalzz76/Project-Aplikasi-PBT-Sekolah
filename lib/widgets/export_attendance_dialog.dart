import 'package:flutter/material.dart';

import '../models/attendance_export_row.dart';
import '../services/attendance_export_service.dart';
import 'custom_button.dart';

Future<void> showExportAttendanceDialog(
  BuildContext context, {
  required List<AttendanceExportRow> rows,
  String title = 'Export Rekap Absensi',
  String? subtitle,
}) {
  return showDialog(
    context: context,
    builder: (dialogContext) => _ExportAttendanceDialog(
      rows: rows,
      title: title,
      subtitle: subtitle,
    ),
  );
}

class _ExportAttendanceDialog extends StatefulWidget {
  final List<AttendanceExportRow> rows;
  final String title;
  final String? subtitle;

  const _ExportAttendanceDialog({
    required this.rows,
    required this.title,
    this.subtitle,
  });

  @override
  State<_ExportAttendanceDialog> createState() => _ExportAttendanceDialogState();
}

class _ExportAttendanceDialogState extends State<_ExportAttendanceDialog> {
  bool _isExporting = false;

  Future<void> _export(Future<String> Function() action, String label) async {
    if (_isExporting) return;
    if (widget.rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk diekspor.')),
      );
      return;
    }

    setState(() => _isExporting = true);
    try {
      final path = await action();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label berhasil diunduh: $path'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal export: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.subtitle != null) ...[
              Text(
                widget.subtitle!,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.indigo),
              ),
              const SizedBox(height: 12),
            ],
            const Text(
              'Format kolom:\n• NIS/NISN\n• Nama Lengkap\n• Kehadiran (Hadir, Sakit, Izin, Alpa)',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              '${widget.rows.length} baris data siap diunduh sebagai file .xlsx atau .pdf.',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            if (_isExporting) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              const Center(child: Text('Menyiapkan file...', style: TextStyle(fontSize: 12))),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        CustomButton(
          variant: ButtonVariant.outline,
          onClick: _isExporting
              ? null
              : () => _export(
                    () => AttendanceExportService.downloadExcel(widget.rows),
                    'Excel',
                  ),
          child: const Text('Download Excel (.xlsx)'),
        ),
        CustomButton(
          onClick: _isExporting
              ? null
              : () => _export(
                    () => AttendanceExportService.downloadPdf(
                      widget.rows,
                      title: widget.title,
                    ),
                    'PDF',
                  ),
          child: const Text('Download PDF'),
        ),
      ],
    );
  }
}
