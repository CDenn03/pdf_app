import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sefer/core/models/file_status.dart';
import 'package:sefer/shared/widgets/file_actions_sheet.dart';

void main() {
  testWidgets('available entry shows Open + Share + Rename', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => ElevatedButton(
                onPressed: () => showFileActionsSheet(
                  context,
                  ref,
                  path: '/x/a.pdf',
                  name: 'a.pdf',
                  libraryEntryId: 'id1',
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

    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Rename'), findsOneWidget);
  });

  testWidgets('unavailable entry hides Open and Share', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => ElevatedButton(
                onPressed: () => showFileActionsSheet(
                  context,
                  ref,
                  path: '/x/a.pdf',
                  name: 'a.pdf',
                  libraryEntryId: 'id1',
                  status: FileStatus.missing,
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

    expect(find.text('Open'), findsNothing);
    expect(find.text('Share'), findsNothing);
    expect(find.text('Rename'), findsOneWidget);
  });

  testWidgets('optional actions appear only when enabled', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => ElevatedButton(
                onPressed: () => showFileActionsSheet(
                  context,
                  ref,
                  path: '/x/a.pdf',
                  name: 'a.pdf',
                  libraryEntryId: 'id1',
                  canSelect: true,
                  onSelect: () {},
                  removeFromCollectionId: 'c1',
                  showInFavorites: true,
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

    expect(find.text('Select'), findsOneWidget);
    expect(find.text('Remove from collection'), findsOneWidget);
    expect(find.text('Show in Favorites'), findsOneWidget);
  });
}
