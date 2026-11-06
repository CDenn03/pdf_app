import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/features/reader/domain/book_flip_machine.dart';
import 'package:sefer/features/reader/presentation/book_flip_controller.dart';
import 'package:sefer/features/reader/presentation/book_flip_interaction.dart';
import 'package:sefer/features/reader/presentation/book_flip_trajectory.dart';

const _page = Rect.fromLTWH(100, 20, 400, 560);
const _duration = Duration(milliseconds: 300);

BookFlipPose _pose(Offset current, {Offset velocity = Offset.zero}) =>
    BookFlipPose(
      start: const Offset(0.8, 0.2),
      current: current,
      velocity: velocity,
      turnFraction: 0.4,
    );

BookFlipPose _target(Offset current, double fraction) => BookFlipPose(
  start: const Offset(0.8, 0.2),
  current: current,
  velocity: Offset.zero,
  turnFraction: fraction,
);

void main() {
  group('BookFlipTrajectory', () {
    test('starts at the release pose with its velocity', () {
      final release = _pose(
        const Offset(0.4, 0.5),
        velocity: const Offset(-1, 0.5),
      );
      final path = BookFlipTrajectory.from(
        release: release,
        target: _target(const Offset(-1.2, 0.2), 1),
        duration: _duration,
      );

      final first = path.poseAt(0);

      expect(first.current, release.current);
      expect(first.turnFraction, release.turnFraction);
      expect(first.velocity.dx, closeTo(-1, 1e-9));
      expect(first.velocity.dy, closeTo(0.5, 1e-9));
    });

    test('a cancel returns to the start and unwinds the twist', () {
      final path = BookFlipTrajectory.from(
        release: _pose(const Offset(0.3, 0.7)),
        target: _target(const Offset(0.8, 0.2), 0),
        duration: _duration,
      );

      final last = path.poseAt(1);

      expect(last.current, const Offset(0.8, 0.2));
      expect(last.turnFraction, 0);
      expect(last.velocity, Offset.zero);
    });

    test('a completion ends beyond the opposite edge at the grab height', () {
      final path = BookFlipTrajectory.from(
        release: _pose(const Offset(0.3, 0.7)),
        target: _target(const Offset(-1.2, 0.2), 1),
        duration: _duration,
      );

      final last = path.poseAt(1);

      expect(last.current, const Offset(-1.2, 0.2));
      expect(last.current.dy, last.start.dy);
      expect(last.turnFraction, 1);
    });

    test('a fast release cannot overshoot beyond twice the distance', () {
      final path = BookFlipTrajectory.from(
        release: _pose(const Offset(0.3, 0.5), velocity: const Offset(-500, 0)),
        target: _target(const Offset(0.8, 0.5), 0),
        duration: _duration,
      );

      for (var t = 0.0; t <= 1; t += 0.05) {
        expect(path.poseAt(t).current.dx, inInclusiveRange(-1.5, 1.5));
      }
    });
  });

  group('BookFlipController settle', () {
    late List<int> reported;
    late BookFlipController controller;

    BookFlipController create({TextDirection direction = TextDirection.ltr}) =>
        controller = BookFlipController(
          vsync: const TestVSync(),
          totalPages: 5,
          initialPage: 2,
          onPageChanged: reported.add,
        )..textDirection = direction;

    setUp(() => reported = []);
    tearDown(() => controller.dispose());

    void dragFrom(Offset start, Offset by, {Offset? velocity}) {
      controller.dragStart(position: start, pageBounds: _page);
      controller.dragUpdate(position: start + by, delta: by);
      controller.dragEnd(velocity: velocity ?? Offset.zero);
    }

    testWidgets('the first settle frame continues from the release', (
      tester,
    ) async {
      create();
      controller.dragStart(position: const Offset(400, 80), pageBounds: _page);
      controller.dragUpdate(
        position: const Offset(250, 300),
        delta: const Offset(-150, 220),
      );
      final released = controller.pose!;

      controller.dragEnd(velocity: const Offset(-400, 100));
      final first = controller.pose!;

      expect(first.current.dx, closeTo(released.current.dx, 1e-9));
      expect(first.current.dy, closeTo(released.current.dy, 1e-9));
      expect(first.start, released.start);
      expect(first.turnFraction, closeTo(released.turnFraction, 1e-9));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('the twist unwinds before the page is reported', (
      tester,
    ) async {
      create();
      dragFrom(
        const Offset(400, 80),
        const Offset(-100, 300),
        velocity: const Offset(-2000, 0),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final midway = controller.pose!;
      expect(reported, isEmpty);

      await tester.pump(const Duration(seconds: 1));

      expect(midway.current.dy, isNot(midway.start.dy));
      expect(reported, [3]);
      expect(controller.pose, isNull);
    });

    testWidgets('a settle ends flat at the grab height', (tester) async {
      create();
      dragFrom(
        const Offset(400, 80),
        const Offset(-100, 300),
        velocity: const Offset(-2000, 0),
      );
      await tester.pump();

      var late = controller.pose!;
      while (controller.pose != null) {
        late = controller.pose!;
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(late.current.dy, closeTo(late.start.dy, 0.05));
      expect(late.turnFraction, lessThanOrEqualTo(1));
    });

    testWidgets('a cancel settles back onto the grab', (tester) async {
      create();
      dragFrom(const Offset(400, 80), const Offset(-30, 40));
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 100));
      final partway = controller.pose!;
      await tester.pump(const Duration(seconds: 1));

      expect(partway.turnFraction, lessThan(0.1));
      expect(reported, isEmpty);
      expect(controller.currentPage, 2);
    });

    testWidgets('a programmatic turn grabs the free edge centre', (
      tester,
    ) async {
      create();
      final turn = controller.goTo(3);

      expect(controller.pose!.start, const Offset(1, 0.5));
      expect(controller.pose!.velocity, Offset.zero);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await turn;
      expect(reported, [3]);
    });

    testWidgets('a programmatic turn back grabs the left edge centre', (
      tester,
    ) async {
      create();
      final turn = controller.goTo(1);

      expect(controller.pose!.start, const Offset(0, 0.5));
      expect(controller.state, isA<BookFlipSettling>());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await turn;
      expect(reported, [1]);
    });

    testWidgets('right to left grabs the right edge going back', (
      tester,
    ) async {
      create(direction: TextDirection.rtl);
      final turn = controller.goTo(1);

      expect(controller.pose!.start, const Offset(1, 0.5));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await turn;
    });
  });
}
