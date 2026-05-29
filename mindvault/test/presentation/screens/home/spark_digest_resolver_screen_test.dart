import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mindvault/domain/entities/jot.dart';
import 'package:mindvault/domain/repositories/jot_repository.dart';
import 'package:mindvault/presentation/providers/auth_provider.dart';
import 'package:mindvault/presentation/providers/encryption_provider.dart';
import 'package:mindvault/presentation/providers/jots_provider.dart';
import 'package:mindvault/presentation/screens/home/spark_digest_resolver_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockUser extends Mock implements User {}

class _FakeJotRepository implements JotRepository {
  @override
  void startSync() {}

  @override
  void stopSync() {}

  @override
  Stream<List<Jot>> watchUnhandledJots({
    JotSortOrder sortOrder = JotSortOrder.oldestFirst,
  }) =>
      Stream.value(const []);

  @override
  Future<List<Jot>> getUnhandledJots({
    JotSortOrder sortOrder = JotSortOrder.oldestFirst,
  }) async =>
      const [];

  @override
  Future<Jot?> getJotById(String id) async => null;

  @override
  Future<Jot> createJot({required String text}) => throw UnimplementedError();

  @override
  Future<Jot?> updateJot({
    required String id,
    String? text,
    DateTime? handledAt,
    DateTime? aiProcessedAt,
    String? aiSuggestionJson,
    String? aiSuggestionRunId,
    DateTime? reminderAt,
  }) =>
      throw UnimplementedError();

  @override
  Future<Jot?> clearReminder(String id) => throw UnimplementedError();

  @override
  Future<void> markHandled(String id) => throw UnimplementedError();

  @override
  Future<void> deleteJot(String id) => throw UnimplementedError();

  @override
  Future<void> deleteJots(List<String> ids) => throw UnimplementedError();

  @override
  Future<void> syncPendingOps() async {}
}

void main() {
  testWidgets('resolves Spark digest notification into Sparks route',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/spark-digest',
      routes: [
        GoRoute(
          path: '/spark-digest',
          builder: (_, __) => const SparkDigestResolverScreen(),
        ),
        GoRoute(
          path: '/home/sparks',
          builder: (_, __) => const Scaffold(body: Text('sparks ready')),
        ),
        GoRoute(
          path: '/auth',
          builder: (_, __) => const Scaffold(body: Text('auth')),
        ),
        GoRoute(
          path: '/pin-entry',
          builder: (_, __) => const Scaffold(body: Text('pin')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(AuthState(AuthChangeEvent.signedIn, null)),
          ),
          currentUserProvider.overrideWithValue(_MockUser()),
          encryptionReadyProvider.overrideWith((ref) async => true),
          jotRepositoryProvider.overrideWithValue(_FakeJotRepository()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('sparks ready'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
