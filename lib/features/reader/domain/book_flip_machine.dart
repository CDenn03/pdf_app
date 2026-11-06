import 'package:flutter/foundation.dart';

enum BookFlipDirection {
  forward(1),
  backward(-1);

  const BookFlipDirection(this.pageDelta);

  final int pageDelta;
}

enum BookFlipOutcome { complete, cancel }

@immutable
class BookFlipPhysics {
  const BookFlipPhysics({
    this.completionThreshold = 0.35,
    this.flingVelocity = 2.0,
    this.minimumFlingProgress = 0.08,
    this.duration = const Duration(milliseconds: 650),
  });

  final double completionThreshold;

  /// Progress per second needed to decide a release regardless of position.
  final double flingVelocity;

  /// A flick shorter than this cannot complete a turn, so a brushing touch
  /// does not flip the page.
  final double minimumFlingProgress;
  final Duration duration;

  BookFlipOutcome outcomeFor({
    required double progress,
    required double velocity,
  }) {
    if (velocity >= flingVelocity && progress >= minimumFlingProgress) {
      return BookFlipOutcome.complete;
    }
    if (velocity <= -flingVelocity) return BookFlipOutcome.cancel;
    return progress >= completionThreshold
        ? BookFlipOutcome.complete
        : BookFlipOutcome.cancel;
  }
}

@immutable
sealed class BookFlipState {
  const BookFlipState();
}

class BookFlipIdle extends BookFlipState {
  const BookFlipIdle();
}

class BookFlipDragging extends BookFlipState {
  const BookFlipDragging({required this.direction, required this.progress});

  final BookFlipDirection direction;
  final double progress;
}

class BookFlipSettling extends BookFlipState {
  const BookFlipSettling({
    required this.direction,
    required this.completing,
    required this.fromProgress,
  });

  final BookFlipDirection direction;
  final bool completing;
  final double fromProgress;
}

class BookFlipMachine {
  BookFlipMachine({this.physics = const BookFlipPhysics()});

  final BookFlipPhysics physics;
  BookFlipState _state = const BookFlipIdle();

  BookFlipState get state => _state;

  bool start(BookFlipDirection direction, {required bool canTurn}) {
    if (!canTurn || _state is! BookFlipIdle) return false;
    _state = BookFlipDragging(direction: direction, progress: 0);
    return true;
  }

  void update(double progress) {
    final current = _state;
    if (current is! BookFlipDragging) return;
    _state = BookFlipDragging(
      direction: current.direction,
      progress: progress.clamp(0.0, 1.0),
    );
  }

  BookFlipOutcome? release({double velocity = 0}) {
    final current = _state;
    if (current is! BookFlipDragging) return null;
    final outcome = physics.outcomeFor(
      progress: current.progress,
      velocity: velocity,
    );
    _state = BookFlipSettling(
      direction: current.direction,
      completing: outcome == BookFlipOutcome.complete,
      fromProgress: current.progress,
    );
    return outcome;
  }

  void cancel() => _settleAs(completing: false);

  /// Settles the current drag as a completed turn, for programmatic turns.
  void complete() => _settleAs(completing: true);

  void _settleAs({required bool completing}) {
    final current = _state;
    if (current is! BookFlipDragging) return;
    _state = BookFlipSettling(
      direction: current.direction,
      completing: completing,
      fromProgress: current.progress,
    );
  }

  /// Returns the page delta to commit, or null when the turn was cancelled
  /// or none was settling.
  int? finish() {
    final current = _state;
    if (current is! BookFlipSettling) return null;
    _state = const BookFlipIdle();
    return current.completing ? current.direction.pageDelta : null;
  }
}
