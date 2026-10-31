import 'dart:async';
import 'package:flutter/material.dart';
import '../../home/presentation/main_shell_screen.dart';

/// Premium Animated Splash Screen for Es Bangla.
/// Displays the official two-line stacked brand wordmark:
///  "Es"
///  "Bangla"
///  ─────── (Golden Accent Bar)
/// Followed by smooth reveal, shimmer expansion, and academic subtitle.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _barAnimation;
  late Animation<double> _subtitleFadeAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // 1. Logo Fade & Scale in
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.50, curve: Curves.easeOutBack),
      ),
    );

    // 2. Golden Bar Expanding smoothly beneath 'Bangla'
    _barAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    // 3. Academic Tagline Fade In
    _subtitleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.60, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // 4. Auto-navigate to MainShellScreen after 3.2 seconds
    _navigationTimer = Timer(const Duration(milliseconds: 3200), _navigateToHome);
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 650),
        pageBuilder: (context, animation, secondaryAnimation) => const MainShellScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF);
    final esColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F1E36);
    const banglaColor = Color(0xFF0070F3); // Vibrant Royal Blue
    const goldColor = Color(0xFFF59E0B);   // Golden Amber

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Two-Line Stacked Brand Typography (Matching user screenshot)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Line 1: "Es"
                          Text(
                            'Es',
                            style: TextStyle(
                              fontFamily: 'AppTitleFont',
                              fontSize: 54,
                              fontWeight: FontWeight.w900,
                              color: esColor,
                              height: 1.05,
                              letterSpacing: -1.0,
                            ),
                          ),
                          // Line 2: "Bangla"
                          Text(
                            'Bangla',
                            style: const TextStyle(
                              fontFamily: 'AppTitleFont',
                              fontSize: 54,
                              fontWeight: FontWeight.w900,
                              color: banglaColor,
                              height: 1.05,
                              letterSpacing: -1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Golden Accent Underline with smooth width reveal
                          Container(
                            margin: const EdgeInsets.only(left: 36),
                            width: 110 * _barAnimation.value,
                            height: 6,
                            decoration: BoxDecoration(
                              color: goldColor,
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: [
                                BoxShadow(
                                  color: goldColor.withOpacity(0.45 * _barAnimation.value),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Academic Subtitle Tagline
                      FadeTransition(
                        opacity: _subtitleFadeAnimation,
                        child: Column(
                          children: [
                            Text(
                              'উচ্চমাধ্যমিক সেমিস্টার সহায়িকা',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Class 11 & 12 · Bengali & Arts',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
