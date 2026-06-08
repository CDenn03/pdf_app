# PDF Reader

A clean, feature-rich PDF reader for Android built with Flutter. Manage your library, annotate documents, and read with a distraction-free immersive viewer.

## Download the App

You can download the latest production APK directly to your Android device here:
👉 [Download Latest Android APK](https://github.com/CDenn03/pdf_app/releases/latest/download/app-release.apk)


## Features

- **Library management** — add PDFs from your device, organise into collections, mark favourites, rename, and share files
- **Immersive reader** — smooth, high-fidelity rendering via [pdfrx](https://pub.dev/packages/pdfrx) with auto-hiding controls
- **Annotations** — highlight text in multiple colours, draw freehand, and attach notes; all annotations are persisted locally
- **Table of contents** — jump to chapters and sections via the in-reader TOC panel
- **In-document search** — find text across the entire document with a results panel
- **Reading modes** — continuous scroll, single page, or horizontal paging
- **Recents** — quick access to recently opened files
- **Settings** — light/dark/system theme, reading mode, and scroll direction preferences
- **Share** — share any PDF directly from the library, recents, or device browser

## Tech Stack

| Concern | Package |
|---|---|
| State management | [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) |
| Navigation | [go_router](https://pub.dev/packages/go_router) |
| PDF rendering | [pdfrx](https://pub.dev/packages/pdfrx) |
| PDF manipulation | [syncfusion_flutter_pdf](https://pub.dev/packages/syncfusion_flutter_pdf) |
| Local database | [sqflite](https://pub.dev/packages/sqflite) |
| Persistence | [shared_preferences](https://pub.dev/packages/shared_preferences) |
| Fonts | [google_fonts](https://pub.dev/packages/google_fonts) |

## Getting Started

**Prerequisites:** Flutter SDK ≥ 3.44.0, Dart ≥ 3.12.0

```bash
# Install dependencies
flutter pub get

# Run code generation (freezed / json_serializable)
dart run build_runner build --delete-conflicting-outputs

# Run on a connected device
flutter run

# Build release APK (arm64)
flutter build apk --release --target-platform android-arm64
```

## Project Structure

```
lib/
├── core/
│   ├── database/      # SQLite DAOs (annotations, notes)
│   ├── models/        # Freezed data models
│   ├── services/      # Business logic (library, scanning, recents)
│   ├── theme/         # ThemeData, colours, reading mode enums
│   ├── router/        # GoRouter configuration
│   └── utils/         # Shared utilities
├── features/
│   ├── library/       # Library & collections UI + state
│   ├── reader/        # PDF viewer, annotations, TOC, search
│   ├── recents/       # Recently opened files
│   ├── device/        # Device file browser
│   ├── home/          # App shell & splash screen
│   └── settings/      # User preferences
└── shared/
    └── widgets/       # Reusable widgets
```
