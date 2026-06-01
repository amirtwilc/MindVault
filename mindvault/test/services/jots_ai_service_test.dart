import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/domain/entities/category.dart';
import 'package:mindvault/domain/entities/jot.dart';
import 'package:mindvault/domain/entities/note.dart';
import 'package:mindvault/services/jots_ai_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeJotsAiBackend implements JotsAiBackend {
  Map<String, dynamic> response;
  JotsAiBackendException? exception;
  int callCount = 0;
  Map<String, dynamic>? lastRequest;

  _FakeJotsAiBackend(this.response, {this.exception});

  @override
  Future<Map<String, dynamic>> call(Map<String, dynamic> request) async {
    callCount++;
    lastRequest = request;
    final exception = this.exception;
    if (exception != null) throw exception;
    return response;
  }
}

Jot _jot({
  required String id,
  String text = 'Thought',
  DateTime? createdAt,
  DateTime? aiProcessedAt,
}) {
  final base = DateTime(2026, 1, 1, 9).toUtc();
  return Jot(
    id: id,
    userId: 'user-1',
    text: text,
    createdAt: createdAt ?? base,
    updatedAt: createdAt ?? base,
    aiProcessedAt: aiProcessedAt,
  );
}

Category _category({String id = 'cat-1', String name = 'General'}) {
  final now = DateTime(2026, 1, 1, 9).toUtc();
  return Category(
    id: id,
    userId: 'user-1',
    name: name,
    sortOrder: 0,
    lastUsedAt: now,
    createdAt: now,
  );
}

Note _note({
  String id = 'note-1',
  String title = 'Note',
  String categoryId = 'cat-1',
  bool isPrivate = false,
  DateTime? updatedAt,
  DateTime? lastOpenedAt,
}) {
  final now = DateTime(2026, 1, 1, 9).toUtc();
  return Note(
    id: id,
    userId: 'user-1',
    categoryId: categoryId,
    title: title,
    body: '',
    isPrivate: isPrivate,
    lastUsedAt: updatedAt ?? now,
    createdAt: now,
    updatedAt: updatedAt ?? now,
    lastOpenedAt: lastOpenedAt,
  );
}

Future<JotsAiService> _service(
  _FakeJotsAiBackend backend,
) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return JotsAiService(
    backend: backend,
    quota: JotsAiQuotaStore(prefs),
  );
}

void main() {
  const locale = Locale('en', 'US');

  test('does not call backend when there are no eligible jots', () async {
    final backend = _FakeJotsAiBackend({'run_id': 'run', 'suggestions': []});
    final service = await _service(backend);

    final result = await service.organize(
      jots: [_jot(id: 'sent', aiProcessedAt: DateTime.now().toUtc())],
      categories: [_category()],
      notes: const [],
      locale: locale,
    );

    expect(result, isNull);
    expect(backend.callCount, equals(0));
  });

  test('sends only the oldest 30 unsent jots', () async {
    final backend = _FakeJotsAiBackend({'run_id': 'run', 'suggestions': []});
    final service = await _service(backend);
    final base = DateTime(2026, 1, 1, 9).toUtc();
    final jots = [
      for (var i = 0; i < 35; i++)
        _jot(
          id: 'jot-$i',
          createdAt: base.add(Duration(minutes: i)),
        ),
    ];

    final result = await service.organize(
      jots: jots.reversed.toList(),
      categories: [_category()],
      notes: const [],
      locale: locale,
    );

    final sent = backend.lastRequest!['jots'] as List;
    expect(sent.length, equals(30));
    expect(sent.first['id'], equals('jot-0'));
    expect(sent.last['id'], equals('jot-29'));
    expect(backend.lastRequest!['local_now'], isA<String>());
    expect(backend.lastRequest!['time_zone_offset_minutes'], isA<int>());
    expect(backend.lastRequest!['time_zone_name'], isA<String>());
    expect(result!.sentCount, equals(30));
    expect(result.limitedToThirty, isTrue);
  });

  test('does not locally block when previous local usage exists', () async {
    SharedPreferences.setMockInitialValues({
      'jots_ai_day_tokens': 99,
      'jots_ai_day_date':
          DateTime.now().toUtc().toIso8601String().split('T').first,
    });
    final prefs = await SharedPreferences.getInstance();
    final backend = _FakeJotsAiBackend({'run_id': 'run', 'suggestions': []});
    final service = JotsAiService(
      backend: backend,
      quota: JotsAiQuotaStore(prefs),
    );

    final result = await service.organize(
      jots: [_jot(id: 'jot-1')],
      categories: [_category()],
      notes: const [],
      locale: locale,
    );

    expect(result, isNotNull);
    expect(backend.callCount, equals(1));
  });

  test('maps edge quota response to quota exception', () async {
    final backend = _FakeJotsAiBackend(
      {'run_id': 'run', 'suggestions': []},
      exception: const JotsAiBackendException(
        'quota_exceeded',
        httpStatus: 429,
      ),
    );
    final service = await _service(backend);

    await expectLater(
      service.organize(
        jots: [_jot(id: 'jot-1')],
        categories: [_category()],
        notes: const [],
        locale: locale,
      ),
      throwsA(isA<JotsAiQuotaExceeded>()),
    );
    expect(backend.callCount, equals(1));
  });

  test('excludes private note titles from AI context', () async {
    final backend = _FakeJotsAiBackend({'run_id': 'run', 'suggestions': []});
    final service = await _service(backend);

    await service.organize(
      jots: [_jot(id: 'jot-1')],
      categories: [_category()],
      notes: [
        _note(id: 'public', title: 'Public title'),
        _note(id: 'private', title: 'Secret title', isPrivate: true),
      ],
      locale: locale,
    );

    final notes = backend.lastRequest!['notes'] as List;
    expect(notes.map((note) => note['title']), contains('Public title'));
    expect(notes.map((note) => note['title']), isNot(contains('Secret title')));
  });

  test('sends compact note context sorted by recency', () async {
    final backend = _FakeJotsAiBackend({'run_id': 'run', 'suggestions': []});
    final service = await _service(backend);
    final base = DateTime(2026, 1, 1, 9).toUtc();

    await service.organize(
      jots: [_jot(id: 'jot-1')],
      categories: [_category()],
      notes: [
        _note(id: 'older', title: 'Older', updatedAt: base),
        _note(
          id: 'opened',
          title: 'Opened',
          updatedAt: base,
          lastOpenedAt: base.add(const Duration(days: 3)),
        ),
        _note(
          id: 'updated',
          title: 'Updated',
          updatedAt: base.add(const Duration(days: 2)),
        ),
      ],
      locale: locale,
    );

    final notes = backend.lastRequest!['notes'] as List;
    expect(notes.map((note) => note['id']),
        equals(['opened', 'updated', 'older']));
    for (final note in notes.cast<Map>()) {
      expect(note.containsKey('category_name'), isFalse);
      expect(note.containsKey('updated_at'), isFalse);
      expect(note.containsKey('last_opened_at'), isFalse);
    }
  });

  test('drops malformed, low-confidence, and hallucinated suggestions',
      () async {
    final backend = _FakeJotsAiBackend({
      'run_id': 'run',
      'suggestions': [
        'bad',
        {
          'jot_id': 'jot-1',
          'action': 'create_note',
          'confidence': 0.2,
          'category_id': 'cat-1',
        },
        {
          'jot_id': 'ghost',
          'action': 'create_note',
          'confidence': 0.9,
          'category_id': 'cat-1',
        },
        {
          'jot_id': 'jot-1',
          'action': 'create_note',
          'confidence': 0.9,
          'category_id': 'made-up',
        },
        {
          'jot_id': 'jot-2',
          'action': 'add_to_note',
          'confidence': 0.9,
          'note_id': 'missing',
        },
        {
          'jot_id': 'jot-2',
          'action': 'create_note',
          'confidence': 0.9,
          'category_id': 'cat-1',
          'updated_text': List.filled(101, 'x').join(),
        },
      ],
    });
    final service = await _service(backend);

    final result = await service.organize(
      jots: [_jot(id: 'jot-1'), _jot(id: 'jot-2')],
      categories: [_category()],
      notes: [_note()],
      locale: locale,
    );

    expect(result!.suggestions, isEmpty);
    expect(result.processedJotIds, equals(['jot-1', 'jot-2']));
  });

  test('keeps valid partial suggestions', () async {
    final reminderAt = DateTime(2026, 1, 2, 8).toUtc().toIso8601String();
    final backend = _FakeJotsAiBackend({
      'run_id': 'run',
      'suggestions': [
        {
          'jot_id': 'jot-1',
          'action': 'create_note',
          'confidence': 0.8,
          'title': 'Groceries',
          'category_id': 'cat-1',
          'note_type': 'checklist',
          'updated_text': 'Milk',
        },
        {
          'jot_id': 'jot-2',
          'action': 'reminder',
          'confidence': 0.8,
          'reminder_at': reminderAt,
        },
      ],
    });
    final service = await _service(backend);

    final result = await service.organize(
      jots: [_jot(id: 'jot-1'), _jot(id: 'jot-2'), _jot(id: 'jot-3')],
      categories: [_category()],
      notes: [_note()],
      locale: locale,
    );

    expect(result!.suggestions.map((s) => s.jotId), equals(['jot-1', 'jot-2']));
    expect(result.processedJotIds, equals(['jot-1', 'jot-2', 'jot-3']));
    expect(result.suggestions.first.noteType, equals('checklist'));
    expect(result.suggestions.first.updatedText, equals('Milk'));
    expect(result.suggestions.last.reminderAt, isNotNull);
  });
}
