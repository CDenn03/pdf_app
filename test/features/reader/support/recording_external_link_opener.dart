import 'package:sefer/features/reader/domain/external_link_opener.dart';

class RecordingExternalLinkOpener implements ExternalLinkOpener {
  final List<Uri> opened = [];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return true;
  }
}
