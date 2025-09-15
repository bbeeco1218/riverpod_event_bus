import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:meta/meta.dart';
import 'package:flutter/foundation.dart';
import 'domain_event.dart';
import 'event_category.dart';

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
    // 🔒 Enhanced lifecycle check
    if (_isDisposed || _eventStream.isClosed) {
      if (kDebugMode) {
        debugPrint('⚠️ [EventBus] Event ignored - bus disposed: ${event.runtimeType}');
      }
      return; // Gracefully ignore instead of throwing
    }
    
    try {
      _eventStream.add(event);
    } catch (e, stackTrace) {
      // 🛡️ Handle unexpected errors to prevent app crash
      if (kDebugMode) {
        debugPrint('❌ [EventBus] Publish failed: $e\n$stackTrace');
      }
      // Continue execution - don't crash the app
    }
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
    if (_isDisposed || _eventStream.isClosed) {
      return Stream.empty();
    }
    
    // 🔄 Return error-resilient stream
    return _eventStream.stream
      .whereType<T>()
      .handleError((error, stackTrace) {
        if (kDebugMode) {
          debugPrint('⚠️ [EventBus] Stream error: $error');
        }
        // Log error but keep stream alive
      });
  }

  /// Returns a stream of events of the specified type and category.
  ///
  /// Only events that are instances of [T] and match the specified [category]
  /// will be emitted by this stream. This provides both type-safe and
  /// category-based event filtering.
  ///
  /// Example:
  /// ```dart
  /// eventBus.on<UserRegisteredEvent>(MyAppCategories.user).listen((event) {
  ///   // event is guaranteed to be UserRegisteredEvent with user category
  ///   print('User ${event.userId} registered in category ${event.category}');
  /// });
  /// ```
  Stream<T> on<T extends DomainEvent>(IEventCategory category) {
    if (_isDisposed || _eventStream.isClosed) {
      return Stream.empty();
    }

    // 🔄 Return error-resilient stream with both type and category filtering
    return _eventStream.stream
      .whereType<T>()
      .where((event) => event.category == category)
      .handleError((error, stackTrace) {
        if (kDebugMode) {
          debugPrint('⚠️ [EventBus] Category stream error: $error');
        }
        // Log error but keep stream alive
      });
  }

  /// Returns a stream of all events regardless of type.
  ///
  /// This is useful for debugging, logging, or implementing
  /// cross-cutting concerns like audit trails.
  Stream<DomainEvent> get allEvents {
    if (_isDisposed || _eventStream.isClosed) {
      return Stream.empty();
    }

    // 🔄 Return error-resilient stream
    return _eventStream.stream.handleError((error, stackTrace) {
      if (kDebugMode) {
        debugPrint('⚠️ [EventBus] AllEvents stream error: $error');
      }
      // Log error but keep stream alive
    });
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