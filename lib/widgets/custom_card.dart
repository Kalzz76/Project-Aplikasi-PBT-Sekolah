import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../providers/app_provider.dart';

class CustomCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onClick;
  final bool noPadding;
  final Color? color;
  final bool hoverEffect;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.onClick,
    this.noPadding = false,
    this.color,
    this.hoverEffect = true,
  });

  @override
  State<CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<AppProvider>(context).isDarkMode;
    final canHover = widget.hoverEffect || widget.onClick != null;

    final innerContent = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onClick,
        splashColor: AppColors.primary.withOpacity(0.1),
        highlightColor: AppColors.primary.withOpacity(0.05),
        child: Padding(
          padding: widget.noPadding ? EdgeInsets.zero : (widget.padding ?? const EdgeInsets.all(24.0)),
          child: widget.child,
        ),
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: canHover && _isHovered 
            ? (Matrix4.identity()..translate(0, -4.0, 0)) 
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: widget.color ?? AppColors.getCardColor(isDark).withOpacity(isDark ? 0.05 : 1.0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: canHover && _isHovered 
                ? AppColors.primary.withOpacity(isDark ? 0.6 : 0.3) 
                : (isDark ? Colors.white.withOpacity(0.1) : AppColors.getBorderColor(false)),
            width: isDark ? 1.5 : 1.0,
          ),
          boxShadow: isDark ? [
             BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
          ] : [
            BoxShadow(
              color: Colors.black.withOpacity(_isHovered && canHover ? 0.12 : 0.05),
              blurRadius: _isHovered && canHover ? 16 : 10,
              offset: Offset(0, _isHovered && canHover ? 8 : 4),
            ),
          ],
        ),
          child: innerContent,
      ),
    );
  }
}
