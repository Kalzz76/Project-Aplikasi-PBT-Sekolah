import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../core/chronos_service.dart';

class DigitalClock extends StatefulWidget {
  const DigitalClock({super.key});

  @override
  State<DigitalClock> createState() => _DigitalClockState();
}

class _DigitalClockState extends State<DigitalClock> {
  late Timer _timer;
  String _timeString = "";

  @override
  void initState() {
    super.initState();
    _timeString = _formatDateTime(ChronosService.instance.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _getTime());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _getTime() {
    final DateTime now = ChronosService.instance.now();
    final String formattedDateTime = _formatDateTime(now);
    if (mounted) {
      setState(() {
        _timeString = formattedDateTime;
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final isChronos = ChronosService.instance.enabled;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isChronos ? const Color(0xFFFEF3C7) : AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isChronos ? const Color(0xFFF59E0B) : AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isChronos ? Icons.science : Icons.access_time,
            size: 14,
            color: isChronos ? const Color(0xFFD97706) : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Text(
            _timeString,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isChronos ? const Color(0xFFD97706) : AppColors.textPrimary,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
