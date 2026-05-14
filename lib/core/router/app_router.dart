import 'package:go_router/go_router.dart';

import 'package:pdf_app/core/constants.dart';
import 'package:pdf_app/features/home/presentation/home_shell.dart';
import 'package:pdf_app/features/reader/presentation/reader_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeShell(),
    ),
    GoRoute(
      path: '/reader',
      name: 'reader',
      builder: (context, state) {
        final pdfPath = state.extra as String? ?? kSamplePdfPath;
        return ReaderPage(pdfPath: pdfPath);
      },
    ),
  ],
);
