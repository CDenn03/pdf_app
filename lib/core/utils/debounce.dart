import 'dart:async';
import 'dart:ui';

/// A utility class that debounces function calls.
///
/// Usage:
/// ```dart
/// final debounce = Debounce(duration: Duration(milliseconds: 300));
/// debounce.run(() => saveAnnotation());
/// ```
class Debounce {
  final Duration duration;
  Timer? _timer;

  Debounce({this.duration = const Duration(milliseconds: 300)});

  /// Schedules [action] to run after [duration]. If [run] is called again
  /// before the timer fires, the previous call is cancelled.
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  /// Cancels any pending debounced action and releases the timer.
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
