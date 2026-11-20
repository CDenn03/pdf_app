import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:sefer/core/models/annotation.dart';
import 'package:sefer/core/models/annotation_type.dart';
import 'package:sefer/core/models/collection.dart';
import 'package:sefer/core/providers.dart';
import 'package:sefer/core/services/app_settings_service.dart';
import 'package:sefer/core/services/library_persistence_service.dart';
import 'package:sefer/core/theme/app_theme.dart';
import 'package:sefer/features/library/presentation/library_page.dart';
import 'package:sefer/features/library/state/library_providers.dart';
import 'package:sefer/features/reader/domain/reader_route_arguments.dart';
import 'package:sefer/features/recents/state/recents_notifier.dart';

import '../../support/library_fakes.dart';
import '../reader/support/fake_annotation_daos.dart';

class _FakeSettingsStore implements AppSettingsStore {
  @override
  Future<AppSettings> load() async => const AppSettings();

  @override
  Future<void> save(AppSettings settings) async {}
}

Future<void> _pumpLibrary(
  WidgetTester tester, {
  required FakeAnnotationDao dao,
  List<PersistedEntry> entries = const [],
  List<PdfCollection> collections = const [],
  ValueChanged<ReaderRouteArguments>? onOpen,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: LibraryPage()),
      ),
      GoRoute(
        path: '/reader',
        builder: (context, state) {
          final args = state.extra! as ReaderRouteArguments;
          onOpen?.call(args);
          return Scaffold(
            body: Text('opened ${args.path} p${args.initialPage}'),
          );
        },
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appSettingsServiceProvider.overrideWithValue(_FakeSettingsStore()),
        fileServiceProvider.overrideWithValue(FakeFileChecker()),
        libraryPersistenceProvider.overrideWithValue(
          FakeLibraryPersistence(initial: entries),
        ),
        collectionsServiceProvider.overrideWithValue(
          FakeCollectionsService(collections),
        ),
        recentsStoreProvider.overrideWithValue(FakeRecentsStore(const [])),
        annotationDaoProvider.overrideWithValue(dao),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('search shows annotation snippet with its book', (tester) async {
    await _pumpLibrary(
      tester,
      dao: FakeAnnotationDao(
        stored: const [
          Annotation(
            id: 'h1',
            pdfId: '/docs/design.pdf',
            page: 12,
            type: AnnotationType.highlight,
            selectedText: 'spacing tokens keep the grid honest',
          ),
        ],
      ),
      entries: const [
        PersistedEntry(
          id: 'e1',
          name: 'Design Systems.pdf',
          path: '/docs/design.pdf',
        ),
      ],
    );

    await tester.enterText(find.byType(TextField), 'tokens');
    await tester.pumpAndSettle();

    expect(find.text('spacing tokens keep the grid honest'), findsOneWidget);
    expect(find.text('Design Systems.pdf'), findsWidgets);
    expect(find.textContaining('p. 12'), findsOneWidget);
  });

  testWidgets('collection chip hides annotations from other books', (
    tester,
  ) async {
    await _pumpLibrary(
      tester,
      dao: FakeAnnotationDao(
        stored: const [
          Annotation(
            id: 'h1',
            pdfId: '/docs/design.pdf',
            page: 1,
            type: AnnotationType.highlight,
            selectedText: 'shared token language',
          ),
          Annotation(
            id: 'h2',
            pdfId: '/docs/habits.pdf',
            page: 4,
            type: AnnotationType.highlight,
            selectedText: 'habit token reminder',
          ),
        ],
      ),
      entries: const [
        PersistedEntry(
          id: 'e1',
          name: 'Design Systems.pdf',
          path: '/docs/design.pdf',
          collectionIds: {'design'},
        ),
        PersistedEntry(
          id: 'e2',
          name: 'Atomic Habits.pdf',
          path: '/docs/habits.pdf',
          collectionIds: {'life'},
        ),
      ],
      collections: const [
        PdfCollection(id: 'design', name: 'Design'),
        PdfCollection(id: 'life', name: 'Life'),
      ],
    );

    await tester.enterText(find.byType(TextField), 'token');
    await tester.pumpAndSettle();
    expect(find.text('shared token language'), findsOneWidget);
    expect(find.text('habit token reminder'), findsOneWidget);

    await tester.tap(find.text('Design'));
    await tester.pumpAndSettle();
    expect(find.text('shared token language'), findsOneWidget);
    expect(find.text('habit token reminder'), findsNothing);
  });

  testWidgets('tapping an annotation opens the book at that page', (
    tester,
  ) async {
    ReaderRouteArguments? opened;
    await _pumpLibrary(
      tester,
      onOpen: (args) => opened = args,
      dao: FakeAnnotationDao(
        stored: const [
          Annotation(
            id: 'h1',
            pdfId: '/docs/design.pdf',
            page: 12,
            type: AnnotationType.highlight,
            selectedText: 'spacing tokens keep the grid honest',
          ),
        ],
      ),
      entries: const [
        PersistedEntry(
          id: 'e1',
          name: 'Design Systems.pdf',
          path: '/docs/design.pdf',
        ),
      ],
    );

    await tester.enterText(find.byType(TextField), 'tokens');
    await tester.pumpAndSettle();
    await tester.tap(find.text('spacing tokens keep the grid honest'));
    await tester.pumpAndSettle();

    expect(opened?.path, '/docs/design.pdf');
    expect(opened?.initialPage, 12);
  });
}
