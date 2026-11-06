import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/core/models/annotation.dart';
import 'package:sefer/core/models/annotation_type.dart';
import 'package:sefer/features/reader/state/annotation_notifier.dart';
import 'package:sefer/features/reader/state/providers.dart';
import '../support/fake_annotation_daos.dart';

Annotation _bookmarkOn(int page) => Annotation(
  id: 'bookmark-$page',
  pdfId: 'doc',
  page: page,
  type: AnnotationType.bookmark,
);

void main() {
  late FakeAnnotationDao dao;
  late ProviderContainer container;

  setUp(() {
    dao = FakeAnnotationDao()..deferRangeReads = true;
    container = ProviderContainer(
      overrides: [
        annotationDaoProvider.overrideWithValue(dao),
        noteEntryDaoProvider.overrideWithValue(FakeNoteEntryDao()),
      ],
    );
    container.listen(annotationNotifierProvider, (_, _) {});
  });

  tearDown(() => container.dispose());

  AnnotationNotifier notifier() =>
      container.read(annotationNotifierProvider.notifier);

  Set<int> pagesWithAnnotations() => {
    for (final entry in container.read(annotationNotifierProvider).entries)
      if (entry.value.isNotEmpty) entry.key,
  };

  test(
    'a slow load for an earlier page cannot overwrite a newer one',
    () async {
      final earlier = notifier().loadForPage('doc', 3);
      final later = notifier().loadForPage('doc', 4);

      dao.pendingRangeReads[1].complete([_bookmarkOn(4)]);
      await later;
      dao.pendingRangeReads[0].complete([_bookmarkOn(3)]);
      await earlier;

      expect(pagesWithAnnotations(), {4});
    },
  );

  test('a load finishing after the reader closed does not throw', () async {
    final inFlight = notifier().loadForPage('doc', 2);

    container.dispose();
    dao.pendingRangeReads.single.complete([_bookmarkOn(2)]);

    await expectLater(inFlight, completes);
  });
}
