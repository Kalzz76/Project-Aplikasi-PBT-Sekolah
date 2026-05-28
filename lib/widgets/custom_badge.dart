import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark || 
                   Provider.of<AppProvider>(context).isDarkMode;

    Color bgColor;
    Color textColor;
    BorderSide border = const BorderSide(color: Colors.transparent);

    switch (variant) {
      case BadgeVariant.defaultValue:
        bgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
        textColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF334155);
        border = BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));
        break;
      case BadgeVariant.success:
      case BadgeVariant.emerald:
        bgColor = isDark ? const Color(0xFF064E3B).withOpacity(0.5) : AppColors.successBg;
        textColor = isDark ? const Color(0xFF34D399) : const Color(0xFF047857);
        border = BorderSide(color: isDark ? const Color(0xFF065F46).withOpacity(0.8) : const Color(0xFFA7F3D0));
        break;
      case BadgeVariant.warning:
      case BadgeVariant.orange:
        bgColor = isDark ? const Color(0xFF78350F).withOpacity(0.4) : AppColors.warningBg;
        textColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
        border = BorderSide(color: isDark ? const Color(0xFF92400E).withOpacity(0.7) : const Color(0xFFFDE68A));
        break;
      case BadgeVariant.danger:
        bgColor = isDark ? const Color(0xFF7F1D1D).withOpacity(0.4) : AppColors.dangerBg;
        textColor = isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C);
        border = BorderSide(color: isDark ? const Color(0xFF991B1B).withOpacity(0.7) : const Color(0xFFFECACA));
        break;
      case BadgeVariant.blue:
        bgColor = isDark ? const Color(0xFF1E3A8A).withOpacity(0.4) : AppColors.infoBg;
        textColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8);
        border = BorderSide(color: isDark ? const Color(0xFF1E40AF).withOpacity(0.7) : const Color(0xFFBFDBFE));
        break;
      case BadgeVariant.indigo:
        bgColor = isDark ? const Color(0xFF312E81).withOpacity(0.4) : AppColors.primaryLight;
        textColor = isDark ? const Color(0xFF818CF8) : const Color(0xFF4338CA);
        border = BorderSide(color: isDark ? const Color(0xFF3730A3).withOpacity(0.7) : const Color(0xFFC7D2FE));
        break;
      case BadgeVariant.outline:
        bgColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
        textColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        border = BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.fromBorderSide(border),
        boxShadow: isDark && variant != BadgeVariant.defaultValue && variant != BadgeVariant.outline
            ? [BoxShadow(color: textColor.withOpacity(0.15), blurRadius: 8, spreadRadius: -2)]
            : [],
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
          letterSpacing: 0.2,
        ),
        child: child,
      ),
    );
  }
}
