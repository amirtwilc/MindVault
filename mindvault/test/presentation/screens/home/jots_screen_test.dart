import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/domain/entities/category.dart';
import 'package:mindvault/domain/entities/jot.dart';
import 'package:mindvault/domain/entities/note.dart';
import 'package:mindvault/l10n/app_localizations.dart';
import 'package:mindvault/presentation/screens/home/jots_screen.dart';

void main() {
  testWidgets('AI suggested updated text is preselected in action sheet',
      (tester) async {
    final now = DateTime(2026, 5, 27, 12).toUtc();
    final category = Category(
      id: 'cat-1',
      userId: 'user-1',
      name: 'General',
      sortOrder: 0,
      lastUsedAt: now,
      createdAt: now,
    );
    final jot = Jot(
      id: 'jot-1',
      userId: 'user-1',
      text: 'messy thought',
      createdAt: now,
      updatedAt: now,
      aiSuggestionJson: jsonEncode({
        'jot_id': 'jot-1',
        'action': 'create_note',
        'confidence': 0.9,
        'title': 'Clean note',
        'category_id': 'cat-1',
        'updated_text': 'Clean thought',
      }),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppStrings.localizationsDelegates,
          supportedLocales: AppStrings.supportedLocales,
          home: Scaffold(
            body: JotActionSheet(
              jot: jot,
              categories: [category],
              notes: const [],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final checkbox = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, 'Update thought text'),
    );
    expect(checkbox.value, isTrue);
    expect(find.text('Clean thought'), findsOneWidget);
  });

  testWidgets('AI add-to-note suggestion keeps the suggested note selected',
      (tester) async {
    final now = DateTime(2026, 5, 27, 12).toUtc();
    final general = Category(
      id: 'cat-1',
      userId: 'user-1',
      name: 'General',
      sortOrder: 0,
      lastUsedAt: now,
      createdAt: now,
    );
    final recipes = Category(
      id: 'cat-2',
      userId: 'user-1',
      name: 'Recipes',
      sortOrder: 1,
      lastUsedAt: now,
      createdAt: now,
    );
    final notes = [
      Note(
        id: 'note-1',
        userId: 'user-1',
        categoryId: 'cat-1',
        title: 'My wife computer',
        body: '',
        isPrivate: false,
        lastUsedAt: now,
        createdAt: now,
        updatedAt: now,
      ),
      Note(
        id: 'note-2',
        userId: 'user-1',
        categoryId: 'cat-2',
        title: 'Lemon cake',
        body: '',
        isPrivate: false,
        lastUsedAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    ];
    final jot = Jot(
      id: 'jot-2',
      userId: 'user-1',
      text: 'When making lemon cake, preheat the stove',
      createdAt: now,
      updatedAt: now,
      aiSuggestionJson: jsonEncode({
        'jot_id': 'jot-2',
        'action': 'add_to_note',
        'confidence': 0.85,
        'note_id': 'note-2',
        'updated_text': 'Preheat the oven',
      }),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppStrings.localizationsDelegates,
          supportedLocales: AppStrings.supportedLocales,
          home: Scaffold(
            body: JotActionSheet(
              jot: jot,
              categories: [general, recipes],
              notes: notes,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recipes'), findsOneWidget);
    expect(find.text('Lemon cake'), findsOneWidget);
    expect(find.text('My wife computer'), findsNothing);
  });
}
