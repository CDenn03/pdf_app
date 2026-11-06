import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/features/reader/domain/book_flip_machine.dart';
import 'package:sefer/features/reader/presentation/book_flip_controller.dart';

const _page = Rect.fromLTWH(100, 20, 400, 560);
const _center = Offset(300, 300);

void main() {
  late List<int> reported;
  late BookFlipController controller;

  BookFlipController create({
    int initialPage = 1,
    TextDirection direction = TextDirection.ltr,
  }) => controller = BookFlipController(
    vsync: const TestVSync(),
    totalPages: 5,
    initialPage: initialPage,
    onPageChanged: reported.add,
  )..textDirection = direction;

  bool grab([Offset at = _center]) =>
      controller.dragStart(position: at, pageBounds: _page);

  void move(Offset from, Offset by) =>
      controller.dragUpdate(position: from + by, delta: by);

  void drag(double dx, {double velocity = 0}) {
    grab();
    move(_center, Offset(dx, 0));
    controller.dragEnd(velocity: Offset(velocity, 0));
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  setUp(() => reported = []);

  tearDown(() => controller.dispose());

  group('dragging', () {
    testWidgets('progress follows the finger', (tester) async {
      create();

      grab();
      move(_center, const Offset(-100, 0));

      expect(controller.isTurning, isTrue);
      expect(controller.progress, closeTo(0.25, 1e-9));
      expect(controller.currentPage, 1);
    });

    testWidgets('releasing past the threshold turns the page once', (
      tester,
    ) async {
      create();

      drag(-200);
      await tester.pump();
      await settle(tester);
      await settle(tester);

      expect(controller.currentPage, 2);
      expect(reported, [2]);
      expect(controller.isTurning, isFalse);
      expect(controller.progress, 0);
    });

    testWidgets('releasing short of the threshold cancels silently', (
      tester,
    ) async {
      create();

      drag(-40);
      await tester.pump();
      await settle(tester);

      expect(controller.currentPage, 1);
      expect(reported, isEmpty);
      expect(controller.isTurning, isFalse);
    });

    testWidgets('a fast fling completes a short drag', (tester) async {
      create();

      drag(-40, velocity: -2000);
      await tester.pump();
      await settle(tester);

      expect(reported, [2]);
    });

    testWidgets('a fast fling back cancels a long drag', (tester) async {
      create();

      drag(-300, velocity: 2000);
      await tester.pump();
      await settle(tester);

      expect(reported, isEmpty);
      expect(controller.currentPage, 1);
    });

    testWidgets('dragging right turns back', (tester) async {
      create(initialPage: 3);

      drag(250);
      await tester.pump();
      await settle(tester);

      expect(reported, [2]);
    });

    testWidgets('right to left reading reverses the drag direction', (
      tester,
    ) async {
      create(direction: TextDirection.rtl);

      drag(250);
      await tester.pump();
      await settle(tester);

      expect(reported, [2]);
    });

    testWidgets('input is ignored while a turn settles', (tester) async {
      create();
      drag(-200);

      drag(-300);
      await tester.pump();
      await settle(tester);

      expect(controller.currentPage, 2);
      expect(reported, [2]);
    });

    testWidgets('a new drag can follow a finished one', (tester) async {
      create();
      drag(-200);
      await tester.pump();
      await settle(tester);

      drag(-200);
      await tester.pump();
      await settle(tester);

      expect(reported, [2, 3]);
    });
  });

  group('touch', () {
    testWidgets('progress is relative to the fitted page, not the viewport', (
      tester,
    ) async {
      create();

      grab();
      move(_center, const Offset(-200, 0));

      expect(controller.progress, closeTo(0.5, 1e-9));
    });

    testWidgets('the pose is page normalized and keeps full 2D velocity', (
      tester,
    ) async {
      create();

      grab();
      move(_center, const Offset(-100, 56));
      for (var i = 0; i < 30; i++) {
        controller.dragUpdate(
          position: _center + const Offset(-100, 56),
          delta: Offset.zero,
        );
      }
      final dragging = controller.pose!;
      controller.dragEnd(velocity: const Offset(-800, 560));
      final released = controller.pose!;

      expect(dragging.start, const Offset(0.5, 0.5));
      expect(dragging.current.dx, closeTo(0.25, 1e-6));
      expect(dragging.current.dy, closeTo(0.6, 1e-6));
      expect(released.velocity.dx, closeTo(-2, 1e-9));
      expect(released.velocity.dy, closeTo(1, 1e-9));
      expect(controller.pose!.turnFraction, closeTo(0.25, 1e-9));
      await tester.pump();
      await settle(tester);
      expect(controller.pose, isNull);
    });

    testWidgets('a touch outside the page is rejected', (tester) async {
      create();

      expect(grab(const Offset(50, 300)), isFalse);
      move(const Offset(50, 300), const Offset(-200, 0));

      expect(controller.isTurning, isFalse);
      expect(controller.pose, isNull);
    });

    testWidgets('a touch in the spine guard band does not turn', (
      tester,
    ) async {
      create();

      expect(grab(const Offset(105, 300)), isTrue);
      move(const Offset(105, 300), const Offset(-3, 0));
      controller.dragEnd(velocity: const Offset(-3000, 0));
      await tester.pump();
      await settle(tester);

      expect(controller.isTurning, isFalse);
      expect(reported, isEmpty);
    });

    testWidgets('the guard follows the spine in right to left reading', (
      tester,
    ) async {
      create(direction: TextDirection.rtl);

      grab(const Offset(495, 300));
      move(const Offset(495, 300), const Offset(3, 0));
      expect(controller.isTurning, isFalse);

      grab(const Offset(105, 300));
      move(const Offset(105, 300), const Offset(200, 0));
      expect(controller.isTurning, isTrue);
    });

    testWidgets('the free edge side is not guarded', (tester) async {
      create();

      grab(const Offset(495, 300));
      move(const Offset(495, 300), const Offset(-200, 0));

      expect(controller.isTurning, isTrue);
    });

    testWidgets('a touch is rejected while a turn settles', (tester) async {
      create();
      drag(-200);

      expect(grab(), isFalse);
      await tester.pump();
      await settle(tester);
    });

    testWidgets('cancel never completes, even past the threshold', (
      tester,
    ) async {
      create();

      grab();
      move(_center, const Offset(-300, 0));
      controller.dragCancel();
      await tester.pump();
      await settle(tester);

      expect(reported, isEmpty);
      expect(controller.currentPage, 1);
      expect(controller.isTurning, isFalse);
    });

    testWidgets('cancel ignores a drag that was not started', (tester) async {
      create();

      controller.dragCancel();

      expect(controller.isTurning, isFalse);
    });

    testWidgets('vertical motion never turns a page', (tester) async {
      create();

      grab();
      move(_center, const Offset(0, 200));
      controller.dragEnd(velocity: const Offset(0, -4000));
      await tester.pump();
      await settle(tester);

      expect(controller.isTurning, isFalse);
      expect(reported, isEmpty);
    });

    testWidgets('the first horizontal movement locks the direction', (
      tester,
    ) async {
      create(initialPage: 3);

      grab();
      move(_center, const Offset(-20, 0));
      move(const Offset(280, 300), const Offset(220, 0));

      expect(controller.direction, BookFlipDirection.forward);
      expect(controller.progress, 0);
    });

    testWidgets('a settling pose ends on the matching resting pose', (
      tester,
    ) async {
      create();
      drag(-200);

      expect(controller.pose!.turnFraction, closeTo(0.5, 1e-9));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(controller.pose, isNull);
    });
  });

  group('first and last page', () {
    testWidgets('dragging outwards stretches a little then returns', (
      tester,
    ) async {
      create();

      grab();
      move(_center, const Offset(300, 0));

      expect(controller.isTurning, isFalse);
      expect(controller.edgeStretch, greaterThan(0));
      expect(controller.edgeStretch, lessThan(_page.width * 0.12));

      controller.dragEnd(velocity: Offset.zero);
      await tester.pump();
      await settle(tester);

      expect(controller.edgeStretch, 0);
      expect(reported, isEmpty);
      expect(controller.currentPage, 1);
    });

    testWidgets('the last page resists forward drags the same way', (
      tester,
    ) async {
      create(initialPage: 5);

      grab();
      move(_center, const Offset(-300, 0));

      expect(controller.edgeStretch, lessThan(0));
      controller.dragEnd(velocity: Offset.zero);
      await tester.pump();
      await settle(tester);

      expect(reported, isEmpty);
    });
  });

  group('goTo', () {
    testWidgets('an adjacent page is turned with an animation', (tester) async {
      create(initialPage: 2);

      final done = controller.goTo(3);
      await tester.pump();

      expect(controller.isTurning, isTrue);
      expect(controller.currentPage, 2);

      await settle(tester);
      await done;
      expect(controller.currentPage, 3);
      expect(reported, [3]);
    });

    testWidgets('a distant page is shown at once with a short fade', (
      tester,
    ) async {
      create();

      await controller.goTo(5);

      expect(controller.currentPage, 5);
      expect(controller.isTurning, isFalse);
      expect(reported, [5]);
      expect(controller.contentOpacity, lessThan(1));

      await settle(tester);
      expect(controller.contentOpacity, 1);
    });

    testWidgets('page one is reachable after resuming further on', (
      tester,
    ) async {
      create(initialPage: 4);

      await controller.goTo(1);

      expect(controller.currentPage, 1);
      expect(reported, [1]);
      await settle(tester);
    });

    testWidgets('the current page is a no-op', (tester) async {
      create(initialPage: 2);

      await controller.goTo(2);

      expect(reported, isEmpty);
      expect(controller.isTurning, isFalse);
    });

    testWidgets('a request during a settling turn finishes it first', (
      tester,
    ) async {
      create();
      drag(-200);

      await controller.goTo(5);

      expect(reported, [2, 5]);
      expect(controller.currentPage, 5);
      await settle(tester);
    });

    testWidgets('a request while the finger is down is ignored', (
      tester,
    ) async {
      create();
      grab();
      move(_center, const Offset(-100, 0));

      await controller.goTo(4);

      expect(controller.currentPage, 1);
      expect(reported, isEmpty);
    });
  });
}
