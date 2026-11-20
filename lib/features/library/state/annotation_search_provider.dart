import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sefer/core/models/annotation_search.dart';
import 'package:sefer/core/providers.dart';

/// Rows matching [query] across every document's annotations and notes.
final annotationSearchProvider = FutureProvider.autoDispose
    .family<List<AnnotationSearchRow>, String>((ref, query) {
      return ref.watch(annotationDaoProvider).search(query);
    });
