import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pdf_app/core/theme/app_colors.dart';

/// Splash screen shown on app launch.
///
/// Fades the logo in, holds briefly, then fades the entire screen out before
/// calling [onDone] so the transition into the home shell feels intentional
/// rather than abrupt.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // 0.0 → 0.4 : logo fades in
  late final Animation<double> _fadeIn;
  // 0.7 → 1.0 : whole screen fades out
  late final Animation<double> _fadeOut;

  static const _total = Duration(milliseconds: 1800);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _total);

    _fadeIn = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );

    _fadeOut = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.72, 1.0, curve: Curves.easeIn),
    );

    _ctrl.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF073D42) : AppColors.brand;
    final textColor = AppColors.onBrand;
    final subtitleColor = AppColors.onBrand.withValues(alpha: 0.75);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Opacity(
          // Fade the whole screen out at the end.
          opacity: 1.0 - _fadeOut.value,
          child: Scaffold(
            backgroundColor: bg,
            body: Center(
              child: FadeTransition(
                opacity: _fadeIn,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo mark — rounded square with book icon.
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.onBrand.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        size: 48,
                        color: AppColors.onBrand,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'PDF Navigator',
                      style: GoogleFonts.fraunces(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your personal reading library',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
