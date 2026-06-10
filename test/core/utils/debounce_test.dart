import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/core/utils/debounce.dart';

void main() {
  group('Debounce', () {
    test('fires callback after specified duration', () async {
      final debounce = Debounce(duration: const Duration(milliseconds: 100));
      var callCount = 0;

      debounce.run(() => callCount++);

      // Should not fire immediately
      expect(callCount, 0);

      // Wait for debounce to fire
      await Future.delayed(const Duration(milliseconds: 150));
      expect(callCount, 1);

      debounce.dispose();
    });

    test('collapses multiple rapid calls into one', () async {
      final debounce = Debounce(duration: const Duration(milliseconds: 100));
      var callCount = 0;

      debounce.run(() => callCount++);
      debounce.run(() => callCount++);
      debounce.run(() => callCount++);

      await Future.delayed(const Duration(milliseconds: 150));
      expect(callCount, 1);

      debounce.dispose();
    });

    test('uses the last callback when debouncing', () async {
      final debounce = Debounce(duration: const Duration(milliseconds: 100));
      var value = '';

      debounce.run(() => value = 'first');
      debounce.run(() => value = 'second');
      debounce.run(() => value = 'third');

      await Future.delayed(const Duration(milliseconds: 150));
      expect(value, 'third');

      debounce.dispose();
    });

    test('dispose cancels pending callback', () async {
      final debounce = Debounce(duration: const Duration(milliseconds: 100));
      var callCount = 0;

      debounce.run(() => callCount++);
      debounce.dispose();

      await Future.delayed(const Duration(milliseconds: 150));
      expect(callCount, 0);
    });

    test('defaults to 300ms duration', () {
      final debounce = Debounce();
      expect(debounce.duration, const Duration(milliseconds: 300));
      debounce.dispose();
    });
  });
}
