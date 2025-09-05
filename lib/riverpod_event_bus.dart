/// A powerful event bus library that integrates seamlessly with Riverpod
/// and Flutter Hooks for reactive Flutter applications.
///
/// This library provides a clean, type-safe way to implement domain events
/// in Flutter applications using the Riverpod state management library.
///
/// ## Features
///
/// - **Type-safe domain events** with automatic serialization
/// - **Riverpod integration** with automatic lifecycle management
/// - **Flutter Hooks support** for widget-level event subscriptions
/// - **Architecture enforcement** (View/ViewModel separation)
/// - **Memory leak prevention** with automatic subscription disposal
/// - **Advanced event processing** (throttling, buffering, filtering)
/// - **Debug-friendly** with comprehensive logging and error handling
///
/// ## Core Concepts
///
/// ### Domain Events
/// Events represent something meaningful that happened in your domain:
/// ```dart
/// class UserRegisteredEvent extends DomainEvent {
///   final String userId;
///   final String email;
///
///   const UserRegisteredEvent({
///     required this.userId,
///     required this.email,
///     required String eventId,
///     required DateTime occurredAt,
///   }) : super(
///     eventType: 'user.registered',
///     category: EventCategory.user,
///     eventId: eventId,
///     occurredAt: occurredAt,
///   );
/// }
/// ```
///
/// ### ViewModel Usage (Riverpod Extensions)
/// Use in NotifierProvider for data layer operations:
/// ```dart
/// @riverpod
/// class UserNotifier extends _$UserNotifier {
///   @override
///   Future<UserState> build() async {
///     final eventBus = ref.read(domainEventBusProvider);
///
///     // ✅ ViewModel usage - for data updates
///     ref.listenToEvent(
///       eventBus.ofType<UserRegisteredEvent>(),
///       (event) {
///         // Handle data changes, cache invalidation, etc.
///         ref.invalidateSelf();
///       },
///       debugName: 'UserNotifier',
///     );
///
///     return UserState(...);
///   }
/// }
/// ```
///
/// ### View Usage (Flutter Hooks)
/// Use in HookConsumerWidget for UI interactions:
/// ```dart
/// class UserScreen extends HookConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final eventBus = ref.read(domainEventBusProvider);
///
///     // ✅ View usage - for UI interactions
///     useEventSubscription(
///       eventBus.ofType<UserRegisteredEvent>(),
///       (event) {
///         // Handle UI interactions
///         showSnackBar(context, 'Welcome ${event.email}!');
///       },
///       debugName: 'UserScreen',
///     );
///
///     return Scaffold(...);
///   }
/// }
/// ```
///
/// ## Architecture Rules
///
/// This library enforces clean architecture principles:
///
/// - **ViewModels** (NotifierProvider): Use `ref.listenToEvent()` for data operations
/// - **Views** (Widgets): Use `useEventSubscription()` Hook for UI interactions
/// - **Automatic validation**: Compile-time checks prevent architectural violations
///
/// ## Getting Started
///
/// 1. Add the provider to your app:
/// ```dart
/// void main() {
///   runApp(
///     ProviderScope(
///       child: MyApp(),
///     ),
///   );
/// }
/// ```
///
/// 2. Create domain events by extending [DomainEvent]
/// 3. Use [domainEventBusProvider] to access the event bus
/// 4. Subscribe using appropriate methods based on your layer:
///    - ViewModels: `ref.listenToEvent()`
///    - Views: `useEventSubscription()`
///
/// For Flutter Hooks integration, also import:
/// ```dart
/// import 'package:riverpod_event_bus/hooks.dart';
/// ```
library;

// Core domain event system
export 'src/core/domain_event.dart';
export 'src/core/domain_event_bus.dart';
export 'src/core/providers.dart';

// Riverpod integration (ViewModel layer)
export 'src/extensions/riverpod_event_extension.dart';

// Note: Flutter Hooks integration (View layer) is exported separately
// Import 'package:riverpod_event_bus/hooks.dart' for widget-level subscriptions
