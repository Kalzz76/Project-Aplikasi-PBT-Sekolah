import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/schedule.dart';
import '../../models/school_class.dart';
import '../../models/subject.dart';
import '../../models/teacher.dart';
import '../../models/room.dart';
import '../../providers/app_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_badge.dart';

class ModulJadwalPelajaran extends StatefulWidget {
  const ModulJadwalPelajaran({super.key});

  @override
  State<ModulJadwalPelajaran> createState() => _ModulJadwalPelajaranState();
}

class _ModulJadwalPelajaranState extends State<ModulJadwalPelajaran> {
  String _selectedDay = 'Senin';
  final List<String> _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];

  void _showAddScheduleDialog(BuildContext context, String classId, String slotLabel) {
    final provider = context.read<AppProvider>();
    bool isEventMode = false;
    String? selectedSubjectId;
    String? selectedRoomId;
    String? selectedTeacherId;
    final eventTitleController = TextEditingController(text: 'Istirahat');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(LucideIcons.plus, color: AppColors.primary), 
                          const SizedBox(width: 12), 
                          Expanded(
                            child: Text(
                              'Atur Jadwal - $slotLabel', 
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]
                      ),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        const Text('Kegiatan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Switch(
                          value: isEventMode, 
                          onChanged: (v) => setDialogState(() => isEventMode = v)
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                if (isEventMode) ...[
                  _buildLabel('Nama Kegiatan'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                    child: TextField(
                      controller: eventTitleController,
                      decoration: const InputDecoration(border: InputBorder.none, hintText: 'Misal: Istirahat, Rapat, dll'),
                    ),
                  ),
                ] else ...[
                  _buildLabel('Pilih Guru Pengajar'),
                  _buildDropdown<String>(
                    hint: 'Pilih Guru',
                    value: selectedTeacherId,
                    items: provider.teachers.map((t) => DropdownMenuItem<String>(value: t.id, child: Text(t.name))).toList(),
                    onChanged: (v) {
                      setDialogState(() {
                        selectedTeacherId = v;
                        if (selectedSubjectId != null && selectedTeacherId != null) {
                          final teacher = provider.teachers.firstWhere((t) => t.id == selectedTeacherId);
                          final sub = provider.subjects.firstWhere((s) => s.id == selectedSubjectId);
                          if (!teacher.subjects.contains(sub.name)) {
                            selectedSubjectId = null;
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Pilih Mata Pelajaran'),
                  _buildDropdown<String>(
                    hint: 'Pilih Mapel',
                    value: selectedSubjectId,
                    items: provider.subjects.where((s) {
                      if (selectedTeacherId == null) return true;
                      final teacher = provider.teachers.firstWhere((t) => t.id == selectedTeacherId);
                      return teacher.subjects.contains(s.name);
                    }).map((s) => DropdownMenuItem<String>(value: s.id, child: Text(s.name))).toList(),
                    onChanged: (v) => setDialogState(() => selectedSubjectId = v),
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Pilih Ruangan'),
                  _buildDropdown<String>(
                    hint: 'Pilih Ruangan',
                    value: selectedRoomId,
                    items: provider.rooms.map((r) => DropdownMenuItem<String>(value: r.id, child: Text(r.name))).toList(),
                    onChanged: (v) => setDialogState(() => selectedRoomId = v),
                  ),
                ],
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(child: CustomButton(variant: ButtonVariant.outline, onClick: () => Navigator.pop(context), child: const Text('Batal'))),
                    const SizedBox(width: 16),
                    Expanded(child: CustomButton(variant: ButtonVariant.primary, onClick: () {
                      if (!isEventMode && (selectedSubjectId == null || selectedRoomId == null || selectedTeacherId == null)) return;
                      provider.addScheduleEntry(ScheduleEntry(
                        id: AppProvider.generateNewUuid(),
                        day: _selectedDay,
                        slotLabel: slotLabel,
                        classId: classId,
                        isEvent: isEventMode,
                        customTitle: isEventMode ? eventTitleController.text : null,
                        subjectId: isEventMode ? null : selectedSubjectId!,
                        roomId: isEventMode ? null : selectedRoomId!,
                        teacherId: isEventMode ? null : selectedTeacherId!,
                      ));
                      Navigator.pop(context);
                    }, child: const Text('Simpan'))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final classes = provider.classes;
    final timeSlots = provider.getTimeSlots(_selectedDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 32),
        _buildDaySwitcher(),
        const SizedBox(height: 24),

        CustomCard(
          noPadding: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGridHeader(timeSlots),
                const Divider(height: 1),
                if (classes.isEmpty)
                   const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('Belum ada data kelas.')))
                else
                  ...classes.map((cls) => _buildClassScheduleRow(cls, timeSlots, provider.schedules, provider)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Jadwal Pelajaran', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        SizedBox(height: 4),
        Text('Kelola jadwal belajar mengajar sesuai waktu operasional harian.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildDaySwitcher() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _days.map((day) {
          final isActive = _selectedDay == day;
          return InkWell(
            onTap: () => setState(() => _selectedDay = day),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: isActive ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(12), boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : []),
              child: Text(day, style: TextStyle(color: isActive ? AppColors.primary : AppColors.textSecondary, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGridHeader(List<TimeSlot> slots) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Row(
        children: [
          _buildCell('KELAS / WAKTU', width: 150, isHeader: true),
          ...slots.map((s) => _buildPeriodHeader(s)),
        ],
      ),
    );
  }

  Widget _buildPeriodHeader(TimeSlot slot) {
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(left: BorderSide(color: AppColors.border))),
      child: Column(
        children: [
          Text(slot.label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: slot.isBreak ? AppColors.primary : AppColors.textPrimary)),
          Text(slot.timeRange, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildClassScheduleRow(SchoolClass cls, List<TimeSlot> slots, List<ScheduleEntry> schedules, AppProvider provider) {
    return Container(
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 150,
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            child: Text(cls.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
          ),
          ...slots.map((slot) {
            final entry = schedules.firstWhere(
              (s) => s.classId == cls.id && s.slotLabel == slot.label && s.day == _selectedDay, 
              orElse: () => ScheduleEntry(id: '', day: '', slotLabel: '', classId: '')
            );
            
            if (entry.id.isEmpty) return _buildEmptyCell(cls.id, slot.label);
            if (entry.isEvent) return _buildBreakCell(entry);

            final subject = provider.subjects.firstWhere((s) => s.name.toLowerCase() == entry.subjectId?.toLowerCase() || s.id == entry.subjectId, orElse: () => Subject(id: '', name: 'N/A', teacherIds: []));
            final room = provider.rooms.firstWhere((r) => r.name.toLowerCase() == entry.roomId?.toLowerCase() || r.id == entry.roomId, orElse: () => Room(id: '', name: 'N/A', category: ''));
            final teacher = provider.teachers.firstWhere((t) => t.name.toLowerCase() == entry.teacherId?.toLowerCase() || t.id == entry.teacherId, orElse: () => Teacher(id: '', nip: '', name: 'N/A', position: '', subjects: [], avatar: ''));

            return _buildScheduleCell(entry, subject, room, teacher);
          }),
        ],
      ),
    );
  }

  Widget _buildBreakCell(ScheduleEntry entry) {
    final label = entry.customTitle ?? 'Kegiatan';
    return Container(
      width: 180,
      height: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.03), border: const Border(left: BorderSide(color: AppColors.border))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12, letterSpacing: 1.5), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => context.read<AppProvider>().deleteScheduleEntry(entry.id),
            child: const Text('Hapus', style: TextStyle(fontSize: 10, color: AppColors.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCell(ScheduleEntry entry, Subject sub, Room room, Teacher teacher) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(border: Border(left: BorderSide(color: AppColors.border))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
            child: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo), overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 6),
          Row(children: [const Icon(LucideIcons.building, size: 12, color: AppColors.textMuted), const SizedBox(width: 4), Text(room.name, style: const TextStyle(fontSize: 11))]),
          const SizedBox(height: 4),
          Row(children: [const Icon(LucideIcons.user, size: 12, color: AppColors.textMuted), const SizedBox(width: 4), Expanded(child: Text(teacher.name, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis))]),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => context.read<AppProvider>().deleteScheduleEntry(entry.id),
            child: const Text('Hapus', style: TextStyle(fontSize: 10, color: AppColors.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCell(String classId, String slotLabel) {
    return InkWell(
      onTap: () => _showAddScheduleDialog(context, classId, slotLabel),
      child: Container(
        width: 180,
        height: 110,
        decoration: const BoxDecoration(border: Border(left: BorderSide(color: AppColors.border))),
        child: const Center(child: Icon(LucideIcons.plus, color: AppColors.border, size: 20)),
      ),
    );
  }

  Widget _buildCell(String text, {double width = 100, bool isHeader = false}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      child: Text(text, style: TextStyle(fontWeight: isHeader ? FontWeight.bold : FontWeight.normal, fontSize: 12, color: isHeader ? AppColors.textSecondary : AppColors.textPrimary)),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)));
  }

  Widget _buildDropdown<T>({required String hint, required T? value, required List<DropdownMenuItem<T>> items, required Function(T?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: DropdownButtonHideUnderline(child: DropdownButton<T>(isExpanded: true, value: value, hint: Text(hint), items: items, onChanged: onChanged)),
    );
  }
}
