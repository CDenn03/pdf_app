/// A single timestamped note entry attached to a note annotation marker.
class NoteEntry {
  const NoteEntry({
    required this.id,
    required this.annotationId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String annotationId;
  final String text;
  final DateTime createdAt;
}
