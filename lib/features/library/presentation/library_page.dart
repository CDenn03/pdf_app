import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pdf_app/core/models/file_status.dart';
import 'package:pdf_app/features/library/state/library_entry.dart';
import 'package:pdf_app/features/library/state/library_providers.dart';

/// Displays the list of PDF files known to the app.
///
/// Files with [FileStatus.missing] or [FileStatus.corrupt] show as unavailable
/// without removing their annotation records.
class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(libraryEntriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: entries.isEmpty
          ? const Center(child: Text('No PDFs added yet.'))
          : ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) =>
                  _PdfListTile(entry: entries[index]),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(libraryEntriesProvider.notifier).addSample(),
        tooltip: 'Add sample PDF',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PdfListTile extends StatelessWidget {
  const _PdfListTile({required this.entry});

  final LibraryEntry entry;

  @override
  Widget build(BuildContext context) {
    final unavailable = entry.status != FileStatus.ok;
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(
        Icons.picture_as_pdf,
        color: unavailable ? colorScheme.outline : colorScheme.primary,
      ),
      title: Text(
        entry.name,
        style: TextStyle(color: unavailable ? colorScheme.outline : null),
      ),
      subtitle: unavailable
          ? Text('Unavailable', style: TextStyle(color: colorScheme.error))
          : null,
      trailing: unavailable ? null : const Icon(Icons.chevron_right),
      onTap: unavailable
          ? null
          : () => context.go('/reader', extra: entry.path),
    );
  }
}
