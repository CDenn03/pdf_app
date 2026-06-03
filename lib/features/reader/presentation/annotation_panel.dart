import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_app/core/models/annotation.dart';
import 'package:pdf_app/core/models/annotation_color.dart';
import 'package:pdf_app/core/models/annotation_type.dart';
import 'package:pdf_app/features/reader/state/providers.dart';
import 'package:pdf_app/shared/widgets/overlay_panel.dart';

/// Shows the annotation panel as a bottom sheet with tabs.
Future<void> showAnnotationPanel({
  required BuildContext context,
  required String pdfId,
  required void Function(int page) onNavigate,
}) {
  return OverlayPanel.show(
    context: context,
    title: 'Annotations',
    builder: (ctx) => _AnnotationPanelContent(
      pdfId: pdfId,
      onNavigate: (page) {
        Navigator.of(ctx).pop();
        onNavigate(page);
      },
    ),
  );
}

class _AnnotationPanelContent extends ConsumerStatefulWidget {
  const _AnnotationPanelContent({
    required this.pdfId,
    required this.onNavigate,
  });

  final String pdfId;
  final void Function(int page) onNavigate;

  @override
  ConsumerState<_AnnotationPanelContent> createState() =>
      _AnnotationPanelContentState();
}

class _AnnotationPanelContentState
    extends ConsumerState<_AnnotationPanelContent>
    with SingleTickerProviderStateMixin {
  List<Annotation>? _annotations;
  late final TabController _tabController;

  static const _tabs = [
    (label: 'All', type: null),
    (label: 'Highlights', type: AnnotationType.highlight),
    (label: 'Notes', type: AnnotationType.note),
    (label: 'Bookmarks', type: AnnotationType.bookmark),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final annotations = await ref
        .read(annotationNotifierProvider.notifier)
        .loadAllForPdf(widget.pdfId);
    if (mounted) setState(() => _annotations = annotations);
  }

  @override
  Widget build(BuildContext context) {
    final annotations = _annotations;

    if (annotations == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _tabs
              .map((t) => Tab(
                    text: t.type == null
                        ? '${t.label} (${annotations.length})'
                        : '${t.label} (${annotations.where((a) => a.type == t.type).length})',
                  ))
              .toList(),
        ),
        Flexible(
          child: TabBarView(
            controller: _tabController,
            children: _tabs.map((t) {
              final filtered = t.type == null
                  ? annotations
                  : annotations.where((a) => a.type == t.type).toList();
              return _AnnotationList(
                annotations: filtered,
                onNavigate: widget.onNavigate,
                onDelete: (id) async {
                  await ref
                      .read(annotationNotifierProvider.notifier)
                      .removeAnnotation(id);
                  _load();
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _AnnotationList extends StatelessWidget {
  const _AnnotationList({
    required this.annotations,
    required this.onNavigate,
    required this.onDelete,
  });

  final List<Annotation> annotations;
  final void Function(int page) onNavigate;
  final void Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    if (annotations.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            'Nothing here yet.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Group by page.
    final byPage = <int, List<Annotation>>{};
    for (final a in annotations) {
      (byPage[a.page] ??= []).add(a);
    }
    final pages = byPage.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: pages.length,
      itemBuilder: (context, index) {
        final page = pages[index];
        final items = byPage[page]!;
        return _PageGroup(
          page: page,
          annotations: items,
          onNavigate: onNavigate,
          onDelete: onDelete,
        );
      },
    );
  }
}

class _PageGroup extends StatelessWidget {
  const _PageGroup({
    required this.page,
    required this.annotations,
    required this.onNavigate,
    required this.onDelete,
  });

  final int page;
  final List<Annotation> annotations;
  final void Function(int page) onNavigate;
  final void Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Text('Page $page', style: theme.textTheme.labelMedium),
        ),
        ...annotations.map(
          (a) => _AnnotationItem(
            annotation: a,
            onTap: () => onNavigate(a.page),
            onDelete: () => onDelete(a.id),
          ),
        ),
      ],
    );
  }
}

class _AnnotationItem extends StatelessWidget {
  const _AnnotationItem({
    required this.annotation,
    required this.onTap,
    required this.onDelete,
  });

  final Annotation annotation;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, label) = switch (annotation.type) {
      AnnotationType.highlight => (Icons.highlight, 'Highlight'),
      AnnotationType.note => (Icons.sticky_note_2_outlined, 'Note'),
      AnnotationType.bookmark => (Icons.bookmark_outline, 'Bookmark'),
    };

    final displayText = switch (annotation.type) {
      AnnotationType.bookmark => annotation.label ?? label,
      AnnotationType.note => annotation.text ?? label,
      AnnotationType.highlight => label,
    };

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: annotation.color.overlay,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: annotation.color.solid),
      ),
      title: Text(
        displayText,
        style: theme.textTheme.bodyMedium,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(label, style: theme.textTheme.bodySmall),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 18),
        onPressed: onDelete,
        tooltip: 'Delete',
      ),
      onTap: onTap,
    );
  }
}
