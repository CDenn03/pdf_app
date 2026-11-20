import 'package:flutter/material.dart';

import 'package:sefer/core/models/collection.dart';

/// Membership rows plus an optional "Add to collection" action.
///
/// Used by the file-actions sheet, recents overflow, and the reader more
/// menu so a book’s collections are listed the same way everywhere.
class DocumentCollectionTiles extends StatelessWidget {
  const DocumentCollectionTiles({
    super.key,
    required this.collections,
    this.onAddToCollection,
    this.onOpenCollection,
    this.titleStyle,
  });

  final List<PdfCollection> collections;
  final VoidCallback? onAddToCollection;
  final ValueChanged<PdfCollection>? onOpenCollection;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final collection in collections)
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text('Show in "${collection.name}"', style: titleStyle),
            onTap: onOpenCollection == null
                ? null
                : () => onOpenCollection!(collection),
          ),
        if (onAddToCollection != null)
          ListTile(
            leading: const Icon(Icons.collections_bookmark_outlined),
            title: Text('Add to collection', style: titleStyle),
            onTap: onAddToCollection,
          ),
      ],
    );
  }
}
