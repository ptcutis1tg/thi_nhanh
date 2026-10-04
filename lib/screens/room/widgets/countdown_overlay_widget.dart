import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class CountdownOverlayWidget extends StatefulWidget {
  final VoidCallback onCountdownComplete;
  final int initialSeconds;

  const CountdownOverlayWidget({
    super.key,
    required this.onCountdownComplete,
    this.initialSeconds = 3,
  });

  @override
  State<CountdownOverlayWidget> createState() => _CountdownOverlayWidgetState();
}

class _CountdownOverlayWidgetState extends State<CountdownOverlayWidget>
    with SingleTickerProviderStateMixin {
  late int _currentSeconds;
  Timer? _timer;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  bool _hasCompleted = false;

  @override
  void initState() {
    super.initState();
    _currentSeconds = widget.initialSeconds;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.2, end: 1.2).chain(CurveTween(curve: Curves.easeOutBack)), weight: 60),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 40),
    ]).animate(_animController);

    _animController.forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_currentSeconds > 1) {
        setState(() {
          _currentSeconds--;
        });
        _animController.reset();
        _animController.forward();
      } else if (_currentSeconds == 1) {
        timer.cancel();
        setState(() {
          _currentSeconds = 0; // 0 represents "BẮT ĐẦU!"
        });
        _animController.reset();
        _animController.forward();

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && !_hasCompleted) {
            _hasCompleted = true;
            widget.onCountdownComplete();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGo = _currentSeconds == 0;

    return Material(
      color: Colors.black.withValues(alpha: 0.82),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 40,
                  color: Color(0xFFFEF08A),
                ),
                const SizedBox(height: 12),
                const Text(
                  'PHÒNG THI CHÍNH THỨC MỞ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    color: Color(0xFFFEF08A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: isGo ? 240 : 130,
                    height: 130,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: isGo
                          ? const LinearGradient(
                              colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [AppTheme.primary, Color(0xFF7C3AED)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      shape: isGo ? BoxShape.rectangle : BoxShape.circle,
                      borderRadius: isGo ? BorderRadius.circular(24) : null,
                      boxShadow: [
                        BoxShadow(
                          color: (isGo ? const Color(0xFF22C55E) : AppTheme.primary)
                              .withValues(alpha: 0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Text(
                      isGo ? 'BẮT ĐẦU!' : '$_currentSeconds',
                      style: TextStyle(
                        fontSize: isGo ? 36 : 64,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: isGo ? 1.0 : 0.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Chúc bạn làm bài thi đạt kết quả xuất sắc!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
