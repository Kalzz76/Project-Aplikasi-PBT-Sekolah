import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../models/attendance.dart';
import '../../providers/app_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_badge.dart';
import '../../models/schedule.dart';
import '../../models/student.dart';
import '../../models/school_class.dart';
import '../../models/subject.dart';
import '../../widgets/export_attendance_dialog.dart';
import '../../services/attendance_export_service.dart';
import '../../core/chronos_service.dart';
import '../../models/teacher.dart';
import '../../models/teacher_attendance.dart';
import '../../widgets/app_avatar.dart';

class ModulLaporanAbsensi extends StatefulWidget {
  const ModulLaporanAbsensi({super.key});

  @override
  State<ModulLaporanAbsensi> createState() => _ModulLaporanAbsensiState();
}

class _ModulLaporanAbsensiState extends State<ModulLaporanAbsensi> {
  int _activeTab = 0; // 0: Monitor Harian, 1: Rekap Bulanan
  DateTime _startDate = ChronosService.instance.now();
  DateTime _endDate = ChronosService.instance.now();
  String _dailyRange = 'Hari Ini';
  String? _detailClassId; // If null, show summary. If not null, show detail for this class.
  int _teacherCurrentPage = 1;
  final int _itemsPerPage = 10;
  
  @override
  void initState() {
    super.initState();
    // Default range: Today
    _startDate = ChronosService.instance.now();
    _endDate = _startDate;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 32),
        
        // Tab Navigation & Filters (Only show if not in detail view)
        if (_detailClassId == null) ...[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTabItem(0, 'Monitor Harian'),
                _buildTabItem(1, 'Rekap Bulanan'),
                _buildTabItem(2, 'Kehadiran Guru'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildFilters(provider),
          const SizedBox(height: 24),
        ],

        // Content
        _activeTab == 0
            ? _buildDailyMonitor(provider)
            : (_activeTab == 1 ? _buildMonthlyRecap(provider) : _buildTeacherReport(provider)),
      ],
    );
  }

  Widget _buildTabItem(int index, String label) {
    final isActive = _activeTab == index;
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(color: isActive ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(12), boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : []),
        child: Text(label, style: TextStyle(color: isActive ? AppColors.primary : AppColors.textSecondary, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Laporan Absensi', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            SizedBox(height: 4),
            Text('Pantau kehadiran siswa secara harian dan rekapitulasi bulanan.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          ],
        ),
        CustomButton(
          variant: ButtonVariant.outline,
          icon: const Icon(LucideIcons.download, size: 18),
          onClick: () {
            final provider = context.read<AppProvider>();
            final data = _getExportableAttendance(provider);
            
            // Format headers based on tab
            String title = _activeTab == 0 ? 'Rekp Absensi Harian' : 'Rekap Absensi Bulanan';
            String dateLabel = _activeTab == 0 
                ? 'Tanggal: ${DateFormat('dd MMM yyyy').format(_startDate)}'
                : 'Tanggal: ${DateFormat('dd/MM').format(_startDate)} - ${DateFormat('dd/MM').format(_endDate)}';
            
            showExportAttendanceDialog(
              context,
              rows: provider.buildAttendanceExportRows(data),
              title: title,
              subtitle: dateLabel,
            );
          },
          child: const Text('Export Excel / PDF'),
        ),
      ],
    );
  }

  List<Attendance> _getExportableAttendance(AppProvider provider, {String? classId}) {
    return provider.attendance.where((a) {
      final attDate = DateTime(a.date.year, a.date.month, a.date.day);
      final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
      final end = DateTime(_endDate.year, _endDate.month, _endDate.day);
      
      final matchesDate = (attDate.isAtSameMomentAs(start) || attDate.isAfter(start)) && 
                          (attDate.isAtSameMomentAs(end) || attDate.isBefore(end));
      final matchesClass = classId == null || a.classId == classId;
      return matchesDate && matchesClass;
    }).toList();
  }

  Future<void> _exportSingleClass(AppProvider provider, String classId, String className, bool isPdf) async {
    final data = _getExportableAttendance(provider, classId: classId);
    final rows = provider.buildAttendanceExportRows(data);
    
    if (rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk kelas ini di rentang tanggal tersebut.')),
      );
      return;
    }

    String title = _activeTab == 0 ? 'Rekp Absensi Harian - $className' : 'Rekap Absensi Bulanan - $className';
    
    try {
      if (isPdf) {
        await AttendanceExportService.downloadPdf(rows, title: title);
      } else {
        await AttendanceExportService.downloadExcel(rows);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export ${isPdf ? 'PDF' : 'Excel'} $className berhasil.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal export: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildFilters(AppProvider provider) {
    if (_activeTab == 0) {
      // Monitor Harian Filters
      return _buildFilterItem(
        label: 'Rentang',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _dailyRange,
              items: const [
                DropdownMenuItem(value: 'Hari Ini', child: Text('Hari Ini')),
                DropdownMenuItem(value: 'Kemarin', child: Text('Kemarin')),
              ],
              onChanged: (v) {
                setState(() {
                  _dailyRange = v!;
                  if (_dailyRange == 'Hari Ini') {
                    _startDate = ChronosService.instance.now();
                  } else {
                    _startDate = ChronosService.instance.now().subtract(const Duration(days: 1));
                  }
                  _endDate = _startDate;
                });
              },
            ),
          ),
        ),
      );
    }

    // Rekap Bulanan Filters
    return Row(
      children: [
        _buildFilterItem(
          label: 'Tanggal Awal',
          child: InkWell(
            onTap: () async {
              final date = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
              if (date != null) setState(() => _startDate = date);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(LucideIcons.calendar, size: 16, color: AppColors.primary), const SizedBox(width: 10), Text(DateFormat('dd MMM yyyy').format(_startDate))]),
            ),
          ),
        ),
        const SizedBox(width: 16),
        _buildFilterItem(
          label: 'Tanggal Akhir',
          child: InkWell(
            onTap: () async {
              final date = await showDatePicker(context: context, initialDate: _endDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
              if (date != null) setState(() => _endDate = date);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(LucideIcons.calendar, size: 16, color: AppColors.primary), const SizedBox(width: 10), Text(DateFormat('dd MMM yyyy').format(_endDate))]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyMonitor(AppProvider provider) {
    if (_detailClassId != null) {
      return _buildClassDetail(provider, _detailClassId!);
    }

    final classes = provider.classes;

    return CustomCard(
      noPadding: true,
      child: Column(
        children: [
          _buildSummaryTableHeader(),
          const Divider(height: 1),
          if (classes.isEmpty)
            const Padding(padding: EdgeInsets.all(60), child: Center(child: Text('Tidak ada data kelas.')))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: classes.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final cls = classes[index];
                final classStudents = provider.students.where((s) => s.kelas == cls.name).toList();
                
                // Monitor Harian: Hanya di Tanggal Awal (Satu hari)
                final classAtt = provider.attendance.where((a) => 
                  a.classId == cls.id && 
                  provider.isSameCalendarDay(a.date, _startDate)
                ).toList();

                int h = 0, s = 0, i = 0, a = 0;
                for (final student in classStudents) {
                  final studentAtt = classAtt.where((record) => record.studentId == student.id).toList();
                  if (studentAtt.isEmpty) continue;
                  if (studentAtt.any((r) => r.status == AttendanceStatus.sakit)) s++;
                  else if (studentAtt.any((r) => r.status == AttendanceStatus.izin)) i++;
                  else if (studentAtt.any((r) => r.status == AttendanceStatus.alpa)) a++;
                  else h++;
                }

                return _buildSummaryRow(
                  index + 1, 
                  cls.name, 
                  h, s, i, a, 
                  DateFormat('dd MMM yyyy').format(_startDate), 
                  onShow: () {
                    setState(() => _detailClassId = cls.id);
                  },
                  onPdf: () => _exportSingleClass(provider, cls.id, cls.name, true),
                  onExcel: () => _exportSingleClass(provider, cls.id, cls.name, false),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMonthlyRecap(AppProvider provider) {
    if (_detailClassId != null) {
      return _buildClassDetail(provider, _detailClassId!);
    }

    final classes = provider.classes;

    return CustomCard(
      noPadding: true,
      child: Column(
        children: [
          _buildSummaryTableHeader(),
          const Divider(height: 1),
          if (classes.isEmpty)
            const Padding(padding: EdgeInsets.all(60), child: Center(child: Text('Tidak ada data kelas.')))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: classes.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final cls = classes[index];
                final classStudents = provider.students.where((s) => s.kelas == cls.name).toList();
                
                // Rekap Bulanan: Seluruh rentang Tanggal Awal - Tanggal Akhir
                final classAtt = provider.attendance.where((a) {
                  if (a.classId != cls.id) return false;
                  final attDate = DateTime(a.date.year, a.date.month, a.date.day);
                  final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
                  final end = DateTime(_endDate.year, _endDate.month, _endDate.day);
                  return (attDate.isAtSameMomentAs(start) || attDate.isAfter(start)) && 
                         (attDate.isAtSameMomentAs(end) || attDate.isBefore(end));
                }).toList();

                int h = 0, s = 0, i = 0, a = 0;
                if (classAtt.isNotEmpty) {
                  for (final student in classStudents) {
                    final studentAtt = classAtt.where((record) => record.studentId == student.id).toList();
                    if (studentAtt.isEmpty) {
                      a++;
                      continue;
                    }
                    if (studentAtt.any((r) => r.status == AttendanceStatus.sakit))
                      s++;
                    else if (studentAtt.any((r) => r.status == AttendanceStatus.izin))
                      i++;
                    else if (studentAtt.any((r) => r.status == AttendanceStatus.alpa))
                      a++;
                    else
                      h++;
                  }
                }

                final dateRangeText = DateFormat('dd/MM').format(_startDate) + ' - ' + DateFormat('dd/MM').format(_endDate);

                return _buildSummaryRow(
                  index + 1, 
                  cls.name, 
                  h, s, i, a, 
                  dateRangeText, 
                  onShow: () {
                    setState(() => _detailClassId = cls.id);
                  },
                  onPdf: () => _exportSingleClass(provider, cls.id, cls.name, true),
                  onExcel: () => _exportSingleClass(provider, cls.id, cls.name, false),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      color: const Color(0xFFF8FAFC),
      child: Row(
        children: const [
          Expanded(flex: 1, child: Text('NO', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
          Expanded(flex: 3, child: Text('KELAS', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
          Expanded(flex: 6, child: Text('KEHADIRAN', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
          Expanded(flex: 4, child: Text('TANGGAL', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
          Expanded(flex: 4, child: Text('AKSI', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(int no, String className, int h, int s, int i, int a, String dateText, {
    required VoidCallback onShow,
    required VoidCallback onPdf,
    required VoidCallback onExcel,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text('$no', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMuted))),
          Expanded(flex: 3, child: Text(className, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
            flex: 6,
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _statusChip('H: $h', AppColors.success),
                _statusChip('S: $s', AppColors.warning),
                _statusChip('I: $i', AppColors.primary),
                _statusChip('A: $a', AppColors.danger),
              ],
            ),
          ),
          Expanded(flex: 4, child: Text(dateText, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.eye, color: AppColors.primary, size: 18),
                  onPressed: onShow,
                  tooltip: 'Lihat Detail',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.fileText, color: Colors.redAccent, size: 18),
                  onPressed: onPdf,
                  tooltip: 'Export PDF',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.fileSpreadsheet, color: Colors.green, size: 18),
                  onPressed: onExcel,
                  tooltip: 'Export Excel',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildClassDetail(AppProvider provider, String classId) {
    final cls = provider.findClassByIdOrName(classId);
    
    // Logic for Daily Monitor (Active Tab 0) - Show Subjects
    if (_activeTab == 0) {
      final dayNames = {
        'Monday': 'Senin', 'Tuesday': 'Selasa', 'Wednesday': 'Rabu',
        'Thursday': 'Kamis', 'Friday': 'Jumat', 'Saturday': 'Sabtu', 'Sunday': 'Minggu'
      };
      final dayName = dayNames[DateFormat('EEEE').format(_startDate)] ?? 'Senin';
      
      final rawSchedules = provider.schedules.where((s) => s.classId == classId && s.day == dayName && s.subjectId != null).toList();
      
      final daySlots = provider.getTimeSlots(dayName);
      final slotOrder = daySlots.map((s) => s.label).toList();
      
      rawSchedules.sort((a, b) {
        final indexA = slotOrder.indexOf(a.slotLabel);
        final indexB = slotOrder.indexOf(b.slotLabel);
        return indexA.compareTo(indexB);
      });
      final seenSubjects = <String>{};
      final schedules = rawSchedules.where((s) => seenSubjects.add(s.subjectId!)).toList();

      final students = provider.students.where((s) => s.kelas == (cls?.name ?? classId)).toList();
      final dayAttendance = provider.attendance.where((a) => a.classId == classId && provider.isSameCalendarDay(a.date, _startDate)).toList();

      // Calculate total width based on number of subjects
      final tableWidth = 250.0 + (schedules.length * 100.0) + 250.0; // No(50) + Name(200) + Mapels + Akhir(250)

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailTopBar(cls, classId),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: CustomCard(
              noPadding: true,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate if we need horizontal scroll
                  final double minRequiredWidth = 50 + 200 + (schedules.length * 100.0) + 250;
                  final bool needsScroll = minRequiredWidth > constraints.maxWidth;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: needsScroll ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
                    child: Container(
                      width: needsScroll ? minRequiredWidth : constraints.maxWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDailyDetailHeader(schedules, provider, needsScroll ? minRequiredWidth : constraints.maxWidth),
                          const Divider(height: 1),
                          if (students.isEmpty)
                            const Padding(padding: EdgeInsets.all(60), child: Center(child: Text('Tidak ada siswa di kelas ini.')))
                          else
                            ...students.asMap().entries.map((entry) {
                              return _buildDailyDetailRow(entry.key + 1, entry.value, schedules, dayAttendance, needsScroll ? minRequiredWidth : constraints.maxWidth, provider);
                            }),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
    }

    // Logic for Monthly Recap (Active Tab 1) - Show Totals
    final students = provider.students.where((s) => s.kelas == (cls?.name ?? classId)).toList();
    final rangeAttendance = provider.attendance.where((a) {
      if (a.classId != classId) return false;
      final attDate = DateTime(a.date.year, a.date.month, a.date.day);
      final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
      final end = DateTime(_endDate.year, _endDate.month, _endDate.day);
      return (attDate.isAtSameMomentAs(start) || attDate.isAfter(start)) && 
             (attDate.isAtSameMomentAs(end) || attDate.isBefore(end));
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailTopBar(cls, classId),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: CustomCard(
            noPadding: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMonthlyDetailHeader(),
                const Divider(height: 1),
                if (students.isEmpty)
                  const Padding(padding: EdgeInsets.all(60), child: Center(child: Text('Tidak ada siswa di kelas ini.')))
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: students.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) => _buildMonthlyDetailRow(index + 1, students[index], rangeAttendance),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailTopBar(SchoolClass? cls, String classId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => setState(() => _detailClassId = null),
          ),
          Text(
            _activeTab == 0 ? 'Detail Monitoring: ${cls?.name ?? classId}' : 'Detail Rekap Bulanan: ${cls?.name ?? classId}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyDetailHeader(List<ScheduleEntry> schedules, AppProvider provider, double containerWidth) {
    // containerWidth already includes the 24*2 padding if it's from constraints.maxWidth, 
    // but the Row is inside a Container with its own padding. 
    // To be safe, we use Expanded for the name when not scrolling.
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 24),
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          Row(
            children: [
              _headerCell('No', 50, isMain: true),
              Expanded(child: _headerCell('Nama Lengkap', 0, isMain: true)),
              if (schedules.isNotEmpty)
                ...schedules.map((s) => _headerCell('', 100)) // Placeholder for top level "Kehadiran" if we want it merged
              else
                _headerCell('Kehadiran', 100, isMain: true),
              _headerCell('Akhir', 250, isMain: true),
            ],
          ),
          Row(
            children: [
              _headerCell('', 50),
              Expanded(child: _headerCell('', 0)),
              ...schedules.map((s) => _headerCell(provider.subjectDisplayName(s.subjectId!), 100)),
              if (schedules.isEmpty) _headerCell('', 100),
              _headerCell('', 250),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyDetailHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      color: const Color(0xFFF8FAFC),
      child: Row(
        children: [
          Expanded(flex: 1, child: _headerText('No')),
          Expanded(flex: 4, child: _headerText('Nama Lengkap')),
          Expanded(flex: 6, child: _headerText('Total Kehadiran')),
        ],
      ),
    );
  }

  Widget _buildDailyDetailRow(int no, Student student, List<ScheduleEntry> schedules, List<Attendance> attendance, double containerWidth, AppProvider provider) {
    final studentAtt = attendance.where((a) => a.studentId == student.id).toList();
    
    int h = 0, s = 0, i = 0, a = 0;
    // Only count status if record exists
    if (studentAtt.isNotEmpty) {
      if (studentAtt.any((r) => r.status == AttendanceStatus.sakit)) s = 1;
      else if (studentAtt.any((r) => r.status == AttendanceStatus.izin)) i = 1;
      else if (studentAtt.any((r) => r.status == AttendanceStatus.alpa)) a = 1;
      else h = 1;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          _cellText('$no', 50),
          Expanded(child: _cellText(student.name, 0, isBold: true)),
          if (schedules.isEmpty)
            _cellText('-', 100, color: AppColors.textMuted)
          else
            ...schedules.map((sch) {
              final subject = provider.subjects.firstWhere((sub) => sub.id == sch.subjectId || sub.name == sch.subjectId, orElse: () => Subject(id: sch.subjectId ?? '', name: sch.subjectId ?? '', teacherIds: []));
              final att = studentAtt.firstWhere(
                (a) => a.subjectId == subject.id || a.subjectId == subject.name, 
                orElse: () => Attendance(
                  id: '', 
                  studentId: '', 
                  classId: '', 
                  subjectId: '', 
                  date: ChronosService.instance.now(), 
                  status: AttendanceStatus.alpa,
                  markedBy: '',
                  markedByRole: '',
                ),
              );
              final statusStr = att.id.isEmpty ? '-' : att.status.name.substring(0, 1).toUpperCase();
              final color = att.id.isEmpty ? AppColors.textMuted : _getStatusColor(att.status);
              return Container(
                width: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(statusStr, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                    if (att.id.isNotEmpty && att.validationStatus == ValidationStatus.validated)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(LucideIcons.checkCircle2, size: 10, color: AppColors.success),
                      ),
                  ],
                ),
              );
            }),
          Container(
            width: 250,
            child: Wrap(
              spacing: 4,
              children: [
                _statusChip('H: $h', AppColors.success),
                _statusChip('S: $s', AppColors.warning),
                _statusChip('I: $i', AppColors.primary),
                _statusChip('A: $a', AppColors.danger),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyDetailRow(int no, Student student, List<Attendance> attendance) {
    final studentAtt = attendance.where((a) => a.studentId == student.id).toList();
    // Sort by date descending
    studentAtt.sort((a, b) => b.date.compareTo(a.date));
    
    final h = studentAtt.where((a) => a.status == AttendanceStatus.hadir).length;
    final s = studentAtt.where((a) => a.status == AttendanceStatus.sakit).length;
    final i = studentAtt.where((a) => a.status == AttendanceStatus.izin).length;
    final a = studentAtt.where((a) => a.status == AttendanceStatus.alpa).length;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text('$no', style: const TextStyle(color: AppColors.textMuted))),
          Expanded(flex: 4, child: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
            flex: 5,
            child: Text('Hadir: $h  Sakit: $s  Alpa: $a  Izin: $i', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 1,
            child: IconButton(
              icon: const Icon(LucideIcons.history, size: 20, color: AppColors.primary),
              tooltip: 'Lihat Riwayat Riil',
              onPressed: () => _showStudentHistoryDialog(context, student, studentAtt),
            ),
          ),
        ],
      ),
    );
  }

  void _showStudentHistoryDialog(BuildContext context, Student student, List<Attendance> records) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.user, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Riwayat Kehadiran (${records.length} Sesi)', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.x, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: Container(
          width: 500,
          height: 400,
          child: Column(
            children: [
              const Divider(),
              Expanded(
                child: records.isEmpty 
                  ? const Center(child: Text('Tidak ada riwayat absensi.'))
                  : ListView.separated(
                      itemCount: records.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final record = records[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('dd MMM yyyy').format(record.date),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    record.slotLabel,
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  provider.subjectDisplayName(record.subjectId),
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              CustomBadge(
                                variant: _getBadgeVariant(record.status),
                                child: Text(record.statusLabel),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text, double width, {bool isMain = false}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.centerLeft,
      child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMain ? 13 : 11, color: isMain ? AppColors.textPrimary : AppColors.textSecondary)),
    );
  }

  Widget _cellText(String text, double width, {bool isBold = false, Color color = AppColors.textPrimary}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(text, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 13, color: color)),
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.hadir: return AppColors.success;
      case AttendanceStatus.sakit: return AppColors.warning;
      case AttendanceStatus.izin: return AppColors.primary;
      case AttendanceStatus.alpa: return AppColors.danger;
      case AttendanceStatus.pulang: return AppColors.textSecondary;
      default: return AppColors.textMuted;
    }
  }

  Widget _headerText(String text) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary));
  }


  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildFilterItem({required String label, required Widget child}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)), const SizedBox(height: 6), child]);
  }

  Widget _buildTeacherReport(AppProvider provider) {
    final summary = provider.getAllTeachersAttendanceSummary(month: _startDate);
    final teachers = provider.teachers;
    
    // Pagination logic
    final totalTeachers = teachers.length;
    final totalPages = (totalTeachers / _itemsPerPage).ceil();
    final startIndex = (_teacherCurrentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage > totalTeachers) ? totalTeachers : startIndex + _itemsPerPage;
    final displayedTeachers = (totalTeachers > 0) ? teachers.sublist(startIndex, endIndex) : [];

    return Column(
      children: [
        CustomCard(
          noPadding: true,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                color: const Color(0xFFF8FAFC),
                child: const Row(
                  children: [
                    Expanded(flex: 1, child: Text('NO', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                    Expanded(flex: 4, child: Text('GURU', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                    Expanded(flex: 3, child: Text('TOTAL JAM', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                    Expanded(flex: 6, child: Center(child: Text('PERBANDINGAN KEHADIRAN (HADIR / TIDAK)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)))),
                    Expanded(flex: 1, child: SizedBox()), // Placeholder for action tooltip
                  ],
                ),
              ),
              const Divider(height: 1),
              if (teachers.isEmpty)
                const Padding(padding: EdgeInsets.all(60), child: Center(child: Text('Tidak ada data guru.')))
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedTeachers.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final teacher = displayedTeachers[index];
                    final stats = summary[teacher.id] ?? {'total': 0, 'hadir': 0, 'tidakHadir': 0};
                    final teacherRecords = provider.teacherAttendance.where((ta) => ta.teacherId == teacher.id || ta.teacherId == teacher.name).toList();
                    return _buildTeacherSummaryRow(startIndex + index + 1, teacher, stats, teacherRecords);
                  },
                ),
              // Pagination inside card
              if (totalPages > 1) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        'Halaman $_teacherCurrentPage dari $totalPages',
                        style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(LucideIcons.chevronLeft, size: 20),
                        onPressed: _teacherCurrentPage > 1 ? () => setState(() => _teacherCurrentPage--) : null,
                        color: _teacherCurrentPage > 1 ? AppColors.textSecondary : AppColors.textMuted.withOpacity(0.3),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        icon: const Icon(LucideIcons.chevronRight, size: 20),
                        onPressed: _teacherCurrentPage < totalPages ? () => setState(() => _teacherCurrentPage++) : null,
                        color: _teacherCurrentPage < totalPages ? AppColors.textSecondary : AppColors.textMuted.withOpacity(0.3),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherSummaryRow(int no, Teacher teacher, Map<String, int> stats, List<TeacherAttendance> records) {
    final hadir = stats['hadir'] ?? 0;
    final tidakHadir = stats['tidakHadir'] ?? 0;
    final total = stats['total'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text('$no', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMuted))),
          Expanded(flex: 4, child: Text(teacher.name, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text('$total Jam')),
          
          // Proportional Bar
          Expanded(
            flex: 6,
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFF1F5F9),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    Expanded(
                      flex: hadir > 0 ? hadir : 1,
                      child: Container(
                        color: AppColors.success.withOpacity(0.15),
                        alignment: Alignment.center,
                        child: Text('$hadir Jam', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ),
                    Container(width: 1, color: Colors.white),
                    Expanded(
                      flex: tidakHadir > 0 ? tidakHadir : 1,
                      child: Container(
                        color: AppColors.danger.withOpacity(0.15),
                        alignment: Alignment.center,
                        child: Text('$tidakHadir Jam', style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          Expanded(
            flex: 1,
            child: IconButton(
              icon: const Icon(LucideIcons.history, size: 20, color: AppColors.primary),
              tooltip: 'Lihat Riwayat',
              onPressed: () => _showTeacherHistoryDialog(context, teacher, records),
            ),
          ),
        ],
      ),
    );
  }

  void _showTeacherHistoryDialog(BuildContext context, Teacher teacher, List<TeacherAttendance> records) {
    // Sort by date descending
    records.sort((a, b) => b.date.compareTo(a.date));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
             AppAvatar(radius: 18, imageUrl: teacher.avatar, name: teacher.name),
             const SizedBox(width: 12),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(teacher.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                   const Text('Riwayat Kehadiran Guru', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                 ],
               ),
             ),
             IconButton(icon: const Icon(LucideIcons.x, size: 20), onPressed: () => Navigator.pop(context)),
          ],
        ),
        content: Container(
          width: 500,
          height: 400,
          child: records.isEmpty 
            ? const Center(child: Text('Belum ada riwayat kehadiran.'))
            : ListView.builder(
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final r = records[index];
                  final isAbsent = r.status == TeacherAttendanceStatus.tidakHadir;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isAbsent ? AppColors.danger.withOpacity(0.05) : AppColors.success.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: (isAbsent ? AppColors.danger : AppColors.success).withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Text(
                               '${r.date.day}/${r.date.month}/${r.date.year}', 
                               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                             ),
                             Text(r.slotLabel, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isAbsent ? AppColors.danger : AppColors.success,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                r.statusLabel.toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (isAbsent && r.reasonLabel.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Alasan: ${r.reasonLabel}',
                                  style: const TextStyle(fontSize: 10, color: AppColors.danger, fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
        ),
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
