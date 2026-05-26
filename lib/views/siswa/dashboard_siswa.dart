import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/responsive.dart';
import '../../providers/app_provider.dart';
import '../../models/schedule.dart';
import '../../models/school_class.dart';
import '../../models/subject.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_badge.dart';
import '../../widgets/app_avatar.dart';
import '../../models/teacher.dart';

class DashboardSiswa extends StatefulWidget {
  const DashboardSiswa({super.key});

  @override
  State<DashboardSiswa> createState() => _DashboardSiswaState();
}

class _DashboardSiswaState extends State<DashboardSiswa> {
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
    final isSecretary = user.position?.contains('Sekretaris') ?? false;

    // Filter schedules for the student's class
    final classId = provider.classes.isEmpty
        ? ''
        : provider.classes.firstWhere(
            (c) => c.name == user.kelas,
            orElse: () => provider.classes.first,
          ).id;
    final allClassSchedules = provider.schedules.where((s) => s.classId == classId).toList();
    final today = provider.currentDayName;
    final todaySchedules = allClassSchedules.where((s) => s.day == today).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStudentBanner(user),
        const SizedBox(height: 32),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _isWeeklyMode ? 'Jadwal Kelas Mingguan' : 'Jadwal Kelas Hari Ini ($today)',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.getTextColor(provider.isDarkMode)),
            ),
            _buildModeToggle(provider.isDarkMode),
          ],
        ),
        const SizedBox(height: 24),

        if (_isWeeklyMode)
          _buildWeeklySchedule(allClassSchedules, provider)
        else
          _buildDailyScheduleList(todaySchedules, provider, isSecretary),
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

  Widget _buildStudentBanner(user) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = Responsive.isMobileConstraint(constraints);
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 20 : 32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF0F766E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: const Color(0xFF0F766E).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, ${user.name}!',
                      style: TextStyle(color: Colors.white, fontSize: isMobile ? 22 : 32, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text('${user.kelas} • ${user.position}', style: TextStyle(color: const Color(0xFFD1FAE5), fontSize: isMobile ? 14 : 18)),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 4),
                ),
                child: AppAvatar(
                  radius: isMobile ? 28 : 40,
                  imageUrl: user.avatar,
                  name: user.name,
                  fontSize: isMobile ? 22 : 32,
                  textColor: const Color(0xFF0F766E),
                  backgroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDailyScheduleList(List<ScheduleEntry> schedules, AppProvider provider, bool isSecretary) {
    if (schedules.isEmpty) return const Center(child: Text('Tidak ada jadwal hari ini.'));
    final grouped = _groupSchedules(schedules, provider, provider.currentDayName);
    final isDark = provider.isDarkMode;

    return Column(
      children: grouped.map((group) {
        if (group.isEvent) return _buildEventRow(group, isDark);
        
        final entry = group.entries.first;
        final teacher = provider.teachers.isNotEmpty 
            ? provider.teachers.firstWhere((t) => t.id == entry.teacherId, orElse: () => provider.teachers[0])
            : Teacher(id: '', nip: '', name: 'N/A', position: '', subjects: [], avatar: '');
        final subject = provider.subjects.isNotEmpty
            ? provider.subjects.firstWhere((s) => s.id == entry.subjectId || s.name == entry.subjectId, orElse: () => provider.subjects[0])
            : Subject(id: '', name: 'N/A', teacherIds: []);
        
        // Check if attendance already marked
        final cls = provider.classes.firstWhere(
          (c) => c.id == entry.classId,
          orElse: () => SchoolClass(id: entry.classId, name: entry.classId, homeroomTeacherId: '', homeroomTeacherName: '', roomName: '-', totalStudents: 0),
        );
        final isMarked = provider.getTodayAttendanceForSession(classId: entry.classId, subjectName: subject.name).isNotEmpty;
        final siswaBlocked = provider.isAttendanceFilledByTeacher(entry.classId, subject.name);
        final isOngoing = provider.isScheduleGroupActive(group.entries, provider.currentDayName);

        final isPassed = provider.isScheduleGroupPassed(group.entries, provider.currentDayName);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: CustomCard(
            child: Row(
              children: [
                Container(
                  width: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.label, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.getTextColor(isDark))),
                      Text(group.timeRange, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(subject.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.getTextColor(isDark))),
                      Text('Guru: ${teacher.name}', style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : AppColors.textSecondary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dual badges row
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Badge 1: Filler Info
                        isMarked
                            ? (siswaBlocked
                                ? const CustomBadge(
                                    variant: BadgeVariant.orange,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(LucideIcons.lock, size: 12, color: Color(0xFFB45309)),
                                        SizedBox(width: 4),
                                        Text('DIISI GURU'),
                                      ],
                                    ),
                                  )
                                : const CustomBadge(
                                    variant: BadgeVariant.indigo,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(LucideIcons.lock, size: 12, color: Color(0xFF4338CA)),
                                        SizedBox(width: 4),
                                        Text('DIISI SEKRETARIS'),
                                      ],
                                    ),
                                  ))
                            : const CustomBadge(
                                variant: BadgeVariant.defaultValue,
                                child: Text('BELUM DIISI'),
                              ),
                        const SizedBox(width: 8),
                        // Badge 2: Status (SELESAI / BELUM)
                        (isMarked || isPassed)
                            ? const CustomBadge(
                                variant: BadgeVariant.success,
                                child: Text('SELESAI'),
                              )
                            : const CustomBadge(
                                variant: BadgeVariant.warning,
                                child: Text('BELUM'),
                              ),
                      ],
                    ),
                    // Action Buttons / Extra text
                    if (isSecretary) ...[
                      if (!isMarked) ...[
                        if (isOngoing) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomButton(
                                variant: ButtonVariant.ghost,
                                size: ButtonSize.sm,
                                icon: const Icon(LucideIcons.megaphone, size: 16),
                                onClick: () {
                                  provider.callTeacher(
                                    entry.classId,
                                    cls.name,
                                    provider.currentUser.name,
                                    teacher.id,
                                    subjectName: subject.name,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Panggilan terkirim ke Guru.')),
                                  );
                                },
                                child: const Text('Panggil Guru'),
                              ),
                              const SizedBox(width: 8),
                              CustomButton(
                                size: ButtonSize.sm,
                                onClick: () {
                                  provider.setActiveScheduleForSession(entry);
                                  provider.startAttendanceSession(cls, subject, forceSecretary: true);
                                  provider.setActiveMenu('isi_absensi');
                                },
                                child: const Text('Isi Absen'),
                              ),
                            ],
                          ),
                        ] else if (!isPassed) ...[
                          const SizedBox(height: 8),
                          Text('Belum waktunya', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.textMuted)),
                        ]
                      ] else ...[
                        // Already marked
                        if (!siswaBlocked && isOngoing) ...[
                          const SizedBox(height: 8),
                          CustomButton(
                            size: ButtonSize.sm,
                            variant: ButtonVariant.outline,
                            onClick: () {
                              provider.setActiveScheduleForSession(entry);
                              provider.startAttendanceSession(cls, subject, forceSecretary: true);
                              provider.setActiveMenu('isi_absensi');
                            },
                            child: const Text('Ubah Absensi'),
                          ),
                        ]
                      ],
                    ] else ...[
                      // Regular student (not secretary)
                      if (!isMarked && !isPassed && !isOngoing) ...[
                        const SizedBox(height: 8),
                        Text('Belum waktunya', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.textMuted)),
                      ]
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEventRow(GroupedSchedule group, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CustomCard(
        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
        child: Row(
          children: [
            Text('${group.label} (${group.timeRange})', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white60 : AppColors.textMuted)),
            const Spacer(),
            Text(group.entries.first.customTitle ?? 'Kegiatan', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.getTextColor(isDark))),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySchedule(List<ScheduleEntry> allSchedules, AppProvider provider) {
    final days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];
    final isDark = provider.isDarkMode;
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
                Text(day, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 12),
                ...groupedDay.map((group) {
                  final s = group.entries.first;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(width: 90, child: Text(group.timeRange, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.getTextColor(isDark)))),
                        Expanded(child: Text(group.isEvent ? (s.customTitle ?? 'Kegiatan') : provider.subjects.firstWhere((sb) => sb.id == s.subjectId || sb.name == s.subjectId, orElse: () => Subject(id: '', name: s.subjectId ?? '?', teacherIds: [])).name, style: TextStyle(color: AppColors.getTextColor(isDark)))),
                        if (!group.isEvent) Text(s.roomId ?? 'R.?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white60 : AppColors.textMuted)),
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
}

class GroupedSchedule {
  final List<ScheduleEntry> entries;
  final String timeRange;
  final String label;
  final bool isEvent;
  GroupedSchedule({required this.entries, required this.timeRange, required this.label, this.isEvent = false});
}
