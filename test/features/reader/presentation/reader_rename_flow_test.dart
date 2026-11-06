import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:sefer/features/library/state/document_rename_result.dart';
import 'package:sefer/features/reader/domain/reader_route_arguments.dart';
import 'package:sefer/features/reader/presentation/reader_rename_flow.dart';
import 'package:sefer/features/reader/state/open_document_rename_coordinator.dart';

class _Host implements OpenDocumentRenameHost {
  var resumed = 0;

  @override
  int get currentPage => 12;

  @override
  Future<void> flushProgress() async {}

  @override
  Future<void> flushAnnotations() async {}

  @override
  void cancelSearch() {}

  @override
  Future<void> suspendViewport() async {}

  @override
  void resumeViewport() => resumed++;
}

Future<List<ReaderRouteArguments>> _pump(
  WidgetTester tester,
  _Host host,
  DocumentRenameResult result,
) async {
  final replaced = <ReaderRouteArguments>[];
  final coordinator = OpenDocumentRenameCoordinator(
    host: host,
    rename: ({required path, required newName}) async => result,
  );
  final router = GoRouter(
    initialLocation: '/reader',
    routes: [
      GoRoute(
        path: '/reader',
        builder: (context, state) {
          final args = state.extra as ReaderRouteArguments?;
          if (args != null) replaced.add(args);
          return Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => renameOpenDocument(
                  context,
                  coordinator: coordinator,
                  path: '/docs/old.pdf',
                ),
                child: const Text('rename'),
              ),
            ),
          );
        },
      ),
    ],
  );
  addTearDown(coordinator.dispose);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.tap(find.text('rename'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), 'fresh');
  await tester.tap(find.widgetWithText(FilledButton, 'Rename'));
  await tester.pumpAndSettle();
  return replaced;
}

void main() {
  testWidgets('success replaces the route once at the captured page', (
    tester,
  ) async {
    final host = _Host();

    final replaced = await _pump(
      tester,
      host,
      const DocumentRenameSuccess('/docs/fresh.pdf'),
    );

    expect(replaced, hasLength(1));
    expect(replaced.single.path, '/docs/fresh.pdf');
    expect(replaced.single.initialPage, 12);
    expect(replaced.single.recordOpened, isFalse);
    expect(find.text('Renamed.'), findsOneWidget);
  });

  testWidgets('rejection keeps the route and shows the reason', (tester) async {
    final host = _Host();

    final replaced = await _pump(
      tester,
      host,
      const DocumentRenameRejected('That name is not valid.'),
    );

    expect(replaced, isEmpty);
    expect(host.resumed, 1);
    expect(find.text('That name is not valid.'), findsOneWidget);
  });
}
