import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../providers/app_provider.dart';

class ModulChronos extends StatelessWidget {
  const ModulChronos({super.key});

  static const _days = {1: 'Senin', 2: 'Selasa', 3: 'Rabu', 4: 'Kamis', 5: 'Jumat'};
  static const _dayColors = {
    1: Color(0xFF6366F1), 2: Color(0xFF8B5CF6), 3: Color(0xFF0EA5E9),
    4: Color(0xFF10B981), 5: Color(0xFFF59E0B),
  };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.science, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Chronos', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                SizedBox(height: 2),
                Text('Pengatur waktu virtual untuk pengujian fitur real-time', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Enable / Disable Card
        _SectionCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: provider.chronosEnabled ? const Color(0xFF6366F1).withOpacity(0.1) : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.schedule, size: 22,
                    color: provider.chronosEnabled ? const Color(0xFF6366F1) : AppColors.textMuted),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider.chronosEnabled ? 'Chronos Aktif' : 'Chronos Tidak Aktif',
                        style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold,
                          color: provider.chronosEnabled ? const Color(0xFF6366F1) : AppColors.textPrimary,
                        )),
                    const SizedBox(height: 2),
                    Text(
                      provider.chronosEnabled
                          ? 'Sistem membaca waktu virtual: ${provider.chronosDayName}, ${provider.chronosHour.toString().padLeft(2, '0')}:${provider.chronosMinute.toString().padLeft(2, '0')}'
                          : 'Aktifkan untuk menguji fitur jadwal dan absensi',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Switch(
                value: provider.chronosEnabled,
                activeColor: const Color(0xFF6366F1),
                onChanged: (v) => provider.setChronosEnabled(v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (provider.chronosEnabled) ...[
          // Day Picker
          const Text('Pilih Hari', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Row(
            children: _days.entries.map((e) {
              final isSelected = provider.chronosDay == e.key;
              final color = _dayColors[e.key] ?? AppColors.primary;
              return Expanded(
                child: GestureDetector(
                  onTap: () => provider.setChronosDay(e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? color : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isSelected ? color : AppColors.border, width: isSelected ? 2 : 1),
                      boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))] : [],
                    ),
                    child: Text(e.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Time Picker
          const Text('Pilih Jam', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          _SectionCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _TimeBox(label: 'Jam', value: provider.chronosHour.toString().padLeft(2, '0')),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(':', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                    _TimeBox(label: 'Menit', value: provider.chronosMinute.toString().padLeft(2, '0')),
                  ],
                ),
                const SizedBox(height: 20),
                // Hour Slider
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('06:00', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        Text('Jam', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                        Text('17:00', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF6366F1),
                        inactiveTrackColor: const Color(0xFF6366F1).withOpacity(0.15),
                        thumbColor: const Color(0xFF6366F1),
                        overlayColor: const Color(0xFF6366F1).withOpacity(0.1),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        min: 6, max: 17,
                        value: provider.chronosHour.toDouble(),
                        divisions: 11,
                        label: '${provider.chronosHour}:00',
                        onChanged: (v) => provider.setChronosHour(v.round()),
                      ),
                    ),
                  ],
                ),
                // Minute Slider
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('00', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        Text('Menit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                        Text('59', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF8B5CF6),
                        inactiveTrackColor: const Color(0xFF8B5CF6).withOpacity(0.15),
                        thumbColor: const Color(0xFF8B5CF6),
                        overlayColor: const Color(0xFF8B5CF6).withOpacity(0.1),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        min: 0, max: 59,
                        value: provider.chronosMinute.toDouble(),
                        divisions: 59,
                        label: '${provider.chronosMinute}',
                        onChanged: (v) => provider.setChronosMinute(v.round()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick presets
          const Text('Preset Cepat', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _PresetChip(label: 'Senin Jam 1', day: 1, hour: 6, minute: 30, provider: provider),
              _PresetChip(label: 'Senin Jam 5', day: 1, hour: 9, minute: 30, provider: provider),
              _PresetChip(label: 'Selasa Pagi', day: 2, hour: 7, minute: 0, provider: provider),
              _PresetChip(label: 'Rabu Siang', day: 3, hour: 12, minute: 0, provider: provider),
              _PresetChip(label: 'Kamis Jam 3', day: 4, hour: 8, minute: 15, provider: provider),
              _PresetChip(label: 'Jumat Jam 1', day: 5, hour: 6, minute: 30, provider: provider),
            ],
          ),
          const SizedBox(height: 24),

          // Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Chronos aktif: sistem membaca Hari = ${provider.chronosDayName}, '
                    'Jam = ${provider.chronosHour.toString().padLeft(2, '0')}:${provider.chronosMinute.toString().padLeft(2, '0')}. '
                    'Jam absensi, jadwal aktif, dan monitor harian menggunakan waktu ini.',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}

class _TimeBox extends StatelessWidget {
  final String label;
  final String value;
  const _TimeBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(value, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace')),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final int day, hour, minute;
  final AppProvider provider;
  const _PresetChip({required this.label, required this.day, required this.hour, required this.minute, required this.provider});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      backgroundColor: const Color(0xFFF1F5F9),
      side: const BorderSide(color: AppColors.border),
      onPressed: () {
        provider.setChronosDay(day);
        provider.setChronosHour(hour);
        provider.setChronosMinute(minute);
      },
    );
  }
}
