import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../core/app_colors.dart';

enum ButtonVariant { primary, secondary, success, danger, outline, ghost }
enum ButtonSize { sm, md, lg }

class CustomButton extends StatelessWidget {
  final Widget child;
  final ButtonVariant variant;
  final ButtonSize size;
  final Widget? icon;
  final VoidCallback? onClick;
  final bool disabled;
  final double? width;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.child,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.md,
    this.icon,
    this.onClick,
    this.disabled = false,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark || 
                   Provider.of<AppProvider>(context, listen: false).isDarkMode;

    Color bgColor;
    Color textColor;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case ButtonVariant.primary:
        bgColor = isDark ? const Color(0xFF6366F1) : AppColors.primary;
        textColor = Colors.white;
        break;
      case ButtonVariant.secondary:
        bgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
        textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF334155);
        break;
      case ButtonVariant.success:
        bgColor = isDark ? const Color(0xFF065F46).withOpacity(0.5) : AppColors.success;
        textColor = isDark ? const Color(0xFF34D399) : Colors.white;
        break;
      case ButtonVariant.danger:
        bgColor = isDark ? const Color(0xFF7F1D1D).withOpacity(0.4) : AppColors.dangerBg;
        textColor = isDark ? const Color(0xFFF87171) : AppColors.danger;
        break;
      case ButtonVariant.outline:
        bgColor = isDark ? Colors.white.withOpacity(0.02) : Colors.white;
        textColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF334155);
        border = BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1));
        break;
      case ButtonVariant.ghost:
        bgColor = Colors.transparent;
        textColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
        break;
    }

    double paddingH = 16;
    double paddingV = 10;
    double fontSize = 14;

    if (size == ButtonSize.sm) {
      paddingH = 12;
      paddingV = 6;
      fontSize = 12;
    } else if (size == ButtonSize.lg) {
      paddingH = 20;
      paddingV = 12;
      fontSize = 16;
    }

    final isActuallyDisabled = disabled || isLoading;

    return _HoverableButton(
      width: width,
      disabled: isActuallyDisabled,
      onClick: isActuallyDisabled ? null : onClick,
      child: Opacity(
        opacity: isActuallyDisabled ? 0.5 : 1.0,
        child: TextButton(
          onPressed: isActuallyDisabled ? null : onClick,
          style: TextButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: textColor,
            padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: border,
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: fontSize,
                  height: fontSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      icon!,
                      const SizedBox(width: 8),
                    ],
                    DefaultTextStyle(
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      child: child,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _HoverableButton extends StatefulWidget {
  final Widget child;
  final double? width;
  final VoidCallback? onClick;
  final bool disabled;

  const _HoverableButton({required this.child, this.width, this.onClick, this.disabled = false});

  @override
  State<_HoverableButton> createState() => _HoverableButtonState();
}

class _HoverableButtonState extends State<_HoverableButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: _isHovered && !widget.disabled ? (Matrix4.identity()..scale(1.03)) : Matrix4.identity(),
        transformAlignment: Alignment.center,
        width: widget.width,
        child: widget.child,
      ),
    );
  }
}
