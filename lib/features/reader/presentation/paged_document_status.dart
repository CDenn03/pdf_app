import 'dart:developer' as developer;

import 'package:flutter/material.dart';

class PagedDocumentLoading extends StatelessWidget {
  const PagedDocumentLoading({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator.adaptive());
}

class PagedDocumentError extends StatefulWidget {
  const PagedDocumentError({
    super.key,
    required this.path,
    required this.error,
    this.stackTrace,
  });

  final String path;
  final Object error;
  final StackTrace? stackTrace;

  @override
  State<PagedDocumentError> createState() => _PagedDocumentErrorState();
}

class _PagedDocumentErrorState extends State<PagedDocumentError> {
  @override
  void initState() {
    super.initState();
    developer.log(
      'Opening ${widget.path} failed',
      name: 'sefer.reader',
      level: 1000,
      error: widget.error,
      stackTrace: widget.stackTrace,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'This document could not be opened.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
      ),
    );
  }
}
