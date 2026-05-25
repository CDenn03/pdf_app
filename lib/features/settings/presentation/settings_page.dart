import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_app/core/providers.dart';
import 'package:pdf_app/core/theme/reading_mode.dart';
import 'package:pdf_app/core/theme/scroll_direction.dart';

/// Global settings screen.
///
/// Lets the user configure the default reading mode and scroll direction.
/// Changes are persisted immediately — no explicit save button needed.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          const _SectionHeader('Reading mode'),
          SegmentedButton<ReadingMode>(
            segments: [
              for (final mode in ReadingMode.values)
                ButtonSegment(value: mode, label: Text(mode.label)),
            ],
            selected: {settings.readingMode},
            onSelectionChanged: (selection) =>
                notifier.setReadingMode(selection.first),
          ),
          const SizedBox(height: 24),
          const _SectionHeader('Scroll direction'),
          SegmentedButton<ScrollDirection>(
            segments: [
              for (final dir in ScrollDirection.values)
                ButtonSegment(value: dir, label: Text(dir.label)),
            ],
            selected: {settings.scrollDirection},
            onSelectionChanged: (selection) =>
                notifier.setScrollDirection(selection.first),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}
