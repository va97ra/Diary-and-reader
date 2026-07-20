class BookScanFolder {
  const BookScanFolder({required this.uri, required this.name});

  factory BookScanFolder.fromJson(Map<String, dynamic> json) => BookScanFolder(
    uri: json['uri']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
  );

  final String uri;
  final String name;

  Map<String, dynamic> toJson() => {'uri': uri, 'name': name};
}
