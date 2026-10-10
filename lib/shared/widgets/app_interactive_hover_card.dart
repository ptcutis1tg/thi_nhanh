import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AppInteractiveHoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double? borderRadius;
  final Color? backgroundColor;
  final Border? customBorder;
  final EdgeInsetsGeometry? padding;
  final bool enableHover;
  final double hoverTranslateY;

  const AppInteractiveHoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.backgroundColor,
    this.customBorder,
    this.padding,
    this.enableHover = true,
    this.hoverTranslateY = -2.5,
  });

  @override
  State<AppInteractiveHoverCard> createState() => _AppInteractiveHoverCardState();
}

class _AppInteractiveHoverCardState extends State<AppInteractiveHoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.borderRadius ?? AppTheme.cardRadius;
    final isInteractive = widget.enableHover;

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: isInteractive ? (_) => setState(() => _isHovered = true) : null,
      onExit: isInteractive ? (_) => setState(() => _isHovered = false) : null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _isHovered ? widget.hoverTranslateY : 0.0, 0),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? AppTheme.surface,
            borderRadius: BorderRadius.circular(effectiveRadius),
            border: widget.customBorder ??
                Border.all(
                  color: _isHovered ? AppTheme.primary : AppTheme.border,
                  width: _isHovered ? 1.2 : 1.0,
                ),
            boxShadow: _isHovered
                ? AppTheme.hoverGlowShadow
                : AppTheme.cardShadow,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
