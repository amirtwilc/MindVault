class AiConstants {
  AiConstants._();

  static const int ftsTopK = 15;
  static const int noteBodyMaxChars = 600;
  static const int tokenBudget = 8000; // total chars of note context sent to Gemini

  // Gemini 2.5 Flash free tier hard cap: 15 RPM, 1500 RPD
  // We stay 1 below to avoid racing the boundary.
  static const int maxRequestsPerMinute = 14;

  // Per-tier daily limits are defined in TierLimits.free() / TierLimits.pro().
  // Change them there to adjust for all users; no rebuild required for the
  // server-side enforcement (update the edge function constants too).

  static const Duration cacheTtl = Duration(hours: 24);

  static const String systemPrompt = 'You are a personal knowledge assistant. '
      'Answer ONLY using the provided notes. '
      'If the answer is not in the notes, say so clearly. '
      'Answer in the same language as the user question when possible. '
      'Be concise and direct. '
      'After your answer, on its own line, write exactly: '
      '"Sources: Title1, Title2" listing only note titles you actually used. '
      'Omit the Sources line entirely if you used no notes.';
}
