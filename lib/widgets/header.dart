import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../providers/app_provider.dart';

import 'dart:ui';
import '../widgets/digital_clock.dart';
import '../widgets/app_avatar.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    final headerContent = Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: provider.isDarkMode ? Colors.black.withOpacity(0.2) : Colors.white,
        border: Border(bottom: BorderSide(color: provider.isDarkMode ? Colors.white.withOpacity(0.05) : AppColors.border)),
      ),
      child: Row(
        children: [
          // Breadcrumbs
          Row(
            children: [
              Text(
                provider.currentUser.role.name.toUpperCase(),
                style: TextStyle(
                  color: provider.isDarkMode ? Colors.white70 : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(LucideIcons.chevronRight, size: 14, color: Color(0xFFCBD5E1)),
              ),
              Text(
                provider.activeMenu.replaceAll('-', ' ').toUpperCase(),
                style: TextStyle(
                  color: provider.isDarkMode ? Colors.white : AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const Spacer(),

          // Clock
          const DigitalClock(),
          const SizedBox(width: 8),
          if (provider.chronosEnabled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.science, size: 13, color: Color(0xFFD97706)),
                  const SizedBox(width: 5),
                  Text(
                    'Chronos: ${provider.chronosDayName}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 16),

          // Dark Mode Toggle
          IconButton(
            onPressed: () => provider.toggleDarkMode(),
            icon: Icon(
              provider.isDarkMode ? LucideIcons.sun : LucideIcons.moon,
              size: 20,
              color: provider.isDarkMode ? Colors.amber : AppColors.textMuted,
            ),
            tooltip: 'Ganti Mode',
          ),

          const SizedBox(width: 16),
          const VerticalDivider(width: 1, indent: 20, endIndent: 20, color: AppColors.border),
          const SizedBox(width: 16),

          // Profile Menu
          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            onSelected: (value) {
              if (value == 'profile') {
                provider.setActiveMenu('profile');
              } else if (value == 'logout') {
                _showLogoutDialog(context, provider);
              }
            },
            child: Row(
              children: [
                AppAvatar(
                  radius: 16,
                  imageUrl: provider.currentUser.avatar,
                  name: provider.currentUser.name,
                ),
                const SizedBox(width: 8),
                const Icon(LucideIcons.chevronDown, size: 14, color: AppColors.textMuted),
              ],
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: const [
                    Icon(LucideIcons.user, size: 16, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Text('Profil Saya', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: const [
                    Icon(LucideIcons.logOut, size: 16, color: AppColors.danger),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(fontSize: 14, color: AppColors.danger)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (provider.isDarkMode) {
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
          child: headerContent,
        ),
      );
    }
    
    return headerContent;
  }

  void _showLogoutDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.logOut, color: Colors.red.shade600, size: 24),
              ),
              const SizedBox(width: 16),
              const Text(
                'Konfirmasi Keluar',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari akun Classio Anda? Sesi Anda akan berakhir.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          actionsPadding: const EdgeInsets.all(20),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                provider.logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Ya, Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
