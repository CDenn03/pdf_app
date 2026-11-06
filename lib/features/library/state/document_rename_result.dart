import 'package:sefer/core/services/document_keys_service.dart';

sealed class DocumentRenameResult {
  const DocumentRenameResult();

  String get userMessage;
}

class DocumentRenameSuccess extends DocumentRenameResult {
  const DocumentRenameSuccess(this.newPath);

  final String newPath;

  @override
  String get userMessage => 'Renamed.';
}

class DocumentRenameRejected extends DocumentRenameResult {
  const DocumentRenameRejected(this.reason);

  final String reason;

  @override
  String get userMessage => reason;
}

class DocumentRenamePartiallyMigrated extends DocumentRenameResult {
  const DocumentRenamePartiallyMigrated(this.newPath, this.failures);

  final String newPath;
  final List<KeyMigrationFailure> failures;

  @override
  String get userMessage =>
      'Renamed, but some data could not be moved: '
      '${failures.map((f) => f.store).join(', ')}.';
}
