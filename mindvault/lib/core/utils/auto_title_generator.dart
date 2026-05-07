class AutoTitleGenerator {
  AutoTitleGenerator._();

  /// Returns a title derived from the first non-empty line of [body]:
  /// the first 4 whitespace-separated words (or fewer if the line is shorter).
  /// Returns an empty string only if [body] contains no non-whitespace content.
  static String fromBody(String body) {
    for (final line in body.split('\n')) {
      final words = line
          .trim()
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toList();
      if (words.isEmpty) continue;
      return words.take(4).join(' ');
    }
    return '';
  }
}
