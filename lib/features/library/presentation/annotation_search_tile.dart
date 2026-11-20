import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:sefer/core/models/annotation_color.dart';
import 'package:sefer/core/models/annotation_type.dart';
import 'package:sefer/core/theme/app_spacing.dart';
import 'package:sefer/features/library/domain/annotation_search.dart';
import 'package:sefer/features/reader/domain/reader_route_arguments.dart';

class AnnotationSearchTile extends StatelessWidget {
  const AnnotationSearchTile({
    super.key,
    required this.hit,
    this.showBook = false,
  });

  final AnnotationSearchHit hit;
  final bool showBook;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, typeLabel) = switch (hit.annotation.type) {
      AnnotationType.highlight => (Icons.highlight, 'Highlight'),
      AnnotationType.note => (Icons.sticky_note_2_outlined, 'Note'),
      AnnotationType.bookmark => (Icons.bookmark_outline, 'Bookmark'),
    };
    final page = hit.annotation.page;
    final details = [
      if (showBook) hit.bookName,
      typeLabel,
      'p. $page',
    ].join(' · ');

    return ListTile(
      enabled: !hit.unavailable,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxs,
      ),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: hit.annotation.color.overlay,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: hit.annotation.color.solid),
      ),
      title: Text(
        hit.snippet.isEmpty ? typeLabel : hit.snippet,
        style: theme.textTheme.bodyMedium,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        hit.unavailable ? '$details · File unavailable' : details,
        style: theme.textTheme.bodySmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: hit.unavailable
          ? null
          : () => context.push(
              '/reader',
              extra: ReaderRouteArguments(
                path: hit.bookPath,
                initialPage: page,
              ),
            ),
    );
  }
}
