import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/responsive.dart';
import '../../models/user.dart';
import '../../models/schedule.dart';
import '../../models/school_class.dart';
import '../../models/subject.dart';
import '../../providers/app_provider.dart';
import '../../models/attendance.dart';
import '../../models/student.dart';
import '../../models/teacher_attendance.dart';
import '../../core/chronos_service.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_badge.dart';

class GroupedSchedule {
  final List<ScheduleEntry> entries;
  final String timeRange;
  final String label;
  final bool isEvent;

  GroupedSchedule({
    required this.entries,
    required this.timeRange,
    required this.label,
    this.isEvent = false,
  });
}

class DashboardGuru extends StatefulWidget {
  const DashboardGuru({super.key});

  @override
  State<DashboardGuru> createState() => _DashboardGuruState();
}

class _DashboardGuruState extends State<DashboardGuru> {
  bool _isWeeklyMode = false;

  List<GroupedSchedule> _groupSchedules(List<ScheduleEntry> schedules, AppProvider provider, String day) {
    if (schedules.isEmpty) return [];
    
    // Sort by slot index to ensure correct order
    final slots = provider.getTimeSlots(day);
    schedules.sort((a, b) {
      final idxA = slots.indexWhere((s) => s.label == a.slotLabel);
      final idxB = slots.indexWhere((s) => s.label == b.slotLabel);
      return idxA.compareTo(idxB);
    });

    List<GroupedSchedule> grouped = [];
    
    for (final curr in schedules) {
      if (curr.isEvent) {
        final slot = slots.firstWhere((s) => s.label == curr.slotLabel, orElse: () => TimeSlot(label: '', timeRange: '00.00 - 00.00'));
        grouped.add(GroupedSchedule(
          entries: [curr],
          timeRange: slot.timeRange,
          label: curr.slotLabel,
          isEvent: true,
        ));
      } else {
        // Find if there's an existing GroupedSchedule with same classId, subjectId, and roomId
        final existingIdx = grouped.indexWhere((g) =>
            !g.isEvent &&
            g.entries.first.classId == curr.classId &&
            g.entries.first.subjectId == curr.subjectId &&
            g.entries.first.roomId == curr.roomId);
            
        if (existingIdx != -1) {
          final existing = grouped[existingIdx];
          existing.entries.add(curr);
          
          // Recalculate time range and label for this grouped schedule
          grouped[existingIdx] = _createGroup(existing.entries, slots);
        } else {
          final slot = slots.firstWhere((s) => s.label == curr.slotLabel, orElse: () => TimeSlot(label: '', timeRange: '00.00 - 00.00'));
          grouped.add(GroupedSchedule(
            entries: [curr],
            timeRange: slot.timeRange,
            label: curr.slotLabel,
            isEvent: false,
          ));
        }
      }
    }

    return grouped;
  }

  GroupedSchedule _createGroup(List<ScheduleEntry> group, List<TimeSlot> slots) {
    // Sort group entries by slot index just to be absolutely sure
    group.sort((a, b) {
      final idxA = slots.indexWhere((s) => s.label == a.slotLabel);
      final idxB = slots.indexWhere((s) => s.label == b.slotLabel);
      return idxA.compareTo(idxB);
    });

    final firstSlot = slots.firstWhere((s) => s.label == group.first.slotLabel, orElse: () => TimeSlot(label: '', timeRange: '00:00 - 00:00'));
    final lastSlot = slots.firstWhere((s) => s.label == group.last.slotLabel, orElse: () => TimeSlot(label: '', timeRange: '00:00 - 00:00'));
    
    final startTime = firstSlot.timeRange.split(' - ')[0];
    final endTime = lastSlot.timeRange.split(' - ')[1];
    
    String label = group.first.slotLabel;
    if (group.length > 1) {
      // Extract numeric part if possible, e.g. "Jam 1" -> "1"
      final startNum = group.first.slotLabel.replaceAll(RegExp(r'[^0-9]'), '');
      final endNum = group.last.slotLabel.replaceAll(RegExp(r'[^0-9]'), '');
      if (startNum.isNotEmpty && endNum.isNotEmpty) {
        label = 'Jam $startNum - $endNum';
      } else {
        label = '${group.first.slotLabel} - ${group.last.slotLabel}';
      }
    }

    return GroupedSchedule(
      entries: group,
      timeRange: '$startTime - $endTime',
      label: label,
      isEvent: group.first.isEvent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final user = provider.currentUser;
    final today = provider.currentDayName;
    final allSchedules = provider.getTeacherSchedules(user.id);
    final todaySchedules = provider.getTeacherSchedules(user.id, day: today);
    final groupedToday = _groupSchedules(todaySchedules, provider, today);
    
    // Check for calls
    final myCalls = provider.calls.where((c) => c.teacherId == user.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGreetingBanner(user.name),
        const SizedBox(height: 32),
        
        if (myCalls.isNotEmpty) ...[
          ...myCalls.map((call) => _buildCallBanner(call, provider)).toList(),
          const SizedBox(height: 32),
        ] else ...[
          _buildEmergencyCallSection(provider.isDarkMode),
          const SizedBox(height: 32),
        ],

        _buildUpcomingReminder(provider, groupedToday),
        const SizedBox(height: 32),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _isWeeklyMode ? 'Jadwal Mengajar Mingguan' : 'Jadwal Mengajar Hari Ini ($today)',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.getTextColor(provider.isDarkMode)),
            ),
            _buildModeToggle(provider.isDarkMode),
          ],
        ),
        const SizedBox(height: 24),

        if (_isWeeklyMode)
          _buildWeeklySchedule(allSchedules, provider)
        else
          _buildDailyScheduleGrid(groupedToday, provider),
      ],
    );
  }

  Widget _buildModeToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9), 
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _toggleItem('Hari Ini', !_isWeeklyMode, isDark),
          _toggleItem('Mingguan', _isWeeklyMode, isDark),
        ],
      ),
    );
  }

  Widget _toggleItem(String label, bool active, bool isDark) {
    return InkWell(
      onTap: () => setState(() => _isWeeklyMode = label == 'Mingguan'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active 
              ? (isDark ? Colors.white.withOpacity(0.1) : Colors.white) 
              : Colors.transparent, 
          borderRadius: BorderRadius.circular(8), 
          boxShadow: active && !isDark ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
        ),
        child: Text(
          label, 
          style: TextStyle(
            fontSize: 13, 
            fontWeight: FontWeight.bold, 
            color: active ? AppColors.primary : (isDark ? Colors.white70 : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingBanner(String name) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = Responsive.isMobileConstraint(constraints);
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 20 : 32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF3730A3)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: const Color(0xFF3730A3).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.sun, color: Colors.amber, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Selamat Pagi, $name!',
                      style: TextStyle(color: Colors.white, fontSize: isMobile ? 20 : 28, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Tetap semangat mengajar demi masa depan bangsa.', style: TextStyle(color: Color(0xFFDBEAFE), fontSize: 14)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmergencyCallSection(bool isDark) {
    return CustomCard(
      color: isDark ? Colors.red.withOpacity(0.15) : const Color(0xFFFEF2F2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(LucideIcons.megaphone, color: Colors.red, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Panggilan dari Siswa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.redAccent : const Color(0xFF991B1B))),
                Text('Belum ada panggilan bantuan dari kelas saat ini.', style: TextStyle(fontSize: 13, color: isDark ? Colors.red.shade200 : const Color(0xFFB91C1C))),
              ],
            ),
          ),
          CustomButton(
            variant: ButtonVariant.ghost,
            size: ButtonSize.sm,
            onClick: () => _showCallHistoryDialog(context),
            child: Text('Lihat Riwayat', style: TextStyle(color: isDark ? Colors.redAccent : const Color(0xFF991B1B))),
          ),
        ],
      ),
    );
  }

  void _showCallHistoryDialog(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final isDark = provider.isDarkMode;
    final userId = provider.currentUser.id;
    final history = provider.callHistory.where((c) => c.teacherId == userId).toList();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? Colors.red.withOpacity(0.1) : const Color(0xFFFEF2F2),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.history, color: isDark ? Colors.redAccent : const Color(0xFF991B1B)),
                    const SizedBox(width: 12),
                    Text(
                      'Riwayat Panggilan',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.redAccent : const Color(0xFF991B1B)),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(LucideIcons.x, color: isDark ? Colors.white60 : AppColors.textSecondary),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: history.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.bellOff, size: 48, color: isDark ? Colors.white30 : AppColors.textMuted),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada riwayat panggilan.',
                              style: TextStyle(fontSize: 14, color: isDark ? Colors.white60 : AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: history.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                        itemBuilder: (_, index) {
                          final call = history[index];
                          final timeStr = '${call.timestamp.hour.toString().padLeft(2, '0')}:${call.timestamp.minute.toString().padLeft(2, '0')}';
                          final dateStr = '${call.timestamp.day}/${call.timestamp.month}/${call.timestamp.year}';
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(LucideIcons.megaphone, color: Colors.red, size: 18),
                            ),
                            title: Text(
                              call.className,
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.getTextColor(isDark)),
                            ),
                            subtitle: Text(
                              'Oleh: ${call.senderName}${call.subjectName != null ? " — ${call.subjectName}" : ""}',
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.textSecondary),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(timeStr, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : AppColors.textSecondary)),
                                Text(dateStr, style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : AppColors.textMuted)),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallBanner(CallNotification call, AppProvider provider) {
    final isDark = provider.isDarkMode;
    return CustomCard(
      color: isDark ? Colors.red.withOpacity(0.15) : const Color(0xFFFEF2F2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(LucideIcons.megaphone, color: Colors.red, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Panggilan dari ${call.className}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.redAccent : const Color(0xFF991B1B))),
                Text(
                  'Sekretaris ${call.senderName} memanggil Anda${call.subjectName != null ? " — ${call.subjectName}" : ""}.',
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.red.shade200 : const Color(0xFFB91C1C)),
                ),
              ],
            ),
          ),
          CustomButton(
            variant: ButtonVariant.ghost,
            size: ButtonSize.sm,
            onClick: () => provider.dismissCall(call.id),
            child: Text('Terima', style: TextStyle(color: isDark ? Colors.redAccent : const Color(0xFF991B1B))),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyScheduleGrid(List<GroupedSchedule> groupedSchedules, AppProvider provider) {
    if (groupedSchedules.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Tidak ada jadwal mengajar hari ini.')));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 450, mainAxisSpacing: 24, crossAxisSpacing: 24, mainAxisExtent: 280),
      itemCount: groupedSchedules.length,
      itemBuilder: (context, index) {
        final isDark = provider.isDarkMode;
        final group = groupedSchedules[index];
        final entry = group.entries.first;
        final isOngoing = provider.isScheduleGroupActive(group.entries, provider.currentDayName);

        if (group.isEvent) {
          return _buildEventCard(group, provider.isDarkMode);
        }

        final subject = provider.subjects.firstWhere((s) => s.id == entry.subjectId || s.name == entry.subjectId, orElse: () => Subject(id: '', name: 'Mapel', teacherIds: []));
        final cls = provider.classes.firstWhere((c) => c.id == entry.classId || c.name == entry.classId, orElse: () => SchoolClass(id: '', name: 'Kelas', homeroomTeacherId: '', homeroomTeacherName: '', roomName: '', totalStudents: 0));

        final today = ChronosService.instance.now();
        // Attendance biasanya disimpan per-slot (mis. "Jam 11"), sedangkan tampilan bisa digabung
        // jadi label "Jam 11 - 12". Anggap "sudah diisi" jika ada record untuk salah satu slot di grup.
        final slotLabels = group.entries.map((e) => e.slotLabel).toSet()..add(group.label);

        final sessionRecords = provider.attendance
            .where((a) =>
                a.classId == entry.classId &&
                a.subjectId == subject.name &&
                slotLabels.contains(a.slotLabel) &&
                a.date.year == today.year &&
                a.date.month == today.month &&
                a.date.day == today.day)
            .toList();

        final teacherRecords = provider.teacherAttendance
            .where((t) =>
                t.teacherId == provider.currentUser.id &&
                t.classId == entry.classId &&
                slotLabels.contains(t.slotLabel) &&
                t.date.year == today.year &&
                t.date.month == today.month &&
                t.date.day == today.day)
            .toList();

        final isAlreadyMarked = sessionRecords.isNotEmpty || teacherRecords.isNotEmpty;
        final validationStatus = sessionRecords.isNotEmpty ? sessionRecords.first.validationStatus : null;
        final isPassed = provider.isScheduleGroupPassed(group.entries, provider.currentDayName);

        // Badge & label berdasarkan status validasi atau kehadiran guru
        BadgeVariant validBadgeVariant;
        String validBadgeText;
        
        if (!isAlreadyMarked) {
          validBadgeVariant = BadgeVariant.defaultValue;
          validBadgeText = 'BELUM DIISI';
        } else if (teacherRecords.isNotEmpty && teacherRecords.first.status == TeacherAttendanceStatus.tidakHadir) {
          validBadgeVariant = BadgeVariant.danger;
          validBadgeText = 'TIDAK HADIR';
        } else if (validationStatus == ValidationStatus.validated) {
          validBadgeVariant = BadgeVariant.success;
          validBadgeText = 'TERVALIDASI';
        } else if (validationStatus == ValidationStatus.rejected) {
          validBadgeVariant = BadgeVariant.danger;
          validBadgeText = 'DITOLAK';
        } else {
          validBadgeVariant = BadgeVariant.warning;
          validBadgeText = 'MENUNGGU VALIDASI';
        }

        return CustomCard(
          noPadding: true,
          child: Stack(
            children: [
              if (isOngoing && !isAlreadyMarked)
                Positioned(
                  top: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: const BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16))),
                    child: const Text('SEDANG BERJALAN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomBadge(variant: isOngoing ? BadgeVariant.indigo : BadgeVariant.defaultValue, child: Text(group.label)),
                        Text(group.timeRange, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(cls.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.getTextColor(isDark))),
                    Text(subject.name, style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : AppColors.textSecondary, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.getBgColor(isDark),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.getBorderColor(isDark)),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.mapPin, size: 16, color: AppColors.textMuted),
                          const SizedBox(width: 8),
                          Text('Ruangan: ${provider.roomDisplayName(entry, cls)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.getTextColor(isDark))),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Badge status validasi
                    Center(
                      child: CustomBadge(
                        variant: validBadgeVariant,
                        child: Text(validBadgeText),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Tombol validasi jika ada yang menunggu
                    if (isAlreadyMarked && validationStatus == ValidationStatus.pending)
                      CustomButton(
                        width: double.infinity,
                        variant: ButtonVariant.primary,
                        icon: const Icon(LucideIcons.clipboardCheck, size: 18),
                        onClick: () => provider.setActiveMenu('validasi_absensi'),
                        child: const Text('Validasi Sekarang'),
                      )
                    else if (!isAlreadyMarked && !isPassed)
                      CustomButton(
                        width: double.infinity,
                        variant: ButtonVariant.outline,
                        icon: const Icon(LucideIcons.clock, size: 18),
                        onClick: null,
                        child: const Text('Menunggu Sekretaris'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEventCard(GroupedSchedule group, bool isDark) {
    final entry = group.entries.first;
    final isBreak = entry.customTitle?.toLowerCase().contains('istirahat') ?? false;
    return CustomCard(
      color: isBreak 
          ? (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC)) 
          : (isDark ? Colors.teal.withOpacity(0.15) : const Color(0xFFECFDF5)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isBreak ? LucideIcons.coffee : LucideIcons.star, color: isBreak ? (isDark ? Colors.white70 : AppColors.textSecondary) : Colors.teal, size: 32),
          const SizedBox(height: 12),
          Text(
            entry.customTitle ?? 'Kegiatan', 
            textAlign: TextAlign.center, 
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold, 
              color: isBreak ? AppColors.getTextColor(isDark) : (isDark ? Colors.tealAccent : Colors.teal),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${group.label} (${group.timeRange})', 
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklySchedule(List<ScheduleEntry> allSchedules, AppProvider provider) {
    final days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];
    return Column(
      children: days.map((day) {
        final daySchedules = allSchedules.where((s) => s.day == day).toList();
        if (daySchedules.isEmpty) return const SizedBox.shrink();
        
        final groupedDay = _groupSchedules(daySchedules, provider, day);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.calendar, size: 18, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(day, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 16),
                ...groupedDay.map((group) {
                  final s = group.entries.first;
                  if (group.isEvent) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(width: 100, child: Text(group.timeRange, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: provider.isDarkMode ? Colors.white70 : AppColors.textMuted))),
                          const SizedBox(width: 16),
                          Expanded(child: Text(s.customTitle ?? 'Kegiatan', style: TextStyle(fontWeight: FontWeight.bold, color: provider.isDarkMode ? Colors.tealAccent : Colors.teal, fontSize: 14))),
                        ],
                      ),
                    );
                  }
                  final cls = provider.classes.firstWhere((c) => c.id == s.classId || c.name == s.classId, orElse: () => SchoolClass(id: s.classId, name: s.classId, homeroomTeacherId: '', homeroomTeacherName: '', roomName: '-', totalStudents: 0));
                  final sub = provider.subjects.firstWhere((sb) => sb.id == s.subjectId || sb.name == s.subjectId, orElse: () => Subject(id: s.subjectId ?? '', name: s.subjectId ?? '?', teacherIds: []));
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 100, child: Text(group.timeRange, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.getTextColor(provider.isDarkMode)))),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cls.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.getTextColor(provider.isDarkMode))),
                              Text(sub.name, style: TextStyle(color: provider.isDarkMode ? Colors.white70 : AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.getBgColor(provider.isDarkMode), borderRadius: BorderRadius.circular(6)),
                          child: Text(provider.roomDisplayName(s, cls), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.getTextColor(provider.isDarkMode))),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showAttendanceDialog(BuildContext context, SchoolClass cls, Subject sub) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Absensi ${cls.name}'),
        content: Container(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Mata Pelajaran: ${sub.name}'),
              const SizedBox(height: 16),
              const Text('Fitur pengisian absensi per siswa akan muncul di sini sesuai data kelas.'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
          CustomButton(onClick: () => Navigator.pop(context), child: const Text('Simpan Absensi')),
        ],
      ),
    );
  }

  Widget _buildUpcomingReminder(AppProvider provider, List<GroupedSchedule> groupedToday) {
    final isDark = provider.isDarkMode;
    
    // Cari jadwal yang belum mulai (upcoming)
    final upcoming = groupedToday.where((g) => 
      !g.isEvent && 
      !provider.isScheduleGroupActive(g.entries, provider.currentDayName) &&
      !provider.isScheduleGroupPassed(g.entries, provider.currentDayName)
    ).toList();

    final pendingValidations = provider.getPendingValidationSessions(provider.currentUser.id);

    if (upcoming.isEmpty && pendingValidations.isEmpty) return const SizedBox.shrink();

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.bell, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Text(
                'Aktivitas Mendatang',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.getTextColor(isDark)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (upcoming.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(LucideIcons.calendar, size: 16, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jadwal Berikutnya: ${upcoming.first.entries.first.classId}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '${provider.subjectDisplayName(upcoming.first.entries.first.subjectId ?? "")} — Pukul ${upcoming.first.timeRange.split(" - ")[0]}',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  CustomBadge(variant: BadgeVariant.indigo, child: const Text('SEGERA DATANG')),
                ],
              ),
            ),
          ],
          if (pendingValidations.isNotEmpty) ...[
            const Divider(height: 24),
            Row(
              children: [
                const Icon(LucideIcons.clipboardCheck, size: 16, color: AppColors.warning),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Anda memiliki ${pendingValidations.length} sesi absensi yang menunggu validasi.',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
                TextButton(
                  onPressed: () => provider.setActiveMenu('validasi_absensi'),
                  child: const Text('Validasi Sekarang'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
