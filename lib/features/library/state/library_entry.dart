import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:sefer/core/models/file_status.dart';

part 'library_entry.freezed.dart';

/// A PDF file entry in the user's personal library.
///
/// Only files explicitly added by the user appear here.
/// [collectionId] is null when the entry is in the root library.
@freezed
abstract class LibraryEntry with _$LibraryEntry {
  const factory LibraryEntry({
    required String id,
    required String name,
    required String path,
    required FileStatus status,
    DateTime? lastOpenedAt,
    String? collectionId,
    @Default(false) bool isFavorite,
  }) = _LibraryEntry;
}
