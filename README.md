<div align="center">

<img src="branding/app_icon.png" width="120" alt="Sefer app icon" />

# Sefer

**Read. Reflect. Understand.**

A clean, offline-first PDF reader for Android, built with Flutter. Manage your
library, annotate documents, and read distraction-free in continuous, swipe, or
realistic book-flip page modes.

</div>

## About the name

*Sefer* (ספר) is the Hebrew word for *book*. The app is made for reading books
to grow in understanding, and the identity reflects that: an enclosed "S" mark
suggesting knowledge gathered and held, set in warm forest and teal tones.

### Brand

| Token | Value | Use |
|---|---|---|
| Forest | `#1B5E4B` | Primary interactive colour (buttons, nav, links) |
| Teal | `#0F9D8E` | Accent (icon fills, progress, thumbnails) |
| Ivory | `#F7F8F4` | Light background |
| Slate | `#64746A` | Secondary text |

Typography is **Fraunces** for the wordmark and headings (italic for the
tagline) and **DM Sans** for the interface. Both are bundled as assets — no
network fonts. Brand masters and source vectors live in [`branding/`](branding/).

## Download

Get the latest APK from the
[**Releases page**](https://github.com/CDenn03/pdf_app/releases/latest).

| Device | File |
|---|---|
| Most phones (64-bit ARM) | `sefer-*-arm64-v8a.apk` |
| Older 32-bit phones | `sefer-*-armeabi-v7a.apk` |
| Emulator / Intel | `sefer-*-x86_64.apk` |
| Not sure | `sefer-*-universal.apk` (larger, runs anywhere) |

Pick the architecture-specific APK when you can — it is roughly a third the size
of the universal build. Release APKs are currently signed with a debug key for
direct install and testing, so they are not Play Store builds.

## Features

- **Three reading modes**
  - *Continuous* — smooth vertical scroll
  - *Swipe Pages* — one page per screen with gallery-style horizontal snapping
  - *Book Flip* — a realistic page curl that bends and twists around your touch
- **Draggable page scrubber** available in every mode for fast navigation
- **Library management** — add PDFs from your device, organise into collections,
  favourite, rename, and share files
- **Favourites** — mark any document from the reader, Device list, or Recently
  Opened, individually or with long-press multi-select
- **Device browser** — scan on-device PDFs and sort by name, date modified, or
  file size (ascending or descending)
- **Annotations** — highlight in multiple colours, draw freehand, and attach
  notes; all persisted locally
- **Text selection** in every reading mode, with copy and share
- **In-document search** — find text across the document; results show the
  surrounding sentence with the match highlighted
- **Table of contents** — jump to chapters via the in-reader TOC panel
- **Rename while reading** — rename the open document without losing your place
  or annotations
- **Recents** — quick access to recently opened files, with multi-select
- **Branded launch** — one continuous splash gated on real startup readiness
- **Settings** — light/dark/system theme, reading mode, and layout preferences

## Tech Stack

| Concern | Package |
|---|---|
| State management | [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) |
| Navigation | [go_router](https://pub.dev/packages/go_router) |
| PDF rendering | [pdfrx](https://pub.dev/packages/pdfrx) |
| PDF text & TOC | [syncfusion_flutter_pdf](https://pub.dev/packages/syncfusion_flutter_pdf) |
| Local database | [sqflite](https://pub.dev/packages/sqflite) |
| Persistence | [shared_preferences](https://pub.dev/packages/shared_preferences) |
| External links | [url_launcher](https://pub.dev/packages/url_launcher) |
| Fonts | Bundled Fraunces & DM Sans (`assets/fonts`) |
| App icon & splash | [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons), [flutter_native_splash](https://pub.dev/packages/flutter_native_splash) |

## Getting Started

**Prerequisites:** Flutter SDK ≥ 3.44.0, Dart ≥ 3.12.0

```bash
# Install dependencies
flutter pub get

# Run code generation (freezed / json_serializable)
dart run build_runner build --delete-conflicting-outputs

# Run on a connected device
flutter run

# Build release APKs, one per CPU architecture (recommended)
flutter build apk --release --split-per-abi
```

### Regenerating brand assets

The app icon and splash are generated from the masters in `branding/`:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Project Structure

```
lib/
├── core/
│   ├── database/      # SQLite DAOs (annotations, notes)
│   ├── models/        # Freezed data models
│   ├── services/      # Business logic (library, scanning, recents)
│   ├── theme/         # ThemeData, brand colours, reading mode enums
│   ├── router/        # GoRouter configuration
│   └── utils/         # Shared utilities
├── features/
│   ├── library/       # Library & collections UI + state
│   ├── reader/        # Viewer, reading modes, annotations, TOC, search
│   ├── recents/       # Recently opened files
│   ├── device/        # Device file browser, sorting, selection
│   ├── home/          # App shell & branded splash screen
│   └── settings/      # User preferences
└── shared/            # Reusable widgets & selection state
branding/              # Brand masters: icon, splash, source vectors
```
