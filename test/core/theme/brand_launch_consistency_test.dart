import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/core/theme/app_colors.dart';
import 'package:sefer/features/home/presentation/splash_screen.dart';

String _hex(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}'
        .toUpperCase();

void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();

  test('native splash colours match the Flutter launch overlay', () {
    expect(pubspec, contains('color: "${_hex(AppColors.splashLight)}"'));
    expect(pubspec, contains('color_dark: "${_hex(AppColors.splashDark)}"'));
  });

  test('Android 12 splash icon is the asset the overlay draws', () {
    expect(pubspec, contains('image: ${SplashScreen.logoAsset}'));
    expect(File(SplashScreen.logoAsset).existsSync(), isTrue);
  });
}
