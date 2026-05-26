import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/data/local/database/app_database.dart';
import 'package:mindvault/presentation/providers/auth_provider.dart';
import 'package:mindvault/presentation/providers/database_provider.dart';
import 'package:mindvault/presentation/providers/notes_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockUser extends Mock implements User {
  _MockUser(this._id);
  final String _id;
  @override
  String get id => _id;
}

NotesTableCompanion _row({
  required String id,
  required String userId,
  required String categoryId,
  String title = 'note',
}) {
  final now = DateTime.now().toUtc();
  return NotesTableCompanion.insert(
    id: id,
    userId: userId,
    categoryId: categoryId,
    title: title,
    lastUsedAt: now,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // Two users, both with notes in a category whose id collides ('c1')
    // — simulates a stale widget configured by user A being tapped after
    // user B signs in on the same device.
    await db.upsertNote(
        _row(id: 'a1', userId: 'user-A', categoryId: 'c1', title: 'A-note'));
    await db.upsertNote(
        _row(id: 'b1', userId: 'user-B', categoryId: 'c1', title: 'B-note'));
  });

  tearDown(() async {
    await db.close();
  });

  test('returns an empty stream when no user is signed in', () async {
    final container = ProviderContainer(overrides: [
      currentUserProvider.overrideWithValue(null),
      appDatabaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);

    // Drain one frame so the StreamProvider can resolve.
    final sub = container.listen(
      notesByCategoryLocalProvider('c1'),
      (_, __) {},
    );
    await Future<void>.delayed(Duration.zero);

    // Stream.empty() never emits a value, so the provider stays in `loading`.
    // The defensive property is that no `data` ever arrives — i.e. residual
    // plaintext rows in Drift cannot be rendered post-sign-out.
    expect(sub.read().hasValue, isFalse);
  });

  test('only returns rows belonging to the signed-in user', () async {
    final container = ProviderContainer(overrides: [
      currentUserProvider.overrideWithValue(_MockUser('user-B')),
      appDatabaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);

    final notes = await container
        .read(notesByCategoryLocalProvider('c1').future)
        .timeout(const Duration(seconds: 1));

    expect(notes.map((n) => n.id), ['b1']);
    expect(notes.every((n) => n.userId == 'user-B'), isTrue);
  });
}
