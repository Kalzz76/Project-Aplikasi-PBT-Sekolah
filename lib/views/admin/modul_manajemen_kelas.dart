import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/school_class.dart';
import '../../models/teacher.dart';
import '../../models/student.dart';
import '../../models/room.dart';
import '../../models/sort_option.dart';
import '../../providers/app_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_badge.dart';

enum ClassViewMode { card, table }

class ModulManajemenKelas extends StatefulWidget {
  const ModulManajemenKelas({super.key});

  @override
  State<ModulManajemenKelas> createState() => _ModulManajemenKelasState();
}

class _ModulManajemenKelasState extends State<ModulManajemenKelas> with SingleTickerProviderStateMixin {
  ClassViewMode _viewMode = ClassViewMode.card;
  String? _selectedClassId;
  int _activeTabIndex = 0;
  DataSortOption _sortOption = DataSortOption.nameAsc;
  final TextEditingController _detailSearchController = TextEditingController();
  DataSortOption _detailSortOption = DataSortOption.nameAsc;

  void _confirmDeleteClass(BuildContext context, SchoolClass cls) {
    final provider = context.read<AppProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus Kelas'),
        content: Text('Apakah Anda yakin ingin menghapus kelas ${cls.name}?\nSiswa di dalam kelas ini tidak akan terhapus, tetapi kelasnya akan menjadi kosong.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () {
              provider.deleteClass(cls.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kelas berhasil dihapus.')),
              );
            },
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveStudentFromClass(BuildContext context, Student student) {
    final provider = context.read<AppProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluarkan Siswa'),
        content: Text('Apakah Anda yakin ingin mengeluarkan ${student.name} dari kelas ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () {
              provider.updateStudent(Student(
                id: student.id,
                name: student.name,
                nis: student.nis,
                nisn: student.nisn,
                gender: student.gender,
                kelas: '-',
                position: 'Anggota',
              ));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Siswa berhasil dikeluarkan dari kelas.')),
              );
            },
            child: const Text('Ya, Keluarkan'),
          ),
        ],
      ),
    );
  }

  void _showManageClassForm(BuildContext context, SchoolClass cls, List<Student> students, List<Teacher> teachers) {
    final provider = context.read<AppProvider>();
    final structure = provider.getClassStructureFromStudents(cls);
    final roleSelections = <String, String?>{
      for (final role in kOrgStructureRoles)
        role: structure[role] == 'Belum Diatur' ? null : structure[role],
    };

    String? selectedTeacher = cls.homeroomTeacherName;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Kelola Struktur & Anggota Kelas'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Informasi Utama'),
                  _buildFieldLabel('Wali Kelas'),
                  _buildSearchableTeacherDropdown(selectedTeacher, teachers, (val) => setDialogState(() => selectedTeacher = val)),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Struktur Kelas (10 Jabatan)'),
                  const Text(
                    'Data disinkronkan ke jabatan siswa di Daftar Siswa.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  ...kOrgStructureRoles.map((role) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel(role),
                          _buildSearchableStudentDropdown(
                            roleSelections[role],
                            students,
                            (val) => setDialogState(() => roleSelections[role] = val),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                final teacherObj = teachers.firstWhere((t) => t.name == selectedTeacher, orElse: () => teachers[0]);
                final isTeacherBusy = provider.classes.any((c) => c.homeroomTeacherId == teacherObj.id && c.id != cls.id);
                if (isTeacherBusy) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${teacherObj.name} sudah menjadi Wali Kelas di kelas lain!')),
                  );
                  return;
                }

                final assignedNames = roleSelections.values
                    .where((n) => n != null && n!.isNotEmpty)
                    .map((n) => n!)
                    .toList();
                if (assignedNames.length != assignedNames.toSet().length) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Satu siswa tidak boleh memegang dua jabatan sekaligus.')),
                  );
                  return;
                }

                provider.updateClass(SchoolClass(
                  id: cls.id,
                  name: cls.name,
                  roomName: cls.roomName,
                  homeroomTeacherName: teacherObj.name,
                  homeroomTeacherId: teacherObj.id,
                  totalStudents: students.length,
                ));
                provider.applyClassStructure(cls, roleSelections);
                setState(() {});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Struktur kelas berhasil disimpan.')),
                );
              },
              child: const Text('Simpan Perubahan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)));
  }

  Widget _buildSearchableTeacherDropdown(String? value, List<Teacher> teachers, Function(String?) onChanged) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') return teachers.map((t) => t.name);
        return teachers.map((t) => t.name).where((name) => name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      initialValue: TextEditingValue(text: value ?? ''),
      onSelected: onChanged,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: _inputStyle('Cari nama guru...'),
        );
      },
    );
  }

  Widget _buildSearchableStudentDropdown(String? value, List<Student> students, Function(String?) onChanged) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') return students.map((s) => s.name);
        return students.map((s) => s.name).where((name) => name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      initialValue: TextEditingValue(text: value ?? ''),
      onSelected: onChanged,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: _inputStyle('Cari nama siswa...'),
        );
      },
    );
  }

  void _showClassForm(BuildContext context, {SchoolClass? cls}) {
    final isEdit = cls != null;
    final nameController = TextEditingController(text: cls?.name ?? '');
    final roomController = TextEditingController(text: cls?.roomName ?? '');
    String? selectedTeacher = cls?.homeroomTeacherName;
    final teachers = context.read<AppProvider>().teachers;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Kelas' : 'Buat Kelas Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFieldLabel('Nama Kelas'),
              TextField(controller: nameController, decoration: _inputStyle('Contoh: XI RPL 1')),
              const SizedBox(height: 16),
              _buildFieldLabel('Ruangan (Autocomplete)'),
              Autocomplete<Room>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  final rooms = context.read<AppProvider>().rooms;
                  if (textEditingValue.text == '') return rooms;
                  return rooms.where((r) => r.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                },
                displayStringForOption: (r) => r.name,
                initialValue: TextEditingValue(text: roomController.text),
                onSelected: (Room selection) => roomController.text = selection.name,
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: _inputStyle('Cari nama ruangan...'),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildFieldLabel('Wali Kelas'),
              _buildSearchableTeacherDropdown(selectedTeacher, teachers, (val) => setDialogState(() => selectedTeacher = val)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty || selectedTeacher == null) return;
                
                final provider = context.read<AppProvider>();
                // VALIDATION: No duplicate class name
                if (provider.classes.any((c) => c.name == nameController.text && c.id != cls?.id)) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Nama kelas sudah ada!')));
                  return;
                }

                final teacherObj = teachers.firstWhere((t) => t.name == selectedTeacher, orElse: () => teachers[0]);
                final newClass = SchoolClass(
                  id: isEdit ? cls.id : AppProvider.generateNewUuid(),
                  name: nameController.text,
                  roomName: roomController.text,
                  homeroomTeacherName: teacherObj.name,
                  homeroomTeacherId: teacherObj.id,
                  totalStudents: cls?.totalStudents ?? 0,
                );
                if (isEdit) {
                  provider.updateClass(newClass);
                } else {
                  provider.addClass(newClass);
                }
                Navigator.pop(context);
              },
              child: Text(isEdit ? 'Simpan' : 'Buat'),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final sortedClasses = provider.sortData<SchoolClass>(
      provider.classes,
      _sortOption,
      (c) => c.name,
      (c) => c.id,
    );
    final classes = sortedClasses;

    if (_selectedClassId != null) {
      final cls = classes.firstWhere((c) => c.id == _selectedClassId);
      final classStudents = provider.students.where((s) => s.kelas == cls.name).toList();
      return _buildDetailKelas(context, cls, classStudents, provider.teachers);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Manajemen Kelas', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                SizedBox(height: 4),
                Text('Pilih kelas untuk mengelola struktur dan anggota.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              ],
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: Row(
                    children: [
                      _buildViewToggle(LucideIcons.layoutGrid, ClassViewMode.card),
                      _buildViewToggle(LucideIcons.list, ClassViewMode.table),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _buildSortFilter(),
                const SizedBox(width: 16),
                CustomButton(variant: ButtonVariant.primary, icon: const Icon(LucideIcons.plus, size: 18), onClick: () => _showClassForm(context), child: const Text('Buat Kelas Baru')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        _viewMode == ClassViewMode.card ? _buildCardGrid(context, classes) : _buildTableView(context, classes, provider.students),
      ],
    );
  }

  Widget _buildViewToggle(IconData icon, ClassViewMode mode) {
    bool isSelected = _viewMode == mode;
    return InkWell(
      onTap: () => setState(() => _viewMode = mode),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 20, color: isSelected ? AppColors.primary : AppColors.textMuted),
      ),
    );
  }

  Widget _buildSortFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DataSortOption>(
          value: _sortOption,
          icon: const Icon(LucideIcons.filter, size: 16, color: AppColors.textSecondary),
          onChanged: (DataSortOption? newValue) {
            if (newValue != null) {
              setState(() {
                _sortOption = newValue;
              });
            }
          },
          items: DataSortOption.values.map((option) {
            return DropdownMenuItem<DataSortOption>(
              value: option,
              child: Text(option.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCardGrid(BuildContext context, List<SchoolClass> classes) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 400, mainAxisSpacing: 24, crossAxisSpacing: 24, mainAxisExtent: 260),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final cls = classes[index];
        return InkWell(
          onTap: () => setState(() => _selectedClassId = cls.id),
          child: CustomCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: const Icon(LucideIcons.layers, color: AppColors.primary, size: 24)),
                    Row(children: [const Icon(LucideIcons.mapPin, size: 14, color: AppColors.textMuted), const SizedBox(width: 4), Text(cls.roomName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))]),
                  ],
                ),
                const SizedBox(height: 20),
                Text(cls.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(children: [const Icon(LucideIcons.users, size: 14, color: AppColors.textMuted), const SizedBox(width: 8), Text('${cls.totalStudents} Siswa terdaftar', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary))]),
                const Spacer(),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildAvatar(cls.homeroomTeacherName, radius: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('WALI KELAS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1)),
                          Text(cls.homeroomTeacherName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(onPressed: () => _showClassForm(context, cls: cls), icon: const Icon(LucideIcons.pencil, size: 16, color: AppColors.primary)),
                    IconButton(onPressed: () => _confirmDeleteClass(context, cls), icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.danger)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableView(BuildContext context, List<SchoolClass> classes, List<Student> students) {
    return CustomCard(
      noPadding: true,
      child: Column(
        children: [
          // STICKY HEADER
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            color: const Color(0xFFF8FAFC),
            child: Row(
              children: const [
                Expanded(flex: 3, child: Text('NIS / NISN', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                Expanded(flex: 5, child: Text('Nama Lengkap', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                Expanded(flex: 3, child: Text('JABATAN KELAS', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                Expanded(flex: 1, child: Text('AKSI', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
              ],
            ),
          ),
          const Divider(height: 1),
          // Scrollable Body
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 600),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: classes.length,
              itemBuilder: (context, classIndex) {
                final cls = classes[classIndex];
                final allClassStudents = students.where((s) => s.kelas == cls.name).toList();
                final pagedStudents = allClassStudents.take(10).toList();
                final hasMore = allClassStudents.length > 10;
                
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.04), border: const Border(bottom: BorderSide(color: AppColors.border))),
                      child: Row(
                        children: [
                          Text(cls.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          const Spacer(),
                          _buildClassInfoBadge('Wali: ${cls.homeroomTeacherName}'),
                          const SizedBox(width: 8),
                          _buildClassInfoBadge('Total: ${allClassStudents.length} Siswa'),
                        ],
                      ),
                    ),
                    ...pagedStudents.map((student) => Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5))),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${student.nis} / ${student.nisn}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))])),
                          Expanded(flex: 5, child: Text(student.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                          Expanded(flex: 3, child: Align(alignment: Alignment.centerLeft, child: CustomBadge(variant: student.position == 'Ketua Murid' ? BadgeVariant.indigo : BadgeVariant.success, child: Text(student.position)))),
                          Expanded(flex: 1, child: Row(children: [IconButton(onPressed: () {}, icon: const Icon(LucideIcons.pencil, size: 14, color: AppColors.primary), padding: EdgeInsets.zero, constraints: const BoxConstraints())])),
                        ],
                      ),
                    )).toList(),
                    if (hasMore)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: TextButton(
                          onPressed: () => setState(() => _selectedClassId = cls.id),
                          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Text('Tampilkan Siswa Lainnya', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)), SizedBox(width: 8), Icon(LucideIcons.chevronRight, size: 16, color: AppColors.primary)]),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailKelas(BuildContext context, SchoolClass cls, List<Student> students, List<Teacher> teachers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () => setState(() => _selectedClassId = null),
                child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)), child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 24)),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cls.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(LucideIcons.mapPin, size: 14, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text(cls.roomName, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 16),
                        const Icon(LucideIcons.users, size: 14, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text('${students.length} Siswa', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CustomButton(
                    variant: ButtonVariant.outline,
                    onClick: () => _showManageClassForm(context, cls, students, teachers),
                    child: Row(
                      children: const [
                        Icon(LucideIcons.settings, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Kelola Kelas', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)),
                    child: Row(
                      children: [
                        _buildAvatar(cls.homeroomTeacherName, radius: 14, isLight: true),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('WALI KELAS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 1)),
                            Text(cls.homeroomTeacherName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            _buildTabButton(0, 'Struktur Kelas', LucideIcons.layers),
            const SizedBox(width: 24),
            _buildTabButton(1, 'Daftar Siswa', LucideIcons.users),
          ],
        ),
        const SizedBox(height: 24),
        _activeTabIndex == 0 ? _buildStrukturTab(cls, students) : _buildDaftarSiswaTab(students),
      ],
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    bool isActive = _activeTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _activeTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isActive ? AppColors.primary : Colors.transparent, width: 3))),
        child: Row(children: [Icon(icon, size: 18, color: isActive ? AppColors.primary : AppColors.textMuted), const SizedBox(width: 8), Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? AppColors.primary : AppColors.textMuted))]),
      ),
    );
  }

  Widget _buildStrukturTab(SchoolClass cls, List<Student> students) {
    final provider = Provider.of<AppProvider>(context);
    final structure = provider.getClassStructureFromStudents(cls);

    const roleMeta = <(IconData, Color)>[
      (LucideIcons.user, Colors.indigo),
      (LucideIcons.userCheck, Colors.blue),
      (LucideIcons.userPlus, Colors.green),
      (LucideIcons.userPlus, Color(0xFF059669)),
      (LucideIcons.fileText, Colors.orange),
      (LucideIcons.fileText, Color(0xFFEA580C)),
      (LucideIcons.star, Color(0xFF7C3AED)),
      (LucideIcons.shield, Colors.red),
      (LucideIcons.building, Colors.teal),
      (LucideIcons.layers, Color(0xFF0D9488)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 280,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.55,
          ),
          itemCount: kOrgStructureRoles.length,
          itemBuilder: (context, index) {
            final role = kOrgStructureRoles[index];
            final meta = roleMeta[index];
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showAssignRoleDialog(context, cls, role, students),
              child: _buildStrukturCard(role, structure[role] ?? 'Belum Diatur', meta.$1, meta.$2),
            );
          },
        ),
      ],
    );
  }

  void _showAssignRoleDialog(BuildContext context, SchoolClass cls, String role, List<Student> students) {
    final provider = context.read<AppProvider>();
    final currentHolder = students.firstWhere((s) => s.position == role, orElse: () => Student(id: '', name: 'Belum Diatur', nis: '', nisn: '', gender: '', kelas: '', position: ''));
    
    String? selectedStudentId = currentHolder.id.isEmpty ? null : currentHolder.id;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.userCheck, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Atur Jabatan: $role',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Pilih Siswa untuk Jabatan ini:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedStudentId,
                      hint: const Text('Belum Diatur / Kosongkan'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Belum Diatur / Kosongkan', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        ),
                        ...students.map((s) => DropdownMenuItem<String>(
                          value: s.id,
                          child: Text(s.name),
                        )),
                      ],
                      onChanged: (v) => setDialogState(() => selectedStudentId = v),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        variant: ButtonVariant.outline,
                        onClick: () => Navigator.pop(context),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        variant: ButtonVariant.primary,
                        onClick: () async {
                          await provider.assignClassRole(selectedStudentId, role, cls.name);
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Jabatan $role berhasil diperbarui!')),
                          );
                        },
                        child: const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStrukturCard(String role, String name, IconData icon, Color color) {
    bool isSet = name != 'Belum Diatur';
    return CustomCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
          const SizedBox(height: 8),
          Text(role, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isSet ? AppColors.textPrimary : AppColors.textMuted.withOpacity(0.4))),
        ],
      ),
    );
  }

  Widget _buildDaftarSiswaTab(List<Student> students) {
    final provider = context.read<AppProvider>();
    
    final sortedStudents = provider.sortData<Student>(
      students,
      _detailSortOption,
      (s) => s.name,
      (s) => s.id,
    );

    final filteredStudents = sortedStudents.where((s) {
      return s.name.toLowerCase().contains(_detailSearchController.text.toLowerCase()) ||
             s.nis.contains(_detailSearchController.text);
    }).toList();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                child: TextField(
                  controller: _detailSearchController,
                  onChanged: (v) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Cari nama siswa di kelas ini...', 
                    prefixIcon: const Icon(LucideIcons.search, size: 18), 
                    suffixIcon: _detailSearchController.text.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 16),
                          onPressed: () {
                            _detailSearchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                    border: InputBorder.none
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            _buildDetailSortFilter(),
          ],
        ),
        const SizedBox(height: 24),
        CustomCard(
          noPadding: true,
          child: Column(
            children: [
              // Sticky Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                color: const Color(0xFFF8FAFC),
                child: Row(children: const [Expanded(flex: 3, child: Text('NIS / NISN', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))), Expanded(flex: 5, child: Text('Nama Siswa', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))), Expanded(flex: 1, child: Text('L/P', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))), Expanded(flex: 3, child: Text('Jabatan', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))), Expanded(flex: 1, child: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary)))]),
              ),
              const Divider(height: 1),
              ...filteredStudents.map((student) => Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5))),
                child: Row(children: [Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${student.nis} / ${student.nisn}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))])), Expanded(flex: 5, child: Text(student.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))), Expanded(flex: 1, child: Text(student.gender)), Expanded(flex: 3, child: Align(alignment: Alignment.centerLeft, child: CustomBadge(variant: BadgeVariant.indigo, child: Text(student.position)))), Expanded(flex: 1, child: IconButton(onPressed: () => _confirmRemoveStudentFromClass(context, student), icon: const Icon(LucideIcons.trash2, size: 14, color: AppColors.danger), padding: EdgeInsets.zero, constraints: const BoxConstraints()))]),
              )).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSortFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DataSortOption>(
          value: _detailSortOption,
          icon: const Icon(LucideIcons.filter, size: 16, color: AppColors.textSecondary),
          onChanged: (DataSortOption? newValue) {
            if (newValue != null) {
              setState(() {
                _detailSortOption = newValue;
              });
            }
          },
          items: DataSortOption.values.map((option) {
            return DropdownMenuItem<DataSortOption>(
              value: option,
              child: Text(option.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, {double radius = 20, bool isLight = false}) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(radius: radius, backgroundColor: isLight ? Colors.white.withOpacity(0.2) : AppColors.primary.withOpacity(0.1), child: Text(initials, style: TextStyle(fontSize: radius * 0.8, fontWeight: FontWeight.bold, color: isLight ? Colors.white : AppColors.primary)));
  }

  Widget _buildClassInfoBadge(String label) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.primary.withOpacity(0.2))), child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)));
  }
}
