import 'package:path/path.dart' as p;

import 'package:sefer/features/device/domain/device_pdf_entry.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  final megabytes = bytes / (1024 * 1024);
  if (megabytes < 1024) return '${megabytes.toStringAsFixed(1)} MB';
  return '${(megabytes / 1024).toStringAsFixed(1)} GB';
}

String formatModifiedDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';

String deviceEntrySubtitle(DevicePdfEntry entry) {
  return [
    if (entry.sizeBytes != null) formatFileSize(entry.sizeBytes!),
    if (entry.modifiedAt != null) formatModifiedDate(entry.modifiedAt!),
    p.basename(p.dirname(entry.path)),
  ].join(' · ');
}
