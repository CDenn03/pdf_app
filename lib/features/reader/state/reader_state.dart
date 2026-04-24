import 'package:freezed_annotation/freezed_annotation.dart';

part 'reader_state.freezed.dart';

/// Immutable state for the PDF reader.
///
/// Kept separate from annotation state to prevent rebuild storms
/// per architecture spec.
@freezed
class ReaderState with _$ReaderState {
  const factory ReaderState({
    @Default('') String pdfId,
    @Default(1) int currentPage,
    @Default(1) int totalPages,
    @Default(false) bool isLoaded,
  }) = _ReaderState;
}
