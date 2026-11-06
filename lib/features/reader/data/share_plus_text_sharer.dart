import 'dart:developer' as developer;

import 'package:share_plus/share_plus.dart';

import 'package:sefer/features/reader/domain/selected_text_sharer.dart';

class SharePlusTextSharer implements SelectedTextSharer {
  const SharePlusTextSharer();

  @override
  Future<void> share(String text) async {
    try {
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (error, stack) {
      developer.log(
        'Sharing selected text failed',
        name: 'sefer.reader',
        level: 1000,
        error: error,
        stackTrace: stack,
      );
    }
  }
}
