import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_app/features/library/state/library_entry.dart';
import 'package:pdf_app/features/library/state/library_providers.dart';

/// Derives the recents list from the persisted library state.
///
/// Because [LibraryNotifier] now persists [lastOpenedAt] across restarts,
/// recents are automatically correct after a cold start.
final recentsProvider = Provider<List<LibraryEntry>>((ref) {
  final all = ref.watch(libraryEntriesProvider);
  final recents = all.where((e) => e.lastOpenedAt != null).toList()
    ..sort((a, b) => b.lastOpenedAt!.compareTo(a.lastOpenedAt!));
  return recents;
});
