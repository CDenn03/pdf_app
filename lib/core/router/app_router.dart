import 'package:go_router/go_router.dart';

import 'package:pdf_app/core/constants.dart';
import 'package:pdf_app/features/library/presentation/library_page.dart';
import 'package:pdf_app/features/reader/presentation/reader_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'library',
      builder: (context, state) => const LibraryPage(),
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
