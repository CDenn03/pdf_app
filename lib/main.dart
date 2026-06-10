import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:sefer/core/providers.dart';
import 'package:sefer/core/router/app_router.dart';
import 'package:sefer/core/theme/app_theme.dart';
import 'package:sefer/features/home/presentation/splash_screen.dart';

void main() {
  // Always use bundled fonts — never fetch from the network.
  GoogleFonts.config.allowRuntimeFetching = false;

  if (Platform.isLinux || Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const ProviderScope(child: SeferApp()));
}

class SeferApp extends ConsumerStatefulWidget {
  const SeferApp({super.key});

  @override
  ConsumerState<SeferApp> createState() => _SeferAppState();
}

class _SeferAppState extends ConsumerState<SeferApp> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    // select() narrows the watch to themeMode only, so unrelated settings
    // changes (readingMode, scrollDirection) do not rebuild MaterialApp (#22).
    final themeMode = ref.watch(appSettingsProvider.select((s) => s.themeMode));

    return MaterialApp.router(
      title: 'Sefer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
      builder: (context, child) {
        if (!_splashDone) {
          return SplashScreen(onDone: () => setState(() => _splashDone = true));
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
