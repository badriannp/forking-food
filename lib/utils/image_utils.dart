String getResizedImageUrl({
  required String originalUrl,
  required int size, // 100, 300, or 600
  String? format = 'webp',
}) {
  final uri = Uri.parse(originalUrl);

  final fileName = uri.pathSegments.last; // ex: main.jpg
  final resizedName = fileName.replaceAllMapped(
    RegExp(r'(.+)(\.\w+)$'),
    (match) => '${match.group(1)}_${size}x$size.$format',
  );

  final newPathSegments = [...uri.pathSegments]..removeLast();
  newPathSegments.add(resizedName);

  return uri.replace(pathSegments: newPathSegments).toString();
}