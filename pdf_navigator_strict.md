# PDF Navigator Constitution (Strict)

## 1. Dependency Constraints (Do Not deviate)
- syncfusion_flutter_pdfviewer: ^25.1.41
- flutter_riverpod: ^2.5.1
- go_router: ^14.2.0
- sqflite: ^2.3.3
- uuid: ^4.4.0
- freezed_annotation: ^2.4.4

## 2. Architecture Rules
- NO `get_it` or `injectable`. Riverpod ONLY for DI.
- Every Annotation must have a UUID.
- Never hard-delete annotation rows; use soft-deletes.
- SQLite Index: `CREATE INDEX idx_pdf_page ON annotations(pdf_id, page);`
- Debounce writes: 300–500ms using `core/utils/debounce.dart`.

## 3. Error Handling (Non-negotiable)
- Implement `FileStatus` enum: `ok`, `missing`, `corrupt`.
- `checkFile(path)` must never throw. If corrupt, return status; do not crash.
- If a file is missing, the library must display "Unavailable" without removing the annotation records.

## 4. Coding Standards
- Emit complete file contents (no `// ... rest of code`).
- Include all imports in every output.
- Every assumption must be marked with `// ASSUMPTION: <details>`.