import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sefer/core/services/reading_progress_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('sanitised key never collides for two different paths', () async {
    // Before fix (#2), hashCode could collide for different strings.
    // After fix, each distinct path maps to a distinct SharedPreferences key.
    const pathA = '/storage/emulated/0/docs/report.pdf';
    const pathB = '/storage/emulated/0/docs/other.pdf';

    final service = ReadingProgressService();
    await service.saveLastPage(pathA, 5);
    await service.saveLastPage(pathB, 9);

    final pageA = await service.getLastPage(pathA);
    final pageB = await service.getLastPage(pathB);

    expect(pageA, 5, reason: 'pathA progress must not be overwritten by pathB');
    expect(pageB, 9);
  });

  test('round-trips page number', () async {
    const path = '/books/sample.pdf';
    final service = ReadingProgressService();
    await service.saveLastPage(path, 42);
    expect(await service.getLastPage(path), 42);
  });

  test('returns 1 when no entry saved', () async {
    final service = ReadingProgressService();
    expect(await service.getLastPage('/new.pdf'), 1);
  });

  test('movePage carries the page across and drops the old key', () async {
    const oldPath = '/books/old.pdf';
    const newPath = '/books/new.pdf';
    final service = ReadingProgressService();
    await service.saveLastPage(oldPath, 7);

    await service.movePage(oldPath, newPath);

    expect(await service.getLastPage(newPath), 7);
    expect(
      await service.getLastPage(oldPath),
      1,
      reason: 'old key must be removed',
    );
  });

  test('movePage is a no-op when nothing is stored', () async {
    const oldPath = '/books/missing.pdf';
    const newPath = '/books/new.pdf';
    final service = ReadingProgressService();

    await service.movePage(oldPath, newPath);

    expect(await service.getLastPage(newPath), 1);
  });

  test('clear removes the stored page', () async {
    const path = '/books/gone.pdf';
    final service = ReadingProgressService();
    await service.saveLastPage(path, 12);

    await service.clear(path);

    expect(await service.getLastPage(path), 1);
  });
}
