import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/user.dart';
import '../widgets/sidebar.dart';
import '../widgets/header.dart';
import '../core/app_colors.dart';
import '../core/responsive.dart';
import 'profile_view.dart';
import 'admin/modul_manajemen_akun.dart';
import 'admin/dashboard_admin.dart';
import 'admin/modul_data_siswa.dart';
import 'admin/modul_manajemen_kelas.dart';
import 'admin/modul_data_guru.dart';
import 'admin/modul_data_ruangan.dart';
import 'admin/modul_mata_pelajaran.dart';
import 'admin/modul_jadwal_pelajaran.dart';
import 'admin/modul_laporan_absensi.dart';
import 'admin/modul_chronos.dart';
import 'guru/dashboard_guru.dart';
import 'guru/modul_rekap_absensi.dart';
import 'guru/halaman_absensi.dart';
import 'siswa/dashboard_siswa.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isMobile = Responsive.isMobile(context);

    final bodyDecoration = provider.isDarkMode
        ? const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F172A),
                Color(0xFF1E1B4B),
                Color(0xFF020617),
              ],
            ),
          )
        : const BoxDecoration(color: AppColors.background);

    final contentArea = Expanded(
      child: Column(
        children: [
          Header(showMenuButton: isMobile),
          Expanded(
            child: Container(
              color: provider.isDarkMode ? Colors.transparent : AppColors.background,
              child: SingleChildScrollView(
                padding: Responsive.contentPadding(context),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1600),
                    child: _buildContent(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (isMobile) {
      // Mobile: Drawer-based layout
      return Scaffold(
        backgroundColor: Colors.transparent,
        drawer: Drawer(
          width: 260,
          backgroundColor: Colors.transparent,
          child: const Sidebar(),
        ),
        body: Container(
          decoration: bodyDecoration,
          child: Row(
            children: [contentArea],
          ),
        ),
      );
    }

    // Desktop: Sidebar selalu tampil di kiri
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: bodyDecoration,
        child: Row(
          children: [
            const Sidebar(),
            contentArea,
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final role = provider.currentUser.role;
    final activeMenu = provider.activeMenu;

    if (activeMenu == 'profile') {
      return const ProfileView();
    }

    if (role == UserRole.admin) {
      switch (activeMenu) {
        case 'dashboard':
          return const DashboardAdmin();
        case 'siswa':
          return const ModulDataSiswa();
        case 'kelas':
          return const ModulManajemenKelas();
        case 'guru':
          return const ModulDataGuru();
        case 'ruangan':
          return const ModulDataRuangan();
        case 'mapel':
          return const ModulMataPelajaran();
        case 'jadwal':
          return const ModulJadwalPelajaran();
        case 'absensi':
          return const ModulLaporanAbsensi();
        case 'accounts':
          return const ModulManajemenAkun();
        case 'chronos':
          return const ModulChronos();
        default:
          return const DashboardAdmin();
      }
    } else if (role == UserRole.guru) {
      switch (activeMenu) {
        case 'dashboard':
          return const DashboardGuru();
        case 'rekap':
          return const ModulRekapAbsensi();
        case 'isi_absensi':
          return const HalamanAbsensi();
        default:
          return const DashboardGuru();
      }
    } else if (role == UserRole.siswa) {
      if (activeMenu == 'isi_absensi') {
        return const HalamanAbsensi();
      }
      return const DashboardSiswa();
    }

    return const Center(child: Text('Unauthorized'));
  }
}
