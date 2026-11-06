import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sefer/core/models/file_status.dart';
import 'package:sefer/core/theme/app_theme.dart';
import 'package:sefer/features/device/presentation/device_empty_states.dart';
import 'package:sefer/features/device/presentation/device_selection_bar.dart';
import 'package:sefer/features/device/presentation/device_tile.dart';
import 'package:sefer/features/device/domain/device_pdf_entry.dart';

Widget _host(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );
}

DevicePdfEntry _entry() => const DevicePdfEntry(
  name: 'a.pdf',
  path: '/d/a.pdf',
  status: FileStatus.ok,
);

void main() {
  group('DeviceEmptyState', () {
    testWidgets('permission denied variant', (tester) async {
      await tester.pumpWidget(
        _host(DeviceEmptyState(permissionDenied: true, onScan: () {})),
      );
      expect(find.text('Storage permission required'), findsOneWidget);
      expect(find.text('Grant Permission'), findsOneWidget);
    });

    testWidgets('no-files variant with scan callback', (tester) async {
      var scanned = false;
      await tester.pumpWidget(
        _host(
          DeviceEmptyState(
            permissionDenied: false,
            onScan: () => scanned = true,
          ),
        ),
      );
      expect(find.text('No PDFs found on device'), findsOneWidget);
      await tester.tap(find.text('Scan Again'));
      expect(scanned, isTrue);
    });
  });

  testWidgets('DeviceScanningState shows progress + label', (tester) async {
    await tester.pumpWidget(_host(const DeviceScanningState()));
    expect(find.text('Scanning device…'), findsOneWidget);
  });

  group('DeviceSelectionHeader', () {
    testWidgets('shows count and toggles all', (tester) async {
      var toggled = false;
      await tester.pumpWidget(
        _host(
          DeviceSelectionHeader(
            count: 2,
            allVisibleSelected: false,
            onToggleAll: () => toggled = true,
          ),
        ),
      );
      expect(find.text('2 selected'), findsOneWidget);
      await tester.tap(find.byType(Checkbox));
      expect(toggled, isTrue);
    });

    testWidgets('empty selection shows prompt', (tester) async {
      await tester.pumpWidget(
        _host(
          DeviceSelectionHeader(
            count: 0,
            allVisibleSelected: false,
            onToggleAll: () {},
          ),
        ),
      );
      expect(find.text('Select files'), findsOneWidget);
    });
  });

  group('DeviceTile', () {
    testWidgets('tap toggles via onTap in selecting mode', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          DeviceTile(
            entry: _entry(),
            inLibrary: false,
            isSelected: false,
            selecting: true,
            onTap: () => taps++,
          ),
        ),
      );
      expect(find.byType(Checkbox), findsOneWidget);
      await tester.tap(find.byType(Checkbox));
      expect(taps, 1);
    });

    testWidgets('non-selecting shows inLibrary check', (tester) async {
      await tester.pumpWidget(
        _host(
          DeviceTile(
            entry: _entry(),
            inLibrary: true,
            isSelected: false,
            selecting: false,
            onTap: () {},
          ),
        ),
      );
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
    });
  });
}
