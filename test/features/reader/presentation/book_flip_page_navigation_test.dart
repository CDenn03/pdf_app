import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/features/reader/presentation/book_flip_controller.dart';
import 'package:sefer/features/reader/presentation/book_flip_page_navigation.dart';

void main() {
  late List<int> reported;
  late BookFlipController controller;
  late BookFlipPageNavigation navigation;

  setUp(() {
    reported = [];
    controller = BookFlipController(
      vsync: const TestVSync(),
      totalPages: 5,
      initialPage: 2,
      onPageChanged: reported.add,
    );
    navigation = BookFlipPageNavigation(controller: controller, totalPages: 5);
  });

  tearDown(() => controller.dispose());

  testWidgets('reports the controller page', (tester) async {
    expect(navigation.currentPage, 2);
  });

  testWidgets('clamps requests to the document', (tester) async {
    await navigation.goToPage(99);
    expect(navigation.currentPage, 5);

    await navigation.goToPage(-3);
    expect(navigation.currentPage, 1);
    expect(reported, [5, 1]);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('the current page is a no-op', (tester) async {
    await navigation.goToPage(2);

    expect(reported, isEmpty);
  });

  testWidgets('an adjacent page animates a single turn', (tester) async {
    final done = navigation.goToPage(3);
    await tester.pump();
    expect(controller.isTurning, isTrue);

    await tester.pump(const Duration(seconds: 1));
    await done;
    expect(reported, [3]);
  });

  testWidgets('does nothing once the controller is disposed', (tester) async {
    controller.dispose();

    await navigation.goToPage(4);

    expect(reported, isEmpty);
    controller = BookFlipController(
      vsync: const TestVSync(),
      totalPages: 5,
      initialPage: 1,
      onPageChanged: reported.add,
    );
  });
}
