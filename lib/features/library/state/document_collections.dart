import 'package:sefer/core/models/collection.dart';
import 'package:sefer/features/library/state/library_entry.dart';

/// Collections [ids] resolve to, in the order they appear in [collections].
List<PdfCollection> collectionsForIds({
  required Iterable<String> ids,
  required Iterable<PdfCollection> collections,
}) {
  if (ids.isEmpty) return const [];
  final idSet = ids is Set<String> ? ids : ids.toSet();
  return [
    for (final collection in collections)
      if (idSet.contains(collection.id)) collection,
  ];
}

/// Membership for [path], in the order collections are listed.
List<PdfCollection> collectionsForPath({
  required String path,
  required Iterable<LibraryEntry> entries,
  required Iterable<PdfCollection> collections,
}) {
  final entry = entries.where((item) => item.path == path).firstOrNull;
  return collectionsForIds(
    ids: entry?.collectionIds ?? const {},
    collections: collections,
  );
}

/// Caption for a one-item selection, or null when several are selected or
/// the selected file is in no collection.
String? singleSelectionMembershipLabel({
  required Set<String> selectedPaths,
  required Iterable<LibraryEntry> entries,
  required Iterable<PdfCollection> collections,
}) {
  if (selectedPaths.length != 1) return null;
  final membership = collectionsForPath(
    path: selectedPaths.single,
    entries: entries,
    collections: collections,
  );
  if (membership.isEmpty) return null;
  return 'In ${membership.map((collection) => collection.name).join(' · ')}';
}
