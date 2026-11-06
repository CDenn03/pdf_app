import 'dart:developer' as developer;

import 'package:url_launcher/url_launcher.dart';

import 'package:sefer/features/reader/domain/external_link_opener.dart';

typedef UriLauncher = Future<bool> Function(Uri uri);

Future<bool> launchInExternalApplication(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

class UrlLauncherExternalLinkOpener implements ExternalLinkOpener {
  const UrlLauncherExternalLinkOpener({required UriLauncher launch})
    : _launch = launch;

  static const _allowedSchemes = {'http', 'https', 'mailto'};

  final UriLauncher _launch;

  @override
  Future<bool> open(Uri uri) async {
    if (!_allowedSchemes.contains(uri.scheme)) {
      developer.log(
        'Refused to open link with scheme "${uri.scheme}"',
        name: 'sefer.reader',
        level: 900,
      );
      return false;
    }
    try {
      return await _launch(uri);
    } catch (error, stack) {
      developer.log(
        'Opening link with scheme "${uri.scheme}" failed',
        name: 'sefer.reader',
        level: 1000,
        error: error,
        stackTrace: stack,
      );
      return false;
    }
  }
}
