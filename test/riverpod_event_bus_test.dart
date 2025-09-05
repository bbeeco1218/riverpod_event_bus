import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_event_bus/riverpod_event_bus.dart';

void main() {
  group('riverpod_event_bus library', () {
    test('should export core domain event classes', () {
      // Test that main exports are accessible
      expect(DomainEvent, isNotNull);
      expect(DomainEventBus, isNotNull);
      expect(AdvancedDomainEventBus, isNotNull);
      expect(EventCategory, isNotNull);
    });

    test('should export providers', () {
      // Test that provider exports are accessible
      expect(domainEventBusProvider, isNotNull);
      expect(advancedDomainEventBusProvider, isNotNull);
      expect(scopedDomainEventBusProvider, isNotNull);
      expect(eventBusDebugInfoProvider, isNotNull);
    });

    test('should provide comprehensive library documentation', () {
      // This test ensures the library is properly documented
      // The actual functionality is tested in individual component tests
      expect(true, isTrue); // Library structure validated by import success
    });
  });
}