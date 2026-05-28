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

    final cardColor = widget.color ?? AppColors.getCardColor(isDark);
    
    Widget cardDecoration = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      transform: canHover && _isHovered 
          ? (Matrix4.identity()..translate(0.0, -4.0, 0.0)) 
          : Matrix4.identity(),
      decoration: BoxDecoration(
        color: isDark ? cardColor.withOpacity(0.4) : cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canHover && _isHovered 
              ? AppColors.primary.withOpacity(isDark ? 0.8 : 0.4) 
              : (isDark ? Colors.white.withOpacity(0.08) : AppColors.getBorderColor(false)),
          width: isDark ? 1.0 : 1.0,
        ),
        boxShadow: isDark 
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered && canHover ? 0.4 : 0.2),
                blurRadius: _isHovered && canHover ? 20 : 12,
                offset: const Offset(0, 8),
              ),
              if (_isHovered && canHover)
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.15),
                  blurRadius: 25,
                  spreadRadius: -5,
                ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered && canHover ? 0.12 : 0.05),
                blurRadius: _isHovered && canHover ? 16 : 10,
                offset: Offset(0, _isHovered && canHover ? 8 : 4),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: isDark 
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: innerContent,
              )
            : innerContent,
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: cardDecoration,
    );
  }
}
