# Feature Spec: Robust RTL/LTR Text Handling for Notes

## Goal

Text input and display must correctly support both RTL and LTR languages,
including mixed-language content (example: Hebrew + English in same note).

Users must also be able to:
- highlight text accurately
- select partial text
- copy/paste without broken directionality
- preserve visual correctness during editing and reading

This must feel native and predictable.

---

## Requirements

### Text Direction Detection

- Automatically detect text direction based on first strong character typed
- Arabic, Hebrew → RTL
- English, German → LTR

### Mixed Content

Examples:
- Hebrew sentence with English product names
- English note with Arabic quote

Must render naturally without broken cursor behavior.

### Cursor Behavior

- Cursor placement should start (when note has no strong character) based on the current app's language (Hebrew=right, English=left)
- If user types Enter (\n), cursor on next line should be the same as the previous line (until a strong character is typed)
- Backspace/delete must behave correctly

### Text Selection

- Highlighting must visually match selected content
- No broken selection handles
- Partial selection must work correctly

### Copy Behavior

- Copied text must preserve logical order
- Pasting elsewhere should not produce reversed text

---

## Edge Cases

- Numbers inside Arabic text
- URLs inside RTL paragraphs
- Emojis mixed with RTL
- Bullet lists
- Quoted text
- Multi-line selection
- Notes containing only symbols first

---

## Done When

- Manual testing passes for Hebrew + English mixed notes
- Copy/paste works correctly into external apps
- Cursor behavior feels native
- No broken alignment or reversed rendering

## Perform after completion

Once feature is finished and I approve it, update README.md with information about:
- What the requirement was
- What challenges were met (if were any)
- What design choice was chosen and why
- What design alternatives were strongly considered (if were any) 