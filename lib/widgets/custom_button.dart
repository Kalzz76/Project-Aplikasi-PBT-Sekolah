import 'package:flutter/material.dart';
import '../core/app_colors.dart';

enum ButtonVariant { primary, secondary, danger, outline, ghost }
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
    Color bgColor;
    Color textColor;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case ButtonVariant.primary:
        bgColor = AppColors.primary;
        textColor = Colors.white;
        break;
      case ButtonVariant.secondary:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF334155);
        break;
      case ButtonVariant.danger:
        bgColor = AppColors.dangerBg;
        textColor = AppColors.danger;
        break;
      case ButtonVariant.outline:
        bgColor = Colors.white;
        textColor = const Color(0xFF334155);
        border = const BorderSide(color: Color(0xFFCBD5E1));
        break;
      case ButtonVariant.ghost:
        bgColor = Colors.transparent;
        textColor = const Color(0xFF475569);
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
