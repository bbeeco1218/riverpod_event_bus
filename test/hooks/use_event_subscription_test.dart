import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_event_bus/riverpod_event_bus.dart';
import 'package:riverpod_event_bus/hooks.dart';

// Test category implementation
class HookTestCategories implements IEventCategory {
  @override
  final String value;
  @override
  final String displayName;

  const HookTestCategories._(this.value, this.displayName);

  static const system = HookTestCategories._('system', 'System Events');
}

// Test event for hook testing
class HookTestEvent extends DomainEvent {
  final String message;

  const HookTestEvent({
    required this.message,
    required super.eventId,
    required super.occurredAt,
  }) : super(
          eventType: 'hook.test',
          category: HookTestCategories.system,
        );

  @override
  Map<String, dynamic> toJson() => {
        'message': message,
        ...super.toJson(),
      };
}

void main() {
  group('useEventSubscription Hook', () {
    late DomainEventBus eventBus;
    final testTime = DateTime(2024, 1, 1, 12, 0, 0);

    setUp(() {
      eventBus = DomainEventBus();
    });

    tearDown(() async {
      await eventBus.dispose();
    });

    testWidgets('should subscribe to events in widget lifecycle',
        (WidgetTester tester) async {
      final receivedEvents = <HookTestEvent>[];

      Widget buildTestWidget() {
        return ProviderScope(
          child: MaterialApp(
            home: HookConsumer(
              builder: (context, ref, child) {
                useEventSubscription<HookTestEvent>(
                  eventBus.ofType<HookTestEvent>(),
                  (event) => receivedEvents.add(event),
                  debugName: 'TestWidget',
                );

                return Container();
              },
            ),
          ),
        );
      }

      await tester.pumpWidget(buildTestWidget());

      final testEvent = HookTestEvent(
        message: 'Hook Test',
        eventId: 'hook-event-123',
        occurredAt: testTime,
      );

      eventBus.publish(testEvent);
      await tester.pump(Duration(milliseconds: 10));

      expect(receivedEvents, hasLength(1));
      expect(receivedEvents.first.message, equals('Hook Test'));
    });

    testWidgets('should dispose subscription when widget is disposed',
        (WidgetTester tester) async {
      final receivedEvents = <HookTestEvent>[];

      Widget buildTestWidget() {
        return ProviderScope(
          child: MaterialApp(
            home: HookConsumer(
              builder: (context, ref, child) {
                useEventSubscription<HookTestEvent>(
                  eventBus.ofType<HookTestEvent>(),
                  (event) => receivedEvents.add(event),
                  debugName: 'TestWidget',
                );

                return Container();
              },
            ),
          ),
        );
      }

      await tester.pumpWidget(buildTestWidget());

      // Replace widget with empty container
      await tester.pumpWidget(Container());

      // Publish event after widget disposal
      final testEvent = HookTestEvent(
        message: 'After Disposal',
        eventId: 'hook-event-456',
        occurredAt: testTime,
      );

      eventBus.publish(testEvent);
      await tester.pump(Duration(milliseconds: 10));

      // Should not receive events after disposal
      expect(receivedEvents, isEmpty);
    });

    testWidgets('should handle subscription recreation on dependency change',
        (WidgetTester tester) async {
      final receivedEvents = <HookTestEvent>[];
      String currentMessage = 'Original';

      Widget buildTestWidget(String message) {
        return ProviderScope(
          child: MaterialApp(
            home: HookConsumer(
              builder: (context, ref, child) {
                useEventSubscription<HookTestEvent>(
                  eventBus
                      .ofType<HookTestEvent>()
                      .where((event) => event.message.contains(message)),
                  (event) => receivedEvents.add(event),
                  dependencies: [message],
                  debugName: 'TestWidget',
                );

                return Container();
              },
            ),
          ),
        );
      }

      await tester.pumpWidget(buildTestWidget(currentMessage));

      // Publish original event
      eventBus.publish(HookTestEvent(
        message: 'Original Message',
        eventId: 'event-1',
        occurredAt: testTime,
      ));
      await tester.pump(Duration(milliseconds: 10));

      expect(receivedEvents, hasLength(1));

      // Change dependency
      currentMessage = 'Updated';
      await tester.pumpWidget(buildTestWidget(currentMessage));

      // Publish updated event
      eventBus.publish(HookTestEvent(
        message: 'Updated Message',
        eventId: 'event-2',
        occurredAt: testTime,
      ));
      await tester.pump(Duration(milliseconds: 10));

      expect(receivedEvents, hasLength(2));
    });

    testWidgets('should handle errors in callback gracefully',
        (WidgetTester tester) async {
      bool callbackExecuted = false;
      bool errorOccurred = false;
      Object? caughtError;

      Widget buildTestWidget() {
        return ProviderScope(
          child: MaterialApp(
            home: HookConsumer(
              builder: (context, ref, child) {
                useEventSubscription<HookTestEvent>(
                  eventBus.ofType<HookTestEvent>(),
                  (event) {
                    callbackExecuted = true;
                    throw Exception('Test error in hook callback');
                  },
                  onError: (error, stackTrace) {
                    errorOccurred = true;
                    caughtError = error;
                  },
                  debugName: 'TestWidget',
                );

                return Container();
              },
            ),
          ),
        );
      }

      await tester.pumpWidget(buildTestWidget());

      final testEvent = HookTestEvent(
        message: 'Error Test',
        eventId: 'error-event-123',
        occurredAt: testTime,
      );

      // Publish event and pump to process
      eventBus.publish(testEvent);
      await tester.pump();

      // Verify graceful error handling
      expect(callbackExecuted, isTrue, reason: 'Callback should be executed');
      expect(errorOccurred, isTrue, reason: 'Error should be caught gracefully');
      expect(caughtError, isA<Exception>(), reason: 'Should catch the thrown exception');
      expect(caughtError.toString(), contains('Test error in hook callback'));
    });

    testWidgets('should support conditional subscriptions',
        (WidgetTester tester) async {
      final receivedEvents = <HookTestEvent>[];

      Widget buildTestWidget() {
        return ProviderScope(
          child: MaterialApp(
            home: HookConsumer(
              builder: (context, ref, child) {
                useEventSubscriptionWhen<HookTestEvent>(
                  eventBus.ofType<HookTestEvent>(),
                  condition: (event) => event.message.contains('Pass'),
                  onEvent: (event) => receivedEvents.add(event),
                  debugName: 'TestWidget',
                );

                return Container();
              },
            ),
          ),
        );
      }

      await tester.pumpWidget(buildTestWidget());

      final passEvent = HookTestEvent(
        message: 'Pass Test',
        eventId: 'pass-event',
        occurredAt: testTime,
      );
      final failEvent = HookTestEvent(
        message: 'Fail Test',
        eventId: 'fail-event',
        occurredAt: testTime,
      );

      eventBus.publish(passEvent);
      eventBus.publish(failEvent);
      await tester.pump(Duration(milliseconds: 10));

      expect(receivedEvents, hasLength(1));
      expect(receivedEvents.first.message, equals('Pass Test'));
    });

    testWidgets('should support multiple event type subscriptions',
        (WidgetTester tester) async {
      final receivedTestEvents = <HookTestEvent>[];

      Widget buildTestWidget() {
        return ProviderScope(
          child: MaterialApp(
            home: HookConsumer(
              builder: (context, ref, child) {
                useMultipleEventSubscriptions({
                  eventBus.ofType<HookTestEvent>(): (event) =>
                      receivedTestEvents.add(event as HookTestEvent),
                }, debugName: 'TestWidget');

                return Container();
              },
            ),
          ),
        );
      }

      await tester.pumpWidget(buildTestWidget());

      final testEvent = HookTestEvent(
        message: 'Multi Hook Test',
        eventId: 'multi-event-123',
        occurredAt: testTime,
      );

      eventBus.publish(testEvent);
      await tester.pump(Duration(milliseconds: 10));

      expect(receivedTestEvents, hasLength(1));
      expect(receivedTestEvents.first.message, equals('Multi Hook Test'));
    });
  });
}
