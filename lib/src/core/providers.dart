import 'package:riverpod/riverpod.dart';
import 'domain_event_bus.dart';

/// Provider for the main domain event bus instance.
/// 
/// This provider creates and manages a singleton instance of [DomainEventBus]
/// that can be used throughout the application for event publishing and subscription.
/// 
/// The event bus will be automatically disposed when the provider scope is disposed,
/// ensuring proper cleanup and preventing memory leaks.
/// 
/// Example usage:
/// ```dart
/// class MyNotifier extends StateNotifier<MyState> {
///   MyNotifier(this.ref) : super(MyState.initial());
///   
///   final Ref ref;
///   
///   void doSomething() {
///     final eventBus = ref.read(domainEventBusProvider);
///     eventBus.publish(SomethingHappenedEvent());
///   }
/// }
/// ```
final domainEventBusProvider = Provider<DomainEventBus>((ref) {
  final eventBus = DomainEventBus();
  
  // Ensure the event bus is disposed when the provider is disposed
  ref.onDispose(() async {
    await eventBus.dispose();
  });
  
  return eventBus;
});

/// Provider for an advanced domain event bus with additional features.
/// 
/// This provider creates an [AdvancedDomainEventBus] instance that includes
/// additional capabilities like event filtering, throttling, and buffering.
/// 
/// Use this provider when you need advanced event processing capabilities
/// beyond basic publish/subscribe functionality.
/// 
/// Example usage:
/// ```dart
/// final eventBus = ref.read(advancedDomainEventBusProvider);
/// 
/// // Throttle events to prevent spam
/// eventBus.throttle<UserClickEvent>(Duration(milliseconds: 100))
///   .listen((event) {
///     // Handle throttled clicks
///   });
/// ```
final advancedDomainEventBusProvider = Provider<AdvancedDomainEventBus>((ref) {
  final eventBus = AdvancedDomainEventBus();
  
  // Ensure the event bus is disposed when the provider is disposed
  ref.onDispose(() async {
    await eventBus.dispose();
  });
  
  return eventBus;
});

/// A family provider that creates scoped event buses.
/// 
/// This is useful when you need isolated event buses for specific
/// features or modules in your application.
/// 
/// Example usage:
/// ```dart
/// // Create a scoped event bus for the chat feature
/// final chatEventBus = ref.read(scopedDomainEventBusProvider('chat'));
/// 
/// // Create a scoped event bus for the notification feature
/// final notificationEventBus = ref.read(scopedDomainEventBusProvider('notifications'));
/// ```
final scopedDomainEventBusProvider = 
    Provider.family<DomainEventBus, String>((ref, scope) {
  final eventBus = DomainEventBus();
  
  ref.onDispose(() async {
    await eventBus.dispose();
  });
  
  return eventBus;
});

/// A provider that exposes useful debugging information about the event bus.
/// 
/// This provider can be used in development to monitor event bus activity,
/// subscription counts, and potential memory leaks.
/// 
/// Example usage:
/// ```dart
/// final debugInfo = ref.watch(eventBusDebugInfoProvider);
/// print('Active subscriptions: ${debugInfo.subscriptionCount}');
/// ```
final eventBusDebugInfoProvider = Provider<EventBusDebugInfo>((ref) {
  final eventBus = ref.watch(domainEventBusProvider);
  
  return EventBusDebugInfo(
    subscriptionCount: eventBus.subscriptionCount,
    isDisposed: eventBus.isDisposed,
  );
});

/// Debug information about the event bus state.
class EventBusDebugInfo {
  /// The number of active subscriptions.
  final int subscriptionCount;
  
  /// Whether the event bus has been disposed.
  final bool isDisposed;
  
  /// Creates debug information.
  const EventBusDebugInfo({
    required this.subscriptionCount,
    required this.isDisposed,
  });
  
  @override
  String toString() => 'EventBusDebugInfo('
      'subscriptionCount: $subscriptionCount, '
      'isDisposed: $isDisposed'
      ')';
}