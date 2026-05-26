class AiConstants {
  AiConstants._();

  static const int ftsTopK = 15;
  static const int noteBodyMaxChars = 600;
  static const int tokenBudget =
      8000; // total chars of note context sent to Gemini

  // Gemini 2.5 Flash free tier hard cap: 15 RPM, 1500 RPD
  // We stay 1 below to avoid racing the boundary.
  static const int maxRequestsPerMinute = 14;

  static const Duration cacheTtl = Duration(hours: 24);
}
