import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:pdf_app/core/providers.dart';
import 'package:pdf_app/core/router/app_router.dart';
import 'package:pdf_app/core/theme/app_theme.dart';
import 'package:pdf_app/features/home/presentation/splash_screen.dart';

void main() {
  if (Platform.isLinux || Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const ProviderScope(child: PdfNavigatorApp()));
}

class PdfNavigatorApp extends ConsumerStatefulWidget {
  const PdfNavigatorApp({super.key});

  @override
  ConsumerState<PdfNavigatorApp> createState() => _PdfNavigatorAppState();
}

class _PdfNavigatorAppState extends ConsumerState<PdfNavigatorApp> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    // select() narrows the watch to themeMode only, so unrelated settings
    // changes (readingMode, scrollDirection) do not rebuild MaterialApp (#22).
    final themeMode = ref.watch(
      appSettingsProvider.select((s) => s.themeMode),
    );

    return MaterialApp.router(
      title: 'PDF Navigator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
      builder: (context, child) {
        if (!_splashDone) {
          return SplashScreen(
            onDone: () => setState(() => _splashDone = true),
          );
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
