import 'dart:io';

String? findPdfiumLibrary() {
  final buildRoot = Directory(
    '${Directory.current.path}/.dart_tool/hooks_runner/shared/pdfium_dart/build',
  );
  if (!buildRoot.existsSync()) return null;
  for (final entity in buildRoot.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('linux-x64/libpdfium.so')) {
      return entity.path;
    }
  }
  return null;
}
