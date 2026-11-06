import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:sefer/core/providers.dart';
import 'package:sefer/core/router/app_router.dart';
import 'package:sefer/core/theme/app_theme.dart';
import 'package:sefer/features/home/presentation/splash_screen.dart';
import 'package:sefer/features/library/state/library_providers.dart';
import 'package:sefer/features/recents/state/recents_notifier.dart';

final startupReadinessProvider = FutureProvider<void>((ref) async {
  await Future.wait<Object?>([
    ref.read(appSettingsProvider.notifier).ready,
    ref.read(libraryEntriesProvider.future),
    ref.read(collectionsProvider.future),
    ref.read(recentsProvider.notifier).ready,
  ], eagerError: true);
});

void main() {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  binding.deferFirstFrame();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  if (Platform.isLinux || Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(
    ProviderScope(
      child: _SplashAssetBootstrap(binding: binding, child: const SeferApp()),
    ),
  );
}

class _SplashAssetBootstrap extends StatefulWidget {
  const _SplashAssetBootstrap({required this.binding, required this.child});

  final WidgetsBinding binding;
  final Widget child;

  @override
  State<_SplashAssetBootstrap> createState() => _SplashAssetBootstrapState();
}

class _SplashAssetBootstrapState extends State<_SplashAssetBootstrap> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(_prepareFirstFrame());
  }

  Future<void> _prepareFirstFrame() async {
    try {
      await precacheImage(const AssetImage(SplashScreen.logoAsset), context);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to precache splash logo',
        name: 'sefer.startup',
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      widget.binding.allowFirstFrame();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class SeferApp extends ConsumerStatefulWidget {
  const SeferApp({super.key});

  @override
  ConsumerState<SeferApp> createState() => _SeferAppState();
}

class _SeferAppState extends ConsumerState<SeferApp> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(appSettingsProvider.select((s) => s.themeMode));
    final startupReadiness = ref.watch(startupReadinessProvider.future);

    return MaterialApp.router(
      title: 'Sefer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            child ?? const SizedBox.shrink(),
            if (_showSplash)
              SplashScreen(
                readiness: startupReadiness,
                onDone: () => setState(() => _showSplash = false),
              ),
          ],
        );
      },
    );
  }
}
