import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/features/reader/presentation/page_controller_navigation.dart';

void main() {
  const totalPages = 6;
  late PageController controller;
  late PageControllerNavigation navigation;

  setUp(() {
    controller = PageController();
    navigation = PageControllerNavigation(
      controller: controller,
      totalPages: totalPages,
    );
  });

  tearDown(() => controller.dispose());

  final builtIndices = <int>[];

  Future<void> attachPager(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: PageView.builder(
        controller: controller,
        itemCount: totalPages,
        itemBuilder: (_, index) {
          builtIndices.add(index);
          return Text('index $index');
        },
      ),
    ),
  );

  Future<void> goTo(WidgetTester tester, int pageNumber) async {
    unawaited(navigation.goToPage(pageNumber));
    await tester.pumpAndSettle();
  }

  group('while unattached', () {
    test('reports page 1', () {
      expect(navigation.currentPage, 1);
    });

    test('ignores navigation requests', () async {
      await navigation.goToPage(4);

      expect(controller.hasClients, isFalse);
    });
  });

  group('while attached', () {
    testWidgets('converts a one-based request to the zero-based index', (
      tester,
    ) async {
      await attachPager(tester);

      await goTo(tester, 4);

      expect(controller.page, 3);
      expect(navigation.currentPage, 4);
    });

    testWidgets('clamps a request below the first page', (tester) async {
      await attachPager(tester);
      await goTo(tester, 3);

      await goTo(tester, 0);

      expect(navigation.currentPage, 1);
    });

    testWidgets('clamps a request beyond the last page', (tester) async {
      await attachPager(tester);

      await goTo(tester, 99);

      expect(navigation.currentPage, totalPages);
    });

    testWidgets('reports the one-based page of a resumed pager', (
      tester,
    ) async {
      controller.dispose();
      controller = PageController(initialPage: 2);
      navigation = PageControllerNavigation(
        controller: controller,
        totalPages: totalPages,
      );
      await attachPager(tester);

      expect(navigation.currentPage, 3);
    });

    testWidgets('jumps over a distance of more than one page', (tester) async {
      await attachPager(tester);
      builtIndices.clear();

      await goTo(tester, 5);

      expect(builtIndices.toSet(), isNot(containsAll([1, 2, 3])));
      expect(navigation.currentPage, 5);
    });

    testWidgets('animates a request instead of jumping', (tester) async {
      await attachPager(tester);

      unawaited(navigation.goToPage(2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(controller.page, allOf(greaterThan(0), lessThan(1)));
      await tester.pumpAndSettle();
      expect(controller.page, 1);
    });
  });
}
