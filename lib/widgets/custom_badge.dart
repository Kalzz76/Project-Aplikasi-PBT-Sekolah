import 'package:flutter/material.dart';
import '../core/app_colors.dart';

enum BadgeVariant { defaultValue, success, warning, danger, blue, indigo, outline, orange, emerald }

class CustomBadge extends StatelessWidget {
  final Widget child;
  final BadgeVariant variant;

  const CustomBadge({
    super.key,
    required this.child,
    this.variant = BadgeVariant.defaultValue,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    BorderSide border = const BorderSide(color: Colors.transparent);

    switch (variant) {
      case BadgeVariant.defaultValue:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF334155);
        border = const BorderSide(color: Color(0xFFE2E8F0));
        break;
      case BadgeVariant.success:
      case BadgeVariant.emerald:
        bgColor = AppColors.successBg;
        textColor = const Color(0xFF047857);
        border = const BorderSide(color: Color(0xFFA7F3D0));
        break;
      case BadgeVariant.warning:
      case BadgeVariant.orange:
        bgColor = AppColors.warningBg;
        textColor = const Color(0xFFB45309);
        border = const BorderSide(color: Color(0xFFFDE68A));
        break;
      case BadgeVariant.danger:
        bgColor = AppColors.dangerBg;
        textColor = const Color(0xFFB91C1C);
        border = const BorderSide(color: Color(0xFFFECACA));
        break;
      case BadgeVariant.blue:
        bgColor = AppColors.infoBg;
        textColor = const Color(0xFF1D4ED8);
        border = const BorderSide(color: Color(0xFFBFDBFE));
        break;
      case BadgeVariant.indigo:
        bgColor = AppColors.primaryLight;
        textColor = const Color(0xFF4338CA);
        border = const BorderSide(color: Color(0xFFC7D2FE));
        break;
      case BadgeVariant.outline:
        bgColor = Colors.white;
        textColor = const Color(0xFF64748B);
        border = const BorderSide(color: Color(0xFFE2E8F0));
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.fromBorderSide(border),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        child: child,
      ),
    );
  }
}
