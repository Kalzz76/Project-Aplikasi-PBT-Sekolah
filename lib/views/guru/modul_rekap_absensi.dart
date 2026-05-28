import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../providers/app_provider.dart';
import '../../core/chronos_service.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_badge.dart';
import '../../models/attendance.dart';
import '../../models/student.dart';
import '../../models/teacher_attendance.dart';
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
  int _activeTab = 0; // 0: Absensi Siswa, 1: Kehadiran Saya

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final user = provider.currentUser;
    final allRekap = provider.getTeacherAttendanceRekap(user.id);
    
    final teacherSchedules = provider.schedules.where((s) => s.teacherId == user.id && !s.isEvent).toList();
    final teacherClassIds = teacherSchedules.map((s) => s.classId).toSet();
    final teacherClasses = provider.classes.where((c) => teacherClassIds.contains(c.id) || teacherClassIds.contains(c.name)).toList();
    final classes = ['Semua Kelas', ...teacherClasses.map((c) => c.name)];

    if (!classes.contains(_selectedClass)) {
      _selectedClass = 'Semua Kelas';
    }

    final subjects = [
      'Semua Mapel',
      ...allRekap.map((e) => e.subjectId).toSet(),
    ];

    final now = ChronosService.instance.now();
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
        
        // Tab Navigation
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: provider.isDarkMode ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16)
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTabItem(0, 'Absensi Siswa', LucideIcons.users),
              _buildTabItem(1, 'Kehadiran Saya', LucideIcons.calendarCheck),
            ],
          ),
        ),
        const SizedBox(height: 32),

        if (_activeTab == 0) ...[
          _buildStatsDashboard(total, hadir, absensiRate),
          const SizedBox(height: 32),
          _buildFilters(classes, subjects),
          const SizedBox(height: 24),
          _buildAttendanceList(filteredRekap, provider),
        ] else ...[
          _buildTeacherOwnStats(provider, user.id),
          const SizedBox(height: 32),
          _buildTeacherAttendanceList(provider, user.id),
        ],
      ],
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    final isActive = _activeTab == index;
    final provider = Provider.of<AppProvider>(context, listen: false);
    final isDark = provider.isDarkMode;

    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive 
              ? (isDark ? AppColors.primary.withValues(alpha: 0.2) : Colors.white) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive && !isDark 
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))] 
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon, 
              size: 16, 
              color: isActive ? AppColors.primary : AppColors.getTextColor(isDark).withValues(alpha: 0.5)
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? AppColors.primary : AppColors.getTextColor(isDark).withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherOwnStats(AppProvider provider, String teacherId) {
    final report = provider.getTeacherAttendanceReport(teacherId);
    
    final totalSesi = report.length;
    final sesiHadir = report.where((r) => r.status == TeacherAttendanceStatus.hadir).length;
    
    int totalJamHadir = 0;
    int totalJamTidakHadir = 0;
    
    for (var r in report) {
      if (r.status == TeacherAttendanceStatus.hadir) {
        totalJamHadir += r.amountOfLessons;
      } else {
        totalJamTidakHadir += r.amountOfLessons;
      }
    }
    
    final rate = totalSesi > 0 ? (sesiHadir / totalSesi * 100).toStringAsFixed(1) : '0';

    return Column(
      children: [
        Row(
          children: [
            _StatCard(label: 'Total Sesi', value: totalSesi.toString(), icon: LucideIcons.layers, color: const Color(0xFF6366F1), flex: 2),
            const SizedBox(width: 24),
            _StatCard(label: 'Jam Masuk', value: '$totalJamHadir Jam', icon: LucideIcons.clock, color: const Color(0xFF10B981), flex: 2),
            const SizedBox(width: 24),
            _StatCard(label: 'Jam Terlewat', value: '$totalJamTidakHadir Jam', icon: LucideIcons.clock9, color: const Color(0xFFF43F5E), flex: 2),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Spacer(flex: 1),
            const SizedBox(width: 12),
            _StatCard(label: 'Hadir (Sesi)', value: sesiHadir.toString(), icon: LucideIcons.circleCheck, color: const Color(0xFF8B5CF6), flex: 2),
            const SizedBox(width: 24),
            _StatCard(label: '% Kehadiran', value: '$rate%', icon: LucideIcons.award, color: const Color(0xFFF59E0B), flex: 2),
            const SizedBox(width: 12),
            const Spacer(flex: 1),
          ],
        ),
      ],
    );
  }


  Widget _buildTeacherAttendanceList(AppProvider provider, String teacherId) {
    final data = provider.getTeacherAttendanceReport(teacherId);
    final isDark = provider.isDarkMode;

    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(LucideIcons.calendarX, size: 48, color: AppColors.textMuted.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              const Text('Belum ada data kehadiran Anda tercatat.', style: TextStyle(color: AppColors.textMuted)),
            ],
          ),
        ),
      );
    }

    return CustomCard(
      noPadding: true,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
            child: Row(
              children: const [
                Expanded(flex: 2, child: Text('TANGGAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted))),
                Expanded(flex: 2, child: Text('JAM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted))),
                Expanded(flex: 2, child: Text('KELAS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted))),
                Expanded(flex: 3, child: Text('MAPEL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted))),
                Expanded(flex: 2, child: Center(child: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted)))),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = data[index];
              final subjectName = provider.subjectDisplayName(item.subjectId);
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text('${item.date.day}/${item.date.month}/${item.date.year}', style: const TextStyle(fontSize: 14))),
                    Expanded(
                      flex: 2, 
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.slotLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          Text('${item.amountOfLessons} Jam Pelajaran', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      )
                    ),
                    Expanded(flex: 2, child: Text(provider.findClassByIdOrName(item.classId)?.name ?? item.classId, style: const TextStyle(fontSize: 14))),
                    Expanded(flex: 3, child: Text(subjectName, style: const TextStyle(fontSize: 14))),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: CustomBadge(
                          variant: item.status == TeacherAttendanceStatus.hadir ? BadgeVariant.success : BadgeVariant.danger,
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

  Widget _buildHeader(BuildContext context, AppProvider provider, List<Attendance> data) {
    final title = _activeTab == 0 ? 'Rekap Absensi Siswa' : 'Kehadiran Mengajar Saya';
    final subtitle = _activeTab == 0 
        ? 'Pantau performa kehadiran siswa di seluruh kelas Anda.' 
        : 'Pantau riwayat kehadiran Anda di setiap sesi pelajaran.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.getTextColor(provider.isDarkMode))),
            if (_activeTab == 0)
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
        Text(subtitle, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
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
        _StatCard(label: 'Total Absensi', value: total.toString(), icon: LucideIcons.fileSpreadsheet, color: const Color(0xFF6366F1)),
        const SizedBox(width: 24),
        _StatCard(label: 'Siswa Hadir', value: hadir.toString(), icon: LucideIcons.users, color: const Color(0xFF10B981)),
        const SizedBox(width: 24),
        _StatCard(label: 'Rasio Kehadiran', value: '$rate%', icon: LucideIcons.trendingUp, color: const Color(0xFFF59E0B)),
      ],
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
            final d = await showDatePicker(context: context, initialDate: _selectedDate ?? ChronosService.instance.now(), firstDate: DateTime(2020), lastDate: ChronosService.instance.now());
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double minWidth = 850.0;
          final bool needsScroll = minWidth > constraints.maxWidth;

          Widget tableContent = Column(
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
                        Expanded(flex: 1, child: Text(provider.findClassByIdOrName(item.classId)?.name ?? item.classId, style: const TextStyle(fontSize: 14))),
                        Expanded(flex: 3, child: Text(item.subjectId, style: const TextStyle(fontSize: 14))),
                        Expanded(flex: 1, child: Text(item.slotLabel, style: const TextStyle(fontSize: 14))),
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
                        Expanded(
                          flex: 1,
                          child: Center(
                            child: Icon(
                              item.validationStatus == ValidationStatus.validated 
                                  ? LucideIcons.checkCircle2 
                                  : (item.validationStatus == ValidationStatus.rejected ? LucideIcons.xCircle : LucideIcons.helpCircle),
                              size: 16,
                              color: item.validationStatus == ValidationStatus.validated 
                                  ? AppColors.success 
                                  : (item.validationStatus == ValidationStatus.rejected ? AppColors.danger : AppColors.warning),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );

          if (needsScroll) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                width: minWidth,
                child: tableContent,
              ),
            );
          }

          return tableContent;
        },
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
          Expanded(flex: 3, child: Text('MAPEL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted))),
          Expanded(flex: 1, child: Text('JAM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted))),
          Expanded(flex: 2, child: Text('TANGGAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted))),
          Expanded(flex: 2, child: Text('DIISI OLEH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted))),
          Expanded(flex: 1, child: Center(child: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted)))),
          Expanded(flex: 1, child: Center(child: Text('VAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted)))),
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
} // end _ModulRekapAbsensiState

class _StatCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int flex;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.flex = 1,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<AppProvider>(context, listen: false).isDarkMode;
    final bgColor = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.border;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = isDark ? Colors.white70 : AppColors.textSecondary;

    return Expanded(
      flex: widget.flex,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isHovered ? widget.color.withValues(alpha: isDark ? 0.15 : 0.03) : bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered ? widget.color : borderColor,
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered ? widget.color.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
                blurRadius: _isHovered ? 20 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isHovered ? widget.color : widget.color.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    widget.icon,
                    color: _isHovered ? Colors.white : widget.color,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        style: TextStyle(fontSize: 13, color: mutedColor, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.value,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _isHovered ? widget.color : textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
