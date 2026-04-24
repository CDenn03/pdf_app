Goal: Build a high-performance PDF annotation tool.

Core Loop: Render PDF -> Overlay Layer -> Capture Gesture -> Save Normalized Coord -> Persist to SQLite.

Constraints: Must maintain performance at 500+ annotations. Must handle document zoom/scroll without drifting highlights.