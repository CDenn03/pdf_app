import 'package:flutter/widgets.dart';

import 'package:sefer/features/reader/presentation/pdfrx_reader_viewport.dart';
import 'package:sefer/features/reader/presentation/reader_viewport_config.dart';

class ContinuousReaderViewport extends StatelessWidget {
  const ContinuousReaderViewport({super.key, required this.config});

  final ReaderViewportConfig config;

  @override
  Widget build(BuildContext context) => PdfrxReaderViewport(config: config);
}
