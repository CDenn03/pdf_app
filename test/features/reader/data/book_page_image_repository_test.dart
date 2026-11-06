import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/features/reader/data/book_page_image_repository.dart';
import 'package:sefer/features/reader/data/page_rasterizer.dart';

class _PendingRender {
  _PendingRender(this.pageNumber, this.pixelSize, this.cancellation);

  final int pageNumber;
  final ui.Size pixelSize;
  final PageRenderCancellation cancellation;
  final Completer<ui.Image?> completer = Completer();
}

class _FakeRasterizer implements PageRasterizer {
  final List<_PendingRender> renders = [];

  @override
  Future<ui.Image?> render(
    int pageNumber,
    ui.Size pixelSize, {
    required PageRenderCancellation cancellation,
  }) {
    final pending = _PendingRender(pageNumber, pixelSize, cancellation);
    renders.add(pending);
    return pending.completer.future;
  }

  List<_PendingRender> rendersOf(int page) =>
      renders.where((r) => r.pageNumber == page).toList();
}

Future<ui.Image> _newImage() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder);
  return recorder.endRecording().toImage(1, 1);
}

const _size = ui.Size(100, 200);

void main() {
  late _FakeRasterizer rasterizer;
  late BookPageImageRepository repository;

  setUp(() {
    rasterizer = _FakeRasterizer();
    repository = BookPageImageRepository(rasterizer: rasterizer);
  });

  tearDown(() => repository.dispose());

  testWidgets('renders a page once and shares the in-flight result', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final first = repository.imageFor(1, _size);
      final second = repository.imageFor(1, _size);
      final image = await _newImage();
      rasterizer.renders.single.completer.complete(image);

      expect(await first, same(image));
      expect(await second, same(image));
      expect(await repository.imageFor(1, _size), same(image));
      expect(rasterizer.renders, hasLength(1));
    });
  });

  testWidgets('clamps the render size to the texture limit', (tester) async {
    await tester.runAsync(() async {
      repository = BookPageImageRepository(
        rasterizer: rasterizer,
        maxTextureDimension: 1000,
      );

      unawaited(repository.imageFor(1, const ui.Size(2000, 4000)));

      expect(rasterizer.renders.single.pixelSize, const ui.Size(500, 1000));
    });
  });

  testWidgets('retain evicts and disposes pages outside the window', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final images = <int, ui.Image>{};
      for (final page in [1, 2, 3]) {
        final future = repository.imageFor(page, _size);
        images[page] = await _newImage();
        rasterizer.rendersOf(page).single.completer.complete(images[page]);
        await future;
      }

      repository.retain({2, 3});

      expect(images[1]!.debugDisposed, isTrue);
      expect(images[2]!.debugDisposed, isFalse);
      expect(images[3]!.debugDisposed, isFalse);
      unawaited(repository.imageFor(1, _size));
      expect(rasterizer.rendersOf(1), hasLength(2));
    });
  });

  testWidgets('retain cancels renders that are still running', (tester) async {
    await tester.runAsync(() async {
      final pending = repository.imageFor(4, _size);
      final render = rasterizer.renders.single;

      repository.retain({5});

      expect(render.cancellation.isCancelled, isTrue);
      final late = await _newImage();
      render.completer.complete(late);
      expect(await pending, isNull);
      expect(late.debugDisposed, isTrue);
    });
  });

  testWidgets('a size change invalidates cached pages', (tester) async {
    await tester.runAsync(() async {
      final future = repository.imageFor(1, _size);
      final old = await _newImage();
      rasterizer.renders.single.completer.complete(old);
      await future;

      unawaited(repository.imageFor(1, const ui.Size(200, 400)));

      expect(old.debugDisposed, isTrue);
      expect(rasterizer.renders, hasLength(2));
      expect(rasterizer.renders.last.pixelSize, const ui.Size(200, 400));
    });
  });

  testWidgets('pages of different sizes do not invalidate each other', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final portrait = repository.imageFor(1, const ui.Size(100, 200));
      final image = await _newImage();
      rasterizer.rendersOf(1).single.completer.complete(image);
      await portrait;

      unawaited(repository.imageFor(2, const ui.Size(200, 100)));

      expect(image.debugDisposed, isFalse);
      expect(await repository.imageFor(1, const ui.Size(100, 200)), image);
      expect(rasterizer.renders, hasLength(2));
    });
  });

  testWidgets('a failed render is retryable', (tester) async {
    await tester.runAsync(() async {
      final failed = repository.imageFor(1, _size);
      rasterizer.renders.single.completer.completeError(StateError('boom'));
      expect(await failed, isNull);

      final retry = repository.imageFor(1, _size);
      final image = await _newImage();
      rasterizer.renders.last.completer.complete(image);

      expect(rasterizer.renders, hasLength(2));
      expect(await retry, same(image));
    });
  });

  testWidgets('a render that yields nothing is retryable', (tester) async {
    await tester.runAsync(() async {
      final empty = repository.imageFor(1, _size);
      rasterizer.renders.single.completer.complete(null);
      expect(await empty, isNull);

      unawaited(repository.imageFor(1, _size));

      expect(rasterizer.renders, hasLength(2));
    });
  });

  testWidgets('dispose frees images, cancels work and rejects new requests', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final done = repository.imageFor(1, _size);
      final image = await _newImage();
      rasterizer.rendersOf(1).single.completer.complete(image);
      await done;
      unawaited(repository.imageFor(2, _size));
      final running = rasterizer.rendersOf(2).single;

      repository.dispose();

      expect(image.debugDisposed, isTrue);
      expect(running.cancellation.isCancelled, isTrue);
      expect(await repository.imageFor(3, _size), isNull);
      expect(rasterizer.renders, hasLength(2));
    });
  });
}
