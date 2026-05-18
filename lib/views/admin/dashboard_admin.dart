import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../providers/app_provider.dart';
import '../../core/chronos_service.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_badge.dart';
import '../../models/attendance.dart';
import '../../services/supabase_sync_service.dart';

class DashboardAdmin extends StatelessWidget {
  const DashboardAdmin({super.key});

  void _handleSync(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sinkronisasi Database'),
        content: const Text('Apakah Anda yakin ingin menyinkronkan seluruh data lokal (Guru, Siswa, Kelas, Ruangan, Mapel, Jadwal) ke Supabase?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );
              try {
                await SupabaseSyncService.syncAllData(provider);
                if (context.mounted) {
                  Navigator.pop(context); // Close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sinkronisasi data ke Supabase BERHASIL!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Close loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sinkronisasi GAGAL: $e')),
                  );
                }
              }
            },
            child: const Text('Mulai Sinkronisasi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final resetRequests = provider.resetRequests;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (resetRequests.isNotEmpty) ...[
          _buildResetNotifications(context, resetRequests),
          const SizedBox(height: 32),
        ],
        
        // Header with dynamic greeting
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ringkasan Dashboard', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.getTextColor(provider.isDarkMode))),
                Text('Pantau performa sekolah secara real-time hari ini.', style: TextStyle(fontSize: 14, color: provider.isDarkMode ? Colors.white70 : AppColors.textSecondary)),
              ],
            ),
            CustomButton(
              variant: ButtonVariant.primary,
              icon: const Icon(LucideIcons.database, size: 18),
              onClick: () => _handleSync(context, provider),
              child: const Text('Sinkronisasi Supabase'),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Quick Actions
        _buildSectionTitle('Aksi Cepat'),
        const SizedBox(height: 12),
        _buildQuickActions(context),
        const SizedBox(height: 32),

        // Statistics (Matching the user's premium screenshot but with real data)
        _buildStatsGrid(provider),
        const SizedBox(height: 32),

        // Real-time Monitoring
        _buildAttendanceStatus(context, provider),
      ],
    );
  }

  Widget _buildResetNotifications(BuildContext context, List<ResetRequest> requests) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    return CustomCard(
      color: const Color(0xFFFFF7ED),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.shieldAlert, color: Colors.orange, size: 24),
              const SizedBox(width: 12),
              Text(
                'Permintaan Reset Password (${requests.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF9A3412)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: requests.length,
            separatorBuilder: (context, index) => const Divider(color: Color(0xFFFED7AA)),
            itemBuilder: (context, index) {
              final req = requests[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(req.email, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF431407))),
                          Text('Diminta pada: ${req.timestamp.hour}:${req.timestamp.minute}', style: const TextStyle(fontSize: 12, color: Color(0xFF9A3412))),
                        ],
                      ),
                    ),
                    CustomButton(
                      size: ButtonSize.sm,
                      variant: ButtonVariant.primary,
                      onClick: () {
                        provider.processResetRequest(req.id);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permintaan diproses.')));
                      },
                      child: const Text('Proses'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.2),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final actions = [
      {'id': 'siswa', 'label': 'Siswa', 'icon': LucideIcons.users, 'color': Colors.indigo},
      {'id': 'jadwal', 'label': 'Jadwal', 'icon': LucideIcons.calendar, 'color': Colors.blue},
      {'id': 'absensi', 'label': 'Laporan', 'icon': LucideIcons.fileText, 'color': AppColors.success},
      {'id': 'guru', 'label': 'Guru', 'icon': LucideIcons.userCheck, 'color': Colors.amber},
      {'id': 'ruangan', 'label': 'Ruangan', 'icon': LucideIcons.building, 'color': Colors.purple},
      {'id': 'accounts', 'label': 'Akun', 'icon': LucideIcons.userPlus, 'color': AppColors.danger},
    ];

    return Row(
      children: actions.map((action) {
        final color = action['color'] as Color;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: action == actions.last ? 0 : 12),
            child: _QuickActionCard(
              action: action,
              color: color,
              onTap: () => provider.setActiveMenu(action['id'] as String),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsGrid(AppProvider provider) {
    final isDark = provider.isDarkMode;
    final today = ChronosService.instance.now();
    final todayAttendance = provider.attendance.where((a) => a.date.day == today.day && a.date.month == today.month && a.date.year == today.year).toList();
    final uniqueStudents = todayAttendance.map((a) => a.studentId).toSet().length;
    final presenceRate = provider.students.isNotEmpty ? (uniqueStudents / provider.students.length * 100).toStringAsFixed(1) : '0';

    // Mocking a thousands separator for the "real" feel if needed, but here we just show the actual count
    String formatNum(int num) => num.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');

    final stats = [
      {'title': 'Total Siswa Aktif', 'value': formatNum(provider.students.length), 'icon': LucideIcons.users, 'color': AppColors.primary},
      {'title': 'Total Guru', 'value': formatNum(provider.teachers.length), 'icon': LucideIcons.userCheck, 'color': AppColors.success},
      {'title': 'Kelas Aktif', 'value': formatNum(provider.classes.length), 'icon': LucideIcons.layers, 'color': AppColors.warning},
      {'title': 'Kehadiran Hari Ini', 'value': '$presenceRate%', 'icon': LucideIcons.circleCheck, 'color': AppColors.info},
    ];

    return Row(
      children: stats.map((stat) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: stat == stats.last ? 0 : 20),
            child: CustomCard(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stat['title'] as String,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          stat['value'] as String,
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.getTextColor(isDark)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE2E8F0)),
                    ),
                    child: Icon(stat['icon'] as IconData, color: stat['color'] as Color, size: 22),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAttendanceStatus(BuildContext context, AppProvider provider) {
    final monitoring = provider.getTodayClassMonitoring();

    return CustomCard(
      noPadding: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Monitoring Absensi Hari Ini (${provider.currentDayName})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                CustomButton(
                  variant: ButtonVariant.ghost,
                  size: ButtonSize.sm,
                  onClick: () => provider.setActiveMenu('absensi'),
                  child: const Text('Detail Laporan', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (monitoring.isEmpty)
            Container(
              padding: const EdgeInsets.all(48),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(LucideIcons.clipboardList, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada absensi yang diisi hari ini',
                    style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          else
            ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300), // Fixed height for ~3-4 items
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: monitoring.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final m = monitoring[index];
                return _buildMonitorRow(
                  m.className,
                  m.hasAttendance,
                  m.filledByLabel ?? m.filledByRole ?? '-',
                  m.studentCount,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitorRow(String className, bool isDone, String filledBy, int count) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isDone ? AppColors.success.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
            child: Text(
              className.length >= 2 ? className.substring(0, 2) : className,
              style: TextStyle(
                color: isDone ? AppColors.success : AppColors.warning,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(className, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  isDone ? 'Diisi oleh: $filledBy' : 'Belum ada absensi hari ini',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomBadge(
                variant: isDone ? BadgeVariant.success : BadgeVariant.warning,
                child: Text(isDone ? 'Sudah' : 'Belum'),
              ),
              if (isDone) Text('$count entri', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatefulWidget {
  final Map<String, Object> action;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.action,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = provider.isDarkMode;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 20),
          transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
          decoration: BoxDecoration(
            color: _isHovered 
                ? widget.color.withOpacity(isDark ? 0.15 : 0.05) 
                : AppColors.getCardColor(isDark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered 
                  ? widget.color.withOpacity(0.5) 
                  : AppColors.getBorderColor(isDark),
            ),
            boxShadow: _isHovered 
                ? [BoxShadow(color: widget.color.withOpacity(isDark ? 0.3 : 0.15), blurRadius: 10, offset: const Offset(0, 4))] 
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: _isHovered ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(widget.action['icon'] as IconData, color: widget.color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                widget.action['label'] as String, 
                style: TextStyle(
                  fontSize: 13, 
                  fontWeight: FontWeight.bold, 
                  color: _isHovered ? widget.color : AppColors.getTextColor(isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
