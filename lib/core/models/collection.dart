/// A user-defined collection (folder) for organising library entries.
class PdfCollection {
  final String id;
  final String name;

  const PdfCollection({required this.id, required this.name});

  factory PdfCollection.fromJson(Map<String, dynamic> json) =>
      PdfCollection(id: json['id'] as String, name: json['name'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  PdfCollection copyWith({String? name}) =>
      PdfCollection(id: id, name: name ?? this.name);
}
