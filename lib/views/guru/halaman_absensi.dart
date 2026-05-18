import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../providers/app_provider.dart';
import '../../core/chronos_service.dart';
import '../../models/user.dart';
import '../../models/student.dart';
import '../../models/attendance.dart';
import '../../models/schedule.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_badge.dart';

class HalamanAbsensi extends StatefulWidget {
  const HalamanAbsensi({super.key});

  @override
  State<HalamanAbsensi> createState() => _HalamanAbsensiState();
}

class _HalamanAbsensiState extends State<HalamanAbsensi> {
  final Map<String, AttendanceStatus> _attendanceState = {};
  List<ScheduleEntry> _scheduleEntries = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStudents());
  }

  void _loadStudents() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final cls = provider.selectedClassForAttendance;
    final sub = provider.selectedSubjectForAttendance;
    if (cls == null || sub == null) return;

    final students = provider.getStudentsByClass(cls.id);
    final state = provider.loadAttendanceStateForSession(
      classId: cls.id,
      subjectName: sub.name,
      students: students,
    );
    setState(() => _attendanceState
      ..clear()
      ..addAll(state));
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final cls = provider.selectedClassForAttendance;
    final sub = provider.selectedSubjectForAttendance;

    if (cls == null || sub == null) {
      return const Center(child: Text('Data kelas tidak ditemukan.'));
    }

    final students = provider.getStudentsByClass(cls.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(cls, sub, provider),
        const SizedBox(height: 32),
        _buildAttendanceList(students),
        const SizedBox(height: 32),
        _buildFooter(context, provider, cls, sub),
      ],
    );
  }

  Widget _buildHeader(cls, sub, provider) {
    return Row(
      children: [
        IconButton(
          onPressed: () => provider.setActiveMenu('dashboard'),
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Absensi ${cls.name}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Text('${sub.name} • ${ChronosService.instance.now().day}/${ChronosService.instance.now().month}/${ChronosService.instance.now().year}', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }

  Widget _buildAttendanceList(List<Student> students) {
    return CustomCard(
      noPadding: true,
      child: Column(
        children: [
          _buildTableHead(),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: students.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final student = students[index];
              final currentStatus = _attendanceState[student.id] ?? AttendanceStatus.hadir;
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          CircleAvatar(radius: 18, backgroundColor: AppColors.primary.withOpacity(0.1), child: Text(student.name[0], style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold))),
                          const SizedBox(width: 12),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(student.nis, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          ]),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: AttendanceStatus.values.where((v) => v != AttendanceStatus.pulang).map((status) {
                          final isSelected = currentStatus == status;
                          return _buildStatusOption(status, isSelected, () {
                            setState(() => _attendanceState[student.id] = status);
                          });
                        }).toList(),
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
          Expanded(flex: 3, child: Text('NAMA SISWA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted))),
          Expanded(flex: 4, child: Center(child: Text('STATUS KEHADIRAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted)))),
        ],
      ),
    );
  }

  Widget _buildStatusOption(AttendanceStatus status, bool isSelected, VoidCallback onTap) {
    Color color;
    String label;
    switch (status) {
      case AttendanceStatus.hadir: color = Colors.green; label = 'H'; break;
      case AttendanceStatus.izin: color = Colors.amber; label = 'I'; break;
      case AttendanceStatus.sakit: color = Colors.blue; label = 'S'; break;
      case AttendanceStatus.alpa: color = Colors.red; label = 'A'; break;
      default: color = Colors.grey; label = '?';
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? color : AppColors.border, width: 2),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, AppProvider provider, cls, sub) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total Siswa: ${_attendanceState.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
          CustomButton(
            size: ButtonSize.lg,
            onClick: () => _saveAttendance(context, provider, cls, sub),
            child: const Text('Simpan Absensi Hari Ini'),
          ),
        ],
      ),
    );
  }

  void _saveAttendance(BuildContext context, AppProvider provider, cls, sub) {
    final user = provider.currentUser;
    final isSiswa = user.role == UserRole.siswa;

    if (!isSiswa && !provider.canGuruMarkAttendance(cls.id, sub.name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Absensi sudah diisi Sekretaris. Guru tidak dapat mengubah.')),
      );
      return;
    }

    if (_scheduleEntries.isNotEmpty &&
        !provider.canMarkAttendanceNow(_scheduleEntries, provider.currentDayName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Absensi hanya dapat diisi selama jam pelajaran berlangsung.')),
      );
      return;
    }

    if (isSiswa) {
      _showReasonDialog(context, (reason) async {
        await provider.saveAttendanceBatch(
          cls: cls,
          sub: sub,
          statuses: Map.from(_attendanceState),
          user: user,
          reason: reason,
          scheduleEntries: _scheduleEntries.isEmpty ? null : _scheduleEntries,
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Absensi oleh Sekretaris berhasil disimpan!'), backgroundColor: Colors.green),
        );
        provider.setActiveMenu('dashboard');
      });
    } else {
      () async {
        await provider.saveAttendanceBatch(
          cls: cls,
          sub: sub,
          statuses: Map.from(_attendanceState),
          user: user,
          scheduleEntries: _scheduleEntries.isEmpty ? null : _scheduleEntries,
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Absensi berhasil disimpan!'), backgroundColor: Colors.green),
        );
        provider.setActiveMenu('dashboard');
      }();
    }
  }

  void _showReasonDialog(BuildContext context, Function(String) onConfirm) {
    String selectedReason = 'Guru Sakit';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alasan Mengisi Absensi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Mengapa Anda menggantikan Guru untuk mengabsensi?'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedReason,
              items: ['Guru Sakit', 'Guru Izin', 'Guru Tanpa Keterangan', 'Guru Rapat']
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => selectedReason = v!,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          CustomButton(onClick: () {
            Navigator.pop(context);
            onConfirm(selectedReason);
          }, child: const Text('Simpan')),
        ],
      ),
    );
  }
}
