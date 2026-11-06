import 'package:flutter/material.dart';

import 'package:sefer/core/theme/app_spacing.dart';
import 'package:sefer/core/theme/reading_mode.dart';
import 'package:sefer/features/reader/presentation/reader_favorite_button.dart';

class ReaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ReaderAppBar({
    super.key,
    required this.title,
    required this.isBookmarked,
    required this.documentPath,
    required this.onBack,
    required this.onBookmark,
    required this.readingMode,
  });

  final String title;
  final bool isBookmarked;
  final String documentPath;
  final VoidCallback onBack;
  final VoidCallback onBookmark;
  final ReadingMode readingMode;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: readingMode.primaryText,
    );

    return AppBar(
      backgroundColor: readingMode.controlSurface,
      foregroundColor: readingMode.primaryText,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: readingMode.primaryText),
        onPressed: onBack,
        tooltip: 'Back',
      ),
      title: Text(title, overflow: TextOverflow.ellipsis, style: titleStyle),
      actions: [
        ReaderFavoriteButton(
          documentPath: documentPath,
          readingMode: readingMode,
        ),
        IconButton(
          icon: Icon(
            isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
            color: readingMode.primaryText,
          ),
          onPressed: onBookmark,
          tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark page',
        ),
      ],
    );
  }
}

/// Floating pill action bar using reading-mode colours so it blends with
/// light, dark, and sepia backgrounds.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    super.key,
    required this.onSearch,
    required this.onAnnotate,
    required this.onToc,
    required this.onMore,
    required this.readingMode,
  });

  final VoidCallback onSearch;
  final VoidCallback onAnnotate;
  final VoidCallback onToc;
  final VoidCallback onMore;
  final ReadingMode readingMode;

  @override
  Widget build(BuildContext context) {
    final surface = readingMode.controlSurface.withValues(alpha: 0.92);
    final borderColor = readingMode.primaryText.withValues(alpha: 0.08);

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _ActionButton(
            icon: Icons.search,
            label: 'Search',
            color: readingMode.primaryText,
            onTap: onSearch,
          ),
          _ActionButton(
            icon: Icons.edit_outlined,
            label: 'Annotate',
            color: readingMode.primaryText,
            onTap: onAnnotate,
          ),
          _ActionButton(
            icon: Icons.list_outlined,
            label: 'Contents',
            color: readingMode.primaryText,
            onTap: onToc,
          ),
          _ActionButton(
            icon: Icons.more_horiz,
            label: 'More',
            color: readingMode.primaryText,
            onTap: onMore,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      // Semantics makes each action button discoverable by screen readers (#14).
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 0,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReadingModeFilter extends StatelessWidget {
  const ReadingModeFilter({super.key, required this.mode, required this.child});

  final ReadingMode mode;
  final Widget child;

  static const _darkMatrix = ColorFilter.matrix(<double>[
    -1,
    0,
    0,
    0,
    255,
    0,
    -1,
    0,
    0,
    255,
    0,
    0,
    -1,
    0,
    255,
    0,
    0,
    0,
    1,
    0,
  ]);

  static const _sepiaMatrix = ColorFilter.matrix(<double>[
    0.393,
    0.769,
    0.189,
    0,
    0,
    0.349,
    0.686,
    0.168,
    0,
    0,
    0.272,
    0.534,
    0.131,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);

  @override
  Widget build(BuildContext context) => switch (mode) {
    ReadingMode.light => child,
    ReadingMode.dark => ColorFiltered(colorFilter: _darkMatrix, child: child),
    ReadingMode.sepia => ColorFiltered(colorFilter: _sepiaMatrix, child: child),
  };
}

class PageIndicator extends StatelessWidget {
  const PageIndicator({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onTap,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$currentPage / $totalPages',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class ReaderMoreMenu extends StatelessWidget {
  const ReaderMoreMenu({
    super.key,
    required this.onAnnotations,
    required this.onReadingMode,
    required this.onShare,
    this.onRename,
  });

  final VoidCallback onAnnotations;
  final VoidCallback onReadingMode;
  final VoidCallback onShare;
  final VoidCallback? onRename;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.sticky_note_2_outlined),
            title: Text('Annotations', style: theme.textTheme.bodyMedium),
            onTap: onAnnotations,
          ),
          ListTile(
            leading: const Icon(Icons.brightness_medium_outlined),
            title: Text('Reading mode', style: theme.textTheme.bodyMedium),
            onTap: onReadingMode,
          ),
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: Text('Share', style: theme.textTheme.bodyMedium),
            onTap: onShare,
          ),
          if (onRename != null)
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: Text('Rename', style: theme.textTheme.bodyMedium),
              onTap: onRename,
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
