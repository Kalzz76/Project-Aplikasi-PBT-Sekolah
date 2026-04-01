import 'package:flutter/material.dart';

void main() {
  runApp(const ClassioApp());
}

class ClassioApp extends StatelessWidget {
  const ClassioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'The Classio',
      theme: ThemeData(
        fontFamily: 'Segoe UI',
      ),
      // Kita panggil DashboardLayout sebagai halaman utama sementara
      home: const DashboardLayout(), 
    );
  }
}

// ==========================================
// KERANGKA UTAMA (SIDEBAR + KONTEN KANAN)
// ==========================================
class DashboardLayout extends StatefulWidget {
  const DashboardLayout({super.key});

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  // Variabel untuk nyimpen menu apa yang lagi aktif
  int _selectedIndex = 1; // Default ke 'Select Class'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 1. BAGIAN KIRI: SIDEBAR PINK
          Container(
            width: 260, // Lebar sidebar
            color: const Color(0xFFFDE8E9), // Warna pink pastel
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bagian Logo Sidebar
                Padding(
                  padding: const EdgeInsets.only(top: 40, left: 30, bottom: 40),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          children: const [
                            Positioned(top: 6, left: 8, child: Icon(Icons.access_time, size: 20, color: Color(0xFF4A4A4A))),
                            Positioned(bottom: 6, right: 6, child: Icon(Icons.menu_book, size: 16, color: Color(0xFFC94B59))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Classio',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF535353)),
                      ),
                    ],
                  ),
                ),

                // List Menu Sidebar
                _buildSidebarMenu(Icons.grid_view_rounded, 'Dashboard', 0),
                _buildSidebarMenu(Icons.class_outlined, 'Select Class', 1),
                _buildSidebarMenu(Icons.calendar_today_outlined, 'Agenda', 2),
                _buildSidebarMenu(Icons.person_add_alt_1_outlined, 'Register New Class', 3),

                const Spacer(), // Dorong profil ke paling bawah

                // Bagian Profil (Bawah Sidebar)
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                    ],
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFE2EBF4),
                        radius: 18,
                        child: Text('MA', style: TextStyle(fontSize: 12, color: Colors.blue)), // Inisial sementara
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Rifan Akhmad', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF535353))),
                          Text('Wali Kelas 11', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. BAGIAN KANAN: KONTEN UTAMA BIRU
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFA6BFE3), Color(0xFFE6EDF7)],
                ),
              ),
              // Nanti isinya diganti berdasarkan state _selectedIndex
              child: _buildRightContent(), 
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk bikin tombol menu di sidebar
  Widget _buildSidebarMenu(IconData icon, String title, int index) {
    bool isActive = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.5) : Colors.transparent,
          border: isActive ? const Border(left: BorderSide(color: Color(0xFF3B8AEB), width: 4)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isActive ? const Color(0xFF3B8AEB) : const Color(0xFF888888)),
            const SizedBox(width: 15),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? const Color(0xFF535353) : const Color(0xFF888888),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk nampilin halaman di kanan berdasarkan menu yang diklik
  Widget _buildRightContent() {
    switch (_selectedIndex) {
      case 0:
        return const Center(child: Text('Halaman Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)));
      case 1:
        return const Center(child: Text('Ini nanti isi UI "Select Your Class" (Gambar Desktop-2)', style: TextStyle(fontSize: 20)));
      case 2:
        return const Center(child: Text('Ini nanti isi UI "Agenda Management" (Gambar Desktop-3)', style: TextStyle(fontSize: 20)));
      case 3:
        return const Center(child: Text('Ini nanti isi UI "Register New Class" (Gambar Desktop-4)', style: TextStyle(fontSize: 20)));
      default:
        return const SizedBox.shrink();
    }
  }
}