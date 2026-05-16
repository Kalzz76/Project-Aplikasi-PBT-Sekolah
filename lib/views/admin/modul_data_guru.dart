import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/teacher.dart';
import '../../models/subject.dart';
import '../../models/sort_option.dart';
import '../../providers/app_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_badge.dart';

class ModulDataGuru extends StatefulWidget {
  const ModulDataGuru({super.key});

  @override
  State<ModulDataGuru> createState() => _ModulDataGuruState();
}

class _ModulDataGuruState extends State<ModulDataGuru> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedSubjectFilter;
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  DataSortOption _sortOption = DataSortOption.nameAsc;

  void _showTeacherForm(BuildContext context, {Teacher? teacher}) {
    final isEdit = teacher != null;
    final nameController = TextEditingController(text: teacher?.name ?? '');
    final nipController = TextEditingController(text: teacher?.nip ?? '');
    List<String> selectedSubjects = List.from(teacher?.subjects ?? []);
    final availableSubjects = context.read<AppProvider>().subjects;

    final subController = TextEditingController();

    int selectionCounter = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Icon(isEdit ? LucideIcons.pencil : LucideIcons.plus, color: AppColors.primary)),
                    const SizedBox(width: 20),
                    Text(isEdit ? 'Edit Data Guru' : 'Tambah Guru Baru', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 32),
                _buildFieldLabel('Nama Lengkap Guru'),
                TextField(controller: nameController, decoration: _inputStyle('Contoh: Drs. H. Bambang')),
                const SizedBox(height: 20),
                _buildFieldLabel('NIP'),
                TextField(controller: nipController, decoration: _inputStyle('Nomor Induk Pegawai')),
                const SizedBox(height: 20),
                _buildFieldLabel('Mata Pelajaran (Autocomplete)'),
                Autocomplete<Subject>(
                  key: ValueKey('autocomplete_$selectionCounter'),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') return availableSubjects.where((s) => !selectedSubjects.contains(s.name));
                    return availableSubjects.where((s) => !selectedSubjects.contains(s.name) && s.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  displayStringForOption: (s) => s.name,
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: _inputStyle('Ketik nama pelajaran...'),
                    );
                  },
                  onSelected: (Subject selection) {
                    setDialogState(() {
                      selectedSubjects.add(selection.name);
                      selectionCounter++; // Force rebuild to clear text
                    });
                  },
                ),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: selectedSubjects.map((s) => Chip(label: Text(s, style: const TextStyle(fontSize: 12)), onDeleted: () => setDialogState(() => selectedSubjects.remove(s)), backgroundColor: AppColors.primary.withOpacity(0.05))).toList()),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(child: CustomButton(variant: ButtonVariant.outline, onClick: () => Navigator.pop(context), child: const Text('Batal'))),
                    const SizedBox(width: 16),
                    Expanded(child: CustomButton(variant: ButtonVariant.primary, onClick: () {
                      if (nameController.text.isEmpty || nipController.text.isEmpty) return;
                      final provider = context.read<AppProvider>();
                      if (provider.teachers.any((t) => t.nip == nipController.text && t.id != teacher?.id)) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: NIP sudah ada!')));
                        return;
                      }
                      final newTeacher = Teacher(id: isEdit ? teacher.id : DateTime.now().toString(), nip: nipController.text, name: nameController.text, position: 'Guru Mapel', subjects: selectedSubjects, avatar: '');
                      if (isEdit) provider.updateTeacher(newTeacher); else provider.addTeacher(newTeacher);
                      Navigator.pop(context);
                    }, child: const Text('Simpan Data'))),
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
    final sortedTeachers = provider.sortData<Teacher>(
      provider.teachers,
      _sortOption,
      (t) => t.name,
      (t) => t.id,
    );
    final filteredTeachers = sortedTeachers.where((t) {
      final matchesSearch = t.name.toLowerCase().contains(_searchController.text.toLowerCase()) || t.nip.contains(_searchController.text);
      final matchesSubject = _selectedSubjectFilter == null || t.subjects.contains(_selectedSubjectFilter);
      return matchesSearch && matchesSubject;
    }).toList();
    
    final totalPages = (filteredTeachers.length / _itemsPerPage).ceil();
    if (_currentPage > totalPages && totalPages > 0) _currentPage = totalPages;
    final pagedTeachers = filteredTeachers.skip((_currentPage - 1) * _itemsPerPage).take(_itemsPerPage).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('Data Guru & Staf', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)), SizedBox(height: 4), Text('Kelola database tenaga pendidik dan mata pelajaran pengampu.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary))]),
            CustomButton(variant: ButtonVariant.primary, icon: const Icon(LucideIcons.plus, size: 18), onClick: () => _showTeacherForm(context), child: const Text('Tambah Guru')),
          ],
        ),
        const SizedBox(height: 32),

        CustomCard(
          noPadding: true,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(child: TextField(controller: _searchController, onChanged: (v) => setState(() => _currentPage = 1), decoration: InputDecoration(hintText: 'Cari nama atau NIP...', prefixIcon: const Icon(LucideIcons.search, size: 20), suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(LucideIcons.x, size: 18), onPressed: () { _searchController.clear(); setState(() => _currentPage = 1); }) : null, filled: true, fillColor: const Color(0xFFF1F5F9), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)))),
                    const SizedBox(width: 16),
                    _buildSortFilter(),
                    const SizedBox(width: 12),
                    _buildSubjectFilter(provider.subjects),
                  ],
                ),
              ),
              _buildTableHeader(),
              const Divider(height: 1),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 600),
                child: pagedTeachers.isEmpty 
                  ? const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('Tidak ada data guru ditemukan.')))
                  : ListView.separated(shrinkWrap: true, itemCount: pagedTeachers.length, separatorBuilder: (context, index) => const Divider(height: 1), itemBuilder: (context, index) => _buildTeacherRow(pagedTeachers[index])),
              ),
              _buildPagination(totalPages),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSortFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DataSortOption>(
          value: _sortOption,
          icon: const Icon(LucideIcons.filter, size: 16, color: AppColors.textSecondary),
          onChanged: (DataSortOption? newValue) {
            if (newValue != null) {
              setState(() {
                _sortOption = newValue;
                _currentPage = 1;
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

  Widget _buildSubjectFilter(List<Subject> subjects) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSubjectFilter,
          hint: const Text('Filter Mapel', style: TextStyle(fontSize: 14)),
          icon: const Icon(LucideIcons.chevronDown, size: 16),
          items: [
            const DropdownMenuItem(value: null, child: Text('Semua Pelajaran')),
            ...subjects.map((s) => DropdownMenuItem(value: s.name, child: Text(s.name))),
          ],
          onChanged: (v) => setState(() => _selectedSubjectFilter = v),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      color: const Color(0xFFF8FAFC),
      child: Row(
        children: const [
          Expanded(flex: 4, child: Text('NIP', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
          Expanded(flex: 7, child: Text('NAMA GURU', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
          Expanded(flex: 6, child: Text('MATA PELAJARAN', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
          Expanded(flex: 2, child: Text('AKSI', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
        ],
      ),
    );
  }

  Widget _buildTeacherRow(Teacher teacher) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(teacher.nip, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary))),
          Expanded(flex: 7, child: Text(teacher.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
          Expanded(flex: 6, child: Wrap(spacing: 4, runSpacing: 4, children: teacher.subjects.map((s) => CustomBadge(variant: BadgeVariant.indigo, child: Text(s, style: const TextStyle(fontSize: 10)))).toList())),
          Expanded(flex: 2, child: Row(children: [
            IconButton(onPressed: () => _showTeacherForm(context, teacher: teacher), icon: const Icon(LucideIcons.pencil, size: 18, color: AppColors.primary), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            const SizedBox(width: 12),
            IconButton(onPressed: () => context.read<AppProvider>().deleteTeacher(teacher.id), icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.danger), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          ])),
        ],
      ),
    );
  }

  Widget _buildPagination(int totalPages) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Halaman $_currentPage dari $totalPages', style: const TextStyle(color: AppColors.textMuted)),
          Row(children: [IconButton(onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null, icon: const Icon(LucideIcons.chevronLeft)), const SizedBox(width: 8), IconButton(onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null, icon: const Icon(LucideIcons.chevronRight))]),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)));
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(hintText: hint, filled: true, fillColor: const Color(0xFFF8FAFC), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)));
  }
}
