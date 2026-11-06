import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/core/models/file_status.dart';
import 'package:sefer/core/services/file_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late FileService fileService;
  late Directory tempDir;

  setUp(() async {
    fileService = const FileService();
    tempDir = await Directory.systemTemp.createTemp('file_service_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<File> seedPdf(String name, List<int> bytes) async {
    final file = File(p.join(tempDir.path, name));
    await file.writeAsBytes(bytes);
    return file;
  }

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

  group('FileService.rename', () {
    test('renames the file and preserves bytes', () async {
      final bytes = [0x25, 0x50, 0x44, 0x46, 0x2d, 0x31];
      final file = await seedPdf('old.pdf', bytes);

      final result = await fileService.rename(file.path, 'new');

      expect(p.basename(result), 'new.pdf');
      expect(await file.exists(), isFalse);
      final renamed = File(result);
      expect(await renamed.exists(), isTrue);
      expect(await renamed.readAsBytes(), bytes);
    });

    test('appends .pdf when absent', () async {
      final file = await seedPdf('old.pdf', [0x25]);

      final result = await fileService.rename(file.path, 'report');

      expect(p.basename(result), 'report.pdf');
    });

    test('does not double the extension for a name typed with .pdf', () async {
      final file = await seedPdf('old.pdf', [0x25]);

      final result = await fileService.rename(file.path, 'report.pdf');

      expect(p.basename(result), 'report.pdf');
    });

    test('treats the .pdf extension case-insensitively', () async {
      final file = await seedPdf('old.pdf', [0x25]);

      final result = await fileService.rename(file.path, 'report.PDF');

      expect(p.basename(result), 'report.PDF');
    });

    test('fails with nameTaken and leaves both files intact', () async {
      final source = await seedPdf('old.pdf', [0x01]);
      final existing = await seedPdf('taken.pdf', [0x02]);

      await expectLater(
        () => fileService.rename(source.path, 'taken'),
        throwsA(
          isA<FileOperationException>().having(
            (e) => e.reason,
            'reason',
            FileOperationReason.nameTaken,
          ),
        ),
      );
      expect(await source.exists(), isTrue);
      expect(await existing.exists(), isTrue);
      expect(await existing.readAsBytes(), [0x02]);
    });

    test('rejects an empty name and leaves the file untouched', () async {
      final file = await seedPdf('old.pdf', [0x01]);

      await expectLater(
        () => fileService.rename(file.path, ''),
        throwsA(
          isA<FileOperationException>().having(
            (e) => e.reason,
            'reason',
            FileOperationReason.invalidName,
          ),
        ),
      );
      expect(await file.exists(), isTrue);
    });

    test('rejects a whitespace-only name', () async {
      final file = await seedPdf('old.pdf', [0x01]);

      await expectLater(
        () => fileService.rename(file.path, '   '),
        throwsA(
          isA<FileOperationException>().having(
            (e) => e.reason,
            'reason',
            FileOperationReason.invalidName,
          ),
        ),
      );
      expect(await file.exists(), isTrue);
    });

    test('rejects a dot-only name', () async {
      final file = await seedPdf('old.pdf', [0x01]);

      await expectLater(
        () => fileService.rename(file.path, '...'),
        throwsA(
          isA<FileOperationException>().having(
            (e) => e.reason,
            'reason',
            FileOperationReason.invalidName,
          ),
        ),
      );
      expect(await file.exists(), isTrue);
    });

    test('rejects a name that is only the extension', () async {
      final file = await seedPdf('old.pdf', [0x01]);

      await expectLater(
        () => fileService.rename(file.path, '.pdf'),
        throwsA(
          isA<FileOperationException>().having(
            (e) => e.reason,
            'reason',
            FileOperationReason.invalidName,
          ),
        ),
      );
      expect(await file.exists(), isTrue);
    });

    test('rejects a forward-slash separator', () async {
      final file = await seedPdf('old.pdf', [0x01]);

      await expectLater(
        () => fileService.rename(file.path, 'sub/new'),
        throwsA(
          isA<FileOperationException>().having(
            (e) => e.reason,
            'reason',
            FileOperationReason.invalidName,
          ),
        ),
      );
      expect(await file.exists(), isTrue);
    });

    test('rejects a backslash separator', () async {
      final file = await seedPdf('old.pdf', [0x01]);

      await expectLater(
        () => fileService.rename(file.path, r'sub\new'),
        throwsA(
          isA<FileOperationException>().having(
            (e) => e.reason,
            'reason',
            FileOperationReason.invalidName,
          ),
        ),
      );
      expect(await file.exists(), isTrue);
    });

    test('reports notFound for a missing source file', () async {
      await expectLater(
        () => fileService.rename(p.join(tempDir.path, 'ghost.pdf'), 'new'),
        throwsA(
          isA<FileOperationException>().having(
            (e) => e.reason,
            'reason',
            FileOperationReason.notFound,
          ),
        ),
      );
    });

    test('reports unsupportedPath for an asset and does not throw '
        'FileSystemException', () async {
      await expectLater(
        () => fileService.rename('assets/sample.pdf', 'new'),
        throwsA(
          isA<FileOperationException>().having(
            (e) => e.reason,
            'reason',
            FileOperationReason.unsupportedPath,
          ),
        ),
      );
      await expectLater(
        () => fileService.rename('assets/sample.pdf', 'new'),
        throwsA(isNot(isA<FileSystemException>())),
      );
    });
  });

  group('FileService.delete', () {
    test('removes the file', () async {
      final file = await seedPdf('doomed.pdf', [0x01]);

      await fileService.delete(file.path);

      expect(await file.exists(), isFalse);
    });

    test('reports notFound for a missing file', () async {
      await expectLater(
        () => fileService.delete(p.join(tempDir.path, 'ghost.pdf')),
        throwsA(
          isA<FileOperationException>().having(
            (e) => e.reason,
            'reason',
            FileOperationReason.notFound,
          ),
        ),
      );
    });

    test('reports unsupportedPath for an asset and does not throw '
        'FileSystemException', () async {
      await expectLater(
        () => fileService.delete('assets/sample.pdf'),
        throwsA(
          isA<FileOperationException>().having(
            (e) => e.reason,
            'reason',
            FileOperationReason.unsupportedPath,
          ),
        ),
      );
      await expectLater(
        () => fileService.delete('assets/sample.pdf'),
        throwsA(isNot(isA<FileSystemException>())),
      );
    });
  });
}
