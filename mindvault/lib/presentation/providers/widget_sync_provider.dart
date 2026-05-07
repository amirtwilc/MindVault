import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/widget_data_service.dart';
import 'categories_provider.dart';
import 'notes_provider.dart';

final widgetDataServiceProvider =
    Provider<WidgetDataService>((_) => WidgetDataService());

/// Watched from HomeShell to keep the Android home widget in sync with
/// the latest notes + categories whenever the app is in the foreground.
final widgetSyncProvider = Provider<void>((ref) {
  final notes = ref.watch(allNotesProvider).valueOrNull ?? [];
  final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
  ref.read(widgetDataServiceProvider).updateWidget(
        categories: categories,
        allNotes: notes,
      );
});
