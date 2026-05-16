import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/subject.dart';
import '../../models/teacher.dart';
import '../../models/sort_option.dart';
import '../../providers/app_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_badge.dart';

class ModulMataPelajaran extends StatefulWidget {
  const ModulMataPelajaran({super.key});

  @override
  State<ModulMataPelajaran> createState() => _ModulMataPelajaranState();
}

class _ModulMataPelajaranState extends State<ModulMataPelajaran> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedSubjectId;
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  DataSortOption _sortOption = DataSortOption.nameAsc;

  void _showSubjectForm(BuildContext context, {Subject? subject}) {
    final isEdit = subject != null;
    final nameController = TextEditingController(text: subject?.name ?? '');

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
                    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Icon(isEdit ? LucideIcons.pencil : LucideIcons.plus, color: AppColors.primary)),
                    const SizedBox(width: 20),
                    Text(isEdit ? 'Edit Mapel' : 'Tambah Mapel', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 32),
                _buildFieldLabel('Nama Mata Pelajaran'),
                TextField(controller: nameController, decoration: _inputStyle('Contoh: Matematika')),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(child: CustomButton(variant: ButtonVariant.outline, onClick: () => Navigator.pop(context), child: const Text('Batal'))),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        variant: ButtonVariant.primary,
                        onClick: () {
                          if (nameController.text.isEmpty) return;
                          final provider = context.read<AppProvider>();
                          
                          // Validation: Anti-Duplicate
                          if (provider.subjects.any((s) => s.name.toLowerCase() == nameController.text.toLowerCase() && s.id != subject?.id)) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Mata pelajaran sudah ada!')));
                            return;
                          }

                          final newSub = Subject(
                            id: isEdit ? subject.id : DateTime.now().toString(),
                            name: nameController.text,
                            teacherIds: [], // Relational logic shifted to Teacher side
                          );
                          if (isEdit) provider.updateSubject(newSub); else provider.addSubject(newSub);
                          Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final sortedSubjects = provider.sortData<Subject>(
      provider.subjects,
      _sortOption,
      (s) => s.name,
      (s) => s.id,
    );
    final filteredSubjects = sortedSubjects.where((s) => s.name.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
    
    final totalPages = (filteredSubjects.length / _itemsPerPage).ceil();
    if (_currentPage > totalPages && totalPages > 0) _currentPage = totalPages;
    final pagedSubjects = filteredSubjects.skip((_currentPage - 1) * _itemsPerPage).take(_itemsPerPage).toList();

    if (_selectedSubjectId != null) {
      final sub = provider.subjects.firstWhere((s) => s.id == _selectedSubjectId);
      // Logic: Filter teachers who have this subject's name in their subjects list
      final subTeachers = provider.teachers.where((t) => t.subjects.contains(sub.name)).toList();
      return _buildDetailMapel(sub, subTeachers);
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
                Text('Mata Pelajaran', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                SizedBox(height: 4),
                Text('Daftar kurikulum. Hubungkan guru melalui Modul Data Guru.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              ],
            ),
            CustomButton(variant: ButtonVariant.primary, icon: const Icon(LucideIcons.plus, size: 18), onClick: () => _showSubjectForm(context), child: const Text('Tambah Mapel')),
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
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _currentPage = 1),
                          decoration: InputDecoration(hintText: 'Cari mata pelajaran...', prefixIcon: const Icon(LucideIcons.search, size: 20), suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(LucideIcons.x, size: 18), onPressed: () { _searchController.clear(); setState(() => _currentPage = 1); }) : null, filled: true, fillColor: const Color(0xFFF1F5F9), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _buildSortFilter(),
                    ],
                  ),
                ),
              _buildTableHeader(),
              const Divider(height: 1),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 600),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: pagedSubjects.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final sub = pagedSubjects[index];
                    final teacherCount = provider.teachers.where((t) => t.subjects.contains(sub.name)).length;
                    return _buildSubjectRow(sub, (index + 1) + ((_currentPage - 1) * _itemsPerPage), teacherCount);
                  },
                ),
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

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      color: const Color(0xFFF8FAFC),
      child: Row(
        children: const [
          Expanded(flex: 1, child: Text('NO', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
          Expanded(flex: 8, child: Text('NAMA MATA PELAJARAN', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
          Expanded(flex: 3, child: Text('JUMLAH GURU', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
          Expanded(flex: 2, child: Text('AKSI', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
        ],
      ),
    );
  }

  Widget _buildSubjectRow(Subject sub, int no, int teacherCount) {
    return InkWell(
      onTap: () => setState(() => _selectedSubjectId = sub.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Row(
          children: [
            Expanded(flex: 1, child: Text('$no', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMuted))),
            Expanded(flex: 8, child: Text(sub.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
            Expanded(flex: 3, child: Align(alignment: Alignment.centerLeft, child: CustomBadge(variant: BadgeVariant.indigo, child: Text('$teacherCount Guru')))),
            Expanded(flex: 2, child: Row(children: [
              IconButton(onPressed: () => _showSubjectForm(context, subject: sub), icon: const Icon(LucideIcons.pencil, size: 18, color: AppColors.primary), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              const SizedBox(width: 12),
              IconButton(onPressed: () => setState(() => _selectedSubjectId = sub.id), icon: const Icon(LucideIcons.eye, size: 18, color: AppColors.textSecondary), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              const SizedBox(width: 12),
              IconButton(onPressed: () => context.read<AppProvider>().deleteSubject(sub.id), icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.danger), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ])),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailMapel(Subject sub, List<Teacher> teachers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () => setState(() => _selectedSubjectId = null),
                child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 24)),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomBadge(variant: BadgeVariant.indigo, child: const Text('MATA PELAJARAN', style: TextStyle(letterSpacing: 1, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 12),
                    Text(sub.name, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
              _buildStatsBox('${teachers.length}', 'GURU PENGAMPU', LucideIcons.users),
            ],
          ),
        ),
        const SizedBox(height: 40),
        const Text('Daftar Guru Pengampu', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 24),
        if (teachers.isEmpty)
          CustomCard(child: const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Belum ada guru yang ditugaskan untuk mata pelajaran ini.'))))
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 350, mainAxisSpacing: 20, crossAxisSpacing: 20, mainAxisExtent: 100),
            itemCount: teachers.length,
            itemBuilder: (context, index) {
              final t = teachers[index];
              return CustomCard(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildAvatar(t.name),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Text('NIP. ${t.nip}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildStatsBox(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: Column(children: [Icon(icon, color: Colors.white70, size: 20), const SizedBox(height: 8), Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)), Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 1))]),
    );
  }

  Widget _buildAvatar(String name) {
    return CircleAvatar(backgroundColor: AppColors.primary.withOpacity(0.1), child: Text(name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)));
  }

  Widget _buildPagination(int totalPages) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Halaman $_currentPage dari $totalPages', style: const TextStyle(color: AppColors.textMuted)),
          Row(
            children: [
              IconButton(onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null, icon: const Icon(LucideIcons.chevronLeft)),
              const SizedBox(width: 8),
              IconButton(onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null, icon: const Icon(LucideIcons.chevronRight)),
            ],
          ),
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
