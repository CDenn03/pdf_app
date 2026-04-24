# PDF Navigator Architectural Principles

- **Clean Architecture**: Strictly separate `core`, `features`, and `shared`.
- **State Management**: Use `flutter_riverpod` only. No `get_it` or `injectable`.
- **Overlay Strategy**: Non-destructive. Use `CustomPainter` for annotations.
- **Coordinate System**: All annotations use `RelativeRectModel` (0.0–1.0 normalized).
- **Persistence**: SQLite with indexed `(pdf_id, page)` queries. Debounce writes by 300ms.
- **TDD (Test-Driven Development)**: Implementation is not done until tests pass.
- **Error Handling**: Never crash on file I/O. Use `FileStatus` enum.
- **KISS/YAGNI**: No speculative complexity. Build the overlay first.