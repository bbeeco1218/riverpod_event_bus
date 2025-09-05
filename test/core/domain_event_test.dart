import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_event_bus/src/core/domain_event.dart';

// Test events for testing purposes
class TestEvent extends DomainEvent {
  final String message;

  const TestEvent({
    required this.message,
    required super.eventId,
    required super.occurredAt,
  }) : super(
          eventType: 'test.event',
          category: EventCategory.system,
        );

  @override
  Map<String, dynamic> toJson() => {
        'message': message,
        ...super.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other && other is TestEvent && message == other.message;

  @override
  int get hashCode => Object.hash(super.hashCode, message);
}

class UserRegisteredTestEvent extends DomainEvent {
  final String userId;
  final String email;

  const UserRegisteredTestEvent({
    required this.userId,
    required this.email,
    required super.eventId,
    required super.occurredAt,
  }) : super(
          eventType: 'user.registered',
          category: EventCategory.user,
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
          other is UserRegisteredTestEvent &&
          userId == other.userId &&
          email == other.email;

  @override
  int get hashCode => Object.hash(super.hashCode, userId, email);
}

class OrderCreatedTestEvent extends DomainEvent {
  final String orderId;
  final double amount;

  const OrderCreatedTestEvent({
    required this.orderId,
    required this.amount,
    required super.eventId,
    required super.occurredAt,
  }) : super(
          eventType: 'order.created',
          category: EventCategory.order,
        );

  @override
  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'amount': amount,
        ...super.toJson(),
      };

  @override
  Map<String, dynamic> get metadata => {
        'currency': 'USD',
        'paymentMethod': 'credit_card',
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is OrderCreatedTestEvent &&
          orderId == other.orderId &&
          amount == other.amount;

  @override
  int get hashCode => Object.hash(super.hashCode, orderId, amount);
}

void main() {
  group('DomainEvent', () {
    final testTime = DateTime(2024, 1, 1, 12, 0, 0);
    const testEventId = 'test-event-123';

    test('should create event with required fields', () {
      final event = TestEvent(
        message: 'test message',
        eventId: testEventId,
        occurredAt: testTime,
      );

      expect(event.message, equals('test message'));
      expect(event.eventType, equals('test.event'));
      expect(event.category, equals(EventCategory.system));
      expect(event.eventId, equals(testEventId));
      expect(event.occurredAt, equals(testTime));
    });

    test('should support JSON serialization', () {
      final event = TestEvent(
        message: 'test message',
        eventId: testEventId,
        occurredAt: testTime,
      );

      final json = event.toJson();

      expect(json['eventType'], equals('test.event'));
      expect(json['category'], equals('system'));
      expect(json['eventId'], equals(testEventId));
      expect(json['occurredAt'], equals(testTime.toIso8601String()));
      expect(json['message'], equals('test message'));
      expect(json['metadata'], isEmpty);
    });

    test('should support custom metadata', () {
      final event = OrderCreatedTestEvent(
        orderId: 'order-123',
        amount: 99.99,
        eventId: testEventId,
        occurredAt: testTime,
      );

      final json = event.toJson();

      expect(json['metadata'], isA<Map<String, dynamic>>());
      expect(json['metadata']['currency'], equals('USD'));
      expect(json['metadata']['paymentMethod'], equals('credit_card'));
    });

    test('should support equality comparison', () {
      final event1 = TestEvent(
        message: 'same message',
        eventId: 'same-id',
        occurredAt: testTime,
      );
      final event2 = TestEvent(
        message: 'same message',
        eventId: 'same-id',
        occurredAt: testTime,
      );
      final event3 = TestEvent(
        message: 'different message',
        eventId: 'same-id',
        occurredAt: testTime,
      );
      final event4 = TestEvent(
        message: 'same message',
        eventId: 'different-id',
        occurredAt: testTime,
      );

      expect(event1, equals(event2));
      expect(event1, isNot(equals(event3)));
      expect(event1, isNot(equals(event4)));
    });

    test('should generate consistent hash codes', () {
      final event1 = TestEvent(
        message: 'same message',
        eventId: 'same-id',
        occurredAt: testTime,
      );
      final event2 = TestEvent(
        message: 'same message',
        eventId: 'same-id',
        occurredAt: testTime,
      );

      expect(event1.hashCode, equals(event2.hashCode));
    });

    test('should have meaningful toString representation', () {
      final event = TestEvent(
        message: 'test message',
        eventId: testEventId,
        occurredAt: testTime,
      );
      final str = event.toString();

      expect(str, contains('TestEvent'));
      expect(str, contains('test.event'));
      expect(str, contains(testEventId));
      expect(str, contains(testTime.toString()));
    });

    test('should work with DomainEvent.now factory', () {
      final event = DomainEvent.now(
        eventType: 'test.factory',
        category: EventCategory.user,
      );

      expect(event.eventType, equals('test.factory'));
      expect(event.category, equals(EventCategory.user));
      expect(event.occurredAt, isA<DateTime>());
      expect(event.eventId, isNotEmpty);
    });
  });

  group('EventCategory', () {
    test('should have correct string values', () {
      expect(EventCategory.user.value, equals('user'));
      expect(EventCategory.order.value, equals('order'));
      expect(EventCategory.product.value, equals('product'));
      expect(EventCategory.payment.value, equals('payment'));
      expect(EventCategory.notification.value, equals('notification'));
      expect(EventCategory.system.value, equals('system'));
    });

    test('should have meaningful toString', () {
      expect(EventCategory.user.toString(), equals('user'));
      expect(EventCategory.order.toString(), equals('order'));
    });
  });

  group('Domain Event Types', () {
    final testTime = DateTime(2024, 1, 1, 12, 0, 0);

    test('UserRegisteredTestEvent should work correctly', () {
      final event = UserRegisteredTestEvent(
        userId: 'user-123',
        email: 'test@example.com',
        eventId: 'event-123',
        occurredAt: testTime,
      );

      expect(event.eventType, equals('user.registered'));
      expect(event.category, equals(EventCategory.user));
      expect(event.userId, equals('user-123'));
      expect(event.email, equals('test@example.com'));

      final json = event.toJson();
      expect(json['userId'], equals('user-123'));
      expect(json['email'], equals('test@example.com'));
    });

    test('OrderCreatedTestEvent should work correctly', () {
      final event = OrderCreatedTestEvent(
        orderId: 'order-456',
        amount: 199.99,
        eventId: 'event-456',
        occurredAt: testTime,
      );

      expect(event.eventType, equals('order.created'));
      expect(event.category, equals(EventCategory.order));
      expect(event.orderId, equals('order-456'));
      expect(event.amount, equals(199.99));

      final json = event.toJson();
      expect(json['orderId'], equals('order-456'));
      expect(json['amount'], equals(199.99));
      expect(json['metadata']['currency'], equals('USD'));
    });
  });
}
