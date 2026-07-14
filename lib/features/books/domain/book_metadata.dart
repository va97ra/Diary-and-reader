class BookMetadata {
  const BookMetadata({
    required this.title,
    this.subtitle = '',
    this.author = '',
    this.description = '',
    this.languageCode = 'ru',
    this.series = '',
    this.genre = '',
    this.isbn = '',
    this.publisher = '',
    this.rights = '',
  });

  factory BookMetadata.fromJson(Map<String, dynamic> json) => BookMetadata(
    title: json['title']?.toString() ?? '',
    subtitle: json['subtitle']?.toString() ?? '',
    author: json['author']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    languageCode: json['languageCode'] == 'en' ? 'en' : 'ru',
    series: json['series']?.toString() ?? '',
    genre: json['genre']?.toString() ?? '',
    isbn: json['isbn']?.toString() ?? '',
    publisher: json['publisher']?.toString() ?? '',
    rights: json['rights']?.toString() ?? '',
  );

  final String title;
  final String subtitle;
  final String author;
  final String description;
  final String languageCode;
  final String series;
  final String genre;
  final String isbn;
  final String publisher;
  final String rights;

  BookMetadata copyWith({
    String? title,
    String? subtitle,
    String? author,
    String? description,
    String? languageCode,
    String? series,
    String? genre,
    String? isbn,
    String? publisher,
    String? rights,
  }) => BookMetadata(
    title: title ?? this.title,
    subtitle: subtitle ?? this.subtitle,
    author: author ?? this.author,
    description: description ?? this.description,
    languageCode: languageCode ?? this.languageCode,
    series: series ?? this.series,
    genre: genre ?? this.genre,
    isbn: isbn ?? this.isbn,
    publisher: publisher ?? this.publisher,
    rights: rights ?? this.rights,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'author': author,
    'description': description,
    'languageCode': languageCode,
    'series': series,
    'genre': genre,
    'isbn': isbn,
    'publisher': publisher,
    'rights': rights,
  };
}
