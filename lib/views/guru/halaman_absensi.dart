import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/attendance.dart';
import '../../models/student.dart';
import '../../models/teacher_attendance.dart';
import '../../models/school_class.dart';
import '../../models/subject.dart';
import '../../models/schedule.dart';
import '../../providers/app_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';

class HalamanAbsensi extends StatefulWidget {
  const HalamanAbsensi({super.key});

  @override
  State<HalamanAbsensi> createState() => _HalamanAbsensiState();
}

class _HalamanAbsensiState extends State<HalamanAbsensi> {
  // State Key: StudentID -> { SlotLabel -> Status }
  final Map<String, Map<String, AttendanceStatus>> _attendanceState = {};
  
  // Slot yang sedang dipilih untuk ditayangkan di tabel
  String? _activeViewSlotLabel;
  
  // State Key: SlotLabel yang dipilih untuk TIDAK HADIR bagi Guru
  final Set<String> _selectedSlots = {}; 
  
  TeacherAttendanceStatus _teacherStatus = TeacherAttendanceStatus.hadir;
  TeacherAbsenceReason? _teacherAbsenceReason;
  final TextEditingController _teacherNotesController = TextEditingController();
  List<ScheduleEntry> _scheduleEntries = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _teacherNotesController.dispose();
    super.dispose();
  }

  void _updateStudentStatus(String studentId, String slotLabel, AttendanceStatus newStatus) {
    setState(() {
      if (!_attendanceState.containsKey(studentId)) _attendanceState[studentId] = {};
      _attendanceState[studentId]![slotLabel] = newStatus;

      // Logika Kaskade Alpa: Jika Alpa di jam ini, jam berikutnya otomatis Alpa
      if (newStatus == AttendanceStatus.alpa) {
        bool startCascading = false;
        for (var entry in _scheduleEntries) {
          if (entry.slotLabel == slotLabel) {
            startCascading = true;
            continue;
          }
          if (startCascading) {
            _attendanceState[studentId]![entry.slotLabel] = AttendanceStatus.alpa;
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final cls = provider.selectedClassForAttendance;
    final sub = provider.selectedSubjectForAttendance;
    
    if (cls == null || sub == null) {
      return const Center(child: Text('Data tidak valid. Silakan kembali ke Dashboard.'));
    }

    final roomName = provider.currentSessionSchedule != null 
        ? provider.roomDisplayName(provider.currentSessionSchedule!, cls) 
        : (cls.roomName ?? '-');

    final students = provider.students.where((s) => s.kelas == cls.name).toList();
    
    // Ambil semua entri jadwal untuk sesi mapel ini
    _scheduleEntries = provider.schedules.where((s) => 
      s.classId == cls.id && 
      s.day == provider.currentDayName && 
      (s.subjectId == sub.id || s.subjectId == sub.name)
    ).toList();

    // Sort schedule entries by slot index
    final slots = provider.getTimeSlots(provider.currentDayName);
    _scheduleEntries.sort((a, b) {
      final idxA = slots.indexWhere((s) => s.label == a.slotLabel);
      final idxB = slots.indexWhere((s) => s.label == b.slotLabel);
      return idxA.compareTo(idxB);
    });

    // Inisialisasi active view jika kosong
    if (_activeViewSlotLabel == null && _scheduleEntries.isNotEmpty) {
      _activeViewSlotLabel = _scheduleEntries.first.slotLabel;
    }

    // Inisialisasi state absensi siswa jika masih kosong
    if (_attendanceState.isEmpty && students.isNotEmpty && _scheduleEntries.isNotEmpty) {
      for (var s in students) {
        _attendanceState[s.id] = {};
        for (var entry in _scheduleEntries) {
          _attendanceState[s.id]![entry.slotLabel] = AttendanceStatus.hadir;
        }
      }
    }

    // Inisialisasi slots guru jika kosong
    if (_selectedSlots.isEmpty && _scheduleEntries.isNotEmpty) {
      for (var entry in _scheduleEntries) {
        _selectedSlots.add(entry.slotLabel);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(cls, sub, roomName, provider),
          const SizedBox(height: 24),
          
          _buildTeacherAttendanceSection(provider, provider.isDarkMode),
          const SizedBox(height: 32),
          
          _buildJPSelector(),
          const SizedBox(height: 16),
          
          _buildAttendanceList(students),
          const SizedBox(height: 32),

          _buildFooter(context, provider, cls, sub),
        ],
      ),
    );
  }

  Widget _buildJPSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Jam Pelajaran untuk Diabsen:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _scheduleEntries.map((entry) {
            final isActive = _activeViewSlotLabel == entry.slotLabel;
            return InkWell(
              onTap: () => setState(() => _activeViewSlotLabel = entry.slotLabel),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isActive ? AppColors.primary : AppColors.border),
                  boxShadow: isActive ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                ),
                child: Text(
                  entry.slotLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHeader(SchoolClass cls, Subject sub, String? roomName, AppProvider provider) {
    final now = DateTime.now();
    return Row(
      children: [
        IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => provider.setActiveMenu('dashboard'),
          tooltip: 'Kembali',
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
          child: const Icon(LucideIcons.clipboardList, color: AppColors.primary, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Absensi ${cls.name}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Text(
                '${sub.name}${roomName != null ? " • $roomName" : ""} • ${now.day}/${now.month}/${now.year}',
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceList(List<Student> students) {
    if (_activeViewSlotLabel == null) return const SizedBox.shrink();

    return CustomCard(
      noPadding: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              final studentRowState = _attendanceState[student.id] ?? {};
              final currentStatus = studentRowState[_activeViewSlotLabel] ?? AttendanceStatus.hadir;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(student.name[0], style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                                Text(student.nis, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Status Options for the Active JP
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: AttendanceStatus.values
                          .where((v) => v != AttendanceStatus.pulang)
                          .map((status) {
                        final isSelected = currentStatus == status;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _buildStatusOption(
                            status,
                            isSelected,
                            () => _updateStudentStatus(student.id, _activeViewSlotLabel!, status),
                          ),
                        );
                      }).toList(),
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
      color: const Color(0xFFF1F5F9),
      child: Row(
        children: [
          const Expanded(child: Text('NAMA SISWA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted))),
          Text('STATUS (${_activeViewSlotLabel})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildStatusOption(AttendanceStatus status, bool isSelected, VoidCallback onTap) {
    Color color;
    String label;
    switch (status) {
      case AttendanceStatus.hadir: color = AppColors.success; label = 'Hadir'; break;
      case AttendanceStatus.izin: color = AppColors.primary; label = 'Izin'; break;
      case AttendanceStatus.sakit: color = AppColors.warning; label = 'Sakit'; break;
      case AttendanceStatus.alpa: color = AppColors.danger; label = 'Alpa'; break;
      default: color = Colors.grey; label = '?';
    }

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : AppColors.border),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textMuted,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherAttendanceSection(AppProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.userCheck, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Text(
                'Kehadiran Guru Pengajar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.getTextColor(isDark)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTeacherStatusButton(
                label: 'Hadir',
                icon: LucideIcons.check,
                color: AppColors.success,
                isSelected: _teacherStatus == TeacherAttendanceStatus.hadir,
                onTap: () => setState(() { _teacherStatus = TeacherAttendanceStatus.hadir; _teacherAbsenceReason = null; }),
              ),
              const SizedBox(width: 12),
              _buildTeacherStatusButton(
                label: 'Tidak Hadir',
                icon: LucideIcons.x,
                color: AppColors.danger,
                isSelected: _teacherStatus == TeacherAttendanceStatus.tidakHadir,
                onTap: () => setState(() => _teacherStatus = TeacherAttendanceStatus.tidakHadir),
              ),
            ],
          ),
          if (_teacherStatus == TeacherAttendanceStatus.tidakHadir) ...[
            const SizedBox(height: 20),
            const Text('Pilih Jam Ketidakhadiran Guru:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _scheduleEntries.map((entry) {
                final isAbsentSelected = _selectedSlots.contains(entry.slotLabel);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isAbsentSelected) {
                        if (_selectedSlots.length > 1) _selectedSlots.remove(entry.slotLabel);
                      } else {
                        _selectedSlots.add(entry.slotLabel);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isAbsentSelected ? AppColors.danger.withOpacity(0.1) : AppColors.success.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isAbsentSelected ? AppColors.danger : AppColors.success.withOpacity(0.5), width: isAbsentSelected ? 2 : 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(entry.slotLabel, style: TextStyle(fontWeight: FontWeight.bold, color: isAbsentSelected ? AppColors.danger : AppColors.success)),
                        const SizedBox(width: 4),
                        Icon(isAbsentSelected ? LucideIcons.xCircle : LucideIcons.checkCircle2, size: 14, color: isAbsentSelected ? AppColors.danger : AppColors.success),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Alasan Tidak Hadir *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<TeacherAbsenceReason>(
                  value: _teacherAbsenceReason,
                  items: TeacherAbsenceReason.values.map((r) => DropdownMenuItem(value: r, child: Text(_reasonLabel(r)))).toList(),
                  onChanged: (v) => setState(() => _teacherAbsenceReason = v),
                  decoration: InputDecoration(
                    hintText: 'Pilih alasan',
                    fillColor: const Color(0xFFF8FAFC),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _teacherNotesController,
              decoration: InputDecoration(
                labelText: 'Keterangan tambahan (opsional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeacherStatusButton({required String label, required IconData icon, required Color color, required bool isSelected, VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : AppColors.border, width: isSelected ? 2 : 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? color : AppColors.textMuted, size: 18),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? color : AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  String _reasonLabel(TeacherAbsenceReason reason) {
    switch (reason) {
      case TeacherAbsenceReason.terlambat: return 'Terlambat';
      case TeacherAbsenceReason.rapat: return 'Rapat';
      case TeacherAbsenceReason.sakit: return 'Sakit';
      case TeacherAbsenceReason.lainnya: return 'Lainnya';
    }
  }

  Widget _buildFooter(BuildContext context, AppProvider provider, SchoolClass cls, Subject sub) {
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Siswa: ${_attendanceState.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const Text('Absensi akan disimpan untuk semua jam.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          CustomButton(
            size: ButtonSize.lg,
            isLoading: _isSaving,
            onClick: _isSaving ? null : () => _saveAttendance(context, provider, cls, sub),
            child: const Text('Simpan Absensi'),
          ),
        ],
      ),
    );
  }

  void _saveAttendance(BuildContext context, AppProvider provider, SchoolClass cls, Subject sub) async {
    if (_teacherStatus == TeacherAttendanceStatus.tidakHadir && _teacherAbsenceReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih alasan ketidakhadiran guru terlebih dahulu.'), backgroundColor: AppColors.danger));
      return;
    }

    // Tampilkan dialog konfirmasi
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Absensi'),
        content: const Text('Apakah data absensi yang Anda masukkan sudah benar dan sesuai?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cek Lagi')),
          CustomButton(onClick: () => Navigator.pop(ctx, true), child: const Text('Ya, Sudah Benar')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);
    try {
      for (var entry in _scheduleEntries) {
        final Map<String, AttendanceStatus> studentStatuses = {};
        _attendanceState.forEach((studentId, slots) {
          studentStatuses[studentId] = slots[entry.slotLabel] ?? AttendanceStatus.hadir;
        });

        TeacherAttendanceStatus currentTeacherStatus = TeacherAttendanceStatus.hadir;
        if (_teacherStatus == TeacherAttendanceStatus.tidakHadir && _selectedSlots.contains(entry.slotLabel)) {
          currentTeacherStatus = TeacherAttendanceStatus.tidakHadir;
        }

        await provider.saveAttendanceBatch(
          cls: cls,
          sub: sub,
          statuses: studentStatuses,
          user: provider.currentUser,
          slotLabel: entry.slotLabel,
          scheduleEntries: [entry],
          teacherStatus: currentTeacherStatus,
          teacherAbsenceReason: currentTeacherStatus == TeacherAttendanceStatus.tidakHadir ? _teacherAbsenceReason : null,
          teacherNotes: _teacherNotesController.text.trim().isEmpty ? null : _teacherNotesController.text.trim(),
          teacherAmountOfLessons: 1,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil menyimpan absensi.'), backgroundColor: AppColors.success));
        provider.setActiveMenu('dashboard');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
