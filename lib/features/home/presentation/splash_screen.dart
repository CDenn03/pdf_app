import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sefer/core/theme/app_colors.dart';
import 'package:sefer/core/theme/app_theme.dart';
import 'package:sefer/core/theme/system_ui.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.readiness,
    required this.onDone,
    this.minimumDuration = const Duration(milliseconds: 725),
    this.loadingDelay = const Duration(milliseconds: 900),
    this.exitDuration = const Duration(milliseconds: 275),
    this.textRevealDelay = const Duration(milliseconds: 120),
    this.textRevealDuration = const Duration(milliseconds: 220),
  });

  final Future<void> readiness;
  final VoidCallback onDone;
  final Duration minimumDuration;
  final Duration loadingDelay;
  final Duration exitDuration;
  final Duration textRevealDelay;
  final Duration textRevealDuration;

  static const logoAsset = 'assets/splash_icon.png';

  // Android 12 draws the 1152 px splash icon at 288 dp; matching it keeps the
  // logo pixel-aligned across the native-to-Flutter handoff.
  static const logoExtent = 288.0;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _minimumTimer;
  Timer? _loadingTimer;
  Timer? _textTimer;
  Timer? _exitTimer;
  bool _minimumElapsed = false;
  bool _readinessSettled = false;
  bool _showText = false;
  bool _showLoading = false;
  bool _exiting = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _minimumTimer = Timer(widget.minimumDuration, _markMinimumElapsed);
    _loadingTimer = Timer(widget.loadingDelay, _revealLoading);
    _textTimer = Timer(widget.textRevealDelay, _revealText);
    widget.readiness.then<void>(
      (_) => _markReadinessSettled(),
      onError: (Object error, StackTrace stackTrace) {
        developer.log(
          'Startup readiness failed',
          name: 'sefer.startup',
          level: 1000,
          error: error,
          stackTrace: stackTrace,
        );
        _markReadinessSettled();
      },
    );
  }

  void _markMinimumElapsed() {
    if (!mounted) return;
    _minimumElapsed = true;
    _exitIfReady();
  }

  void _markReadinessSettled() {
    if (!mounted || _readinessSettled) return;
    _readinessSettled = true;
    _loadingTimer?.cancel();
    _exitIfReady();
  }

  void _revealText() {
    if (!mounted || _exiting) return;
    setState(() => _showText = true);
  }

  void _revealLoading() {
    if (!mounted || _readinessSettled || _exiting) return;
    setState(() => _showLoading = true);
  }

  void _exitIfReady() {
    if (!_minimumElapsed || !_readinessSettled || _exiting) return;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (disableAnimations || widget.exitDuration == Duration.zero) {
      _finish();
      return;
    }
    setState(() => _exiting = true);
    _exitTimer = Timer(widget.exitDuration, _finish);
  }

  void _finish() {
    if (!mounted || _done) return;
    _done = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _minimumTimer?.cancel();
    _loadingTimer?.cancel();
    _textTimer?.cancel();
    _exitTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final background = brightness == Brightness.dark
        ? AppColors.splashDark
        : AppColors.splashLight;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppSystemUi.lightIcons,
      child: AnimatedOpacity(
        key: const ValueKey('splash-opacity'),
        opacity: _exiting ? 0 : 1,
        duration: disableAnimations ? Duration.zero : widget.exitDuration,
        curve: Curves.easeInOut,
        child: ColoredBox(
          key: const ValueKey('splash-background'),
          color: background,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Image.asset(
                  SplashScreen.logoAsset,
                  key: const ValueKey('splash-logo'),
                  width: SplashScreen.logoExtent,
                  height: SplashScreen.logoExtent,
                ),
              ),
              Center(
                child: Transform.translate(
                  offset: const Offset(0, 128),
                  child: AnimatedSwitcher(
                    duration: disableAnimations
                        ? Duration.zero
                        : widget.textRevealDuration,
                    child: _showText
                        ? const _BrandCopy(key: ValueKey('splash-copy'))
                        : const SizedBox(
                            key: ValueKey('splash-copy-placeholder'),
                          ),
                  ),
                ),
              ),
              Center(
                child: Transform.translate(
                  offset: const Offset(0, 196),
                  child: _LoadingAffordance(
                    visible: _showLoading,
                    disableAnimations: disableAnimations,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandCopy extends StatelessWidget {
  const _BrandCopy({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Sefer',
          style: TextStyle(
            fontFamily: AppTheme.fontSerif,
            color: AppColors.onBrand,
            fontSize: 34,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Read. Reflect. Understand.',
          style: TextStyle(
            fontFamily: AppTheme.fontSerif,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
            color: AppColors.onBrand.withValues(alpha: 0.85),
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _LoadingAffordance extends StatelessWidget {
  const _LoadingAffordance({
    required this.visible,
    required this.disableAnimations,
  });

  final bool visible;
  final bool disableAnimations;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    if (disableAnimations) {
      return Text(
        'Loading…',
        style: TextStyle(
          fontFamily: AppTheme.fontSans,
          color: AppColors.onBrand.withValues(alpha: 0.72),
          fontSize: 13,
        ),
      );
    }
    return const SizedBox.square(
      dimension: 18,
      child: CircularProgressIndicator(
        color: AppColors.onBrand,
        strokeWidth: 2,
      ),
    );
  }
}
