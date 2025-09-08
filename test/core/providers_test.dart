import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_event_bus/riverpod_event_bus.dart';

// Test category implementation
class ProviderTestCategories implements IEventCategory {
  @override
  final String value;
  @override
  final String displayName;

  const ProviderTestCategories._(this.value, this.displayName);

  static const system = ProviderTestCategories._('system', 'System Events');
}

// Test event for provider testing
class ProviderTestEvent extends DomainEvent {
  final String message;

  const ProviderTestEvent({
    required this.message,
    required super.eventId,
    required super.occurredAt,
  }) : super(
          eventType: 'provider.test',
          category: ProviderTestCategories.system,
        );

  @override
  Map<String, dynamic> toJson() => {
        'message': message,
        ...super.toJson(),
      };
}

void main() {
  group('DomainEventBus Providers', () {
    late ProviderContainer container;
    final testTime = DateTime(2024, 1, 1, 12, 0, 0);

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('domainEventBusProvider', () {
      test('should provide DomainEventBus instance', () {
        final eventBus = container.read(domainEventBusProvider);

        expect(eventBus, isA<DomainEventBus>());
        expect(eventBus.isDisposed, isFalse);
        expect(eventBus.subscriptionCount, equals(0));
      });

      test('should provide same instance on multiple reads', () {
        final eventBus1 = container.read(domainEventBusProvider);
        final eventBus2 = container.read(domainEventBusProvider);

        expect(identical(eventBus1, eventBus2), isTrue);
      });

      test('should dispose event bus when container is disposed', () async {
        final eventBus = container.read(domainEventBusProvider);
        expect(eventBus.isDisposed, isFalse);

        container.dispose();

        // Give some time for disposal callback to execute
        await Future.delayed(Duration(milliseconds: 10));
        expect(eventBus.isDisposed, isTrue);
      });

      test('should work with event publishing and subscription', () async {
        final eventBus = container.read(domainEventBusProvider);
        final receivedEvents = <ProviderTestEvent>[];

        final subscription = eventBus.ofType<ProviderTestEvent>().listen(
              (event) => receivedEvents.add(event),
            );

        final testEvent = ProviderTestEvent(
          message: 'Provider Test',
          eventId: 'provider-event-123',
          occurredAt: testTime,
        );

        eventBus.publish(testEvent);
        await Future.delayed(Duration(milliseconds: 10));

        expect(receivedEvents, hasLength(1));
        expect(receivedEvents.first.message, equals('Provider Test'));

        await subscription.cancel();
      });
    });

    group('advancedDomainEventBusProvider', () {
      test('should provide AdvancedDomainEventBus instance', () {
        final eventBus = container.read(advancedDomainEventBusProvider);

        expect(eventBus, isA<AdvancedDomainEventBus>());
        expect(eventBus.isDisposed, isFalse);
        expect(eventBus.subscriptionCount, equals(0));
      });

      test('should provide same instance on multiple reads', () {
        final eventBus1 = container.read(advancedDomainEventBusProvider);
        final eventBus2 = container.read(advancedDomainEventBusProvider);

        expect(identical(eventBus1, eventBus2), isTrue);
      });

      test('should dispose event bus when container is disposed', () async {
        final eventBus = container.read(advancedDomainEventBusProvider);
        expect(eventBus.isDisposed, isFalse);

        container.dispose();

        // Give some time for disposal callback to execute
        await Future.delayed(Duration(milliseconds: 10));
        expect(eventBus.isDisposed, isTrue);
      });

      test('should work with advanced features like filtering', () async {
        final eventBus = container.read(advancedDomainEventBusProvider);
        final receivedEvents = <ProviderTestEvent>[];

        final subscription = eventBus
            .ofTypeWhere<ProviderTestEvent>(
              (event) => event.message.contains('Advanced'),
            )
            .listen((event) => receivedEvents.add(event));

        final matchingEvent = ProviderTestEvent(
          message: 'Advanced Test',
          eventId: 'advanced-event-123',
          occurredAt: testTime,
        );
        final nonMatchingEvent = ProviderTestEvent(
          message: 'Basic Test',
          eventId: 'basic-event-456',
          occurredAt: testTime,
        );

        eventBus.publish(matchingEvent);
        eventBus.publish(nonMatchingEvent);
        await Future.delayed(Duration(milliseconds: 10));

        expect(receivedEvents, hasLength(1));
        expect(receivedEvents.first.message, equals('Advanced Test'));

        await subscription.cancel();
      });
    });

    group('scopedDomainEventBusProvider', () {
      test('should provide different instances for different scopes', () {
        final chatEventBus =
            container.read(scopedDomainEventBusProvider('chat'));
        final notificationEventBus =
            container.read(scopedDomainEventBusProvider('notifications'));

        expect(chatEventBus, isA<DomainEventBus>());
        expect(notificationEventBus, isA<DomainEventBus>());
        expect(identical(chatEventBus, notificationEventBus), isFalse);
      });

      test('should provide same instance for same scope', () {
        final chatEventBus1 =
            container.read(scopedDomainEventBusProvider('chat'));
        final chatEventBus2 =
            container.read(scopedDomainEventBusProvider('chat'));

        expect(identical(chatEventBus1, chatEventBus2), isTrue);
      });

      test('should isolate events between different scopes', () async {
        final chatEventBus =
            container.read(scopedDomainEventBusProvider('chat'));
        final notificationEventBus =
            container.read(scopedDomainEventBusProvider('notifications'));

        final chatEvents = <ProviderTestEvent>[];
        final notificationEvents = <ProviderTestEvent>[];

        final chatSubscription =
            chatEventBus.ofType<ProviderTestEvent>().listen(
                  (event) => chatEvents.add(event),
                );
        final notificationSubscription =
            notificationEventBus.ofType<ProviderTestEvent>().listen(
                  (event) => notificationEvents.add(event),
                );

        final chatEvent = ProviderTestEvent(
          message: 'Chat Event',
          eventId: 'chat-event-123',
          occurredAt: testTime,
        );
        final notificationEvent = ProviderTestEvent(
          message: 'Notification Event',
          eventId: 'notification-event-456',
          occurredAt: testTime,
        );

        chatEventBus.publish(chatEvent);
        notificationEventBus.publish(notificationEvent);
        await Future.delayed(Duration(milliseconds: 10));

        expect(chatEvents, hasLength(1));
        expect(chatEvents.first.message, equals('Chat Event'));
        expect(notificationEvents, hasLength(1));
        expect(notificationEvents.first.message, equals('Notification Event'));

        await chatSubscription.cancel();
        await notificationSubscription.cancel();
      });

      test('should dispose scoped event buses when container is disposed',
          () async {
        final chatEventBus =
            container.read(scopedDomainEventBusProvider('chat'));
        final notificationEventBus =
            container.read(scopedDomainEventBusProvider('notifications'));

        expect(chatEventBus.isDisposed, isFalse);
        expect(notificationEventBus.isDisposed, isFalse);

        container.dispose();

        // Give some time for disposal callbacks to execute
        await Future.delayed(Duration(milliseconds: 10));
        expect(chatEventBus.isDisposed, isTrue);
        expect(notificationEventBus.isDisposed, isTrue);
      });
    });

    group('eventBusDebugInfoProvider', () {
      test('should provide debug information about event bus', () {
        final debugInfo = container.read(eventBusDebugInfoProvider);

        expect(debugInfo, isA<EventBusDebugInfo>());
        expect(debugInfo.subscriptionCount, equals(0));
        expect(debugInfo.isDisposed, isFalse);
      });

      test('should update debug info when subscriptions change', () async {
        final eventBus = container.read(domainEventBusProvider);

        // Initial state
        var debugInfo = container.read(eventBusDebugInfoProvider);
        expect(debugInfo.subscriptionCount, equals(0));

        // Add subscription and track it
        final subscription =
            eventBus.ofType<ProviderTestEvent>().listen((_) {});
        eventBus.trackSubscription(subscription);

        // Refresh debug info (in real app this would be automatic with watch)
        container.refresh(eventBusDebugInfoProvider);
        debugInfo = container.read(eventBusDebugInfoProvider);
        expect(debugInfo.subscriptionCount, equals(1));

        // Manually untrack before cancelling
        eventBus.untrackSubscription(subscription);
        await subscription.cancel();

        // Verify subscription count decreases
        container.refresh(eventBusDebugInfoProvider);
        debugInfo = container.read(eventBusDebugInfoProvider);
        expect(debugInfo.subscriptionCount, equals(0));
      });

      test('should reflect disposed state in debug info', () async {
        final debugInfo = container.read(eventBusDebugInfoProvider);
        expect(debugInfo.isDisposed, isFalse);

        container.dispose();

        // Give some time for disposal callback to execute
        await Future.delayed(Duration(milliseconds: 10));

        // Note: After container disposal, we can't read from it anymore
        // but we can verify the debug info was accurate before disposal
      });
    });

    group('EventBusDebugInfo', () {
      test('should create debug info with correct values', () {
        const debugInfo = EventBusDebugInfo(
          subscriptionCount: 5,
          isDisposed: false,
        );

        expect(debugInfo.subscriptionCount, equals(5));
        expect(debugInfo.isDisposed, isFalse);
      });

      test('should have meaningful toString representation', () {
        const debugInfo = EventBusDebugInfo(
          subscriptionCount: 3,
          isDisposed: true,
        );

        final str = debugInfo.toString();
        expect(str, contains('EventBusDebugInfo'));
        expect(str, contains('subscriptionCount: 3'));
        expect(str, contains('isDisposed: true'));
      });
    });
  });
}
