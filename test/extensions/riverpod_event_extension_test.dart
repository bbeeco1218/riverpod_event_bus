import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_event_bus/src/core/domain_event.dart';
import 'package:riverpod_event_bus/src/core/domain_event_bus.dart';
import 'package:riverpod_event_bus/src/extensions/riverpod_event_extension.dart';

// Simple test event
class SimpleTestEvent extends DomainEvent {
  final String message;

  const SimpleTestEvent({
    required this.message,
    required super.eventId,
    required super.occurredAt,
  }) : super(
          eventType: 'test.simple',
          category: EventCategory.system,
        );

  @override
  Map<String, dynamic> toJson() => {
        'message': message,
        ...super.toJson(),
      };
}

// Simple mock for Ref
class SimpleMockRef implements Ref {
  final List<void Function()> _disposeCallbacks = [];

  @override
  void onDispose(void Function() callback) {
    _disposeCallbacks.add(callback);
  }

  void triggerDispose() {
    for (final callback in _disposeCallbacks) {
      callback();
    }
    _disposeCallbacks.clear();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('RiverpodEventSubscriptionExtension', () {
    late DomainEventBus eventBus;
    late SimpleMockRef mockRef;
    final testTime = DateTime(2024, 1, 1, 12, 0, 0);

    setUp(() {
      eventBus = DomainEventBus();
      mockRef = SimpleMockRef();
    });

    tearDown(() async {
      mockRef.triggerDispose();
      await eventBus.dispose();
    });

    test('should subscribe to events successfully', () async {
      final stream = eventBus.ofType<SimpleTestEvent>();
      final receivedEvents = <SimpleTestEvent>[];

      final subscription = mockRef.listenToEvent(
        stream,
        (event) => receivedEvents.add(event),
        debugName: 'TestNotifier',
      );

      expect(subscription, isA<StreamSubscription<SimpleTestEvent>>());

      final testEvent = SimpleTestEvent(
        message: 'Hello Test',
        eventId: 'event-123',
        occurredAt: testTime,
      );

      eventBus.publish(testEvent);
      await Future.delayed(Duration(milliseconds: 10));

      expect(receivedEvents, hasLength(1));
      expect(receivedEvents.first.message, equals('Hello Test'));
    });

    test('should dispose subscription when ref is disposed', () async {
      final stream = eventBus.ofType<SimpleTestEvent>();
      final receivedEvents = <SimpleTestEvent>[];

      mockRef.listenToEvent(
        stream,
        (event) => receivedEvents.add(event),
        debugName: 'TestNotifier',
      );

      // Dispose the ref
      mockRef.triggerDispose();

      // Publish event after disposal
      final testEvent = SimpleTestEvent(
        message: 'After Dispose',
        eventId: 'event-456',
        occurredAt: testTime,
      );

      eventBus.publish(testEvent);
      await Future.delayed(Duration(milliseconds: 10));

      // Should not receive events after disposal
      expect(receivedEvents, isEmpty);
    });

    test('should handle multiple event subscriptions', () async {
      final receivedEvents = <SimpleTestEvent>[];

      mockRef.listenToMultipleEvents({
        eventBus.ofType<SimpleTestEvent>(): (event) =>
            receivedEvents.add(event as SimpleTestEvent),
      }, debugName: 'MultiTestNotifier');

      final testEvent = SimpleTestEvent(
        message: 'Multi Test',
        eventId: 'event-789',
        occurredAt: testTime,
      );

      eventBus.publish(testEvent);
      await Future.delayed(Duration(milliseconds: 10));

      expect(receivedEvents, hasLength(1));
      expect(receivedEvents.first.message, equals('Multi Test'));
    });

    test('should filter events with condition', () async {
      final receivedEvents = <SimpleTestEvent>[];

      mockRef.listenToEventWhen(
        eventBus.ofType<SimpleTestEvent>(),
        condition: (event) => event.message.contains('Pass'),
        onEvent: (event) => receivedEvents.add(event),
        debugName: 'ConditionalTestNotifier',
      );

      final passEvent = SimpleTestEvent(
        message: 'Pass Test',
        eventId: 'event-pass',
        occurredAt: testTime,
      );
      final failEvent = SimpleTestEvent(
        message: 'Fail Test',
        eventId: 'event-fail',
        occurredAt: testTime,
      );

      eventBus.publish(passEvent);
      eventBus.publish(failEvent);
      await Future.delayed(Duration(milliseconds: 10));

      expect(receivedEvents, hasLength(1));
      expect(receivedEvents.first.message, equals('Pass Test'));
    });
  });
}
