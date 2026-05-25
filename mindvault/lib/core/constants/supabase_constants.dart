/// Supabase project configuration.
///
/// Values are injected at build time via --dart-define-from-file=dart-define.json
/// so that credentials never appear in source code.
///
/// To build: flutter build apk --release --dart-define-from-file=dart-define.json
/// To run:   flutter run --dart-define-from-file=dart-define.json
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
  static const String tierLimitsTable = 'tier_limits';
  static const String categoriesTable = 'categories';
  static const String notesTable = 'notes';
  static const String jotsTable = 'jots';
  static const String jotAiUsageTable = 'jot_ai_usage';
  static const String noteRemindersTable = 'note_reminders';
  static const String checklistItemsTable = 'checklist_items';
  static const String userKeysTable = 'user_keys';
  static const String analyticsEventsTable = 'analytics_events';

  // Realtime channels
  static const String notesChannel = 'notes_realtime';
  static const String jotsChannel = 'jots_realtime';
  static const String noteRemindersChannel = 'note_reminders_realtime';
  static const String checklistItemsChannel = 'checklist_items_realtime';
  static const String categoriesChannel = 'categories_realtime';
}
