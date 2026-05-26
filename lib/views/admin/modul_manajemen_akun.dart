import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/user.dart';
import '../../models/sort_option.dart';
import '../../providers/app_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_badge.dart';
import '../../widgets/app_avatar.dart';

class ModulManajemenAkun extends StatefulWidget {
  const ModulManajemenAkun({super.key});

  @override
  State<ModulManajemenAkun> createState() => _ModulManajemenAkunState();
}

class _ModulManajemenAkunState extends State<ModulManajemenAkun> {
  final TextEditingController _searchController = TextEditingController();
  UserRole? _filterRole;
  int _currentPage = 0;
  final int _rowsPerPage = 8;
  DataSortOption _sortOption = DataSortOption.nameAsc;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final sortedAccounts = provider.sortData<UserProfile>(
      provider.accounts,
      _sortOption,
      (u) => u.name,
      (u) => u.id,
    );
    final filteredAccounts = sortedAccounts.where((a) {
      final matchSearch = a.name.toLowerCase().contains(_searchController.text.toLowerCase()) || 
                          a.username.toLowerCase().contains(_searchController.text.toLowerCase());
      final matchRole = _filterRole == null || a.role == _filterRole;
      return matchSearch && matchRole;
    }).toList();

    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage < filteredAccounts.length) ? startIndex + _rowsPerPage : filteredAccounts.length;
    final pagedAccounts = filteredAccounts.isEmpty ? <UserProfile>[] : filteredAccounts.sublist(startIndex, endIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(provider),
        const SizedBox(height: 32),
        _buildStats(provider),
        const SizedBox(height: 32),
        _buildFilters(),
        const SizedBox(height: 24),
        CustomCard(
          noPadding: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTable(pagedAccounts, provider),
              _buildPagination(filteredAccounts.length),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddAccountDialog(BuildContext context, AppProvider provider) {
    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    UserRole selectedRole = UserRole.guru;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tambah Akun Baru', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x, size: 20)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Silakan isi data akun yang akan dibuat secara manual.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 32),
                
                _buildModernField('Nama Lengkap', nameController, LucideIcons.user, 'Masukkan nama lengkap'),
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(child: _buildModernField('Username', usernameController, LucideIcons.user, 'username_id')),
                    const SizedBox(width: 16),
                    Expanded(child: _buildModernField('Password', passwordController, LucideIcons.lock, '********')),
                  ],
                ),
                
                const SizedBox(height: 24),
                const Text('Tentukan Hak Akses (Role)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Row(
                  children: UserRole.values.map((role) {
                    final isSelected = selectedRole == role;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setDialogState(() => selectedRole = role),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                            boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))] : [],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                role == UserRole.admin ? LucideIcons.shieldCheck : (role == UserRole.guru ? LucideIcons.userCheck : LucideIcons.users),
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                role.name.toUpperCase(),
                                style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        variant: ButtonVariant.outline,
                        child: const Text('Batal'),
                        onClick: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        child: const Text('Buat Akun'),
                        onClick: () {
                          if (nameController.text.isEmpty || usernameController.text.isEmpty || passwordController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap lengkapi semua data!')));
                            return;
                          }
                          
                          final newAccount = UserProfile(
                            id: 'USR-${DateTime.now().millisecondsSinceEpoch}',
                            name: nameController.text,
                            username: usernameController.text,
                            password: passwordController.text,
                            role: selectedRole,
                            avatar: '',
                          );
                          
                          provider.addAccount(newAccount);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Akun baru berhasil ditambahkan!'), backgroundColor: Colors.green));
                        },
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

  Widget _buildModernField(String label, TextEditingController controller, IconData icon, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(AppProvider provider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Manajemen Akun', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              SizedBox(height: 4),
              Text('Kelola akses akun secara manual atau generate otomatis untuk guru dan siswa.', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            CustomButton(
              variant: ButtonVariant.outline,
              icon: const Icon(LucideIcons.userPlus, size: 18),
              onClick: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
                final count = await provider.generateTeacherAccounts();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  if (count > 0) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$count Akun Guru baru berhasil di-generate!'), backgroundColor: Colors.green));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada akun guru baru yang perlu di-generate.'), backgroundColor: Colors.orange));
                  }
                }
              },
              child: const Text('Generate Akun Guru'),
            ),
            CustomButton(
              variant: ButtonVariant.outline,
              icon: const Icon(LucideIcons.userCheck, size: 18),
              onClick: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
                final count = await provider.generateStudentAccounts();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  if (count == -1) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Gagal: Belum ada siswa yang ditunjuk sebagai Sekretaris (Sekretaris 1 atau Sekretaris 2) di kelas mana pun!'),
                        backgroundColor: Colors.redAccent,
                        duration: Duration(seconds: 5),
                      ),
                    );
                  } else if (count > 0) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$count Akun Siswa Sekretaris baru berhasil di-generate!'), backgroundColor: Colors.green));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada akun sekretaris baru yang perlu di-generate.'), backgroundColor: Colors.orange));
                  }
                }
              },
              child: const Text('Generate Akun Siswa'),
            ),
            CustomButton(
              variant: ButtonVariant.primary,
              icon: const Icon(LucideIcons.plus, size: 18),
              onClick: () => _showAddAccountDialog(context, provider),
              child: const Text('Tambah Akun Baru'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStats(AppProvider provider) {
    final guruCount = provider.accounts.where((a) => a.role == UserRole.guru).length;
    final siswaCount = provider.accounts.where((a) => a.role == UserRole.siswa).length;
    final adminCount = provider.accounts.where((a) => a.role == UserRole.admin).length;

    return Row(
      children: [
        _buildStatCard('Total Guru', guruCount.toString(), LucideIcons.userCheck, Colors.indigo),
        const SizedBox(width: 24),
        _buildStatCard('Total Siswa', siswaCount.toString(), LucideIcons.users, Colors.teal),
        const SizedBox(width: 24),
        _buildStatCard('Total Admin', adminCount.toString(), LucideIcons.shieldCheck, Colors.orange),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: CustomCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() {
                _currentPage = 0;
              }),
              decoration: InputDecoration(
                icon: const Icon(LucideIcons.search, size: 20, color: AppColors.textMuted), 
                hintText: 'Cari nama atau username...', 
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _currentPage = 0);
                      },
                    )
                  : null,
                border: InputBorder.none
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        _buildSortFilter(),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<UserRole?>(
              value: _filterRole,
              hint: const Text('Filter Role'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Semua Role')),
                ...UserRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.name.toUpperCase()))),
              ],
              onChanged: (v) => setState(() {
                _filterRole = v;
                _currentPage = 0;
              }),
            ),
          ),
        ),
      ],
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
                _currentPage = 0;
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

  Widget _buildTable(List<UserProfile> accounts, AppProvider provider) {
    final isDark = provider.isDarkMode;
    return Container(
      width: double.infinity,
      child: DataTable(
        horizontalMargin: 24,
        columnSpacing: 40,
        headingRowHeight: 56,
        dataRowHeight: 72,
        headingRowColor: MaterialStateProperty.all(isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFF8FAFC)),
        columns: [
          DataColumn(label: Text('NO', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : AppColors.textSecondary))),
          DataColumn(label: Text('PENGGUNA', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : AppColors.textSecondary))),
          DataColumn(label: Text('USERNAME', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : AppColors.textSecondary))),
          DataColumn(label: Text('PASSWORD', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : AppColors.textSecondary))),
          DataColumn(label: Text('ROLE', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : AppColors.textSecondary))),
          DataColumn(label: Text('AKSI', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : AppColors.textSecondary))),
        ],
        rows: accounts.asMap().entries.map((entry) {
          final int index = entry.key;
          final account = entry.value;
          final isAdmin = account.role == UserRole.admin;
          // Calculate actual row number considering pagination
          final rowNumber = (_currentPage * _rowsPerPage) + index + 1;
          
          return DataRow(
            cells: [
              DataCell(Text(rowNumber.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white60 : AppColors.textSecondary))),
              DataCell(Row(
                children: [
                  AppAvatar(
                    radius: 18,
                    imageUrl: account.avatar,
                    name: account.name,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account.name, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.getTextColor(isDark))),
                      if (account.nipNis != null) Text(account.nipNis!, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.textMuted)),
                    ],
                  ),
                ],
              )),
              DataCell(Text(account.username, style: TextStyle(color: isDark ? Colors.indigoAccent : AppColors.primary, fontWeight: FontWeight.w500))),
              DataCell(Text(account.password, style: TextStyle(color: AppColors.getTextColor(isDark)))),
              DataCell(CustomBadge(
                variant: account.role == UserRole.admin ? BadgeVariant.orange : (account.role == UserRole.guru ? BadgeVariant.indigo : BadgeVariant.emerald),
                child: Text(account.role.name.toUpperCase()),
              )),
              DataCell(Row(
                children: [
                  if (!isAdmin) ...[
                    IconButton(
                      icon: const Icon(LucideIcons.refreshCw, size: 18, color: AppColors.primary),
                      tooltip: 'Reset Password',
                      onPressed: () {
                        provider.resetPassword(account.id);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password berhasil direset ke default.')));
                      },
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.danger),
                      tooltip: 'Hapus Akun',
                      onPressed: () => _showDeleteConfirmDialog(context, provider, account),
                    ),
                  ] else 
                    Text('-', style: TextStyle(color: isDark ? Colors.white30 : AppColors.textMuted)),
                ],
              )),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPagination(int totalItems) {
    final totalPages = (totalItems / _rowsPerPage).ceil();
    if (totalPages <= 1) return const SizedBox(height: 16);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Menampilkan ${(_currentPage * _rowsPerPage) + 1} - ${(_currentPage + 1) * _rowsPerPage > totalItems ? totalItems : (_currentPage + 1) * _rowsPerPage} dari $totalItems data', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Row(
            children: [
              IconButton(icon: const Icon(LucideIcons.chevronLeft, size: 20), onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null),
              const SizedBox(width: 8),
              ...List.generate(totalPages, (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => setState(() => _currentPage = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: _currentPage == i ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                    child: Text((i + 1).toString(), style: TextStyle(color: _currentPage == i ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  ),
                ),
              )),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(LucideIcons.chevronRight, size: 20), onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, AppProvider provider, UserProfile account) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(LucideIcons.trash2, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('Hapus Akun?', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus akun "${account.name}" (${account.role.name.toUpperCase()}) secara permanen dari sistem?',
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
                
                // Show loading spinner
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
                
                await provider.deleteAccount(account.id);
                
                if (context.mounted) {
                  Navigator.of(context).pop(); // dismiss loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Akun berhasil dihapus!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Ya, Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
