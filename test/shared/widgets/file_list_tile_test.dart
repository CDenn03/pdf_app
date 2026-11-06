import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sefer/core/theme/app_theme.dart';
import 'package:sefer/shared/widgets/file_list_tile.dart';

Widget _host(Widget child, {Brightness brightness = Brightness.light}) {
  return MaterialApp(
    theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('renders title and subtitle', (tester) async {
    await tester.pumpWidget(
      _host(const FileListTile(title: 'Book.pdf', subtitle: 'Favorite')),
    );
    expect(find.text('Book.pdf'), findsOneWidget);
    expect(find.text('Favorite'), findsOneWidget);
    expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
  });

  testWidgets('unavailable shows unavailable label, hides subtitle', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const FileListTile(
          title: 'Gone.pdf',
          subtitle: 'Favorite',
          unavailable: true,
        ),
      ),
    );
    expect(find.text('File unavailable'), findsOneWidget);
    expect(find.text('Favorite'), findsNothing);
  });

  testWidgets('invokes tap and long-press', (tester) async {
    var tapped = false;
    var longPressed = false;
    await tester.pumpWidget(
      _host(
        FileListTile(
          title: 'Book.pdf',
          onTap: () => tapped = true,
          onLongPress: () => longPressed = true,
        ),
      ),
    );
    await tester.tap(find.byType(FileListTile));
    await tester.longPress(find.byType(FileListTile));
    expect(tapped, isTrue);
    expect(longPressed, isTrue);
  });

  testWidgets('leadingOverride replaces gradient icon', (tester) async {
    await tester.pumpWidget(
      _host(
        const FileListTile(
          title: 'Book.pdf',
          leadingOverride: Icon(Icons.check_box),
        ),
      ),
    );
    expect(find.byIcon(Icons.check_box), findsOneWidget);
    expect(find.byIcon(Icons.picture_as_pdf_outlined), findsNothing);
  });

  testWidgets('renders trailing widget', (tester) async {
    await tester.pumpWidget(
      _host(
        const FileListTile(title: 'Book.pdf', trailing: Icon(Icons.favorite)),
      ),
    );
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });
}
