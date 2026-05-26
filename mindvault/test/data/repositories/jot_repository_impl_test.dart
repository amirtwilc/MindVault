import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/data/local/database/app_database.dart';
import 'package:mindvault/data/models/jot_model.dart';
import 'package:mindvault/data/remote/supabase/supabase_jots_datasource.dart';
import 'package:mindvault/data/repositories/jot_repository_impl.dart';
import 'package:mindvault/services/encryption_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fake_secure_storage.dart';

class MockJotsDatasource extends Mock implements SupabaseJotsDatasource {}

JotModel _remoteJot({
  required EncryptionService encryption,
  required Key key,
  String id = 'jot-1',
  String userId = 'user-1',
  String text = 'Remote thought',
  DateTime? createdAt,
  DateTime? updatedAt,
  DateTime? handledAt,
  String? aiSuggestionJson,
}) {
  final now = DateTime.now().toUtc();
  return JotModel(
    id: id,
    userId: userId,
    text: encryption.encrypt(text, key),
    createdAt: (createdAt ?? now).toIso8601String(),
    updatedAt: (updatedAt ?? createdAt ?? now).toIso8601String(),
    handledAt: handledAt?.toIso8601String(),
    aiSuggestionJson: aiSuggestionJson == null
        ? null
        : encryption.encrypt(aiSuggestionJson, key),
  );
}

JotsTableCompanion _localJot({
  String id = 'jot-1',
  String userId = 'user-1',
  String text = 'Local thought',
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime.now().toUtc();
  return JotsTableCompanion(
    id: Value(id),
    userId: Value(userId),
    jotText: Value(text),
    createdAt: Value(createdAt ?? now),
    updatedAt: Value(updatedAt ?? createdAt ?? now),
  );
}

void main() {
  late MockJotsDatasource remote;
  late AppDatabase db;
  late EncryptionService encryption;
  late Key aesKey;
  late JotRepositoryImpl repo;
  const userId = 'user-1';

  setUp(() {
    remote = MockJotsDatasource();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    encryption = EncryptionService(FakeSecureStorage());
    aesKey = encryption.generateKey();
    repo = JotRepositoryImpl(
      remote: remote,
      local: db,
      encryption: encryption,
      aesKey: aesKey,
      userId: userId,
    );

    when(() => remote.fetchAllJots()).thenAnswer((_) async => []);
    when(() => remote.fetchJotById(any())).thenAnswer((_) async => null);
    when(() => remote.subscribeToJots(any())).thenReturn(null);
  });

  tearDown(() => db.close());

  group('createJot', () {
    test('writes to Drift before calling Supabase', () async {
      var driftWrittenBeforeRemote = false;
      when(() => remote.insertJot(any())).thenAnswer((inv) async {
        driftWrittenBeforeRemote =
            (await db.select(db.jotsTable).get()).isNotEmpty;
        final payload = inv.positionalArguments.single as Map<String, dynamic>;
        return _remoteJot(
          encryption: encryption,
          key: aesKey,
          id: payload['id'] as String,
          text: 'Capture this',
        );
      });

      await repo.createJot(text: 'Capture this');

      expect(driftWrittenBeforeRemote, isTrue);
    });

    test('encrypts remote text payload but keeps plaintext locally', () async {
      Map<String, dynamic>? payload;
      when(() => remote.insertJot(any())).thenAnswer((inv) async {
        payload = inv.positionalArguments.single as Map<String, dynamic>;
        return _remoteJot(
          encryption: encryption,
          key: aesKey,
          id: payload!['id'] as String,
          text: 'Secret thought',
        );
      });

      final jot = await repo.createJot(text: 'Secret thought');

      expect(payload!['text'], isNot(equals('Secret thought')));
      expect(encryption.decrypt(payload!['text'] as String, aesKey),
          equals('Secret thought'));
      expect((await db.getJot(jot.id))!.jotText, equals('Secret thought'));
    });

    test('queues create_spark when Supabase fails', () async {
      when(() => remote.insertJot(any())).thenThrow(Exception('offline'));

      final jot = await repo.createJot(text: 'Offline thought');

      final ops = await db.getPendingOps();
      expect(ops.single.opType, equals('create_spark'));
      expect(ops.single.recordId, equals(jot.id));
      expect((await db.getJot(jot.id))!.jotText, equals('Offline thought'));
    });
  });

  group('syncPendingOps', () {
    test('replays pending create_spark with encrypted payload', () async {
      await db.upsertJot(_localJot(id: 'pending', text: 'Queued thought'));
      await db.upsertPendingOp('pending', 'create_spark', 'pending');

      Map<String, dynamic>? payload;
      when(() => remote.upsertJot(any())).thenAnswer((inv) async {
        payload = inv.positionalArguments.single as Map<String, dynamic>;
        return _remoteJot(
          encryption: encryption,
          key: aesKey,
          id: payload!['id'] as String,
          text: 'Queued thought',
        );
      });

      await repo.syncPendingOps();

      expect(payload!['id'], equals('pending'));
      expect(payload!['text'], isNot(equals('Queued thought')));
      expect(encryption.decrypt(payload!['text'] as String, aesKey),
          equals('Queued thought'));
      expect(await db.getPendingOps(), isEmpty);
    });

    test('delete_spark removes remote and local rows after realtime reinsert',
        () async {
      await db.upsertJot(_localJot(id: 'deleted'));
      await db.upsertPendingOp('del_deleted', 'delete_spark', 'deleted');
      when(() => remote.deleteJot('deleted')).thenAnswer((_) async {});

      await repo.syncPendingOps();

      verify(() => remote.deleteJot('deleted')).called(1);
      expect(await db.getJot('deleted'), isNull);
      expect(await db.getPendingOps(), isEmpty);
    });
  });

  test('realtime merge decrypts remote jots', () async {
    void Function(bool isDelete, Map<String, dynamic> record)? callback;
    when(() => remote.subscribeToJots(any())).thenAnswer((inv) {
      callback = inv.positionalArguments.single as void Function(
          bool, Map<String, dynamic>);
    });

    repo.startSync();
    callback!(
      false,
      _remoteJot(
        encryption: encryption,
        key: aesKey,
        id: 'remote',
        text: 'Synced thought',
      ).toJson(),
    );
    await Future<void>.delayed(Duration.zero);

    expect((await db.getJot('remote'))!.jotText, equals('Synced thought'));
  });

  test('clearReminder clears nullable reminderAt locally and remotely',
      () async {
    final reminderAt = DateTime(2026, 1, 2, 9).toUtc();
    await db.upsertJot(
      _localJot(id: 'jot-1').copyWith(reminderAt: Value(reminderAt)),
    );
    Map<String, dynamic>? payload;
    when(() => remote.upsertJot(any())).thenAnswer((inv) async {
      payload = inv.positionalArguments.single as Map<String, dynamic>;
      return _remoteJot(
        encryption: encryption,
        key: aesKey,
        id: 'jot-1',
        text: 'Local thought',
      );
    });

    await repo.clearReminder('jot-1');

    expect(payload!['reminder_at'], isNull);
    expect((await db.getJot('jot-1'))!.reminderAt, isNull);
  });
}
