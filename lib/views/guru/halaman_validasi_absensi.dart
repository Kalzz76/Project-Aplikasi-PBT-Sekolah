import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/attendance.dart';
import '../../models/student.dart';
import '../../models/teacher_attendance.dart';
import '../../providers/app_provider.dart';
import '../../widgets/custom_badge.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_card.dart';

class HalamanValidasiAbsensi extends StatefulWidget {
  const HalamanValidasiAbsensi({super.key});

  @override
  State<HalamanValidasiAbsensi> createState() => _HalamanValidasiAbsensiState();
}

class _HalamanValidasiAbsensiState extends State<HalamanValidasiAbsensi> {
  Map<String, dynamic>? _selectedSessionGroup;
  String? _activeSlot;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final user = provider.currentUser;
    final isDark = provider.isDarkMode;
    
    // Group pending sessions by Class + Subject + Date
    final pendingSessions = _getGroupedSessions(provider, user.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              if (_selectedSessionGroup != null)
                IconButton(
                  onPressed: () => setState(() {
                    _selectedSessionGroup = null;
                    _activeSlot = null;
                  }),
                  icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
                ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedSessionGroup == null ? 'Validasi Absensi' : 'Validasi Sesi',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextColor(isDark),
                    ),
                  ),
                  Text(
                    _selectedSessionGroup == null
                        ? 'Periksa dan konfirmasi absensi yang diisi sekretaris'
                        : '${_selectedSessionGroup!['className']} • ${_selectedSessionGroup!['subjectName']}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_selectedSessionGroup == null)
            _buildGroupList(pendingSessions, isDark)
          else
            _buildSessionDetail(context, provider, _selectedSessionGroup!, isDark),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getGroupedSessions(AppProvider provider, String teacherId) {
    final pendingRecords = provider.attendance.where((a) =>
        a.validationStatus == ValidationStatus.pending &&
        a.markedByRole == 'siswa').toList();

    // Group by Class + Subject + Date
    final Map<String, Map<String, dynamic>> groups = {};
    
    for (final record in pendingRecords) {
      final teaches = provider.schedules.any((s) =>
          s.teacherId == teacherId &&
          (s.classId == record.classId) &&
          (provider.subjectDisplayName(s.subjectId ?? '') == record.subjectId));
      
      if (!teaches) continue;

      final dateStr = '${record.date.day}/${record.date.month}/${record.date.year}';
      final key = '${record.classId}_${record.subjectId}_$dateStr';

      if (!groups.containsKey(key)) {
        groups[key] = {
          'classId': record.classId,
          'className': provider.findClassByIdOrName(record.classId)?.name ?? record.classId,
          'subjectName': record.subjectId,
          'date': record.date,
          'dateStr': dateStr,
          'slots': <String, List<Attendance>>{},
        };
      }
      
      final slotsMap = groups[key]!['slots'] as Map<String, List<Attendance>>;
      slotsMap.putIfAbsent(record.slotLabel, () => []).add(record);
    }

    return groups.values.toList()..sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
  }

  Widget _buildGroupList(List<Map<String, dynamic>> groups, bool isDark) {
    if (groups.isEmpty) {
      return CustomCard(
        child: Column(
          children: [
            const SizedBox(height: 32),
            Icon(LucideIcons.clipboardCheck, size: 48, color: AppColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'Semua Absensi Terkonfirmasi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.getTextColor(isDark)),
            ),
            const SizedBox(height: 8),
            const Text('Tidak ada laporan baru yang perlu divalidasi.', style: TextStyle(color: AppColors.textMuted), textAlign: TextAlign.center),
            const SizedBox(height: 32),
          ],
        ),
      );
    }

    return Column(
      children: groups.map((g) {
        final slots = (g['slots'] as Map<String, List<Attendance>>).keys.toList();
        slots.sort(); // Sort slots if possible

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CustomCard(
            onClick: () {
              setState(() {
                _selectedSessionGroup = g;
                _activeSlot = slots.first;
              });
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(LucideIcons.clipboardList, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${g['className']} — ${g['subjectName']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('${g['dateStr']} • ${slots.length} Jam Pelajaran', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const CustomBadge(variant: BadgeVariant.warning, child: Text('Verifikasi')),
                const SizedBox(width: 12),
                const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.textMuted),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSessionDetail(BuildContext context, AppProvider provider, Map<String, dynamic> group, bool isDark) {
    final slotsMap = group['slots'] as Map<String, List<Attendance>>;
    final slots = slotsMap.keys.toList()..sort();
    
    if (_activeSlot == null || !slotsMap.containsKey(_activeSlot)) {
      _activeSlot = slots.first;
    }

    final currentRecords = slotsMap[_activeSlot]!;
    final studentIds = currentRecords.map((r) => r.studentId).toSet();
    final sortedStudents = provider.students.where((s) => studentIds.contains(s.id)).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    // Find teacher attendance for this specific slot and date
    TeacherAttendance? teacherAtt;
    try {
      final List<TeacherAttendance> allTeacherAtt = provider.teacherAttendance.whereType<TeacherAttendance>().toList();
      teacherAtt = allTeacherAtt.firstWhere(
        (ta) => ta.teacherId == provider.currentUser.id &&
                ta.slotLabel == _activeSlot &&
                provider.isSameCalendarDay(ta.date, group['date'] as DateTime) &&
                ta.classId == group['classId'],
      );
    } catch (_) {
      teacherAtt = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Teacher Self-Status Card
        CustomCard(
          color: isDark ? AppColors.primary.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.03),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(LucideIcons.userCheck, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('STATUS KEHADIRAN GURU', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                    const SizedBox(height: 2),
                    Text(
                      teacherAtt == null 
                        ? 'Belum dilaporkan' 
                        : (teacherAtt.status == TeacherAttendanceStatus.hadir 
                            ? 'Anda diabsenkan HADIR' 
                            : 'Anda diabsenkan TIDAK HADIR — ${teacherAtt.reasonLabel}'),
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.getTextColor(isDark)),
                    ),
                  ],
                ),
              ),
              if (teacherAtt != null)
                CustomBadge(
                  variant: teacherAtt.status == TeacherAttendanceStatus.hadir ? BadgeVariant.success : BadgeVariant.danger,
                  child: Text(teacherAtt.statusLabel),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // JP Selector
        Text('PILIH JAM PELAJARAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted.withValues(alpha: 0.7))),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: slots.map((s) {
              final isActive = _activeSlot == s;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => setState(() => _activeSlot = s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isActive ? AppColors.primary : AppColors.border),
                    ),
                    child: Text(
                      s,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.white : AppColors.getTextColor(isDark),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),

        // Attendance Table Header
        CustomCard(
          noPadding: true,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                child: const Row(
                  children: [
                    Expanded(flex: 3, child: Text('NAMA SISWA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textMuted))),
                    Expanded(flex: 1, child: Center(child: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textMuted)))),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedStudents.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final student = sortedStudents[index];
                  final record = currentRecords.firstWhere((r) => r.studentId == student.id);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(student.nis, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: CustomBadge(
                              variant: _statusBadge(record.status),
                              child: Text(record.statusLabel),
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
        ),
        const SizedBox(height: 32),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: CustomButton(
                variant: ButtonVariant.outline,
                onClick: () => _handleValidation(context, provider, group, _activeSlot!, ValidationStatus.rejected),
                child: const Text('Tolak Jam Ini', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomButton(
                variant: ButtonVariant.primary,
                onClick: () => _handleValidation(context, provider, group, _activeSlot!, ValidationStatus.validated),
                child: const Text('Validasi Jam Ini', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            variant: ButtonVariant.success,
            onClick: () => _handleBulkValidation(context, provider, group),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(LucideIcons.checkCheck, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Konfirmasi SEMUA Jam Pelajaran', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  BadgeVariant _statusBadge(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.hadir: return BadgeVariant.success;
      case AttendanceStatus.izin: return BadgeVariant.warning;
      case AttendanceStatus.sakit: return BadgeVariant.indigo;
      case AttendanceStatus.alpa: return BadgeVariant.danger;
      default: return BadgeVariant.defaultValue;
    }
  }

  void _handleValidation(BuildContext context, AppProvider provider, Map<String, dynamic> group, String slot, ValidationStatus newStatus) {
    final isConfirm = newStatus == ValidationStatus.validated;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isConfirm ? 'Konfirmasi Verifikasi' : 'Tolak Absensi'),
        content: Text(isConfirm 
            ? 'Konfirmasi kehadiran untuk jam pelajaran "$slot"? Data ini akan menjadi resmi.' 
            : 'Tolak laporan absensi untuk jam ini? Sekretaris harus mengisi ulang.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          CustomButton(
            onClick: () async {
              Navigator.pop(ctx);
              await provider.validateAttendanceSession(
                classId: group['classId'] as String,
                subjectId: group['subjectName'] as String,
                slotLabel: slot,
                date: group['date'] as DateTime,
                newStatus: newStatus,
                validatedBy: provider.currentUser.id,
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(isConfirm ? 'Berhasil konfirmasi $slot.' : 'Absensi ditolak.'),
                backgroundColor: isConfirm ? AppColors.success : AppColors.danger,
              ));
              
              // If group still has other pending slots, stay. Else go back.
              final updatedGroup = _getGroupedSessions(provider, provider.currentUser.id)
                  .firstWhere((g) => g['classId'] == group['classId'] && g['dateStr'] == group['dateStr'] && g['subjectName'] == group['subjectName'], orElse: () => {});
              
              if (updatedGroup.isEmpty) {
                setState(() {
                  _selectedSessionGroup = null;
                  _activeSlot = null;
                });
              } else {
                setState(() {
                  _selectedSessionGroup = updatedGroup;
                  final availableSlots = (updatedGroup['slots'] as Map).keys.toList();
                  if (!availableSlots.contains(_activeSlot)) {
                    _activeSlot = availableSlots.first;
                  }
                });
              }
            },
            child: Text(isConfirm ? 'Ya, Konfirmasi' : 'Tolak'),
          ),
        ],
      ),
    );
  }

  void _handleBulkValidation(BuildContext context, AppProvider provider, Map<String, dynamic> group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tindakan Masal (Bulk Action)'),
        content: const Text('Pilih tindakan yang ingin Anda lakukan untuk SELURUH jam pelajaran di sesi ini.'),
        actions: [
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  variant: ButtonVariant.danger,
                  onClick: () {
                    Navigator.pop(ctx);
                    _confirmBulkAction(context, provider, group, ValidationStatus.rejected);
                  },
                  child: const Text('Tolak Semua', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  variant: ButtonVariant.success,
                  onClick: () {
                    Navigator.pop(ctx);
                    _confirmBulkAction(context, provider, group, ValidationStatus.validated);
                  },
                  child: const Text('Validasi Semua', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmBulkAction(BuildContext context, AppProvider provider, Map<String, dynamic> group, ValidationStatus status) {
    final isConfirm = status == ValidationStatus.validated;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isConfirm ? 'Yakin Validasi Semua?' : 'Yakin Tolak Semua?'),
        content: Text(isConfirm 
            ? 'Seluruh absensi di sesi ini akan dikonfirmasi.' 
            : 'Seluruh laporan absensi di sesi ini akan ditolak.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tidak')),
          CustomButton(
            variant: isConfirm ? ButtonVariant.success : ButtonVariant.danger,
            onClick: () async {
              Navigator.pop(ctx);
              final slots = (group['slots'] as Map).keys.toList();
              for (final slot in slots) {
                await provider.validateAttendanceSession(
                  classId: group['classId'] as String,
                  subjectId: group['subjectName'] as String,
                  slotLabel: slot as String,
                  date: group['date'] as DateTime,
                  newStatus: status,
                  validatedBy: provider.currentUser.id,
                );
              }
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(isConfirm ? 'Seluruh jam pelajaran berhasil divalidasi!' : 'Seluruh jam pelajaran ditolak.'),
                backgroundColor: isConfirm ? AppColors.success : AppColors.danger,
              ));
              setState(() {
                _selectedSessionGroup = null;
                _activeSlot = null;
              });
            },
            child: const Text('Ya, Yakin'),
          ),
        ],
      ),
    );
  }
}
