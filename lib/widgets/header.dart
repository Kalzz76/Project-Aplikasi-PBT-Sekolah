import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../providers/app_provider.dart';

import '../widgets/digital_clock.dart';
import '../widgets/app_avatar.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: provider.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        border: Border(bottom: BorderSide(color: provider.isDarkMode ? const Color(0xFF334155) : AppColors.border)),
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
                provider.logout();
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
  }
}
