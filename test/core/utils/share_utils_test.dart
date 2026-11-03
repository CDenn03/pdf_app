import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sefer/core/utils/share_utils.dart';

/// Opens the rename dialog and returns whatever it resolves to.
Future<String?> runDialog(
  WidgetTester tester, {
  required String currentName,
  String? type,
  bool cancel = false,
}) async {
  String? result;
  var captured = false;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showRenameDialog(
                context,
                currentName: currentName,
              );
              captured = true;
            },
            child: const Text('go'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('go'));
  await tester.pumpAndSettle();

  if (type != null) {
    await tester.enterText(find.byType(TextField), type);
  }
  // Both the dialog title and its confirm button read "Rename", so the
  // button has to be addressed by widget type.
  await tester.tap(
    cancel
        ? find.widgetWithText(TextButton, 'Cancel')
        : find.widgetWithText(FilledButton, 'Rename'),
  );
  await tester.pumpAndSettle();

  expect(captured, isTrue, reason: 'the dialog never resolved');
  return result;
}

void main() {
  group('showRenameDialog', () {
    testWidgets('returns the stem with no extension appended', (tester) async {
      final result = await runDialog(
        tester,
        currentName: 'Report.pdf',
        type: 'Quarterly Report',
      );

      // Extension policy belongs to FileMutator.rename, not to the dialog.
      expect(result, 'Quarterly Report');
    });

    testWidgets('strips only a trailing .pdf, not one mid-name', (
      tester,
    ) async {
      String? seeded;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showRenameDialog(
                  context,
                  // The old implementation used a global
                  // replaceAll('.pdf', ''), which struck the middle
                  // occurrence too and came back as 'report.backup'.
                  currentName: 'report.pdf.backup.pdf',
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      seeded = tester.widget<TextField>(find.byType(TextField)).controller!.text;
      expect(seeded, 'report.pdf.backup');
    });

    testWidgets('is case-insensitive about the extension', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showRenameDialog(
                  context,
                  currentName: 'SCAN.PDF',
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      final seeded = tester
          .widget<TextField>(find.byType(TextField))
          .controller!
          .text;
      expect(seeded, 'SCAN');
    });

    testWidgets('returns null when cancelled', (tester) async {
      final result = await runDialog(
        tester,
        currentName: 'Report.pdf',
        type: 'Something',
        cancel: true,
      );

      expect(result, isNull);
    });

    testWidgets('returns null for an empty or whitespace-only name', (
      tester,
    ) async {
      final result = await runDialog(
        tester,
        currentName: 'Report.pdf',
        type: '   ',
      );

      // Confirming an empty field must not be read as "rename to .pdf".
      expect(result, isNull);
    });

    testWidgets('trims surrounding whitespace', (tester) async {
      final result = await runDialog(
        tester,
        currentName: 'Report.pdf',
        type: '  Tidy Name  ',
      );

      expect(result, 'Tidy Name');
    });

    testWidgets('leaves a name with no extension alone', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showRenameDialog(
                  context,
                  currentName: 'Untitled',
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      final seeded = tester
          .widget<TextField>(find.byType(TextField))
          .controller!
          .text;
      expect(seeded, 'Untitled');
    });
  });
}
