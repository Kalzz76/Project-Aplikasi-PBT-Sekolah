import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../providers/app_provider.dart';
import '../models/user.dart';
import 'custom_badge.dart';
import 'app_avatar.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final currentUser = provider.currentUser;

    return Container(
      width: 260,
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          // Logo Header
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: const BoxDecoration(
              color: AppColors.sidebarHeader,
              border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.bookOpen, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Edusync',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              children: _buildMenus(context, provider),
            ),
          ),

          // User Profile Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.sidebarHeader,
              border: Border(top: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155).withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  AppAvatar(
                    radius: 20,
                    imageUrl: currentUser.avatar,
                    name: currentUser.name,
                    backgroundColor: const Color(0xFF334155),
                    textColor: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        CustomBadge(
                          variant: BadgeVariant.indigo,
                          child: Text(currentUser.role.name.toUpperCase()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMenus(BuildContext context, AppProvider provider) {
    final role = provider.currentUser.role;
    
    if (role == UserRole.admin) {
      return [
        _buildGroupHeader('Overview'),
        _buildMenuItem(context, provider, 'dashboard', 'Dashboard', LucideIcons.layoutDashboard),
        const SizedBox(height: 24),
        _buildGroupHeader('Master Data'),
        _buildMenuItem(context, provider, 'siswa', 'Data Siswa', LucideIcons.users),
        _buildMenuItem(context, provider, 'kelas', 'Manajemen Kelas', LucideIcons.layers),
        _buildMenuItem(context, provider, 'guru', 'Data Guru', LucideIcons.userCheck),
        _buildMenuItem(context, provider, 'ruangan', 'Data Ruangan', LucideIcons.building),
        _buildMenuItem(context, provider, 'mapel', 'Mata Pelajaran', LucideIcons.bookOpen),
        const SizedBox(height: 24),
        _buildGroupHeader('Akademik'),
        _buildMenuItem(context, provider, 'jadwal', 'Jadwal Pelajaran', LucideIcons.calendar),
        _buildMenuItem(context, provider, 'absensi', 'Laporan Absensi', LucideIcons.fileText),
        const SizedBox(height: 24),
        _buildGroupHeader('Sistem'),
        _buildMenuItem(context, provider, 'accounts', 'Manajemen Akun', LucideIcons.userPlus),
      ];
    } else if (role == UserRole.guru) {
      return [
        _buildGroupHeader('Akademik'),
        _buildMenuItem(context, provider, 'dashboard', 'Jadwal Mengajar', LucideIcons.calendar),
        _buildMenuItem(context, provider, 'rekap', 'Rekap Absensi', LucideIcons.fileText),
      ];
    } else {
      return [
        _buildGroupHeader('Akademik'),
        _buildMenuItem(context, provider, 'dashboard', 'Jadwal Kelas', LucideIcons.calendar),
      ];
    }
  }

  Widget _buildGroupHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, AppProvider provider, String id, String label, IconData icon) {
    return _HoverableSidebarItem(
      id: id,
      label: label,
      icon: icon,
      isActive: provider.activeMenu == id,
      onTap: () => provider.setActiveMenu(id),
    );
  }
}

class _HoverableSidebarItem extends StatefulWidget {
  final String id;
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _HoverableSidebarItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_HoverableSidebarItem> createState() => _HoverableSidebarItemState();
}

class _HoverableSidebarItemState extends State<_HoverableSidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final showHighlight = widget.isActive || _isHovered;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: showHighlight 
                  ? AppColors.primary.withOpacity(widget.isActive ? 0.2 : 0.1) 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: showHighlight ? AppColors.sidebarTextActive : AppColors.sidebarText,
                  ),
                  child: Icon(
                    widget.icon,
                    size: 20,
                    color: showHighlight ? AppColors.sidebarTextActive : AppColors.sidebarText,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: showHighlight ? Colors.white : AppColors.sidebarText,
                      fontSize: 14,
                      fontWeight: widget.isActive ? FontWeight.bold : FontWeight.w600,
                    ),
                    child: Text(widget.label),
                  ),
                ),
                if (widget.isActive)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(color: AppColors.sidebarTextActive, shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
