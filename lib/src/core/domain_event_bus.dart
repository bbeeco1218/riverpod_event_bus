import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:meta/meta.dart';
import 'domain_event.dart';

/// A powerful event bus that provides type-safe event publishing and subscription.
/// 
/// The [DomainEventBus] uses RxDart streams internally to provide:
/// - Type-safe event filtering
/// - Automatic subscription management
/// - Memory leak prevention
/// - High performance event routing
/// 
/// Example usage:
/// ```dart
/// final eventBus = DomainEventBus();
/// 
/// // Publish an event
/// eventBus.publish(UserRegisteredEvent(userId: '123', email: 'user@example.com'));
/// 
/// // Subscribe to events
/// eventBus.ofType<UserRegisteredEvent>().listen((event) {
///   print('User registered: ${event.email}');
/// });
/// ```
class DomainEventBus {
  final PublishSubject<DomainEvent> _eventStream = PublishSubject<DomainEvent>();
  final Set<StreamSubscription> _subscriptions = <StreamSubscription>{};
  bool _isDisposed = false;

  /// Creates a new instance of [DomainEventBus].
  DomainEventBus();

  /// Publishes an event to all subscribers.
  /// 
  /// The event will be delivered to all subscribers that are listening
  /// for events of this type or its supertypes.
  /// 
  /// Throws [StateError] if the event bus has been disposed.
  void publish(DomainEvent event) {
    if (_isDisposed) {
      throw StateError('Cannot publish events to a disposed EventBus');
    }
    
    _eventStream.add(event);
  }

  /// Returns a stream of events of the specified type [T].
  /// 
  /// Only events that are instances of [T] will be emitted by this stream.
  /// This provides type-safe event filtering.
  /// 
  /// Example:
  /// ```dart
  /// eventBus.ofType<UserRegisteredEvent>().listen((event) {
  ///   // event is guaranteed to be UserRegisteredEvent
  ///   print('User ${event.userId} registered');
  /// });
  /// ```
  Stream<T> ofType<T extends DomainEvent>() {
    if (_isDisposed) {
      return Stream.empty();
    }
    
    return _eventStream.stream.whereType<T>();
  }

  /// Returns a stream of all events regardless of type.
  /// 
  /// This is useful for debugging, logging, or implementing
  /// cross-cutting concerns like audit trails.
  Stream<DomainEvent> get allEvents {
    if (_isDisposed) {
      return Stream.empty();
    }
    
    return _eventStream.stream;
  }

  /// Returns whether the event bus has been disposed.
  bool get isDisposed => _isDisposed;

  /// Returns the number of active subscriptions.
  /// 
  /// This is useful for debugging and monitoring memory usage.
  int get subscriptionCount => _subscriptions.length;

  /// Disposes the event bus and closes all streams.
  /// 
  /// After calling this method, no more events can be published
  /// and all existing subscriptions will be cancelled.
  /// 
  /// This method should be called when the event bus is no longer needed
  /// to prevent memory leaks.
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    
    _isDisposed = true;
    
    // Cancel all tracked subscriptions
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    
    // Close the main stream
    await _eventStream.close();
  }

  /// Tracks a subscription for automatic cleanup.
  /// 
  /// This method is typically used internally by the Riverpod extensions
  /// and hooks to ensure proper cleanup of subscriptions.
  @internal
  void trackSubscription(StreamSubscription subscription) {
    if (!_isDisposed) {
      _subscriptions.add(subscription);
      
      // Remove the subscription when it's done
      subscription.onDone(() {
        _subscriptions.remove(subscription);
      });
    }
  }

  /// Removes a subscription from tracking.
  /// 
  /// This is called automatically when subscriptions are cancelled.
  @internal
  void untrackSubscription(StreamSubscription subscription) {
    _subscriptions.remove(subscription);
  }
}

/// A specialized event bus that supports event filtering and transformation.
/// 
/// This extends the basic [DomainEventBus] with additional capabilities:
/// - Event filtering based on predicates
/// - Event transformation and mapping
/// - Buffering and throttling capabilities
class AdvancedDomainEventBus extends DomainEventBus {
  /// Creates a new advanced event bus.
  AdvancedDomainEventBus();

  /// Returns a filtered stream of events of type [T] that match the given predicate.
  /// 
  /// Example:
  /// ```dart
  /// eventBus.ofTypeWhere<UserEvent>((event) => event.userId == currentUserId)
  ///   .listen((event) {
  ///     // Only events for the current user
  ///   });
  /// ```
  Stream<T> ofTypeWhere<T extends DomainEvent>(bool Function(T) predicate) {
    return ofType<T>().where(predicate);
  }

  /// Returns a stream that emits events with a maximum frequency.
  /// 
  /// This is useful to prevent overwhelming subscribers with too many events.
  Stream<T> throttle<T extends DomainEvent>(Duration duration) {
    return ofType<T>().throttleTime(duration);
  }

  /// Returns a stream that buffers events and emits them in batches.
  /// 
  /// This is useful for batch processing of events.
  Stream<List<T>> buffer<T extends DomainEvent>(Duration duration) {
    return ofType<T>().bufferTime(duration).where((list) => list.isNotEmpty);
  }

  /// Returns a stream that only emits distinct events.
  /// 
  /// This prevents duplicate events from being processed.
  Stream<T> distinct<T extends DomainEvent>() {
    return ofType<T>().distinct();
  }
}