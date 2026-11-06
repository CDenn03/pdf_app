import 'package:flutter/widgets.dart';

import 'package:sefer/core/theme/reader_layout_mode.dart';
import 'package:sefer/features/reader/presentation/continuous_reader_viewport.dart';
import 'package:sefer/features/reader/presentation/book_flip_reader_viewport.dart';
import 'package:sefer/features/reader/presentation/paged_reader_viewport.dart';
import 'package:sefer/features/reader/presentation/reader_viewport_config.dart';

class ReaderViewport extends StatelessWidget {
  const ReaderViewport({
    super.key,
    required this.layoutMode,
    required this.config,
  });

  final ReaderLayoutMode layoutMode;
  final ReaderViewportConfig config;

  @override
  Widget build(BuildContext context) => switch (layoutMode) {
    ReaderLayoutMode.continuous => ContinuousReaderViewport(config: config),
    ReaderLayoutMode.paged => PagedReaderViewport(config: config),
    ReaderLayoutMode.bookFlip => BookFlipReaderViewport(config: config),
  };
}
