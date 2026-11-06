import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sefer/core/theme/reading_mode.dart';
import 'package:sefer/features/library/state/library_providers.dart';

class ReaderFavoriteButton extends ConsumerStatefulWidget {
  const ReaderFavoriteButton({
    super.key,
    required this.documentPath,
    required this.readingMode,
  });

  final String documentPath;
  final ReadingMode readingMode;

  @override
  ConsumerState<ReaderFavoriteButton> createState() =>
      _ReaderFavoriteButtonState();
}

class _ReaderFavoriteButtonState extends ConsumerState<ReaderFavoriteButton> {
  bool _saving = false;

  Future<void> _toggle(bool isFavorite) async {
    setState(() => _saving = true);
    try {
      await ref.read(libraryEntriesProvider.notifier).setFavoriteForPaths({
        widget.documentPath,
      }, favorite: !isFavorite);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = ref.watch(
      favoritePathsProvider.select(
        (paths) => paths.contains(widget.documentPath),
      ),
    );
    return IconButton(
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: widget.readingMode.primaryText,
      ),
      onPressed: _saving ? null : () => _toggle(isFavorite),
      tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
    );
  }
}
