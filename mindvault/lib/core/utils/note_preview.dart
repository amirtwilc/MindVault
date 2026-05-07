import 'auto_title_generator.dart';

class NotePreview {
  NotePreview._();

  static String displayTitle(String storedTitle, String body) {
    if (storedTitle.isNotEmpty) return storedTitle;
    return AutoTitleGenerator.fromBody(body);
  }

  /// Body text for list-view previews. When [storedTitle] is empty (derived),
  /// removes the tokens that form the title to avoid showing them twice.
  static String previewBody(String storedTitle, String body) {
    if (storedTitle.isNotEmpty) return body;
    if (body.isEmpty) return '';

    final lines = body.split('\n');
    final firstLineTokens = lines[0]
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (firstLineTokens.isEmpty) return body;

    if (firstLineTokens.length <= 4) {
      // Entire first line is the title — preview starts from the next non-empty line.
      final remaining = lines.sublist(1).join('\n');
      // Strip leading whitespace-only lines (e.g. blank separator lines).
      return remaining.replaceFirst(RegExp(r'^([^\S\n]*\n)+'), '');
    } else {
      // First 4 tokens are the title — preview starts from token 5.
      final tail = firstLineTokens.sublist(4).join(' ');
      final afterLines = lines.sublist(1).join('\n');
      return afterLines.isEmpty ? tail : '$tail\n$afterLines';
    }
  }
}
