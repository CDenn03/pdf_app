import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:sefer/features/reader/domain/reader_route_arguments.dart';
import 'package:sefer/core/theme/app_colors.dart';
import 'package:sefer/core/theme/app_spacing.dart';
import 'package:sefer/features/library/state/library_providers.dart';
import 'package:sefer/features/recents/state/recents_notifier.dart';
import 'package:sefer/features/home/presentation/home_shell.dart';
import 'package:sefer/core/utils/time_ago.dart';

class RecentFilesSection extends StatelessWidget {
  const RecentFilesSection({super.key, required this.recents});

  final List<RecentEntry> recents;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _RecentsHeading(),
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

class _RecentsHeading extends StatelessWidget {
  const _RecentsHeading();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: SectionLabel('Recently opened')),
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          child: TextButton(
            onPressed: () => context.push('/recents'),
            child: const Text('See all'),
          ),
        ),
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
    final isFavorite = ref.watch(favoritePathsProvider).contains(entry.path);

    return Semantics(
      button: true,
      label: 'Open $title',
      child: GestureDetector(
        onTap: () => _open(context, ref),
        onLongPress: () => context.push('/recents', extra: entry.path),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            formatTimeAgo(entry.openedAt),
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                        if (isFavorite)
                          const Icon(
                            Icons.favorite,
                            size: 12,
                            color: AppColors.brand,
                            semanticLabel: 'Favorite',
                          ),
                      ],
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
    context.push('/reader', extra: ReaderRouteArguments(path: entry.path));
  }
}
