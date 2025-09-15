import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../core/domain_event.dart';

/// Flutter Hook for subscribing to domain events with automatic lifecycle management.
/// 
/// **✅ IMPORTANT: Use ONLY in Views (Widgets)!**
/// For ViewModels (NotifierProvider), use Riverpod extension methods instead.
///
/// This hook provides automatic widget lifecycle-synchronized event subscriptions.
/// Subscriptions are automatically created when the widget mounts and disposed
/// when the widget unmounts, preventing memory leaks.
///
/// **✅ Correct Usage (View):**
/// ```dart
/// class MyScreen extends HookConsumerWidget {
///   Widget build(context, ref) {
///     // ✅ Hook usage - for UI interactions
///     useEventSubscription(
///       eventBus.ofType<UserRegisteredEvent>(),
///       (event) {
///         // UI interactions (dialogs, snackbars, navigation, etc.)
///         showDialog(context: context, ...);
///       },
///       debugName: 'MyScreen',
///     );
///   }
/// }
/// ```
///
/// **❌ Wrong Usage (ViewModel):**
/// ```dart
/// @riverpod
/// class HomeNotifier extends _$HomeNotifier {
///   @override
///   Future<HomeState> build() async {
///     // ❌ Don't use in ViewModels! Use ref.listenToEvent() instead
///     useEventSubscription(...);
///   }
/// }
/// ```
///
/// **Key Features:**
/// - Automatic subscription disposal when widget is unmounted
/// - Widget lifecycle synchronization
/// - Memory leak prevention
/// - Debug logging with debugName
/// - Error handling with graceful recovery
/// - Dependency tracking for subscription recreation

/// Subscribes to a domain event stream with automatic widget lifecycle management.
///
/// [stream] - The event stream to subscribe to
/// [onEvent] - Callback function to handle received events
/// [dependencies] - List of dependencies that trigger subscription recreation
/// [debugName] - Optional name for debugging and logging
///
/// **Automatic Features:**
/// - Widget unmount triggers subscription cancellation
/// - Memory leak prevention
/// - Error handling with logging
/// - Debug information output
/// - Dependency change handling
///
/// **Example:**
/// ```dart
/// // Single event subscription
/// useEventSubscription(
///   eventBus.ofType<UserRegisteredEvent>(),
///   (event) => showSnackBar('User registered: ${event.email}'),
///   debugName: 'HomeScreen',
/// );
///
/// // Category-based event subscription
/// useEventSubscription(
///   eventBus.on<UserRegisteredEvent>(MyAppCategories.user),
///   (event) => _handleUserEvent(event),
///   debugName: 'UserScreen',
/// );
///
/// // With dependencies for recreation
/// useEventSubscription(
///   eventBus.ofType<OrderUpdatedEvent>().where((e) => e.userId == currentUserId),
///   (event) => _handleOrderUpdate(event),
///   dependencies: [currentUserId],
///   debugName: 'OrderScreen',
/// );
/// ```
StreamSubscription<T>? useEventSubscription<T extends DomainEvent>(
  Stream<T> stream,
  void Function(T) onEvent, {
  void Function(Object error, StackTrace stackTrace)? onError,
  List<Object?> dependencies = const [],
  String? debugName,
}) {
  return use(_EventSubscriptionHook<T>(
    stream: stream,
    onEvent: onEvent,
    onError: onError,
    dependencies: dependencies,
    debugName: debugName,
  ));
}

/// Subscribes to events conditionally based on a predicate.
///
/// [stream] - The event stream to subscribe to
/// [condition] - Predicate to filter events (true = process event)
/// [onEvent] - Callback function to handle filtered events
/// [dependencies] - List of dependencies that trigger subscription recreation
/// [debugName] - Optional name for debugging and logging
///
/// **Example:**
/// ```dart
/// useEventSubscriptionWhen(
///   eventBus.ofType<UserRegisteredEvent>(),
///   condition: (event) => event.userId == currentUserId,
///   onEvent: (event) => showWelcomeDialog(event),
///   dependencies: [currentUserId],
///   debugName: 'UserDetailScreen',
/// );
/// ```
StreamSubscription<T>? useEventSubscriptionWhen<T extends DomainEvent>(
  Stream<T> stream, {
  required bool Function(T) condition,
  required void Function(T) onEvent,
  List<Object?> dependencies = const [],
  String? debugName,
}) {
  return useEventSubscription(
    stream.where(condition),
    onEvent,
    dependencies: dependencies,
    debugName: debugName,
  );
}

/// Subscribes to multiple event streams simultaneously.
///
/// [eventSubscriptions] - Map of streams to their respective handlers
/// [dependencies] - List of dependencies that trigger subscription recreation
/// [debugName] - Optional name for debugging and logging
///
/// **Example:**
/// ```dart
/// useMultipleEventSubscriptions({
///   eventBus.ofType<UserRegisteredEvent>(): (event) {
///     showSnackBar('Welcome ${event.email}');
///   },
///   eventBus.ofType<UserDeletedEvent>(): (event) {
///     showSnackBar('User deleted');
///   },
/// }, debugName: 'UserScreen');
/// ```
List<StreamSubscription>? useMultipleEventSubscriptions<T extends DomainEvent>(
  Map<Stream<T>, void Function(T)> eventSubscriptions, {
  List<Object?> dependencies = const [],
  String? debugName,
}) {
  return use(_MultipleEventSubscriptionHook<T>(
    eventSubscriptions: eventSubscriptions,
    dependencies: dependencies,
    debugName: debugName,
  ));
}

/// Internal hook implementation for single event subscription
class _EventSubscriptionHook<T extends DomainEvent> extends Hook<StreamSubscription<T>?> {
  final Stream<T> stream;
  final void Function(T) onEvent;
  final void Function(Object error, StackTrace stackTrace)? onError;
  final List<Object?> dependencies;
  final String? debugName;

  const _EventSubscriptionHook({
    required this.stream,
    required this.onEvent,
    this.onError,
    this.dependencies = const [],
    this.debugName,
  });

  @override
  List<Object?> get keys => [stream, ...dependencies];

  @override
  _EventSubscriptionHookState<T> createState() => _EventSubscriptionHookState<T>();
}

class _EventSubscriptionHookState<T extends DomainEvent>
    extends HookState<StreamSubscription<T>?, _EventSubscriptionHook<T>> {
  StreamSubscription<T>? _subscription;

  @override
  void initHook() {
    super.initHook();
    _createSubscription();
  }

  @override
  void didUpdateHook(_EventSubscriptionHook<T> oldHook) {
    super.didUpdateHook(oldHook);
    if (oldHook.stream != hook.stream || 
        !_listEquals(oldHook.dependencies, hook.dependencies)) {
      _disposeSubscription();
      _createSubscription();
    }
  }

  @override
  StreamSubscription<T>? build(BuildContext context) => _subscription;

  @override
  void dispose() {
    _disposeSubscription();
    super.dispose();
  }

  void _createSubscription() {
    try {
      _subscription = hook.stream.listen(
        (event) {
          try {
            // Debug logging
            if (hook.debugName != null && kDebugMode) {
              debugPrint('🎯 [${hook.debugName}] Hook event received: ${event.runtimeType}');
            }

            // Execute user callback
            hook.onEvent(event);
          } catch (e, stackTrace) {
            // Call user's error handler if provided
            if (hook.onError != null) {
              hook.onError!(e, stackTrace);
            }
            
            // Always log callback errors but don't crash the app
            debugPrint(
              '❌ ${hook.debugName ?? 'Unknown'} hook event handler error: $e\n$stackTrace'
            );
          }
        },
        onError: (error, stackTrace) {
          // Handle stream errors
          debugPrint(
            '⚠️ ${hook.debugName ?? 'Unknown'} hook event stream error: $error\n$stackTrace'
          );
        },
      );

      // Debug log subscription start
      if (hook.debugName != null && kDebugMode) {
        debugPrint('🟢 [${hook.debugName}] Hook event subscription started: ${T.toString()}');
      }
    } catch (e, stackTrace) {
      // Handle subscription creation failure
      debugPrint(
        '💥 ${hook.debugName ?? 'Unknown'} hook subscription creation failed: $e\n$stackTrace'
      );
    }
  }

  void _disposeSubscription() {
    try {
      _subscription?.cancel();
      if (hook.debugName != null && kDebugMode) {
        debugPrint('🔴 [${hook.debugName}] Hook event subscription disposed');
      }
    } catch (e) {
      debugPrint('⚠️ ${hook.debugName ?? 'Unknown'} hook subscription disposal error: $e');
    } finally {
      _subscription = null;
    }
  }

  bool _listEquals(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Internal hook implementation for multiple event subscriptions
class _MultipleEventSubscriptionHook<T extends DomainEvent> extends Hook<List<StreamSubscription>?> {
  final Map<Stream<T>, void Function(T)> eventSubscriptions;
  final List<Object?> dependencies;
  final String? debugName;

  const _MultipleEventSubscriptionHook({
    required this.eventSubscriptions,
    this.dependencies = const [],
    this.debugName,
  });

  @override
  List<Object?> get keys => [eventSubscriptions, ...dependencies];

  @override
  _MultipleEventSubscriptionHookState<T> createState() => _MultipleEventSubscriptionHookState<T>();
}

class _MultipleEventSubscriptionHookState<T extends DomainEvent>
    extends HookState<List<StreamSubscription>?, _MultipleEventSubscriptionHook<T>> {
  List<StreamSubscription>? _subscriptions;

  @override
  void initHook() {
    super.initHook();
    _createSubscriptions();
  }

  @override
  void didUpdateHook(_MultipleEventSubscriptionHook<T> oldHook) {
    super.didUpdateHook(oldHook);
    if (oldHook.eventSubscriptions != hook.eventSubscriptions || 
        !_listEquals(oldHook.dependencies, hook.dependencies)) {
      _disposeSubscriptions();
      _createSubscriptions();
    }
  }

  @override
  List<StreamSubscription>? build(BuildContext context) => _subscriptions;

  @override
  void dispose() {
    _disposeSubscriptions();
    super.dispose();
  }

  void _createSubscriptions() {
    final subscriptions = <StreamSubscription>[];

    hook.eventSubscriptions.forEach((stream, callback) {
      try {
        final subscription = stream.listen(
          (event) {
            try {
              // Debug logging
              if (hook.debugName != null && kDebugMode) {
                debugPrint('🎯 [${hook.debugName}] Multi-hook event received: ${event.runtimeType}');
              }

              // Execute user callback
              callback(event);
            } catch (e, stackTrace) {
              // Log callback errors but don't crash the app
              debugPrint(
                '❌ ${hook.debugName ?? 'Unknown'} multi-hook event handler error: $e\n$stackTrace'
              );
            }
          },
          onError: (error, stackTrace) {
            // Handle stream errors
            debugPrint(
              '⚠️ ${hook.debugName ?? 'Unknown'} multi-hook event stream error: $error\n$stackTrace'
            );
          },
        );
        subscriptions.add(subscription);
      } catch (e, stackTrace) {
        debugPrint(
          '💥 ${hook.debugName ?? 'Unknown'} multi-hook subscription creation failed: $e\n$stackTrace'
        );
      }
    });

    _subscriptions = subscriptions;

    // Debug log subscription start
    if (hook.debugName != null && kDebugMode) {
      debugPrint('🟢 [${hook.debugName}] Multi-hook event subscriptions started: ${hook.eventSubscriptions.length} streams');
    }
  }

  void _disposeSubscriptions() {
    try {
      _subscriptions?.forEach((subscription) => subscription.cancel());
      if (hook.debugName != null && kDebugMode) {
        debugPrint('🔴 [${hook.debugName}] Multi-hook event subscriptions disposed');
      }
    } catch (e) {
      debugPrint('⚠️ ${hook.debugName ?? 'Unknown'} multi-hook subscriptions disposal error: $e');
    } finally {
      _subscriptions = null;
    }
  }

  bool _listEquals(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}