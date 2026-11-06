import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sefer/core/constants.dart';
import 'package:sefer/core/models/file_status.dart';
import 'package:sefer/core/providers.dart';
import 'package:sefer/core/services/file_service.dart';
import 'package:sefer/shared/widgets/file_actions_sheet.dart';

/// Fails every mutation with a fixed reason.
///
/// The real [FileService] is exercised by its own tests; using it here would
/// make these cases depend on dart:io futures, which do not complete inside
/// `pumpAndSettle`'s fake-async zone. What this file is testing is whether
/// the sheet calls the orchestration and surfaces its result.
class _RefusingMutator implements FileMutator {
  const _RefusingMutator(this.reason);

  final FileOperationReason reason;

  @override
  Future<String> rename(String path, String newName) async =>
      throw FileOperationException(reason, 'refused');

  @override
  Future<void> delete(String path) async =>
      throw FileOperationException(reason, 'refused');
}

/// Pumps a button that opens the sheet, then opens it.
Future<void> openSheet(
  WidgetTester tester, {
  String path = '/x/a.pdf',
  String name = 'a.pdf',
  String? libraryEntryId = 'id1',
  bool canRename = true,
  bool canSelect = false,
  String? removeFromCollectionId,
  bool showInFavorites = false,
  FileStatus status = FileStatus.ok,
  Size? surfaceSize,
  FileMutator? mutator,
}) async {
  if (surfaceSize != null) {
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (mutator != null) fileMutatorProvider.overrideWithValue(mutator),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => ElevatedButton(
              onPressed: () => showFileActionsSheet(
                context,
                ref,
                path: path,
                name: name,
                libraryEntryId: libraryEntryId,
                canRename: canRename,
                canSelect: canSelect,
                onSelect: canSelect ? () {} : null,
                removeFromCollectionId: removeFromCollectionId,
                showInFavorites: showInFavorites,
                status: status,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('available entry shows Open + Share + Rename', (tester) async {
    await openSheet(tester);

    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Rename'), findsOneWidget);
  });

  testWidgets('unavailable entry hides Open, Share and Rename', (tester) async {
    await openSheet(tester, status: FileStatus.missing);

    expect(find.text('Open'), findsNothing);
    expect(find.text('Share'), findsNothing);
    // Rename is hidden rather than offered-and-failing: there is no file on
    // disk to rename, so the action could only ever report an error.
    expect(find.text('Rename'), findsNothing);
  });

  testWidgets('unavailable entry still offers Remove from library', (
    tester,
  ) async {
    await openSheet(tester, status: FileStatus.missing);

    // A missing file is precisely the library row you most want to clear,
    // so this one does NOT depend on availability.
    expect(find.text('Remove from library'), findsOneWidget);
  });

  testWidgets('optional actions appear only when enabled', (tester) async {
    await openSheet(
      tester,
      canSelect: true,
      removeFromCollectionId: 'c1',
      showInFavorites: true,
    );

    expect(find.text('Select'), findsOneWidget);
    expect(find.text('Remove from collection'), findsOneWidget);
    expect(find.text('Show in Favorites'), findsOneWidget);
  });

  testWidgets('library entry offers both Remove from library and Delete', (
    tester,
  ) async {
    await openSheet(tester);

    expect(find.text('Remove from library'), findsOneWidget);
    expect(find.text('Delete file'), findsOneWidget);
    // The two are distinguished on the sheet itself, not only in the
    // confirmation, because that is where the user chooses between them.
    expect(find.text('Keeps the file on your device'), findsOneWidget);
    expect(find.text('Removes it from your device'), findsOneWidget);
  });

  testWidgets('Delete is offered for a file with no library entry', (
    tester,
  ) async {
    await openSheet(tester, libraryEntryId: null);

    // Reachable from the Device tab, where nothing has been added yet.
    expect(find.text('Delete file'), findsOneWidget);
    expect(find.text('Rename'), findsOneWidget);
    // Nothing to remove from, so this one is absent.
    expect(find.text('Remove from library'), findsNothing);
  });

  testWidgets('bundled sample hides Rename, Remove and Delete', (tester) async {
    await openSheet(tester, path: kSamplePdfPath, name: 'sample.pdf');

    // It is an asset, not a file on disk: all three would fail.
    expect(find.text('Rename'), findsNothing);
    expect(find.text('Remove from library'), findsNothing);
    expect(find.text('Delete file'), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('Delete asks for confirmation naming the file', (tester) async {
    await openSheet(tester, name: 'Quarterly Report.pdf');

    await tester.tap(find.text('Delete file'));
    await tester.pumpAndSettle();

    expect(find.text('Delete file?'), findsOneWidget);
    expect(
      find.textContaining('"Quarterly Report.pdf"'),
      findsOneWidget,
      reason: 'the confirmation must name the file being destroyed',
    );
    expect(find.textContaining('cannot be undone'), findsOneWidget);
  });

  testWidgets('cancelling the Delete confirmation deletes nothing', (
    tester,
  ) async {
    await openSheet(tester);

    await tester.tap(find.text('Delete file'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // No outcome is reported, because no action ran.
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('confirming Delete runs the action and reports the outcome', (
    tester,
  ) async {
    await openSheet(
      tester,
      mutator: const _RefusingMutator(FileOperationReason.notFound),
    );

    await tester.tap(find.text('Delete file'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    // Proves the sheet is wired to the orchestration and surfaces its
    // result, rather than swallowing a failed delete silently.
    expect(find.text('That file is no longer on the device.'), findsOneWidget);
  });

  testWidgets('a failed rename is reported rather than swallowed', (
    tester,
  ) async {
    await openSheet(
      tester,
      mutator: const _RefusingMutator(FileOperationReason.nameTaken),
    );

    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'taken-name');
    await tester.tap(find.widgetWithText(FilledButton, 'Rename'));
    await tester.pumpAndSettle();

    expect(
      find.text('A file with that name already exists in the same folder.'),
      findsOneWidget,
    );
  });

  testWidgets('cancelling the rename dialog does nothing', (tester) async {
    await openSheet(
      tester,
      mutator: const _RefusingMutator(FileOperationReason.nameTaken),
    );

    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    // No rename attempted, so no outcome reported.
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('sheet scrolls when every action is present', (tester) async {
    // Eight actions overflow a short viewport; without a scroll view this
    // throws a RenderFlex overflow instead of letting the user reach Delete.
    await openSheet(
      tester,
      canSelect: true,
      removeFromCollectionId: 'c1',
      showInFavorites: true,
      surfaceSize: const Size(400, 420),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    expect(find.text('Delete file'), findsOneWidget);
  });
}
