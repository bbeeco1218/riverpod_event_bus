# 🚀 Riverpod Event Bus

[![pub package](https://img.shields.io/pub/v/riverpod_event_bus.svg)](https://pub.dev/packages/riverpod_event_bus)
[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A powerful, type-safe event bus library that integrates seamlessly with **Riverpod** and **Flutter Hooks** for reactive Flutter applications. Built with clean architecture principles and automatic memory management.

## ✨ Features

- 🎯 **Type-safe domain events** with automatic serialization
- 🔄 **Riverpod integration** with automatic lifecycle management  
- 🪝 **Flutter Hooks support** for widget-level event subscriptions
- 🏗️ **Architecture enforcement** (View/ViewModel separation)
- 🛡️ **Memory leak prevention** with automatic subscription disposal
- ⚡ **Advanced event processing** (throttling, buffering, filtering)
- 🐛 **Debug-friendly** with comprehensive logging and error handling
- ✅ **Fully tested** (54 tests, 100% pass rate)

## 📦 Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  riverpod_event_bus: ^0.1.0
  flutter_riverpod: ^2.4.10
  flutter_hooks: ^0.20.5  # Optional, for hooks support
  hooks_riverpod: ^2.4.10 # Optional, for hooks support
```

Then run:

```bash
flutter pub get
```

## 🚀 Quick Start

### 1. Wrap your app with ProviderScope

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}
```

### 2. Create domain events

```dart
import 'package:riverpod_event_bus/riverpod_event_bus.dart';

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
    category: EventCategory.user,
  );

  @override
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'email': email,
    ...super.toJson(),
  };
}
```

### 3. Publish events

```dart
@riverpod
class UserRepository extends _$UserRepository {
  @override
  Future<void> build() async {}
  
  Future<void> registerUser(String email) async {
    // Your registration logic...
    final userId = await _performRegistration(email);
    
    // Publish the event
    final eventBus = ref.read(domainEventBusProvider);
    eventBus.publish(UserRegisteredEvent(
      userId: userId,
      email: email,
      eventId: 'user-${DateTime.now().millisecondsSinceEpoch}',
      occurredAt: DateTime.now(),
    ));
  }
}
```

## 🏗️ Architecture Guide

This library enforces **clean architecture** by separating concerns between Views and ViewModels:

### ✅ ViewModel Usage (Data Layer)

Use `ref.listenToEvent()` in **NotifierProvider** for data operations:

```dart
@riverpod
class HomeNotifier extends _$HomeNotifier {
  @override
  Future<HomeState> build() async {
    final eventBus = ref.read(domainEventBusProvider);

    // ✅ ViewModel usage - for data updates
    ref.listenToEvent(
      eventBus.ofType<UserRegisteredEvent>(),
      (event) {
        // Handle data changes, cache invalidation, etc.
        ref.invalidateSelf();
      },
      debugName: 'HomeNotifier',
    );

    return HomeState(users: await _loadUsers());
  }
}
```

### ✅ View Usage (UI Layer)

Use `useEventSubscription()` Hook in **HookConsumerWidget** for UI interactions:

```dart
import 'package:riverpod_event_bus/hooks.dart';

class HomeScreen extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventBus = ref.read(domainEventBusProvider);

    // ✅ View usage - for UI interactions
    useEventSubscription(
      eventBus.ofType<UserRegisteredEvent>(),
      (event) {
        // Handle UI interactions
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome ${event.email}!')),
        );
      },
      debugName: 'HomeScreen',
    );

    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Consumer(
        builder: (context, ref, child) {
          final homeState = ref.watch(homeNotifierProvider);
          return homeState.when(
            data: (data) => ListView(children: [...]),
            loading: () => CircularProgressIndicator(),
            error: (error, stack) => Text('Error: $error'),
          );
        },
      ),
    );
  }
}
```

### 🚨 Architecture Enforcement

The library **prevents architectural violations** at compile-time:

```dart
// ❌ This will throw ArgumentError at runtime
class BadExample extends ConsumerWidget {
  Widget build(context, ref) {
    final eventBus = ref.read(domainEventBusProvider);
    
    // ❌ Don't use in Views! Will throw ArgumentError
    ref.listenToEvent(eventBus.ofType<UserEvent>(), (event) {});
    
    return Container();
  }
}
```

**Error message:**
```
🚨 Architecture Rule Violation!

❌ Cannot use Ref extension methods in Views (Widgets)
✅ Use useEventSubscription() Hook instead
```

## 🎛️ Advanced Features

### Event Filtering

```dart
// Filter events with conditions
ref.listenToEventWhen(
  eventBus.ofType<UserRegisteredEvent>(),
  condition: (event) => event.userId == currentUserId,
  onEvent: (event) => ref.invalidateSelf(),
  debugName: 'UserDetailNotifier',
);
```

### Multiple Event Subscriptions

```dart
// Listen to multiple event types
ref.listenToMultipleEvents({
  eventBus.ofType<UserRegisteredEvent>(): (event) => _handleUserRegistered(event),
  eventBus.ofType<UserDeletedEvent>(): (event) => _handleUserDeleted(event),
}, debugName: 'UserNotifier');
```

### Advanced Event Bus Features

```dart
final advancedEventBus = ref.read(advancedDomainEventBusProvider);

// Throttling - limit event frequency
final throttledStream = advancedEventBus.throttle(
  eventBus.ofType<UserClickEvent>(),
  Duration(milliseconds: 500),
);

// Buffering - collect events in batches
final bufferedStream = advancedEventBus.buffer(
  eventBus.ofType<AnalyticsEvent>(),
  Duration(seconds: 5),
);

// Distinct - eliminate duplicate events
final distinctStream = advancedEventBus.distinct(
  eventBus.ofType<UserEvent>(),
);
```

### Scoped Event Buses

```dart
// Create scoped event buses for feature isolation
@riverpod
Raw<DomainEventBus> userScopedEventBus(UserScopedEventBusRef ref) {
  return ref.watch(scopedDomainEventBusProvider('user-scope'));
}
```

### Debug Information

```dart
@riverpod  
class EventBusMonitor extends _$EventBusMonitor {
  @override
  String build() {
    final debugInfo = ref.watch(eventBusDebugInfoProvider);
    return 'Active subscriptions: ${debugInfo.subscriptionCount}';
  }
}
```

## 🎨 Event Categories

Organize your events using predefined categories:

```dart
enum EventCategory {
  user,         // User-related events
  order,        // Order and transaction events  
  product,      // Product catalog events
  payment,      // Payment processing events
  notification, // Notification events
  system,       // System and infrastructure events
}

// Usage
class OrderCreatedEvent extends DomainEvent {
  const OrderCreatedEvent({...}) : super(
    eventType: 'order.created',
    category: EventCategory.order, // 👈 Categorize your event
  );
}
```

## 🧪 Testing

The library is thoroughly tested with **54 tests achieving 100% pass rate**:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_event_bus/riverpod_event_bus.dart';

void main() {
  test('should publish and receive events', () async {
    final eventBus = DomainEventBus();
    final receivedEvents = <TestEvent>[];
    
    eventBus.ofType<TestEvent>().listen(receivedEvents.add);
    
    final event = TestEvent(message: 'Hello');
    eventBus.publish(event);
    
    expect(receivedEvents, contains(event));
  });
}
```

## 📚 Examples

Check out the `/example` folder for complete examples:

- **Basic Usage**: Simple event publishing and subscription
- **Clean Architecture**: Full View/ViewModel separation example
- **Advanced Features**: Throttling, buffering, and filtering
- **Testing**: How to test your event-driven architecture

## 🎯 Best Practices

### 1. Event Naming Convention
```dart
// ✅ Use descriptive, past-tense event names
class UserRegisteredEvent extends DomainEvent { ... }
class OrderCompletedEvent extends DomainEvent { ... }
class PaymentFailedEvent extends DomainEvent { ... }

// ❌ Avoid vague or imperative names
class UserEvent extends DomainEvent { ... }
class RegisterUser extends DomainEvent { ... }
```

### 2. Event Granularity
```dart
// ✅ Fine-grained events for specific actions
class UserEmailUpdatedEvent extends DomainEvent { ... }
class UserPasswordChangedEvent extends DomainEvent { ... }

// ❌ Overly broad events
class UserUpdatedEvent extends DomainEvent { ... }
```

### 3. Error Handling
```dart
// ✅ Handle errors gracefully
ref.listenToEvent(
  eventBus.ofType<PaymentEvent>(),
  (event) {
    try {
      _processPayment(event);
    } catch (error) {
      _handlePaymentError(error);
    }
  },
  debugName: 'PaymentProcessor',
);
```

### 4. Memory Management
```dart
// ✅ The library handles this automatically
// No need for manual subscription disposal!

// ❌ Don't try to manage subscriptions manually
// StreamSubscription? subscription; // Not needed!
```

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

1. Fork the repository
2. Clone your fork: `git clone https://github.com/bbeeco1218/riverpod_event_bus.git`
3. Install dependencies: `flutter pub get`
4. Run tests: `flutter test`
5. Create a feature branch: `git checkout -b feature/amazing-feature`
6. Make your changes and add tests
7. Ensure all tests pass: `flutter test`
8. Commit your changes: `git commit -m 'Add amazing feature'`
9. Push to your branch: `git push origin feature/amazing-feature`
10. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Riverpod](https://riverpod.dev) for excellent state management
- [Flutter Hooks](https://pub.dev/packages/flutter_hooks) for reactive UI patterns
- [RxDart](https://pub.dev/packages/rxdart) for powerful stream operators

---

**Made with ❤️ for the Flutter community**

[![GitHub stars](https://img.shields.io/github/stars/bbeeco1218/riverpod_event_bus.svg?style=social&label=Star)](https://github.com/bbeeco1218/riverpod_event_bus)