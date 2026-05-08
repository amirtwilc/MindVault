import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/domain/entities/category.dart';
import 'package:mindvault/domain/entities/note.dart';
import 'package:mindvault/l10n/app_localizations.dart';
import 'package:mindvault/presentation/providers/categories_provider.dart';
import 'package:mindvault/presentation/providers/notes_provider.dart';
import 'package:mindvault/presentation/screens/widget/widget_category_notes_screen.dart';

class _FakeCategoriesNotifier extends CategoriesNotifier {
  _FakeCategoriesNotifier(this._cats);
  final List<Category> _cats;

  @override
  Future<List<Category>> build() async => _cats;
}

Category _cat(String id, String name) => Category(
      id: id,
      userId: 'u1',
      name: name,
      sortOrder: 0,
      color: null,
      lastUsedAt: DateTime(2024),
      createdAt: DateTime(2024),
    );

Note _note(String id, String title, String categoryId) => Note(
      id: id,
      userId: 'u1',
      categoryId: categoryId,
      title: title,
      body: '',
      isPrivate: false,
      isPinned: false,
      pinOrder: null,
      lastUsedAt: DateTime(2024),
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      lastOpenedAt: null,
    );

Widget _harness({
  required List<Category> categories,
  required List<Note> notesForCategory,
  required String categoryId,
  String? initialName,
}) {
  return ProviderScope(
    overrides: [
      categoriesProvider.overrideWith(() => _FakeCategoriesNotifier(categories)),
      notesByCategoryLocalProvider
          .overrideWith((ref, _) => Stream.value(notesForCategory)),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppStrings.localizationsDelegates,
      supportedLocales: AppStrings.supportedLocales,
      home: WidgetCategoryNotesScreen(
        categoryId: categoryId,
        initialName: initialName,
      ),
    ),
  );
}

void main() {
  testWidgets('renders the resolved category name in the header',
      (tester) async {
    await tester.pumpWidget(_harness(
      categories: [_cat('c1', 'Work'), _cat('c2', 'Personal')],
      notesForCategory: const [],
      categoryId: 'c1',
    ));
    await tester.pumpAndSettle();

    expect(find.text('Work'), findsOneWidget);
  });

  testWidgets('falls back to initialName before categoriesProvider resolves',
      (tester) async {
    await tester.pumpWidget(_harness(
      categories: const [],
      notesForCategory: const [],
      categoryId: 'unknown',
      initialName: 'Books',
    ));
    // Even after settle, the category isn't in the provider — header should
    // still show the deep-link-supplied name rather than going blank.
    await tester.pumpAndSettle();

    expect(find.text('Books'), findsOneWidget);
  });

  testWidgets('renders a row per note in the category', (tester) async {
    await tester.pumpWidget(_harness(
      categories: [_cat('c1', 'Work')],
      notesForCategory: [
        _note('n1', 'First note', 'c1'),
        _note('n2', 'Second note', 'c1'),
      ],
      categoryId: 'c1',
    ));
    await tester.pumpAndSettle();

    expect(find.text('First note'), findsOneWidget);
    expect(find.text('Second note'), findsOneWidget);
  });

  testWidgets('shows the empty-state message when there are no notes',
      (tester) async {
    await tester.pumpWidget(_harness(
      categories: [_cat('c1', 'Work')],
      notesForCategory: const [],
      categoryId: 'c1',
    ));
    await tester.pumpAndSettle();

    final l = await AppStrings.delegate.load(const Locale('en'));
    expect(find.text(l.notesListEmptyTitle), findsOneWidget);
  });

}
