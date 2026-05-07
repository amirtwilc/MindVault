/// Supabase project configuration.
///
/// Values are injected at build time via --dart-define-from-file=dart-define.json
/// so that credentials never appear in source code (even though the anon key is
/// designed to be public, keeping it out of git history is good hygiene).
///
/// To build:   flutter build apk --release --dart-define-from-file=dart-define.json
/// To run:     flutter run --dart-define-from-file=dart-define.json
///
/// Copy dart-define.json.example → dart-define.json and fill in your values.
/// dart-define.json is gitignored.
class SupabaseConstants {
  SupabaseConstants._();

  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static const String googleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  // Tables
  static const String profilesTable = 'profiles';
  static const String categoriesTable = 'categories';
  static const String notesTable = 'notes';
  static const String userKeysTable = 'user_keys';
  static const String analyticsEventsTable = 'analytics_events';

  // Realtime channels
  static const String notesChannel = 'notes_realtime';
  static const String categoriesChannel = 'categories_realtime';
}
