package app.amir.mindvault

import android.graphics.Color

/// Fallback dot color (Material grey 500) used when a category has no
/// color set or the stored value can't be parsed.
internal const val DEFAULT_DOT_COLOR: Int = 0xFF9E9E9E.toInt()

/// Parses an Android color string. Whatever `Color.parseColor` accepts is
/// accepted here — at minimum `#RRGGBB` and `#AARRGGBB` (the only forms the
/// app currently writes), but also the named-color list. Falls back to a
/// neutral grey when the value is missing or unparseable.
internal fun parseColorOrDefault(hex: String?): Int {
    if (hex.isNullOrBlank()) return DEFAULT_DOT_COLOR
    return try {
        Color.parseColor(hex)
    } catch (_: IllegalArgumentException) {
        DEFAULT_DOT_COLOR
    }
}

/// First-strong directional check — returns true iff the first character
/// with strong directionality is RTL (Hebrew, Arabic, etc.). Neutrals
/// (digits, punctuation, parentheses from a "(N)" suffix) are skipped so
/// labels like "Work (3)" stay LTR while "עבודה" stays RTL. Used by both
/// widget factories to lay out a row by the dominant direction of its
/// label, independent of device locale.
internal fun firstStrongIsRtl(s: String): Boolean {
    for (c in s) {
        when (Character.getDirectionality(c)) {
            Character.DIRECTIONALITY_RIGHT_TO_LEFT,
            Character.DIRECTIONALITY_RIGHT_TO_LEFT_ARABIC,
            Character.DIRECTIONALITY_RIGHT_TO_LEFT_EMBEDDING,
            Character.DIRECTIONALITY_RIGHT_TO_LEFT_OVERRIDE -> return true
            Character.DIRECTIONALITY_LEFT_TO_RIGHT,
            Character.DIRECTIONALITY_LEFT_TO_RIGHT_EMBEDDING,
            Character.DIRECTIONALITY_LEFT_TO_RIGHT_OVERRIDE -> return false
            else -> continue
        }
    }
    return false
}
