import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sefer/core/services/recents_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('moveEntry keeps position and timestamp, changes path and name',
      () async {
    final service = RecentsService();
    await service.recordOpened('/a.pdf', 'A');
    await service.recordOpened('/b.pdf', 'B');
    await service.recordOpened('/c.pdf', 'C');

    final before = await service.load();
    final target = before.firstWhere((e) => e.path == '/b.pdf');
    final originalIndex = before.indexWhere((e) => e.path == '/b.pdf');

    await service.moveEntry(
      oldPath: '/b.pdf',
      newPath: '/renamed.pdf',
      newName: 'Renamed',
    );

    final after = await service.load();
    final movedIndex = after.indexWhere((e) => e.path == '/renamed.pdf');
    final moved = after[movedIndex];

    expect(movedIndex, originalIndex, reason: 'position preserved');
    expect(moved.name, 'Renamed');
    expect(moved.openedAt, target.openedAt, reason: 'timestamp preserved');
    expect(after.any((e) => e.path == '/b.pdf'), isFalse);
    expect(after.length, before.length);
  });

  test('moveEntry is a no-op when the path is absent', () async {
    final service = RecentsService();
    await service.recordOpened('/a.pdf', 'A');

    await service.moveEntry(
      oldPath: '/missing.pdf',
      newPath: '/x.pdf',
      newName: 'X',
    );

    final after = await service.load();
    expect(after.length, 1);
    expect(after.single.path, '/a.pdf');
  });

  test('remove deletes the matching entry only', () async {
    final service = RecentsService();
    await service.recordOpened('/a.pdf', 'A');
    await service.recordOpened('/b.pdf', 'B');

    await service.remove('/a.pdf');

    final after = await service.load();
    expect(after.length, 1);
    expect(after.single.path, '/b.pdf');
  });

  test('remove is a no-op when the path is absent', () async {
    final service = RecentsService();
    await service.recordOpened('/a.pdf', 'A');

    await service.remove('/missing.pdf');

    final after = await service.load();
    expect(after.single.path, '/a.pdf');
  });
}
