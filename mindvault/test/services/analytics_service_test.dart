import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/services/analytics_service.dart';

void main() {
  group('NoopAnalyticsService', () {
    test('track() does not throw regardless of event type', () {
      const svc = NoopAnalyticsService();
      expect(() => svc.track('session_started'), returnsNormally);
      expect(() => svc.track('note_created', metadata: {'key': 'value'}), returnsNormally);
      expect(() => svc.track('note_deleted'), returnsNormally);
      expect(() => svc.track('category_created'), returnsNormally);
    });

    test('track() accepts null metadata without throwing', () {
      const svc = NoopAnalyticsService();
      expect(() => svc.track('session_started', metadata: null), returnsNormally);
    });
  });
}
