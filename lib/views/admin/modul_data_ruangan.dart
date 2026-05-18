import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/room.dart';
import '../../models/sort_option.dart';
import '../../providers/app_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_badge.dart';

class ModulDataRuangan extends StatefulWidget {
  const ModulDataRuangan({super.key});

  @override
  State<ModulDataRuangan> createState() => _ModulDataRuanganState();
}

class _ModulDataRuanganState extends State<ModulDataRuangan> {
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  DataSortOption _sortOption = DataSortOption.nameAsc;

  final List<String> _categories = ['Kelas', 'Lab Komputer', 'Laboratorium', 'Perpustakaan', 'Aula'];

  void _confirmDelete(BuildContext context, Room room) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus ruangan ${room.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            onPressed: () {
              context.read<AppProvider>().deleteRoom(room.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data ruangan berhasil dihapus.')),
              );
            },
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );
  }

  void _showRoomForm(BuildContext context, {Room? room}) {
    final isEdit = room != null;
    final nameController = TextEditingController(text: room?.name ?? '');
    String selectedCategory = room?.category ?? _categories[0];

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
                    Text(isEdit ? 'Edit Ruangan' : 'Tambah Ruangan', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 32),
                _buildFieldLabel('Nama Ruangan'),
                TextField(controller: nameController, decoration: _inputStyle('Contoh: R.101')),
                const SizedBox(height: 20),
                _buildFieldLabel('Kategori'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedCategory,
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setDialogState(() => selectedCategory = v!),
                    ),
                  ),
                ),
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
                          if (provider.rooms.any((r) => r.name.toLowerCase() == nameController.text.toLowerCase() && r.id != room?.id)) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Nama ruangan sudah ada!')));
                            return;
                          }

                          final newRoom = Room(id: isEdit ? room.id : AppProvider.generateNewUuid(), name: nameController.text, category: selectedCategory);
                          if (isEdit) provider.updateRoom(newRoom); else provider.addRoom(newRoom);
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
    final sortedRooms = provider.sortData<Room>(
      provider.rooms,
      _sortOption,
      (r) => r.name,
      (r) => r.id,
    );
    final filteredRooms = sortedRooms.where((r) => r.name.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
    
    final totalPages = (filteredRooms.length / _itemsPerPage).ceil();
    if (_currentPage > totalPages && totalPages > 0) _currentPage = totalPages;
    final pagedRooms = filteredRooms.skip((_currentPage - 1) * _itemsPerPage).take(_itemsPerPage).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Data Ruangan', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                SizedBox(height: 4),
                Text('Kelola daftar sarana prasarana dan ruangan sekolah.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              ],
            ),
            CustomButton(variant: ButtonVariant.primary, icon: const Icon(LucideIcons.plus, size: 18), onClick: () => _showRoomForm(context), child: const Text('Tambah Ruangan')),
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
                          decoration: InputDecoration(hintText: 'Cari nama ruangan...', prefixIcon: const Icon(LucideIcons.search, size: 20), suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(LucideIcons.x, size: 18), onPressed: () { _searchController.clear(); setState(() => _currentPage = 1); }) : null, filled: true, fillColor: const Color(0xFFF1F5F9), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
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
                child: pagedRooms.isEmpty 
                  ? const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('Belum ada data ruangan.')))
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: pagedRooms.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final room = pagedRooms[index];
                        return _buildRoomRow(room, (index + 1) + ((_currentPage - 1) * _itemsPerPage));
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
    final provider = Provider.of<AppProvider>(context, listen: false);
    final isDark = provider.isDarkMode;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      color: isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFF8FAFC),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text('NO', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : AppColors.textSecondary))),
          Expanded(flex: 6, child: Text('NAMA RUANGAN', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : AppColors.textSecondary))),
          Expanded(flex: 4, child: Text('KATEGORI', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : AppColors.textSecondary))),
          Expanded(flex: 2, child: Text('AKSI', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : AppColors.textSecondary))),
        ],
      ),
    );
  }

  Widget _buildRoomRow(Room room, int no) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final isDark = provider.isDarkMode;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text('$no', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white30 : AppColors.textMuted))),
          Expanded(flex: 6, child: Text(room.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.getTextColor(isDark)))),
          Expanded(flex: 4, child: Align(alignment: Alignment.centerLeft, child: CustomBadge(variant: BadgeVariant.indigo, child: Text(room.category)))),
          Expanded(flex: 2, child: Row(children: [
            IconButton(onPressed: () => _showRoomForm(context, room: room), icon: const Icon(LucideIcons.pencil, size: 18, color: AppColors.primary), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            const SizedBox(width: 12),
            IconButton(onPressed: () => _confirmDelete(context, room), icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.danger), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
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
