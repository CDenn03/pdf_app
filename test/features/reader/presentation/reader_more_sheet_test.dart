import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/features/reader/presentation/reader_more_sheet.dart';
import 'package:sefer/features/reader/state/open_document_rename_coordinator.dart';

class _Host implements OpenDocumentRenameHost {
  @override
  int get currentPage => 1;

  @override
  Future<void> flushProgress() async {}

  @override
  Future<void> flushAnnotations() async {}

  @override
  void cancelSearch() {}

  @override
  Future<void> suspendViewport() async {}

  @override
  void resumeViewport() {}
}

Future<void> _openSheet(
  WidgetTester tester, {
  required OpenDocumentRenameCoordinator? coordinator,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Consumer(
          builder: (context, ref, _) => TextButton(
            onPressed: () => showReaderMoreSheet(
              context,
              ref,
              pdfPath: '/docs/a.pdf',
              renameCoordinator: coordinator,
              onAnnotations: () {},
              onPanelClosed: () {},
            ),
            child: const Text('more'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('more'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Rename is hidden when no coordinator is given (assets)', (
    tester,
  ) async {
    await _openSheet(tester, coordinator: null);

    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Rename'), findsNothing);
  });

  testWidgets('Rename is offered for a local file', (tester) async {
    final coordinator = OpenDocumentRenameCoordinator(
      host: _Host(),
      rename: ({required path, required newName}) => throw UnimplementedError(),
    );
    addTearDown(coordinator.dispose);

    await _openSheet(tester, coordinator: coordinator);

    expect(find.text('Rename'), findsOneWidget);
  });
}
