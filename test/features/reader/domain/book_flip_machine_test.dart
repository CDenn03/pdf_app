import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/features/reader/domain/book_flip_machine.dart';

const _forward = BookFlipDirection.forward;

BookFlipMachine _dragging(double progress, {BookFlipDirection? direction}) {
  final machine = BookFlipMachine();
  machine.start(direction ?? _forward, canTurn: true);
  machine.update(progress);
  return machine;
}

void main() {
  group('start', () {
    test('begins dragging at zero progress', () {
      final machine = BookFlipMachine();

      expect(machine.start(_forward, canTurn: true), isTrue);

      final state = machine.state as BookFlipDragging;
      expect(state.direction, _forward);
      expect(state.progress, 0);
    });

    test('is rejected at a document boundary', () {
      final machine = BookFlipMachine();

      expect(machine.start(_forward, canTurn: false), isFalse);
      expect(machine.state, isA<BookFlipIdle>());
    });

    test('is rejected while a turn is dragging or settling', () {
      final machine = _dragging(0.5);
      expect(machine.start(BookFlipDirection.backward, canTurn: true), isFalse);

      machine.release();
      expect(machine.start(_forward, canTurn: true), isFalse);
      expect(machine.state, isA<BookFlipSettling>());
    });
  });

  group('update', () {
    test('clamps progress into 0..1', () {
      final machine = _dragging(0);

      machine.update(1.7);
      expect((machine.state as BookFlipDragging).progress, 1);

      machine.update(-0.4);
      expect((machine.state as BookFlipDragging).progress, 0);
    });

    test('is ignored when not dragging', () {
      final machine = BookFlipMachine();

      machine.update(0.5);

      expect(machine.state, isA<BookFlipIdle>());
    });
  });

  group('release', () {
    test('completes past the threshold', () {
      final machine = _dragging(0.4);

      expect(machine.release(), BookFlipOutcome.complete);
    });

    test('cancels below the threshold', () {
      final machine = _dragging(0.3);

      expect(machine.release(), BookFlipOutcome.cancel);
    });

    test('a fast fling forward completes even from a short drag', () {
      final machine = _dragging(0.1);

      expect(machine.release(velocity: 2), BookFlipOutcome.complete);
    });

    test('a fast flick from a brushing touch does not turn the page', () {
      final machine = _dragging(0.05);

      expect(machine.release(velocity: 5), BookFlipOutcome.cancel);
    });

    test('a programmatic complete settles as a completed turn', () {
      final machine = _dragging(0)..complete();

      expect(machine.finish(), BookFlipDirection.forward.pageDelta);
    });

    test('a fast fling back cancels even from a long drag', () {
      final machine = _dragging(0.9);

      expect(machine.release(velocity: -2), BookFlipOutcome.cancel);
    });

    test('settles from the released progress', () {
      final machine = _dragging(0.6);

      machine.release();

      final state = machine.state as BookFlipSettling;
      expect(state.completing, isTrue);
      expect(state.fromProgress, 0.6);
      expect(state.direction, _forward);
    });

    test('does nothing unless dragging', () {
      final machine = BookFlipMachine();

      expect(machine.release(), isNull);
      expect(machine.state, isA<BookFlipIdle>());
    });
  });

  group('finish', () {
    test('commits one page forward after a completed turn', () {
      final machine = _dragging(0.8)..release();

      expect(machine.finish(), 1);
      expect(machine.state, isA<BookFlipIdle>());
    });

    test('commits one page back for a backward turn', () {
      final machine = _dragging(0.8, direction: BookFlipDirection.backward)
        ..release();

      expect(machine.finish(), -1);
    });

    test('commits nothing for a cancelled turn', () {
      final machine = _dragging(0.1)..release();

      expect(machine.finish(), isNull);
      expect(machine.state, isA<BookFlipIdle>());
    });

    test('commits nothing when no turn is settling', () {
      final machine = _dragging(0.9);

      expect(machine.finish(), isNull);
      expect(machine.state, isA<BookFlipDragging>());
    });

    test('allows a new turn afterwards', () {
      final machine = _dragging(0.8)..release();
      machine.finish();

      expect(machine.start(_forward, canTurn: true), isTrue);
    });
  });

  group('cancel', () {
    test('settles back even past the completion threshold', () {
      final machine = _dragging(0.9)..cancel();

      final state = machine.state as BookFlipSettling;
      expect(state.completing, isFalse);
      expect(state.fromProgress, 0.9);
      expect(machine.finish(), isNull);
    });

    test('does nothing when not dragging', () {
      final machine = BookFlipMachine()..cancel();

      expect(machine.state, isA<BookFlipIdle>());
    });
  });

  test('custom physics change the completion threshold', () {
    final machine = BookFlipMachine(
      physics: const BookFlipPhysics(completionThreshold: 0.8),
    );
    machine.start(_forward, canTurn: true);
    machine.update(0.7);

    expect(machine.release(), BookFlipOutcome.cancel);
  });
}
