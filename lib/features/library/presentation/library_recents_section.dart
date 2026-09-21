import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sefer/core/theme/app_colors.dart';
import 'package:sefer/core/theme/app_spacing.dart';
import 'package:sefer/features/library/state/library_providers.dart';
import 'package:sefer/features/recents/state/recents_notifier.dart';
import 'package:sefer/features/home/presentation/home_shell.dart';
import 'package:sefer/shared/widgets/file_actions_sheet.dart';

class RecentFilesSection extends StatelessWidget {
  const RecentFilesSection({super.key, required this.recents});

  final List<RecentEntry> recents;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Recently opened'),
        SizedBox(
          height: 136,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: AppSpacing.pageHorizontal,
            itemCount: recents.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, i) => RecentCard(entry: recents[i], colorIndex: i),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
      ],
    );
  }
}

class RecentCard extends ConsumerWidget {
  const RecentCard({super.key, required this.entry, required this.colorIndex});

  final RecentEntry entry;
  final int colorIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = entry.name.replaceAll('.pdf', '');
    final gradient = AppColors.coverGradientAt(colorIndex);

    return Semantics(
      button: true,
      label: 'Open $title',
      child: GestureDetector(
        onTap: () => _open(context, ref),
        onLongPress: () => _showActions(context, ref),
        child: Container(
          width: 96,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.md),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 28,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _timeAgo(entry.openedAt),
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, WidgetRef ref) {
    ref.read(recentsProvider.notifier).recordOpened(entry.path);
    context.push('/reader', extra: entry.path);
  }

  void _showActions(BuildContext context, WidgetRef ref) {
    final libraryEntry = ref
        .read(libraryEntriesProvider)
        .value
        ?.where((e) => e.path == entry.path)
        .firstOrNull;
    showFileActionsSheet(
      context,
      ref,
      path: entry.path,
      name: entry.name,
      libraryEntryId: libraryEntry?.id,
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
