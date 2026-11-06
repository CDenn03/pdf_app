import 'package:sefer/features/reader/domain/selected_text_sharer.dart';

class RecordingTextSharer implements SelectedTextSharer {
  final List<String> shared = [];

  @override
  Future<void> share(String text) async => shared.add(text);
}
