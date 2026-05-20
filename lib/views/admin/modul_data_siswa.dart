import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/student.dart';
import '../../models/sort_option.dart';
import '../../providers/app_provider.dart';
import '../../models/import_student_row.dart';
import '../../services/student_import_service.dart';
import 'package:file_picker/file_picker.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_badge.dart';

class ModulDataSiswa extends StatefulWidget {
  const ModulDataSiswa({super.key});

  @override
  State<ModulDataSiswa> createState() => _ModulDataSiswaState();
}

class _ModulDataSiswaState extends State<ModulDataSiswa> {
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  DataSortOption _sortOption = DataSortOption.nameAsc;
  bool _isImporting = false;

  void _showStudentForm(BuildContext context, {Student? student}) {
    final isEdit = student != null;
    final nameController = TextEditingController(text: student?.name ?? '');
    final nisController = TextEditingController(text: student?.nis ?? '');
    final nisnController = TextEditingController(text: student?.nisn ?? '');
    String gender = student?.gender ?? 'L';
    String? selectedKelas = student?.kelas;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                        child: Icon(isEdit ? LucideIcons.pencil : LucideIcons.plus, color: AppColors.primary),
                      ),
                      const SizedBox(width: 20),
                      Text(isEdit ? 'Edit Data Siswa' : 'Tambah Siswa Baru', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                
                // Form Fields
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Nama Lengkap Siswa'),
                        TextField(controller: nameController, decoration: _inputStyle('Contoh: Ahmad Fauzi'), inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[0-9]'))]),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildFieldLabel('NIS'), TextField(controller: nisController, decoration: _inputStyle('Nomor Induk (maks. 10)'), keyboardType: TextInputType.number, maxLength: 10, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)])])),
                            const SizedBox(width: 16),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildFieldLabel('NISN'), TextField(controller: nisnController, decoration: _inputStyle('Nomor Nasional (maks. 10)'), keyboardType: TextInputType.number, maxLength: 10, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)])])),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Searchable Dropdown for Kelas
                        _buildFieldLabel('Kelas'),
                        Consumer<AppProvider>(
                          builder: (context, provider, child) => Autocomplete<String>(
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text == '') return provider.classes.map((c) => c.name);
                              return provider.classes.map((c) => c.name).where((name) => name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                            },
                            initialValue: TextEditingValue(text: selectedKelas ?? ''),
                            onSelected: (String selection) => setDialogState(() => selectedKelas = selection),
                            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: _inputStyle('Ketik nama kelas...'),
                              );
                            },
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        _buildFieldLabel('Jenis Kelamin'),
                        Row(
                          children: [
                            _buildGenderOption('L', 'Laki-laki', gender, (v) => setDialogState(() => gender = v)),
                            const SizedBox(width: 16),
                            _buildGenderOption('P', 'Perempuan', gender, (v) => setDialogState(() => gender = v)),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // Footer
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Row(
                    children: [
                      Expanded(child: CustomButton(variant: ButtonVariant.outline, onClick: () => Navigator.pop(context), child: const Text('Batalkan'))),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomButton(
                          variant: ButtonVariant.primary,
                          onClick: () {
                            // Validation Rules
                            if (nameController.text.isEmpty || nisController.text.isEmpty || selectedKelas == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon isi semua data wajib.')));
                              return;
                            }
                            if (RegExp(r'[0-9]').hasMatch(nameController.text)) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama lengkap tidak boleh mengandung angka.')));
                              return;
                            }
                            if (!RegExp(r'^[0-9]+$').hasMatch(nisController.text)) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('NIS hanya boleh diisi angka.')));
                              return;
                            }
                            if (nisnController.text.isNotEmpty && !RegExp(r'^[0-9]+$').hasMatch(nisnController.text)) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('NISN hanya boleh diisi angka.')));
                              return;
                            }
                            
                            final provider = context.read<AppProvider>();
                            // Check for duplicate NIS
                            if (provider.isDuplicateNis(nisController.text, excludeStudentId: student?.id)) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: NIS sudah digunakan siswa lain!')));
                              return;
                            }
                            if (nisnController.text.isNotEmpty &&
                                provider.isDuplicateNisn(nisnController.text, excludeStudentId: student?.id)) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: NISN sudah digunakan!')));
                              return;
                            }
                            if (provider.isDuplicateStudentName(nameController.text, selectedKelas!, excludeStudentId: student?.id)) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Nama siswa sudah ada di kelas ini!')));
                              return;
                            }

                            final newStudent = Student(
                              id: isEdit ? student.id : AppProvider.generateNewUuid(),
                              name: nameController.text,
                              nis: nisController.text,
                              nisn: nisnController.text,
                              gender: gender,
                              kelas: selectedKelas!,
                              position: student?.position ?? 'Anggota',
                            );
                            if (isEdit) {
                              provider.updateStudent(newStudent);
                            } else {
                              provider.addStudent(newStudent);
                            }
                            Navigator.pop(context);
                          },
                          child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Siswa'),
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

  Future<void> _handleImportExcel(BuildContext context, AppProvider provider) async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv'],
        allowMultiple: false,
        withData: true,
      );

      if (picked == null || picked.files.isEmpty) return;

      final platformFile = picked.files.first;
      final bytes = platformFile.bytes;

      if (bytes == null || bytes.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membaca data file. File mungkin kosong.')),
        );
        return;
      }

      debugPrint('Mengimpor file: ${platformFile.name}');
      debugPrint('Ukuran file: ${bytes.length} bytes');

      setState(() => _isImporting = true);

      final ext = platformFile.extension ?? 'xlsx';
      final rows = StudentImportService.parseFile(bytes, ext, platformFile.name);

      setState(() => _isImporting = false);

      if (rows.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File valid tapi tidak ditemukan data siswa yang bisa diimpor.')),
        );
        return;
      }

      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(LucideIcons.fileDown, color: AppColors.primary),
              const SizedBox(width: 12),
              const Text('Konfirmasi Import'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('File: ${platformFile.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('Ditemukan ${rows.length} baris data siswa yang siap diimpor.'),
              const SizedBox(height: 16),
              const Text('Ketentuan:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const Text('• NIS & Nama Lengkap wajib diisi.', style: TextStyle(fontSize: 12)),
              const Text('• Kelas akan otomatis dibuat jika belum ada.', style: TextStyle(fontSize: 12)),
              const Text('• Data dengan NIS yang sama akan dilewati.', style: TextStyle(fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
            ),
            CustomButton(
              onClick: () => Navigator.pop(ctx, true),
              child: const Text('Lanjutkan Import'),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) return;

      setState(() => _isImporting = true);
      final result = await provider.importStudents(rows);
      setState(() => _isImporting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: result.success > 0 ? Colors.green.shade800 : Colors.orange.shade800,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Import Selesai!', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('${result.success} siswa berhasil ditambahkan.'),
              if (result.skipped > 0) Text('${result.skipped} data dilewati (mungkin duplikat atau tidak lengkap).'),
              if (result.classesCreated > 0) Text('${result.classesCreated} kelas baru berhasil dibuat.'),
            ],
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e, stackTrace) {
      setState(() => _isImporting = false);
      debugPrint('IMPORT EXCEL ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');
      if (!context.mounted) return;
      
      String msg = 'Terjadi kesalahan saat import: $e';
      if (e.toString().contains('Unexpected null value') || e.toString().contains('nullCheck')) {
        msg = 'File Excel tidak kompatibel. Silakan buka file tersebut di Microsoft Excel/Google Sheets, klik "Save" (Simpan), lalu coba import kembali.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context, Student student, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus data siswa ${student.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () {
              provider.deleteStudent(student.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data siswa berhasil dihapus.')),
              );
            },
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final sortedStudents = provider.sortData<Student>(
      provider.students,
      _sortOption,
      (s) => s.name,
      (s) => s.id,
    );
    final filteredStudents = sortedStudents.where((s) => s.name.toLowerCase().contains(_searchController.text.toLowerCase()) || s.nis.contains(_searchController.text)).toList();
    
    final totalPages = (filteredStudents.length / _itemsPerPage).ceil();
    if (_currentPage > totalPages && totalPages > 0) _currentPage = totalPages;
    final pagedStudents = filteredStudents.skip((_currentPage - 1) * _itemsPerPage).take(_itemsPerPage).toList();

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Data Siswa', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                SizedBox(height: 4),
                Text('Kelola informasi detail seluruh siswa sekolah.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              ],
            ),
            Row(
              children: [
                if (provider.students.isNotEmpty) ...[
                  CustomButton(
                    variant: ButtonVariant.outline,
                    icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                    onClick: () => _showClearAllConfirmDialog(context, provider),
                    child: const Text('Kosongkan Siswa', style: TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(width: 12),
                ],
                CustomButton(
                  variant: ButtonVariant.outline,
                  icon: const Icon(LucideIcons.fileDown, size: 18),
                  onClick: () => _handleImportExcel(context, provider),
                  child: const Text('Import Excel'),
                ),
                const SizedBox(width: 12),
                CustomButton(
                  variant: ButtonVariant.primary,
                  icon: const Icon(LucideIcons.plus, size: 18),
                  onClick: () => _showStudentForm(context),
                  child: const Text('Tambah Siswa'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),

        CustomCard(
          noPadding: true,
          child: Column(
            children: [
              // Search Bar & Filter
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _currentPage = 1),
                        decoration: InputDecoration(
                          hintText: 'Cari NIS/NISN atau Nama...',
                          prefixIcon: const Icon(LucideIcons.search, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty 
                            ? IconButton(
                                icon: const Icon(LucideIcons.x, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _currentPage = 1);
                                },
                              )
                            : null,
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<DataSortOption>(
                          value: _sortOption,
                          icon: const Icon(LucideIcons.filter, size: 18, color: AppColors.textSecondary),
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
                    ),
                  ],
                ),
              ),
              
              // Sticky Header using a static Column + Scrollable body
              _buildTableHeader(),
              const Divider(height: 1),
              
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 600),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: pagedStudents.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final student = pagedStudents[index];
                    final rowNumber = ((_currentPage - 1) * _itemsPerPage) + index + 1;
                    return _buildStudentRow(student, provider, rowNumber);
                  },
                ),
              ),

              // Pagination Footer
              _buildPagination(totalPages),
            ],
          ),
        ),
            ],
          ),
        ),
        if (_isImporting)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CustomCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Sedang memproses data...', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Mohon tunggu sebentar', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTableHeader() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final isDark = provider.isDarkMode;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      color: isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFF8FAFC),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text('NO', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : AppColors.textSecondary))),
          Expanded(flex: 5, child: Text('NIS / NISN', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : AppColors.textSecondary))),
          Expanded(flex: 6, child: Text('NAMA LENGKAP', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : AppColors.textSecondary))),
          Expanded(flex: 1, child: Text('L/P', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : AppColors.textSecondary))),
          Expanded(flex: 2, child: Text('KELAS', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : AppColors.textSecondary))),
          Expanded(flex: 1, child: Text('AKSI', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : AppColors.textSecondary))),
        ],
      ),
    );
  }

  Widget _buildStudentRow(Student student, AppProvider provider, int rowNumber) {
    final isDark = provider.isDarkMode;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text(rowNumber.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white60 : AppColors.textSecondary))),
          Expanded(flex: 5, child: Text('${student.nis} / ${student.nisn}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.getTextColor(isDark)))),
          Expanded(flex: 6, child: Text(student.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.getTextColor(isDark)))),
          Expanded(flex: 1, child: Text(student.gender, style: TextStyle(color: AppColors.getTextColor(isDark)))),
          Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: CustomBadge(variant: BadgeVariant.indigo, child: Text(student.kelas)))),
          Expanded(flex: 1, child: Row(children: [
            IconButton(onPressed: () => _showStudentForm(context, student: student), icon: const Icon(LucideIcons.pencil, size: 18, color: AppColors.primary), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            const SizedBox(width: 8),
            IconButton(onPressed: () => _confirmDelete(context, student, provider), icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.danger), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
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

  Widget _buildGenderOption(String value, String label, String current, Function(String) onTap) {
    bool isSelected = current == value;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? AppColors.primary : AppColors.border)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(value == 'L' ? LucideIcons.user : LucideIcons.user, size: 16, color: isSelected ? AppColors.primary : AppColors.textMuted), const SizedBox(width: 8), Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? AppColors.primary : AppColors.textSecondary))]),
        ),
      ),
    );
  }

  void _showClearAllConfirmDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(LucideIcons.trash2, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('Hapus Semua Siswa?', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Apakah Anda yakin ingin menghapus seluruh data siswa di sekolah ini? Tindakan ini akan mengosongkan seluruh data siswa dan absensi di database Supabase secara permanen dan tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
                
                await provider.clearAllStudents();
                
                // Close loading indicator
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Seluruh data siswa berhasil dihapus!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Ya, Hapus Semua', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
