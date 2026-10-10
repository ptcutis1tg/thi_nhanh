import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AppInteractiveHoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double? borderRadius;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Border? customBorder;
  final EdgeInsetsGeometry? padding;
  final bool enableHover;
  final double hoverTranslateY;
  final bool applyCardDecoration;

  const AppInteractiveHoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.backgroundColor,
    this.gradient,
    this.customBorder,
    this.padding,
    this.enableHover = true,
    this.hoverTranslateY = -3.0,
    this.applyCardDecoration = true,
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

    Widget content = widget.child;

    if (widget.applyCardDecoration) {
      content = AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.gradient == null
              ? (widget.backgroundColor ?? (_isHovered ? const Color(0xFFFFFFFF) : const Color(0xF5FFFFFF)))
              : null,
          gradient: widget.gradient,
          borderRadius: BorderRadius.circular(effectiveRadius),
          border: widget.customBorder ??
              Border.all(
                color: _isHovered ? AppTheme.primary : AppTheme.border.withValues(alpha: 0.8),
                width: _isHovered ? 1.5 : 1.0,
              ),
          boxShadow: _isHovered
              ? AppTheme.hoverGlowShadow
              : (widget.gradient != null
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryDark.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : AppTheme.luminescenceShadow),
        ),
        child: widget.child,
      );
    }

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: isInteractive ? (_) => setState(() => _isHovered = true) : null,
      onExit: isInteractive ? (_) => setState(() => _isHovered = false) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _isHovered ? widget.hoverTranslateY : 0.0, 0),
          child: content,
        ),
      ),
    );
  }
}
