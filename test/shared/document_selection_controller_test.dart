import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/shared/state/document_selection_controller.dart';

void main() {
  late DocumentSelectionController controller;
  late int notifications;

  setUp(() {
    controller = DocumentSelectionController();
    notifications = 0;
    controller.addListener(() => notifications++);
  });

  tearDown(() => controller.dispose());

  test('given empty, when selecting, then isSelecting is true', () {
    expect(controller.isSelecting, isFalse);

    controller.select('/a');

    expect(controller.isSelecting, isTrue);
    expect(controller.selectedPaths, {'/a'});
  });

  test('given a selected path, when selected again, then no notification', () {
    controller.select('/a');
    controller.select('/a');

    expect(notifications, 1);
  });

  test('given a path, when toggled twice, then it is deselected', () {
    controller
      ..toggle('/a')
      ..toggle('/a');

    expect(controller.isSelecting, isFalse);
  });

  test('when selectVisible is called, then paths are added', () {
    controller.select('/hidden');

    controller.selectVisible(['/a', '/b']);

    expect(controller.selectedPaths, {'/hidden', '/a', '/b'});
  });

  test('when retainExisting is called, then vanished paths are dropped', () {
    controller.selectVisible(['/a', '/b']);

    controller.retainExisting(['/b', '/c']);

    expect(controller.selectedPaths, {'/b'});
  });

  test('given nothing to prune or clear, then listeners are not notified', () {
    controller.retainExisting(['/a']);
    controller.clear();

    expect(notifications, 0);
  });

  test('when cleared, then selection is empty', () {
    controller.selectVisible(['/a', '/b']);

    controller.clear();

    expect(controller.isSelecting, isFalse);
  });

  test('selectedPaths cannot be mutated from outside', () {
    controller.select('/a');

    expect(() => controller.selectedPaths.add('/b'), throwsUnsupportedError);
  });
}
