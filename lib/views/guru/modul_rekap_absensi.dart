import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../providers/app_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_badge.dart';
import '../../models/attendance.dart';
import '../../models/student.dart';
import '../../widgets/export_attendance_dialog.dart';

class ModulRekapAbsensi extends StatefulWidget {
  const ModulRekapAbsensi({super.key});

  @override
  State<ModulRekapAbsensi> createState() => _ModulRekapAbsensiState();
}

class _ModulRekapAbsensiState extends State<ModulRekapAbsensi> {
  String _selectedPeriod = '1 Bulan';
  final List<String> _periods = ['Semua', '1 Bulan', '3 Bulan', '6 Bulan'];
  String _selectedClass = 'Semua Kelas';
  String _selectedSubject = 'Semua Mapel';
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final user = provider.currentUser;
    final allRekap = provider.getTeacherAttendanceRekap(user.id);
    
    final classes = ['Semua Kelas', ...provider.classes.map((c) => c.name)];
    final subjects = [
      'Semua Mapel',
      ...allRekap.map((e) => e.subjectId).toSet(),
    ];

    final now = DateTime.now();
    final filteredRekap = allRekap.where((r) {
      var periodMatch = true;
      if (_selectedPeriod == '1 Bulan') {
        periodMatch = r.date.month == now.month && r.date.year == now.year;
      } else if (_selectedPeriod == '3 Bulan') {
        periodMatch = r.date.isAfter(now.subtract(const Duration(days: 90)));
      } else if (_selectedPeriod == '6 Bulan') {
        periodMatch = r.date.isAfter(now.subtract(const Duration(days: 180)));
      }

      final classMatch = _selectedClass == 'Semua Kelas' ||
          r.classId == _selectedClass ||
          provider.findClassByIdOrName(_selectedClass)?.id == r.classId;

      final subjectMatch = _selectedSubject == 'Semua Mapel' || r.subjectId == _selectedSubject;

      final dateMatch = _selectedDate == null || provider.isSameCalendarDay(r.date, _selectedDate!);

      return periodMatch && classMatch && subjectMatch && dateMatch;
    }).toList();

    // Stats Calculation
    final total = filteredRekap.length;
    final hadir = filteredRekap.where((r) => r.status == AttendanceStatus.hadir).length;
    final absensiRate = total > 0 ? (hadir / total * 100).toStringAsFixed(1) : '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, provider, filteredRekap),
        const SizedBox(height: 32),
        _buildStatsDashboard(total, hadir, absensiRate),
        const SizedBox(height: 32),
        _buildFilters(classes, subjects),
        const SizedBox(height: 24),
        _buildAttendanceList(filteredRekap, provider),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, AppProvider provider, List<Attendance> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Rekap Absensi Siswa', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            CustomButton(
              variant: ButtonVariant.primary,
              size: ButtonSize.md,
              icon: const Icon(LucideIcons.download, size: 18),
              onClick: () => _handleExport(context, provider, data), 
              child: const Text('Export Excel/PDF'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Pantau performa kehadiran siswa di seluruh kelas Anda.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      ],
    );
  }

  void _handleExport(BuildContext context, AppProvider provider, List<Attendance> data) {
    showExportAttendanceDialog(
      context,
      rows: provider.buildAttendanceExportRows(data),
      title: 'Rekap Absensi Siswa',
    );
  }

  Widget _buildStatsDashboard(int total, int hadir, String rate) {
    return Row(
      children: [
        _buildStatCard('Total Absensi', total.toString(), LucideIcons.fileSpreadsheet, const Color(0xFF6366F1)),
        const SizedBox(width: 24),
        _buildStatCard('Siswa Hadir', hadir.toString(), LucideIcons.users, const Color(0xFF10B981)),
        const SizedBox(width: 24),
        _buildStatCard('Rasio Kehadiran', '$rate%', LucideIcons.trendingUp, const Color(0xFFF59E0B)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: CustomCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(List<String> classes, List<String> subjects) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        _buildFilterDropdown('Rentang Waktu', _selectedPeriod, _periods, (v) => setState(() => _selectedPeriod = v!)),
        _buildFilterDropdown('Kelas', _selectedClass, classes, (v) => setState(() => _selectedClass = v!)),
        _buildFilterDropdown('Mapel', _selectedSubject, subjects, (v) => setState(() => _selectedSubject = v!)),
        InkWell(
          onTap: () async {
            final d = await showDatePicker(context: context, initialDate: _selectedDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
            if (d != null) setState(() => _selectedDate = d);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Text(_selectedDate == null ? 'Semua Tanggal' : 'Tanggal: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ),
        if (_selectedDate != null)
          TextButton(onPressed: () => setState(() => _selectedDate = null), child: const Text('Reset tanggal')),
      ],
    );
  }

  Widget _buildFilterDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)))).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(List<Attendance> data, AppProvider provider) {
    if (data.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Tidak ada data untuk periode ini.')));
    }

    return CustomCard(
      noPadding: true,
      child: Column(
        children: [
          _buildTableHead(),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = data[index];
              final student = provider.students.firstWhere((s) => s.id == item.studentId, orElse: () => Student(id: '', nis: '', nisn: '', name: 'Siswa', gender: '', kelas: '', position: ''));
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(student.nis, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    Expanded(flex: 1, child: Text(item.classId, style: const TextStyle(fontSize: 14))),
                    Expanded(flex: 2, child: Text(item.subjectId, style: const TextStyle(fontSize: 14))),
                    Expanded(flex: 2, child: Text('${item.date.day}/${item.date.month}/${item.date.year}', style: const TextStyle(fontSize: 14))),
                    Expanded(flex: 2, child: Text(item.markedByLabel, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: CustomBadge(
                          variant: _getBadgeVariant(item.status),
                          child: Text(item.statusLabel),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTableHead() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: const Color(0xFFF8FAFC),
      child: Row(
        children: const [
          Expanded(flex: 3, child: Text('SISWA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted))),
          Expanded(flex: 1, child: Text('KELAS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted))),
          Expanded(flex: 2, child: Text('MAPEL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted))),
          Expanded(flex: 2, child: Text('TANGGAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted))),
          Expanded(flex: 2, child: Text('DIISI OLEH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted))),
          Expanded(flex: 1, child: Center(child: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted)))),
        ],
      ),
    );
  }

  BadgeVariant _getBadgeVariant(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.hadir: return BadgeVariant.success;
      case AttendanceStatus.izin: return BadgeVariant.warning;
      case AttendanceStatus.sakit: return BadgeVariant.indigo;
      case AttendanceStatus.alpa: return BadgeVariant.danger;
      default: return BadgeVariant.defaultValue;
    }
  }
}
