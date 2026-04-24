# Tasks for PDF Navigator

## Milestone 1: Core Setup
- [x] Initialize Flutter project and `pubspec.yaml` with required dependencies.
- [x] Set up folder structure: `core/`, `features/`, `shared/`.
- [x] Implement `core/utils/debounce.dart` and `core/services/file_service.dart`.

## Milestone 2: Overlay Foundation (The Proof of Concept)
- [x] Create `RelativeRectModel` and `coordinate_mapper.dart`.
- [x] Implement `HighlightPainter` using `CustomPainter`.
- [x] Create `reader_page.dart` with a `Stack` that renders a sample PDF and a single static highlight.
- [x] Verify coordinate mapping via `flutter_test`.

## Milestone 3: Annotation Data Layer
- [x] Define SQLite schema and `Annotation` entity.
- [x] Create `AnnotationNotifier` (Riverpod).
- [x] Implement debounced saving to SQLite.

## Milestone 4: Gesture Integration
- [x] Implement `gesture_handler.dart` for highlight and note placement.
- [x] Update overlay to render dynamic state from `AnnotationNotifier`.

## Milestone 5: Polish & Validation
- [x] Ensure all code passes `flutter_lints`.
- [x] Add golden tests for overlay rendering.
