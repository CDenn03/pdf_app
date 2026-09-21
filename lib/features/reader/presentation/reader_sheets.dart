import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sefer/core/models/annotation.dart' as app;
import 'package:sefer/core/models/annotation_color.dart';
import 'package:sefer/core/models/note_entry.dart';
import 'package:sefer/features/reader/state/providers.dart';

class NoteMarkerSheet extends ConsumerStatefulWidget {
  const NoteMarkerSheet({super.key, required this.annotation});

  final app.Annotation annotation;

  @override
  ConsumerState<NoteMarkerSheet> createState() => _NoteMarkerSheetState();
}

class _NoteMarkerSheetState extends ConsumerState<NoteMarkerSheet> {
  List<NoteEntry>? _entries;
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final entries = await ref
          .read(annotationNotifierProvider.notifier)
          .loadNoteEntries(widget.annotation.id);
      if (mounted) setState(() => _entries = entries);
    } catch (e, s) {
      developer.log(
        'Failed to load note entries',
        name: 'sefer.reader',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      if (mounted) setState(() => _entries = []);
    }
  }

  Future<void> _addEntry() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _saving = true);
    await ref
        .read(annotationNotifierProvider.notifier)
        .addNoteEntry(widget.annotation.id, text);
    _controller.clear();
    await _load();
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.annotation.color;
    final entries = _entries;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color.solid,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text('Note', style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          if (entries == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator.adaptive(),
              ),
            )
          else if (entries.isEmpty)
            Text(
              'No entries yet.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: entries.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (_, i) =>
                    _NoteEntryTile(entry: entries[i], color: color),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Add a note…',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.all(10),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _saving ? null : _addEntry,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoteEntryTile extends StatelessWidget {
  const _NoteEntryTile({required this.entry, required this.color});

  final NoteEntry entry;
  final AnnotationColor color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 40,
            margin: const EdgeInsets.only(right: 10, top: 2),
            decoration: BoxDecoration(
              color: color.solid,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.text, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  _formatTime(entry.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m ${m == 1 ? 'min' : 'mins'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h ${h == 1 ? 'hr' : 'hrs'} ago';
    }
    if (diff.inDays < 7) {
      final d = diff.inDays;
      return '$d ${d == 1 ? 'day' : 'days'} ago';
    }
    if (diff.inDays < 30) {
      final w = (diff.inDays / 7).floor();
      return '$w ${w == 1 ? 'week' : 'weeks'} ago';
    }
    final local = dt.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }
}

class BookmarkSheet extends ConsumerWidget {
  const BookmarkSheet({super.key, required this.annotation});

  final app.Annotation annotation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = annotation.color;
    final label = annotation.label ?? 'Page ${annotation.page}';

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color.solid,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: 'Remove bookmark',
                onPressed: () {
                  Navigator.of(context).pop();
                  ref
                      .read(annotationNotifierProvider.notifier)
                      .removeAnnotation(annotation.id);
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Page ${annotation.page}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
