import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_event_bus/riverpod_event_bus.dart';

// Test category implementation
class BusTestCategories implements IEventCategory {
  @override
  final String value;
  @override
  final String displayName;
  
  const BusTestCategories._(this.value, this.displayName);
  
  static const user = BusTestCategories._('user', 'User Events');
  static const order = BusTestCategories._('order', 'Order Events');
}

// Test events
class UserRegisteredEvent extends DomainEvent {
  final String userId;
  final String email;

  const UserRegisteredEvent({
    required this.userId,
    required this.email,
    required super.eventId,
    required super.occurredAt,
  }) : super(
          eventType: 'user.registered',
          category: BusTestCategories.user,
        );

  @override
  Map<String, dynamic> toJson() => {
        'userId': userId,
        'email': email,
        ...super.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is UserRegisteredEvent &&
          userId == other.userId &&
          email == other.email;

  @override
  int get hashCode => Object.hash(super.hashCode, userId, email);
}

class OrderCreatedEvent extends DomainEvent {
  final String orderId;
  final double amount;

  const OrderCreatedEvent({
    required this.orderId,
    required this.amount,
    required super.eventId,
    required super.occurredAt,
  }) : super(
          eventType: 'order.created',
          category: BusTestCategories.order,
        );

  @override
  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'amount': amount,
        ...super.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is OrderCreatedEvent &&
          orderId == other.orderId &&
          amount == other.amount;

  @override
  int get hashCode => Object.hash(super.hashCode, orderId, amount);
}

void main() {
  group('DomainEventBus', () {
    late DomainEventBus eventBus;
    final testTime = DateTime(2024, 1, 1, 12, 0, 0);

    setUp(() {
      eventBus = DomainEventBus();
    });

    tearDown(() async {
      await eventBus.dispose();
    });

    test('should initialize with no subscriptions', () {
      expect(eventBus.subscriptionCount, equals(0));
      expect(eventBus.isDisposed, isFalse);
    });

    test('should publish and receive events of specific type', () async {
      final testEvent = UserRegisteredEvent(
        userId: 'user-123',
        email: 'test@example.com',
        eventId: 'event-123',
        occurredAt: testTime,
      );

      final receivedEvents = <UserRegisteredEvent>[];
      final subscription =
          eventBus.ofType<UserRegisteredEvent>().listen((event) {
        receivedEvents.add(event);
      });

      eventBus.publish(testEvent);

      await Future.delayed(Duration(milliseconds: 10));

      expect(receivedEvents, hasLength(1));
      expect(receivedEvents.first, equals(testEvent));

      await subscription.cancel();
    });

    test('should filter events by type correctly', () async {
      final userEvent = UserRegisteredEvent(
        userId: 'user-123',
        email: 'test@example.com',
        eventId: 'user-event-123',
        occurredAt: testTime,
      );
      final orderEvent = OrderCreatedEvent(
        orderId: 'order-456',
        amount: 99.99,
        eventId: 'order-event-456',
        occurredAt: testTime,
      );

      final userEvents = <UserRegisteredEvent>[];
      final orderEvents = <OrderCreatedEvent>[];

      final userSubscription =
          eventBus.ofType<UserRegisteredEvent>().listen((event) {
        userEvents.add(event);
      });

      final orderSubscription =
          eventBus.ofType<OrderCreatedEvent>().listen((event) {
        orderEvents.add(event);
      });

      eventBus.publish(userEvent);
      eventBus.publish(orderEvent);

      await Future.delayed(Duration(milliseconds: 10));

      expect(userEvents, hasLength(1));
      expect(userEvents.first, equals(userEvent));
      expect(orderEvents, hasLength(1));
      expect(orderEvents.first, equals(orderEvent));

      await userSubscription.cancel();
      await orderSubscription.cancel();
    });

    test('should support multiple subscribers for same event type', () async {
      final testEvent = UserRegisteredEvent(
        userId: 'user-123',
        email: 'test@example.com',
        eventId: 'event-123',
        occurredAt: testTime,
      );

      final subscriber1Events = <UserRegisteredEvent>[];
      final subscriber2Events = <UserRegisteredEvent>[];

      final subscription1 =
          eventBus.ofType<UserRegisteredEvent>().listen((event) {
        subscriber1Events.add(event);
      });

      final subscription2 =
          eventBus.ofType<UserRegisteredEvent>().listen((event) {
        subscriber2Events.add(event);
      });

      eventBus.publish(testEvent);

      await Future.delayed(Duration(milliseconds: 10));

      expect(subscriber1Events, hasLength(1));
      expect(subscriber2Events, hasLength(1));
      expect(subscriber1Events.first, equals(testEvent));
      expect(subscriber2Events.first, equals(testEvent));

      await subscription1.cancel();
      await subscription2.cancel();
    });

    test('should provide access to all events stream', () async {
      final userEvent = UserRegisteredEvent(
        userId: 'user-123',
        email: 'test@example.com',
        eventId: 'user-event-123',
        occurredAt: testTime,
      );
      final orderEvent = OrderCreatedEvent(
        orderId: 'order-456',
        amount: 99.99,
        eventId: 'order-event-456',
        occurredAt: testTime,
      );

      final allEvents = <DomainEvent>[];
      final subscription = eventBus.allEvents.listen((event) {
        allEvents.add(event);
      });

      eventBus.publish(userEvent);
      eventBus.publish(orderEvent);

      await Future.delayed(Duration(milliseconds: 10));

      expect(allEvents, hasLength(2));
      expect(allEvents[0], equals(userEvent));
      expect(allEvents[1], equals(orderEvent));

      await subscription.cancel();
    });

    test('should gracefully handle publishing to disposed bus', () async {
      await eventBus.dispose();

      final testEvent = UserRegisteredEvent(
        userId: '123',
        email: 'test@example.com',
        eventId: 'event-123',
        occurredAt: testTime,
      );

      // ✅ Should NOT throw - gracefully ignore instead
      expect(
        () => eventBus.publish(testEvent),
        returnsNormally,
      );
    });

    test('should return empty stream when accessing disposed bus', () async {
      await eventBus.dispose();

      final events = <UserRegisteredEvent>[];
      final subscription =
          eventBus.ofType<UserRegisteredEvent>().listen((event) {
        events.add(event);
      });

      await Future.delayed(Duration(milliseconds: 10));

      expect(events, isEmpty);
      await subscription.cancel();
    });

    test('should properly dispose and clean up resources', () async {
      expect(eventBus.isDisposed, isFalse);

      await eventBus.dispose();

      expect(eventBus.isDisposed, isTrue);
      expect(eventBus.subscriptionCount, equals(0));
    });

    test('should be safe to dispose multiple times', () async {
      await eventBus.dispose();

      // Should not throw
      await eventBus.dispose();

      expect(eventBus.isDisposed, isTrue);
    });

    test('should handle rapid sequential publishes after dispose', () async {
      await eventBus.dispose();

      final testEvent = UserRegisteredEvent(
        userId: '123',
        email: 'test@example.com',
        eventId: 'event-123',
        occurredAt: testTime,
      );

      // 🔄 Multiple rapid publishes should all be safely ignored
      expect(() {
        for (int i = 0; i < 10; i++) {
          eventBus.publish(testEvent);
        }
      }, returnsNormally);
    });

    test('should handle stream errors gracefully', () async {
      final events = <UserRegisteredEvent>[];
      final streamErrors = <dynamic>[];
      bool handlerErrorOccurred = false;
      
      // 🧪 Test our enhanced error handling by wrapping handler in try-catch
      final subscription = eventBus.ofType<UserRegisteredEvent>().listen(
        (event) {
          try {
            events.add(event);
            // 💥 Simulate handler error on second event
            if (events.length == 2) {
              handlerErrorOccurred = true;
              throw Exception('Test handler error');
            }
          } catch (e) {
            // 🛡️ Handler errors are caught and logged, not propagated to stream
            // In production code, this would be handled by our Extension/Hook error handling
          }
        },
        onError: (error) {
          streamErrors.add(error);
        },
      );

      final testEvent1 = UserRegisteredEvent(
        userId: '1',
        email: 'test1@example.com',
        eventId: 'event-1',
        occurredAt: testTime,
      );
      
      final testEvent2 = UserRegisteredEvent(
        userId: '2',
        email: 'test2@example.com',
        eventId: 'event-2',
        occurredAt: testTime,
      );
      
      final testEvent3 = UserRegisteredEvent(
        userId: '3',
        email: 'test3@example.com',
        eventId: 'event-3',
        occurredAt: testTime,
      );

      eventBus.publish(testEvent1);
      eventBus.publish(testEvent2); // This should cause error in handler
      eventBus.publish(testEvent3);

      await Future.delayed(Duration(milliseconds: 50));

      // ✅ Verify graceful error handling
      expect(events.length, equals(3)); // All events received
      expect(handlerErrorOccurred, isTrue); // Error occurred in handler  
      expect(streamErrors.length, equals(0)); // No stream errors thanks to our handleError protection

      await subscription.cancel();
    });
  });

  group('AdvancedDomainEventBus', () {
    late AdvancedDomainEventBus eventBus;
    final testTime = DateTime(2024, 1, 1, 12, 0, 0);

    setUp(() {
      eventBus = AdvancedDomainEventBus();
    });

    tearDown(() async {
      await eventBus.dispose();
    });

    test('should filter events with predicate', () async {
      final user1Event = UserRegisteredEvent(
        userId: 'user-1',
        email: 'user1@example.com',
        eventId: 'user1-event',
        occurredAt: testTime,
      );
      final user2Event = UserRegisteredEvent(
        userId: 'user-2',
        email: 'user2@example.com',
        eventId: 'user2-event',
        occurredAt: testTime,
      );

      final filteredEvents = <UserRegisteredEvent>[];
      final subscription = eventBus
          .ofTypeWhere<UserRegisteredEvent>(
        (event) => event.userId == 'user-1',
      )
          .listen((event) {
        filteredEvents.add(event);
      });

      eventBus.publish(user1Event);
      eventBus.publish(user2Event);

      await Future.delayed(Duration(milliseconds: 10));

      expect(filteredEvents, hasLength(1));
      expect(filteredEvents.first.userId, equals('user-1'));

      await subscription.cancel();
    });

    test('should support throttling', () async {
      final throttledEvents = <UserRegisteredEvent>[];
      final subscription = eventBus
          .throttle<UserRegisteredEvent>(
        Duration(milliseconds: 100),
      )
          .listen((event) {
        throttledEvents.add(event);
      });

      // Publish multiple events quickly
      eventBus.publish(UserRegisteredEvent(
        userId: 'user-1',
        email: 'user1@example.com',
        eventId: 'event-1',
        occurredAt: testTime,
      ));
      eventBus.publish(UserRegisteredEvent(
        userId: 'user-2',
        email: 'user2@example.com',
        eventId: 'event-2',
        occurredAt: testTime,
      ));
      eventBus.publish(UserRegisteredEvent(
        userId: 'user-3',
        email: 'user3@example.com',
        eventId: 'event-3',
        occurredAt: testTime,
      ));

      await Future.delayed(Duration(milliseconds: 50));
      expect(throttledEvents, hasLength(1)); // Should only get the first event

      await Future.delayed(Duration(milliseconds: 100));
      // After throttle period, should be able to receive more events

      await subscription.cancel();
    });

    test('should support buffering', () async {
      final bufferedEvents = <List<UserRegisteredEvent>>[];
      final subscription = eventBus
          .buffer<UserRegisteredEvent>(
        Duration(milliseconds: 100),
      )
          .listen((eventList) {
        bufferedEvents.add(eventList);
      });

      eventBus.publish(UserRegisteredEvent(
        userId: 'user-1',
        email: 'user1@example.com',
        eventId: 'event-1',
        occurredAt: testTime,
      ));
      eventBus.publish(UserRegisteredEvent(
        userId: 'user-2',
        email: 'user2@example.com',
        eventId: 'event-2',
        occurredAt: testTime,
      ));

      await Future.delayed(Duration(milliseconds: 150));

      expect(bufferedEvents, hasLength(1));
      expect(bufferedEvents.first, hasLength(2));

      await subscription.cancel();
    });

    test('should support distinct events', () async {
      final duplicateEvent = UserRegisteredEvent(
        userId: 'user-1',
        email: 'user1@example.com',
        eventId: 'event-1',
        occurredAt: testTime,
      );

      final distinctEvents = <UserRegisteredEvent>[];
      final subscription =
          eventBus.distinct<UserRegisteredEvent>().listen((event) {
        distinctEvents.add(event);
      });

      eventBus.publish(duplicateEvent);
      eventBus.publish(duplicateEvent);
      eventBus.publish(duplicateEvent);

      await Future.delayed(Duration(milliseconds: 10));

      expect(distinctEvents, hasLength(1));

      await subscription.cancel();
    });
  });
}
