import 'package:flutter/material.dart';

class ThemeSwitcher extends StatefulWidget {
  final bool isDark;
  final Function(bool) onThemeChanged;

  const ThemeSwitcher({
    super.key,
    required this.isDark,
    required this.onThemeChanged,
  });

  @override
  State<ThemeSwitcher> createState() => _ThemeSwitcherState();
}

class _ThemeSwitcherState extends State<ThemeSwitcher> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _rippleAnimation;

  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _isDark = widget.isDark;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      reverseDuration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 360,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _rippleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    if (_isDark) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleTheme() {
    setState(() {
      _isDark = !_isDark;
      if (_isDark) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
      widget.onThemeChanged(_isDark);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleTheme,
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Stack(
          children: [
            // Ripple animation
            AnimatedBuilder(
              animation: _rippleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _rippleAnimation.value,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2 * (1 - _rippleAnimation.value)),
                    ),
                  ),
                );
              },
            ),
            // Icon animation
            Center(
              child: AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value * 3.14159 / 180,
                    child: Stack(
                      children: [
                        Opacity(
                          opacity: 1 - _animation.value,
                          child: const Icon(
                            Icons.light_mode_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        Opacity(
                          opacity: _animation.value,
                          child: const Icon(
                            Icons.dark_mode_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}