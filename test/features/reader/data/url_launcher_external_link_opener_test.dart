import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/features/reader/data/url_launcher_external_link_opener.dart';

void main() {
  late List<Uri> launched;

  UrlLauncherExternalLinkOpener openerLaunching(
    Future<bool> Function(Uri) launch,
  ) => UrlLauncherExternalLinkOpener(
    launch: (uri) {
      launched.add(uri);
      return launch(uri);
    },
  );

  setUp(() => launched = []);

  for (final address in [
    'http://example.com',
    'https://example.com/a?b=c',
    'mailto:reader@example.com',
  ]) {
    test('given $address, it is launched', () async {
      final opener = openerLaunching((_) async => true);

      final opened = await opener.open(Uri.parse(address));

      expect(opened, isTrue);
      expect(launched, [Uri.parse(address)]);
    });
  }

  for (final address in [
    'javascript:alert(1)',
    'file:///etc/passwd',
    'tel:+15551234',
    'intent://scan/#Intent;scheme=zxing;end',
    'relative/path',
  ]) {
    test('given $address, it is refused without launching', () async {
      final opener = openerLaunching((_) async => true);

      final opened = await opener.open(Uri.parse(address));

      expect(opened, isFalse);
      expect(launched, isEmpty);
    });
  }

  test('given a launcher that declines, it reports false', () async {
    final opener = openerLaunching((_) async => false);

    expect(await opener.open(Uri.parse('https://example.com')), isFalse);
  });

  test('given a launcher that throws, it reports false', () async {
    final opener = openerLaunching((_) => throw StateError('no handler'));

    expect(await opener.open(Uri.parse('https://example.com')), isFalse);
  });
}
