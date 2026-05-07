import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show Bidi;

TextDirection? firstStrongOf(String s) {
  if (s.isEmpty) return null;
  if (Bidi.startsWithRtl(s)) return TextDirection.rtl;
  if (Bidi.startsWithLtr(s)) return TextDirection.ltr;
  return null;
}

(int, int) _paragraphBounds(String text, int cursor) {
  final c = cursor.clamp(0, text.length);
  final lineStart = c == 0 ? 0 : text.lastIndexOf('\n', c - 1) + 1;
  final next = text.indexOf('\n', c);
  final lineEnd = next == -1 ? text.length : next;
  return (lineStart, lineEnd);
}

/// Direction the body editor should lock to for the duration of an edit
/// session. Computed once on enter-edit so the field doesn't flip mid-typing.
/// Falls back to the device locale when the body has no strong character.
TextDirection lockedBodyDirection(String body, TextDirection localeDefault) =>
    firstStrongOf(body) ?? localeDefault;

TextDirection paragraphDirectionAt({
  required String text,
  required int cursor,
  required TextDirection localeDefault,
}) {
  if (text.isEmpty) return localeDefault;

  final (start, end) = _paragraphBounds(text, cursor);
  final cursorDir = firstStrongOf(text.substring(start, end));
  if (cursorDir != null) return cursorDir;

  // Walk backwards through previous paragraphs.
  var pos = start;
  while (pos > 0) {
    final prevEnd = pos - 1;
    final prevStart =
        prevEnd == 0 ? 0 : text.lastIndexOf('\n', prevEnd - 1) + 1;
    final prevDir = firstStrongOf(text.substring(prevStart, prevEnd));
    if (prevDir != null) return prevDir;
    pos = prevStart;
  }

  return localeDefault;
}
