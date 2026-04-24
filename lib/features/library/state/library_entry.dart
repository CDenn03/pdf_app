import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:pdf_app/core/models/file_status.dart';

part 'library_entry.freezed.dart';

/// A PDF file entry in the user's library.
@freezed
class LibraryEntry with _$LibraryEntry {
  const factory LibraryEntry({
    required String id,
    required String name,
    required String path,
    required FileStatus status,
  }) = _LibraryEntry;
}
