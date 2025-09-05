import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/domain_event.dart';

/// Extension for Riverpod Provider to subscribe to domain events safely.
///
/// **⚠️ IMPORTANT: Use only in ViewModels (NotifierProvider)!**
/// For Views (Widgets), use useEventSubscription() Hook instead.
///
/// This extension provides automatic lifecycle management for event subscriptions
/// in Riverpod providers. Subscriptions are automatically disposed when the
/// provider is disposed, preventing memory leaks.
///
/// **✅ Correct Usage (ViewModel):**
/// ```dart
/// @riverpod
/// class HomeNotifier extends _$HomeNotifier {
///   @override
///   Future<HomeState> build() async {
///     final eventBus = ref.read(domainEventBusProvider);
///
///     // ✅ ViewModel usage - for data updates
///     ref.listenToEvent(
///       eventBus.ofType<UserRegisteredEvent>(),
///       (event) {
///         print('📥 User registered: ${event.email}');
///         ref.invalidateSelf(); // Refresh data
///       },
///       debugName: 'HomeNotifier',
///     );
///
///     return HomeState(...);
///   }
/// }
/// ```
///
/// **❌ Wrong Usage (View):**
/// ```dart
/// class MyScreen extends HookConsumerWidget {
///   Widget build(context, ref) {
///     // ❌ Don't use in Views! Will throw ArgumentError
///     ref.listenToEvent(...);
///
///     // ✅ Use this instead for UI interactions
///     useEventSubscription(...);
///   }
/// }
/// ```
///
/// **Key Features:**
/// - Automatic subscription disposal when provider is disposed
/// - Memory leak prevention
/// - View/ViewModel usage enforcement
/// - Debug logging with debugName
/// - Error handling with graceful recovery
extension RiverpodEventSubscriptionExtension on Ref {
  /// Checks if this extension is being used in a View (Widget) context.
  /// Throws ArgumentError if used incorrectly.
  void _checkViewUsage(String? debugName) {
    if (this is WidgetRef) {
      throw ArgumentError('''
🚨 Architecture Rule Violation!

❌ Cannot use Ref extension methods in Views (Widgets)
📍 Location: ${debugName ?? 'Unknown'}

✅ Correct Solution:
1. Import the Hook: import 'package:riverpod_event_bus/hooks.dart';
2. Use useEventSubscription() Hook instead:

useEventSubscription(
  eventBus.ofType<YourEvent>(),
  (event) {
    // UI interactions (dialogs, snackbars, navigation, etc.)
    showDialog(context: context, ...);
  },
  debugName: '${debugName ?? 'YourScreen'}',
);

📚 Reason: Views should use Widget lifecycle-synchronized Flutter Hooks 
to prevent performance issues and memory leaks.
      ''');
    }
  }

  /// Subscribes to a domain event stream with automatic lifecycle management.
  ///
  /// [stream] - The event stream to subscribe to
  /// [onEvent] - Callback function to handle received events
  /// [debugName] - Optional name for debugging and logging
  ///
  /// **Returns:** StreamSubscription&lt;T&gt; (usually not needed directly)
  ///
  /// **Automatic Features:**
  /// - Provider dispose triggers subscription cancellation
  /// - Memory leak prevention
  /// - Error handling with logging
  /// - Debug information output
  ///
  /// **Example:**
  /// ```dart
  /// // Single event subscription
  /// ref.listenToEvent(
  ///   eventBus.ofType<UserRegisteredEvent>(),
  ///   (event) => ref.invalidateSelf(),
  ///   debugName: 'HomeNotifier',
  /// );
  ///
  /// // Category-based event subscription
  /// ref.listenToEvent(
  ///   eventBus.on<UserRegisteredEvent>(EventCategory.user),
  ///   (event) => _handleUserEvent(event),
  ///   debugName: 'UserNotifier',
  /// );
  /// ```
  StreamSubscription<T> listenToEvent<T extends DomainEvent>(
    Stream<T> stream,
    void Function(T) onEvent, {
    String? debugName,
  }) {
    // 🚨 Prevent usage in Views (Widgets)
    _checkViewUsage(debugName);

    StreamSubscription<T>? subscription;

    try {
      // Subscribe to the event stream
      subscription = stream.listen(
        (event) {
          try {
            // Debug logging
            if (debugName != null && kDebugMode) {
              debugPrint(
                  '🎯 [$debugName] Event received: ${event.runtimeType}');
            }

            // Execute user callback
            onEvent(event);
          } catch (e, stackTrace) {
            // Log callback errors but don't crash the app
            debugPrint(
                '❌ ${debugName ?? 'Unknown'} event handler error: $e\n$stackTrace');
          }
        },
        onError: (error, stackTrace) {
          // Handle stream errors
          debugPrint(
              '⚠️ ${debugName ?? 'Unknown'} event stream error: $error\n$stackTrace');
        },
      );

      // Debug log subscription start
      if (debugName != null && kDebugMode) {
        debugPrint(
            '🟢 [$debugName] Event subscription started: ${T.toString()}');
      }
    } catch (e, stackTrace) {
      // Handle subscription creation failure
      debugPrint(
          '💥 ${debugName ?? 'Unknown'} subscription creation failed: $e\n$stackTrace');
      rethrow;
    }

    // Automatically dispose subscription when provider is disposed
    onDispose(() {
      try {
        subscription?.cancel();
        if (debugName != null && kDebugMode) {
          debugPrint('🔴 [$debugName] Event subscription disposed');
        }
      } catch (e) {
        debugPrint(
            '⚠️ ${debugName ?? 'Unknown'} subscription disposal error: $e');
      }
    });

    return subscription;
  }

  /// Subscribes to multiple event streams simultaneously.
  ///
  /// [eventSubscriptions] - Map of streams to their respective handlers
  /// [debugName] - Optional name for debugging and logging
  ///
  /// **Example:**
  /// ```dart
  /// ref.listenToMultipleEvents({
  ///   eventBus.ofType<UserRegisteredEvent>(): (event) {
  ///     ref.invalidateSelf();
  ///   },
  ///   eventBus.ofType<UserDeletedEvent>(): (event) {
  ///     ref.invalidateSelf();
  ///   },
  /// }, debugName: 'UserNotifier');
  /// ```
  List<StreamSubscription> listenToMultipleEvents<T extends DomainEvent>(
    Map<Stream<T>, void Function(T)> eventSubscriptions, {
    String? debugName,
  }) {
    // 🚨 Prevent usage in Views (Widgets)
    _checkViewUsage(debugName);

    final subscriptions = <StreamSubscription>[];

    eventSubscriptions.forEach((stream, callback) {
      final subscription = listenToEvent(
        stream,
        callback,
        debugName: debugName,
      );
      subscriptions.add(subscription);
    });

    return subscriptions;
  }

  /// Subscribes to events conditionally based on a predicate.
  ///
  /// [stream] - The event stream to subscribe to
  /// [condition] - Predicate to filter events (true = process event)
  /// [onEvent] - Callback function to handle filtered events
  /// [debugName] - Optional name for debugging and logging
  ///
  /// **Example:**
  /// ```dart
  /// ref.listenToEventWhen(
  ///   eventBus.ofType<UserRegisteredEvent>(),
  ///   condition: (event) => event.userId == currentUserId,
  ///   onEvent: (event) => ref.invalidateSelf(),
  ///   debugName: 'UserDetailNotifier',
  /// );
  /// ```
  StreamSubscription<T> listenToEventWhen<T extends DomainEvent>(
    Stream<T> stream, {
    required bool Function(T) condition,
    required void Function(T) onEvent,
    String? debugName,
  }) {
    // 🚨 Prevent usage in Views (Widgets)
    _checkViewUsage(debugName);

    return listenToEvent(
      stream.where(condition),
      onEvent,
      debugName: debugName,
    );
  }
}
