import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? color;

  const AppLogo({
    super.key, 
    this.size = 48, 
    this.showText = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final logoColor = color ?? const Color(0xFF1E3A8A);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer semi-shield shape similar to the logo in image
            Container(
              width: size,
              height: size * 1.1,
              child: CustomPaint(
                painter: LogoPainter(color: logoColor),
              ),
            ),
            // The Graduation Cap (simplified)
            Positioned(
              top: size * 0.1,
              right: size * 0.1,
              child: Icon(
                Icons.school, 
                size: size * 0.35, 
                color: logoColor,
              ),
            ),
          ],
        ),
        if (showText) ...[
          const SizedBox(height: 8),
          Text(
            'CLASSIO',
            style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: logoColor,
            ),
          ),
        ],
      ],
    );
  }
}

class LogoPainter extends CustomPainter {
  final Color color;
  LogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    // Draw the "Open Book" wings from the logo
    final w = size.width;
    final h = size.height;
    
    // Left Wing
    path.moveTo(w * 0.5, h * 0.2);
    path.quadraticBezierTo(w * 0.1, h * 0.15, w * 0.1, h * 0.5);
    path.lineTo(w * 0.1, h * 0.8);
    path.quadraticBezierTo(w * 0.1, h * 0.9, w * 0.5, h * 0.95);
    
    // Middle spine
    path.moveTo(w * 0.5, h * 0.2);
    path.lineTo(w * 0.5, h * 0.95);
    
    // Right Wing
    path.moveTo(w * 0.5, h * 0.2);
    path.quadraticBezierTo(w * 0.9, h * 0.15, w * 0.9, h * 0.5);
    path.lineTo(w * 0.9, h * 0.8);
    path.quadraticBezierTo(w * 0.9, h * 0.9, w * 0.5, h * 0.95);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
