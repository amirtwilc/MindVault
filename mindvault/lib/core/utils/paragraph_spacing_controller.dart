import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SelectedContent;
import 'package:flutter/services.dart';

import 'bidi_utils.dart';

/// A [TextEditingController] that visually distinguishes paragraph breaks
/// (Enter key) from soft-wrapped lines by elevating the line height of the
/// first visible character after each `\n`, and relying on
/// [TextLeadingDistribution.proportional] to push most of the extra line-box
/// height above that character. The "above" space becomes the visual gap
/// between paragraphs; the small "below" residual is contained within the
/// next paragraph (~20% of leading for typical fonts) and is subtle enough
/// to be unnoticeable.
///
/// Previous approaches that put the elevated height on the last character
/// *before* `\n` had a visible bug: when Enter was pressed at the end of a
/// wrapped paragraph, the last char landed on the last wrapped line,
/// inflating that line's box and growing the gap between the two soft-wrapped
/// lines. This approach avoids that entirely — if there is no next paragraph
/// yet, no elevation is applied to any visible-char line.
///
/// For empty paragraphs (consecutive `\n`s mid-text) the next `\n` itself is
/// elevated — its line carries the paragraph height even without a glyph.
/// For a trailing `\n` (where the cursor sits on a brand-new empty line), a
/// zero-width-space styled with the paragraph height is appended at the very
/// end of the rendered span so that empty line gets the same visual gap.
/// The ZWS is only ever appended after the entire editable string, so cursor
/// offsets inside the string are never disturbed.
///
/// Callers must set `strutStyle: StrutStyle(forceStrutHeight: false)` on the
/// [TextField] so that per-span heights are not clamped.
class ParagraphSpacingController extends TextEditingController {
  ParagraphSpacingController({super.text});

  static const double _lineHeight = 1.0;
  // With proportional leading on a typical font, (height - 1.0) * ~0.8 * fontSize
  // of extra space appears above the elevated char — for bodyLarge (16sp) at
  // height 2.0 that's ~13dp, clearly visible as a paragraph break without
  // feeling excessive.
  static const double _paragraphHeight = 2.5;

  // Zero-width-space (U+200B) — invisible glyph used to carry an elevated
  // line height on an otherwise empty line (cursor sitting after a trailing
  // `\n`).
  static const String _zws = '​';

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = (style ?? const TextStyle()).copyWith(height: _lineHeight);
    final paraStart = base.copyWith(
      height: _paragraphHeight,
      leadingDistribution: TextLeadingDistribution.proportional,
    );

    final TextSpan body;
    if (!value.isComposingRangeValid || !withComposing) {
      body = _spannedText(text, base, paraStart);
    } else {
      final composingBase =
          base.merge(const TextStyle(decoration: TextDecoration.underline));
      final composingStart =
          paraStart.merge(const TextStyle(decoration: TextDecoration.underline));
      final composing = value.composing;
      body = TextSpan(
        style: style,
        children: [
          _spannedText(text.substring(0, composing.start), base, paraStart),
          _spannedText(text.substring(composing.start, composing.end),
              composingBase, composingStart),
          _spannedText(text.substring(composing.end), base, paraStart),
        ],
      );
    }

    // The cursor's line after a trailing `\n` has no glyph to carry a height.
    // Append a zero-width-space styled with the paragraph height *outside* the
    // editable text so visible-text offsets (selection, IME, taps within the
    // string) are unchanged.
    if (text.endsWith('\n')) {
      return TextSpan(
        style: style,
        children: [body, TextSpan(text: _zws, style: paraStart)],
      );
    }

    return body;
  }

  /// Elevates the first character of every paragraph that follows a `\n`. If
  /// that character is itself a `\n` (an empty paragraph), the `\n` is
  /// elevated — Flutter still applies the height to the line the `\n` sits
  /// on, producing a visible gap.
  static TextSpan _spannedText(
      String text, TextStyle normal, TextStyle paraStart) {
    if (!text.contains('\n')) return TextSpan(text: text, style: normal);

    // Positions that begin a new paragraph (the char immediately after each
    // `\n`, when it is in range).
    final paragraphStarts = <int>{};
    for (var i = 0; i < text.length - 1; i++) {
      if (text[i] == '\n') paragraphStarts.add(i + 1);
    }

    final spans = <InlineSpan>[];
    var start = 0;
    for (var i = 0; i < text.length; i++) {
      if (paragraphStarts.contains(i)) {
        if (i > start) {
          spans.add(TextSpan(text: text.substring(start, i), style: normal));
        }
        spans.add(TextSpan(text: text[i], style: paraStart));
        start = i + 1;
      }
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: normal));
    }
    return TextSpan(children: spans, style: normal);
  }

  /// Builds a read-only [TextSpan] with the same paragraph spacing applied.
  /// Use with [SelectableText.rich] or [RichText].
  static TextSpan buildReadSpan(String text, TextStyle baseStyle) {
    final base = baseStyle.copyWith(height: _lineHeight);
    final paraStart = base.copyWith(
      height: _paragraphHeight,
      leadingDistribution: TextLeadingDistribution.proportional,
    );
    return _spannedText(text, base, paraStart);
  }

  /// Renders [text] with each paragraph in its own [Directionality] resolved
  /// from the paragraph's first strong character (falling back to the
  /// previous paragraph's direction, then to [localeDefault]).
  ///
  /// The whole column is wrapped in a [SelectionArea] so the user can
  /// drag-select across paragraphs (and copy mixed-direction text in one go).
  /// Each paragraph is a plain [Text] — not [SelectableText] — because
  /// SelectableText owns its own selection scope and would block the parent
  /// SelectionArea from chaining across paragraphs.
  ///
  /// The [SelectionArea]'s copy button is overridden to re-insert the `\n`
  /// characters that SelectionArea loses when concatenating text from
  /// separate [Text] widgets.
  static Widget buildBidiAwareView(
    String text,
    TextStyle baseStyle,
    TextDirection localeDefault,
  ) {
    return _BidiAwareView(
      text: text,
      baseStyle: baseStyle,
      localeDefault: localeDefault,
    );
  }
}

// ---------------------------------------------------------------------------
// Read-mode bidi view widget
// ---------------------------------------------------------------------------

/// Finds [flat] (selected text with `\n` stripped by SelectionArea) inside
/// [original] (the full text including `\n`) and returns the corresponding
/// substring from [original], restoring any newlines within the range.
///
/// Falls back to [flat] unchanged when matching is ambiguous or fails.
String _reinsertNewlines(String flat, String original) {
  if (flat.isEmpty || !original.contains('\n')) return flat;

  final stripped = original.replaceAll('\n', '');
  final idx = stripped.indexOf(flat);
  if (idx < 0) return flat;

  // Map [idx, idx+flat.length) in the stripped string back to the span in
  // the original that may contain `\n` characters.
  var pos = 0;
  var start = -1;
  var end = original.length;
  for (var i = 0; i < original.length; i++) {
    if (original[i] == '\n') continue;
    if (pos == idx && start < 0) start = i;
    pos++;
    if (pos == idx + flat.length) {
      end = i + 1;
      break;
    }
  }
  if (start < 0) return flat;
  return original.substring(start, end);
}

/// StatefulWidget returned by [ParagraphSpacingController.buildBidiAwareView].
///
/// Captures [SelectedContent] via [SelectionArea.onSelectionChanged] so the
/// custom Copy handler can reconstruct the original text (with `\n`) from the
/// flat string that [SelectionArea] produces by default.
class _BidiAwareView extends StatefulWidget {
  const _BidiAwareView({
    required this.text,
    required this.baseStyle,
    required this.localeDefault,
  });

  final String text;
  final TextStyle baseStyle;
  final TextDirection localeDefault;

  @override
  State<_BidiAwareView> createState() => _BidiAwareViewState();
}

class _BidiAwareViewState extends State<_BidiAwareView> {
  SelectedContent? _lastSelection;

  List<Widget> _buildChildren() {
    final paragraphs = widget.text.split('\n');
    final dirs = <TextDirection>[];
    var lastDir = widget.localeDefault;
    for (final p in paragraphs) {
      final detected = firstStrongOf(p);
      final dir = detected ?? lastDir;
      dirs.add(dir);
      if (detected != null) lastDir = detected;
    }

    final fontSize = widget.baseStyle.fontSize ?? 14;
    // Gap inserted between consecutive non-empty paragraphs (mirrors the
    // ~1.2× extra leading that ParagraphSpacingController adds in edit mode).
    final paragraphGap = fontSize * 0.8;
    // Height for blank lines (empty paragraphs between two \n).
    final emptyHeight = fontSize * 0.9;
    final children = <Widget>[];
    var isFirstContent = true;
    for (var i = 0; i < paragraphs.length; i++) {
      final p = paragraphs[i];
      if (p.isEmpty) {
        children.add(SizedBox(height: emptyHeight));
        continue;
      }
      if (!isFirstContent) {
        children.add(SizedBox(height: paragraphGap));
      }
      children.add(Directionality(
        textDirection: dirs[i],
        child: Text(
          p,
          style: widget.baseStyle,
          textAlign: TextAlign.start,
        ),
      ));
      isFirstContent = false;
    }
    return children;
  }

  Widget _buildContextMenu(
      BuildContext context, SelectableRegionState state) {
    final items = state.contextMenuButtonItems.map((item) {
      if (item.type == ContextMenuButtonType.copy) {
        return ContextMenuButtonItem(
          type: ContextMenuButtonType.copy,
          onPressed: () {
            ContextMenuController.removeAny();
            final flat = _lastSelection?.plainText ?? '';
            Clipboard.setData(ClipboardData(
              text: _reinsertNewlines(flat, widget.text),
            ));
          },
        );
      }
      return item;
    }).toList();

    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: state.contextMenuAnchors,
      buttonItems: items,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      onSelectionChanged: (content) => _lastSelection = content,
      contextMenuBuilder: _buildContextMenu,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _buildChildren(),
      ),
    );
  }
}
