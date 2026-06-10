import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:sefer/core/services/pdf_scan_service.dart';

void main() {
  const scanner = PdfScanService();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('scan_test_');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('depth limit stops recursion beyond depth 8', () async {
    // Build a 10-level deep directory chain with a PDF at the bottom.
    var current = tempDir;
    for (var i = 0; i < 10; i++) {
      current = await Directory(p.join(current.path, 'd$i')).create();
    }
    await File(p.join(current.path, 'deep.pdf')).create();

    final results = await scanner.walkDirectory(tempDir);
    // The file sits at depth 10 — beyond the depth-8 guard, so it is excluded.
    expect(results, isEmpty);
  });

  test('shallow PDFs within depth limit are found', () async {
    final shallow = await Directory(p.join(tempDir.path, 'books')).create();
    await File(p.join(shallow.path, 'a.pdf')).create();

    final results = await scanner.walkDirectory(tempDir);
    expect(results, contains(p.join(shallow.path, 'a.pdf')));
  });

  test('result cap stops scan at 5001 entries', () async {
    // Create 5002 PDF files in a flat directory.
    final flat = await Directory(p.join(tempDir.path, 'flat')).create();
    for (var i = 0; i < 5002; i++) {
      await File(p.join(flat.path, '$i.pdf')).create();
    }

    final results = await scanner.walkDirectory(tempDir);
    // Guard check fires when results.length > 5000, so max possible is 5001.
    expect(results.length, lessThanOrEqualTo(5001));
  });
}
