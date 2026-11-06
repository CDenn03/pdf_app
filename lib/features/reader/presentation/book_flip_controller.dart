import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:sefer/features/reader/domain/book_flip_machine.dart';
import 'package:sefer/features/reader/domain/page_range.dart';
import 'package:sefer/features/reader/presentation/book_flip_interaction.dart';
import 'package:sefer/features/reader/presentation/book_flip_trajectory.dart';

/// Drives one page turn at a time: drag, settle, and page changes. Reports a
/// new one-based page exactly once per completed turn or jump.
class BookFlipController extends ChangeNotifier {
  BookFlipController({
    required TickerProvider vsync,
    required int totalPages,
    required int initialPage,
    required ValueChanged<int> onPageChanged,
    BookFlipPhysics physics = const BookFlipPhysics(),
  }) : _range = PageRange(totalPages),
       _onPageChanged = onPageChanged,
       _machine = BookFlipMachine(physics: physics),
       _page = PageRange(totalPages).clamp(initialPage),
       _turn = AnimationController(vsync: vsync),
       _fade = AnimationController(
         vsync: vsync,
         duration: _jumpFadeDuration,
         value: 1,
       ) {
    _turn.addListener(notifyListeners);
    _fade.addListener(notifyListeners);
  }

  static const _jumpFadeDuration = Duration(milliseconds: 150);
  static const _jumpFadeFloor = 0.25;
  static const _edgeReturnDuration = Duration(milliseconds: 200);
  static const _edgeStretchFraction = 0.12;
  static const _minimumSettle = Duration(milliseconds: 280);
  static const _touchSmoothing = 0.45;
  static const _spineGuard = 0.04;
  static const _goToGrab = 0.5;
  static const _completeOvershoot = 2.0;

  final PageRange _range;
  final ValueChanged<int> _onPageChanged;
  final BookFlipMachine _machine;
  final AnimationController _turn;
  final AnimationController _fade;
  int _page;
  bool _dragging = false;
  double _dragOffset = 0;
  Rect _pageBounds = Rect.zero;
  Offset _start = Offset.zero;
  Offset _current = Offset.zero;
  BookFlipPose? _release;
  BookFlipTrajectory? _trajectory;
  double _edgeAtRelease = 0;
  bool _returningFromEdge = false;
  bool _disposed = false;
  Completer<void>? _settled;

  TextDirection textDirection = TextDirection.ltr;

  int get currentPage => _page;
  bool get isActive => !_disposed;
  BookFlipState get state => _machine.state;
  bool get isTurning => _machine.state is! BookFlipIdle;

  BookFlipDirection? get direction => switch (_machine.state) {
    BookFlipDragging(:final direction) => direction,
    BookFlipSettling(:final direction) => direction,
    BookFlipIdle() => null,
  };

  double get progress => switch (_machine.state) {
    BookFlipDragging(:final progress) => progress,
    BookFlipSettling() => _settledProgress,
    BookFlipIdle() => 0,
  };

  /// Opacity of the page content while a long jump fades in.
  double get contentOpacity => _fade.value;

  /// Horizontal displacement, in the drag's own units, of a page pulled
  /// against the first or last page.
  double get edgeStretch =>
      _returningFromEdge ? _edgeAtRelease * _turn.value : _edgeAtRelease;

  BookFlipPose? get pose => switch (_machine.state) {
    BookFlipIdle() => null,
    BookFlipDragging(:final progress) => BookFlipPose(
      start: _start,
      current: _current,
      velocity: Offset.zero,
      turnFraction: progress,
    ),
    BookFlipSettling() => _settlePose(),
  };

  /// Returns whether the touch can begin a turn. A rejected touch is ignored
  /// by every later drag call.
  bool dragStart({required Offset position, required Rect pageBounds}) {
    _dragging =
        !isTurning &&
        !_returningFromEdge &&
        !pageBounds.isEmpty &&
        pageBounds.contains(position);
    if (!_dragging) return false;
    _pageBounds = pageBounds;
    _start = _current = _normalize(position);
    _dragOffset = 0;
    _edgeAtRelease = 0;
    return true;
  }

  void dragUpdate({required Offset position, required Offset delta}) {
    if (!_dragging) return;
    _dragOffset += delta.dx;
    _current = Offset.lerp(_current, _normalize(position), _touchSmoothing)!;
    final toward = _towardForward(_dragOffset);
    if (_machine.state is BookFlipIdle && toward != 0) {
      final direction = toward > 0
          ? BookFlipDirection.forward
          : BookFlipDirection.backward;
      if (_touchesSpine(direction)) return _abandonDrag();
      _startAt(direction);
    }
    final current = _machine.state;
    if (current is BookFlipDragging) {
      final along = current.direction == BookFlipDirection.forward
          ? toward
          : -toward;
      _machine.update(along / _pageBounds.width);
      _edgeAtRelease = 0;
    } else {
      _edgeAtRelease = _resisted(_dragOffset, _pageBounds.width);
    }
    notifyListeners();
  }

  void dragEnd({required Offset velocity}) {
    if (!_dragging) return;
    _dragging = false;
    final current = _machine.state;
    if (current is! BookFlipDragging) return _returnFromEdge();
    final normalized = Offset(
      velocity.dx / _pageBounds.width,
      velocity.dy / _pageBounds.height,
    );
    final along = current.direction == BookFlipDirection.forward
        ? _towardForward(normalized.dx)
        : -_towardForward(normalized.dx);
    _release = BookFlipPose(
      start: _start,
      current: _current,
      velocity: normalized,
      turnFraction: current.progress,
    );
    final outcome = _machine.release(velocity: along);
    _settle(complete: outcome == BookFlipOutcome.complete);
  }

  /// Ends the touch without turning, however far it had gone.
  void dragCancel() {
    if (!_dragging) return;
    _dragging = false;
    final current = _machine.state;
    if (current is! BookFlipDragging) return _returnFromEdge();
    _release = BookFlipPose(
      start: _start,
      current: _current,
      velocity: Offset.zero,
      turnFraction: current.progress,
    );
    _machine.cancel();
    _settle(complete: false);
  }

  Future<void> goTo(int pageNumber) async {
    if (_disposed || _machine.state is BookFlipDragging) return;
    if (_machine.state is BookFlipSettling) _snapToEnd();
    final target = _range.clamp(pageNumber);
    if (target == _page) return;
    if ((target - _page).abs() == 1) {
      final turn = target > _page
          ? BookFlipDirection.forward
          : BookFlipDirection.backward;
      if (!_startAt(turn)) return;
      _grabFreeEdge(turn);
      _machine.complete();
      await _settle(complete: true);
    } else {
      _jumpTo(target);
    }
  }

  bool _startAt(BookFlipDirection direction) {
    final canTurn = direction == BookFlipDirection.forward
        ? _page < _range.totalPages
        : _page > 1;
    return _machine.start(direction, canTurn: canTurn);
  }

  void _grabFreeEdge(BookFlipDirection direction) {
    final freeX = bookFlipFreeEdgeIsRight(direction, textDirection) ? 1.0 : 0.0;
    _start = _current = Offset(freeX, _goToGrab);
    _release = BookFlipPose(
      start: _start,
      current: _current,
      velocity: Offset.zero,
      turnFraction: 0,
    );
  }

  Offset _normalize(Offset position) => Offset(
    (position.dx - _pageBounds.left) / _pageBounds.width,
    (position.dy - _pageBounds.top) / _pageBounds.height,
  );

  bool _touchesSpine(BookFlipDirection direction) {
    final canTurn = direction == BookFlipDirection.forward
        ? _page < _range.totalPages
        : _page > 1;
    if (!canTurn) return false;
    final spineX = bookFlipFreeEdgeIsRight(direction, textDirection) ? 0 : 1;
    return (_start.dx - spineX).abs() < _spineGuard;
  }

  void _abandonDrag() {
    _dragging = false;
    _edgeAtRelease = 0;
  }

  BookFlipPose _settlePose() => _trajectory!.poseAt(_turn.value);

  double get _settledProgress => _settlePose().turnFraction;

  BookFlipPose _settleTarget(BookFlipPose release, {required bool complete}) {
    if (!complete) {
      return BookFlipPose(
        start: release.start,
        current: release.start,
        velocity: Offset.zero,
        turnFraction: 0,
      );
    }
    final toLeft = bookFlipFreeEdgeIsRight(
      (_machine.state as BookFlipSettling).direction,
      textDirection,
    );
    final shift = toLeft ? -_completeOvershoot : _completeOvershoot;
    return BookFlipPose(
      start: release.start,
      current: Offset(release.start.dx + shift, release.start.dy),
      velocity: Offset.zero,
      turnFraction: 1,
    );
  }

  double _towardForward(double dx) =>
      textDirection == TextDirection.rtl ? dx : -dx;

  double _resisted(double offset, double extent) {
    final reach = extent * _edgeStretchFraction;
    return offset.sign * reach * (1 - math.exp(-offset.abs() / (extent * 0.3)));
  }

  Future<void> _settle({required bool complete}) {
    final done = _settled = Completer<void>();
    final settling = _machine.state as BookFlipSettling;
    final release = _release!;
    final span = ((complete ? 1.0 : 0.0) - settling.fromProgress).abs();
    final duration = Duration(
      microseconds: math.max(
        _minimumSettle.inMicroseconds,
        (_machine.physics.duration.inMicroseconds * span).round(),
      ),
    );
    _trajectory = BookFlipTrajectory.from(
      release: release,
      target: _settleTarget(release, complete: complete),
      duration: duration,
    );
    _turn.value = 0;
    notifyListeners();
    _turn
        .animateTo(1, duration: duration, curve: Curves.easeInOutSine)
        .whenComplete(_finishTurn);
    return done.future;
  }

  void _snapToEnd() {
    _turn.stop();
    _finishTurn();
  }

  void _finishTurn() {
    if (_disposed || _machine.state is! BookFlipSettling) return;
    final delta = _machine.finish();
    _trajectory = null;
    _turn.value = 0;
    if (delta != null) _page = _range.clamp(_page + delta);
    notifyListeners();
    if (delta != null) _onPageChanged(_page);
    _settled?.complete();
    _settled = null;
  }

  void _returnFromEdge() {
    if (_edgeAtRelease == 0) return;
    _returningFromEdge = true;
    _turn.value = 1;
    _turn
        .animateTo(0, duration: _edgeReturnDuration, curve: Curves.easeOut)
        .whenComplete(() {
          if (_disposed) return;
          _returningFromEdge = false;
          _edgeAtRelease = 0;
          notifyListeners();
        });
  }

  void _jumpTo(int target) {
    _page = target;
    _fade.value = _jumpFadeFloor;
    _fade.forward();
    notifyListeners();
    _onPageChanged(target);
  }

  @override
  void dispose() {
    _disposed = true;
    _turn.dispose();
    _fade.dispose();
    _settled?.complete();
    super.dispose();
  }
}
