class PexelsImage {
  final int id;
  final String url;
  final String photographer;
  final String src;
  final String original;

  PexelsImage({
    required this.id,
    required this.url,
    required this.photographer,
    required this.src,
    required this.original,
  });

  factory PexelsImage.fromJson(Map<String, dynamic> json) {
    return PexelsImage(
      id: json['id'],
      url: json['url'],
      photographer: json['photographer'],
      src: json['src']['medium'],
      original: json['src']['large'] ?? json['src']['original'],
    );
  }
}
