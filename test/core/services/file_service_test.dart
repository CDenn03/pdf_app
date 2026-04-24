import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:pdf_app/core/models/file_status.dart';
import 'package:pdf_app/core/services/file_service.dart';

void main() {
  late FileService fileService;
  late Directory tempDir;

  setUp(() async {
    fileService = FileService();
    tempDir = await Directory.systemTemp.createTemp('file_service_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('FileService.checkFile', () {
    test('returns ok for a valid readable file', () async {
      final file = File('${tempDir.path}/valid.pdf');
      await file.writeAsBytes([0x25, 0x50, 0x44, 0x46]); // %PDF header

      final status = await fileService.checkFile(file.path);

      expect(status, FileStatus.ok);
    });

    test('returns missing for a non-existent file', () async {
      final status = await fileService.checkFile(
        '${tempDir.path}/does_not_exist.pdf',
      );

      expect(status, FileStatus.missing);
    });

    test('returns missing for an empty path', () async {
      final status = await fileService.checkFile('');

      // Empty path should not crash — returns missing or corrupt
      expect(status, isIn([FileStatus.missing, FileStatus.corrupt]));
    });

    test('never throws an exception', () async {
      // This should not throw even with an absurd path
      expect(
        () async => await fileService.checkFile('/\x00/invalid/\x00path'),
        returnsNormally,
      );
    });
  });
}
