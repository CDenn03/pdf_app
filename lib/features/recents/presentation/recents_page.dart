import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pdf_app/core/theme/app_colors.dart';
import 'package:pdf_app/features/recents/state/recents_notifier.dart';

/// Shows all PDFs the user has opened recently, newest first.
/// Includes files from outside the library.
class RecentsPage extends ConsumerWidget {
  const RecentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recents = ref.watch(recentsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;

    if (recents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_outlined, size: 48, color: secondary),
              const SizedBox(height: 16),
              Text('No recent files', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Files you open will appear here.',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: recents.length,
      itemBuilder: (_, i) => _RecentTile(entry: recents[i]),
    );
  }
}

class _RecentTile extends ConsumerWidget {
  const _RecentTile({required this.entry});

  final RecentEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final primary =
        isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final colorIndex = entry.path.hashCode.abs();
    final gradient = AppColors.coverGradientAt(colorIndex);

    return InkWell(
      onTap: () {
        ref.read(recentsProvider.notifier).recordOpened(entry.path);
        context.push('/reader', extra: entry.path);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.picture_as_pdf_outlined,
                size: 20,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name.replaceAll('.pdf', ''),
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _timeAgo(entry.openedAt),
                    style: GoogleFonts.dmSans(fontSize: 12, color: secondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: secondary),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
