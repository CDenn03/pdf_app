# PDF Navigator — UI Design Guide

## Design Philosophy

The document is the primary visual element. Every UI decision should serve
the reading experience, not compete with it.

- **Neutral surfaces.** Chrome is low-contrast and recedes behind content.
- **One accent.** A single muted blue (`#4C6EF5`) for interactive states only — never decoration.
- **Vivid annotations only.** Yellow / green / blue / pink highlights are the only
  saturated color in the entire app. They must always stand out against any reading mode.
- **Flat, no elevation.** Cards and panels are distinguished by border (`#E5E5E5` light /
  `#2A2A2A` dark), never by shadow.
- **Typography is secondary.** UI text is small (12–16 sp) so it never fights document text.

---

## Color Tokens

### Light Mode
| Token | Hex | Usage |
|---|---|---|
| `lightBackground` | `#F7F7F5` | Scaffold background, soft paper tone |
| `lightSurface` | `#FFFFFF` | Cards, app bar, bottom sheet, nav bar |
| `lightPrimaryText` | `#1C1C1C` | All headings and body copy |
| `lightSecondaryText` | `#6B6B6B` | Subtitles, captions, hints |
| `lightDivider` | `#E5E5E5` | List separators, card borders |

### Dark Mode
| Token | Hex | Usage |
|---|---|---|
| `darkBackground` | `#121212` | Scaffold background |
| `darkSurface` | `#1E1E1E` | Cards, app bar, bottom sheet, nav bar |
| `darkPrimaryText` | `#EAEAEA` | Body and headings |
| `darkSecondaryText` | `#9A9A9A` | Captions, hints |
| `darkDivider` | `#2A2A2A` | Separators, card borders |

### Accent (both modes)
| Token | Hex | Usage |
|---|---|---|
| `accent` | `#4C6EF5` | Active nav indicator, selection, focus ring, primary buttons |
| `accentMuted` | `#144C6EF5` | Nav bar indicator fill, selection chips |

### Annotation Colors (vivid layer — never used for UI chrome)
| Name | Solid | Overlay (55% alpha) |
|---|---|---|
| Yellow | `#FFD43B` | `#55FFD43B` |
| Green | `#69DB7C` | `#5569DB7C` |
| Blue | `#74C0FC` | `#5574C0FC` |
| Pink | `#F783AC` | `#55F783AC` |

---

## Typography

Font: **Inter** (via `google_fonts`). All sizes are intentionally small to stay
behind document content.

| Style | Size | Weight | Color | Usage |
|---|---|---|---|---|
| `titleMedium` | 16 sp | 500 | primaryText | Screen titles, panel headers |
| `titleSmall` | 14 sp | 500 | primaryText | Section labels |
| `labelLarge` | 14 sp | 500 | primaryText | Settings section headers, button labels |
| `labelMedium` | 12 sp | 500 | secondaryText | Nav bar labels, action button labels |
| `bodyMedium` | 14 sp | 400 | primaryText | List item titles, body copy |
| `bodySmall` | 12 sp | 400 | secondaryText | Subtitles, timestamps, page numbers, hints |

---

## Layout & Spacing

- Standard horizontal padding: **20 px** for list content.
- Standard vertical padding for list tiles: **2 px** (`contentPadding` vertical).
- Empty states: **32 px** all-around padding, content centered.
- Bottom list clearance: **24 px** `padding: EdgeInsets.only(bottom: 24)`.
- Icon size in action bars: **22 px**.
- Leading icon containers in list tiles: **40 × 40 px**, `borderRadius: 8`.

---

## App Structure

```
PdfNavigatorApp (MaterialApp.router)
└── HomeShell  ─── / (GoRouter)
│   ├── AppBar (title / search / actions)
│   ├── IndexedStack
│   │   ├── LibraryPage    (tab 0)
│   │   ├── DevicePage     (tab 1)
│   │   └── RecentsPage    (tab 2)
│   └── NavigationBar (3 tabs)
│
├── ReaderPage  ─── /reader
└── SettingsPage  ── /settings
```

---

## Screens

### HomeShell

The persistent shell for all three browse tabs.

**AppBar**
- Title text: `titleMedium`, left-aligned.
- In search mode: replaces title with a borderless `TextField` (autofocus, `hintText: 'Search…'`).
- Right actions (context-sensitive):
  - Search toggle (`Icons.search_outlined` / `Icons.close`) — always visible.
  - Add PDF (`Icons.add_outlined`) — Library tab only.
  - Rescan (`Icons.refresh_outlined`) — Device tab only.
  - Settings (`Icons.settings_outlined`) — always visible.
- `backgroundColor: surface`, `elevation: 0`, `scrolledUnderElevation: 0`.

**NavigationBar**
- `backgroundColor: surface`, `elevation: 0`.
- Indicator fill: `accentMuted`.
- Labels: 12 sp / 500 weight Inter.
- Tabs: Library (`collections_bookmark_outlined`), Device (`phone_android_outlined`), Recents (`history_outlined`).
- Switching tabs clears any active multi-select in the outgoing tab.

---

### LibraryPage

User-curated list of PDFs, optionally grouped into collections.

**Layout (no collections, no search)**
- Plain `ListView` of `_EntryTile` rows.
- Footer: `OutlinedButton.icon` ("New collection"), `fromLTRB(20, 16, 20, 0)` padding.

**With collections**
- Section header per collection: folder icon (accent color), name (bodyMedium),
  expand/collapse chevron + `PopupMenuButton` (rename / delete) in trailing.
- Expanded entries indented: `padding: left: 16`.
- Uncollected files section header "Files" in `labelMedium` when collections exist.

**`_EntryTile`**
- Leading: 40×40 container, `primaryContainer` fill, `primary` icon — or `surfaceContainerHighest` + `outline` icon when unavailable.
- Title: `bodyMedium`, single line + ellipsis.
- Subtitle (unavailable only): "File unavailable" in `error` color, `bodySmall`.
- Trailing: `Icons.more_vert` (18 px, `outline` color) → popup: Open / Move to collection / Remove.
- `contentPadding: horizontal 20, vertical 2`.

**Empty state**
- Centered column, `Collections_bookmark_outlined` icon 48 px in `outline` color.
- Title: "Your library is empty", `titleMedium`.
- Body: guidance text, `bodySmall`, centered.

---

### DevicePage / RecentsPage

Both use `SelectableFileList` — a shared list widget that supports long-press
multi-select for bulk operations.

**SelectableFileList behavior**
- Normal tap: open file in reader.
- Long press: enter multi-select mode — checkboxes appear, bulk-action bar slides
  up at the bottom with "Add to library" and "Add to collection" actions.
- `clearSelection()` called by HomeShell on tab change.

**Recents empty state**
- `Icons.history_outlined` 48 px / `outline` color.
- Title: "No recent files", `titleMedium`.
- Body: "Files you open will appear here.", `bodySmall`, centered.

---

### ReaderPage

Full-screen immersive reader. All chrome auto-hides after 4 seconds of
inactivity and reappears on tap.

**Scaffold structure**
```
Scaffold
├── AppBar         (visible = barsVisible && !annotating)
├── body
│   └── Stack
│       ├── _ReadingModeFilter → PdfViewer
│       ├── _PageIndicator (bottom center, absolute)
│       └── _SideScrollThumb (right edge, absolute)
└── bottomNavigationBar
    ├── _BottomActionBar  (visible = barsVisible && !annotating)
    └── AnnotationToolbar (visible = annotating)
```

**`_ReaderAppBar`**
- `backgroundColor: readingMode.controlSurface`.
- Back arrow left, bookmark icon right (filled when current page is bookmarked).
- All icon colors: `readingMode.primaryText`.

**`_BottomActionBar`**
- `backgroundColor: readingMode.controlSurface`, `BorderSide` top divider.
- 4 equal-width `_ActionButton` items: Search / Annotate / Contents / More.
- Each button: icon 22 px + label 11 sp / `labelMedium`, spaced with `spaceAround`.

**`_PageIndicator`**
- Pill shape, `Colors.black` at 45% alpha, white text.
- `padding: horizontal 14, vertical 6`, `borderRadius: 20`.
- Tap opens jump-to-page dialog.

**`_SideScrollThumb`**
- Right edge, full height. Draggable vertical scrubber.
- Resting: 4 px wide, `outline` color at 50% alpha.
- Dragging: expands to 44 px, accent color, shows page number in white.
- Thumb height clamps between 32–80 px proportional to page count.

**Reading modes** (applied as `ColorFilter` over the entire viewer)
- Light: no filter.
- Dark: invert matrix (`-1` diagonal, `+255` offset) — turns white pages dark.
- Sepia: warm desaturation matrix.

---

### Annotation Mode

Entered via the "Annotate" button. Bars hide, a toolbar slides up from the bottom.

**`AnnotationToolbar`**
- `backgroundColor: readingMode.controlSurface`.
- Tool chips: Highlight / Underline / Note / Erase — styled as `ChoiceChip` with annotation color fill for Highlight.
- Right actions: Undo, Exit (×).

**Highlight colors** — four swatches shown inline:
Yellow (`#FFD43B`) · Green (`#69DB7C`) · Blue (`#74C0FC`) · Pink (`#F783AC`)

Highlights render as semi-transparent overlays (55% alpha) on top of page content.

---

### Overlay Panels (Bottom Sheets)

All secondary panels (TOC, Search, Annotations) share `OverlayPanel`:
- `isScrollControlled: true`, `useSafeArea: true`, `showDragHandle: true`.
- Max height: **85% of screen height**.
- Header: `titleMedium` title + optional trailing widget + close `×` button.
- `backgroundColor: surface`, `borderRadius: vertical top 16`.

**TOC Panel**
- Loading: compact row — 20×20 spinner + "Detecting chapters…" text, `padding: horizontal 24, vertical 32`.
- Auto-detected banner: `secondaryContainer` pill, `auto_awesome` icon + warning text.
- Chapter list: `ListTile` rows, left-indented by depth (`20 + depth × 16` px), page number as `bodySmall` trailing.

**Search Panel**
- Non-dismissible (`isDismissible: false`), no drag handle.
- Search field at top, results scroll below.

**Annotations Panel**
- Lists all bookmarks and highlights for the document.
- Tap navigates to that page.

---

### SettingsPage

Simple `ListView` with two `SegmentedButton` controls.

- Section headers: `labelLarge` text, 8 px bottom margin.
- Reading mode: 3 segments — Light / Dark / Sepia.
- Scroll direction: segments — Continuous / Paginated.
- Changes persist immediately (no save button).
- `padding: horizontal 16, vertical 8`.

---

## Component Patterns

### Cards
`elevation: 0`, `color: surface`, border `1 px solid divider`, `borderRadius: 12`.

### Dialogs (AlertDialog)
- Title: `titleMedium`.
- Content: `bodyMedium` text or a single `TextField` with `OutlineInputBorder`.
- Actions: `TextButton` (Cancel) + `FilledButton` (confirm).

### Snackbars
- `behavior: floating`, `borderRadius: 8`.
- `backgroundColor: onSurface` (inverted — dark in light mode, light in dark mode).
- Text color: `surface` (contrasting against background).
- Used for undo confirmations only (2-second duration).

### Empty States
All follow the same pattern:
```
Center → Padding(32) → Column(mainAxisSize: min)
  Icon (48 px, outline color)
  SizedBox(16)
  Text (titleMedium)
  SizedBox(8)
  Text (bodySmall, centered, descriptive)
```

### Icon Sizes
| Context | Size |
|---|---|
| AppBar actions | 22 px |
| List tile leading icon | 20 px |
| `more_vert` overflow | 18 px |
| Inline / banner icons | 16 px |
| Empty state illustration | 48 px |
| Action buttons (reader bottom bar) | 22 px |

### Minimum tap targets
All `IconButton`s: `minimumSize: 44×44` (`MaterialTapTargetSize.padded`).
