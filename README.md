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
- 🛡️ **Error resilience** with graceful disposal and automatic recovery
- 🔧 **Custom error handling** with optional onError callbacks
- ⚡ **Advanced event processing** (throttling, buffering, filtering)
- 🔥 **Pure interface-based event categories** (industry best practices)
- 🐛 **Production stability** with comprehensive logging and crash prevention

## 📦 Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  riverpod_event_bus: ^0.1.0
  flutter_riverpod: ^2.4.10
  flutter_hooks: ^0.20.5 # Optional, for hooks support
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

The library follows **industry best practices** by using a pure interface-based approach for event categories. You define categories that match your specific domain needs, just like popular EventBus libraries in Android and JavaScript ecosystems.

#### 🎯 **Define Your Event Categories**

First, create categories specific to your application domain:

```dart
import 'package:riverpod_event_bus/riverpod_event_bus.dart';

// Define categories for your app domain
class AppEventCategories implements IEventCategory {
  @override
  final String value;
  @override
  final String displayName;

  const AppEventCategories._(this.value, this.displayName);

  // Define your app-specific categories
  static const user = AppEventCategories._('user', 'User Events');
  static const order = AppEventCategories._('order', 'Order Events');
  static const system = AppEventCategories._('system', 'System Events');
}
```

#### 🚀 **Create Your Domain Events**

Then use your categories in domain events:

```dart
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
    category: AppEventCategories.user,  // ✨ Your custom category
  );

  @override
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'email': email,
    ...super.toJson(),
  };
}
```

#### 🏥 **Domain-Specific Categories** (Advanced)

For complex domains, create specialized category groups:

```dart
// Medical domain categories
class MedicalCategories implements IEventCategory {
  @override
  final String value;
  @override
  final String displayName;

  const MedicalCategories._(this.value, this.displayName);

  static const patient = MedicalCategories._('medical.patient', 'Patient Events');
  static const doctor = MedicalCategories._('medical.doctor', 'Doctor Events');
  static const appointment = MedicalCategories._('medical.appointment', 'Appointment Events');
}

class PatientAdmittedEvent extends DomainEvent {
  const PatientAdmittedEvent({...}) : super(
    eventType: 'patient.admitted',
    category: MedicalCategories.patient,  // ✨ Domain-specific category
  );
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

    // Publish the event with your custom category
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
      onError: (error, stackTrace) {
        // Optional custom error handling
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Event processing failed')),
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

### Event Category Filtering

```dart
// Filter by category type
ref.listenToEvent(
  eventBus.stream.where((event) => event.category.isUserRelated),
  (event) => _handleUserEvent(event),
  debugName: 'UserEventHandler',
);

// Filter by category namespace
final medicalEvents = eventBus.stream.where(
  (event) => event.category.belongsTo('medical'),
);

// Filter by custom categories
final criticalEvents = eventBus.stream.where(
  (event) => event.category.value.contains('critical'),
);
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

The library uses a **pure interface-based approach** for event categories, giving you complete control without imposing predefined categories.

### Basic Implementation

```dart
// Define categories for your application
class AppEventCategories implements IEventCategory {
  @override
  final String value;
  @override
  final String displayName;

  const AppEventCategories._(this.value, this.displayName);

  static const user = AppEventCategories._('user', 'User Events');
  static const order = AppEventCategories._('order', 'Order Events');
  static const system = AppEventCategories._('system', 'System Events');
}

// Use in your events
class UserLoginEvent extends DomainEvent {
  const UserLoginEvent({...}) : super(
    eventType: 'user.login',
    category: AppEventCategories.user,
  );
}
```

### Category Filtering

```dart
// Filter by category namespace
final userEvents = eventBus.stream.where(
  (event) => event.category.belongsTo('user'),
);

// Filter by custom criteria
final criticalEvents = eventBus.stream.where(
  (event) => event.category.value.contains('critical'),
);
```

## 🧪 Testing

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_event_bus/riverpod_event_bus.dart';

// Define test categories
class TestCategories implements IEventCategory {
  @override
  final String value;
  @override
  final String displayName;

  const TestCategories._(this.value, this.displayName);

  static const user = TestCategories._('user', 'User Events');
}

// Define test event
class TestEvent extends DomainEvent {
  final String message;

  const TestEvent({
    required this.message,
    required super.eventId,
    required super.occurredAt,
  }) : super(
    eventType: 'test.event',
    category: TestCategories.user,
  );

  @override
  Map<String, dynamic> toJson() => {
    'message': message,
    ...super.toJson(),
  };
}

void main() {
  test('should publish and receive events', () async {
    final eventBus = DomainEventBus();
    final receivedEvents = <TestEvent>[];

    eventBus.ofType<TestEvent>().listen(receivedEvents.add);

    final event = TestEvent(
      message: 'Hello',
      eventId: 'test-123',
      occurredAt: DateTime.now(),
    );
    eventBus.publish(event);

    expect(receivedEvents, contains(event));
  });
}
```

## 📚 Examples

Complete examples are coming soon and will include:

- **Basic Usage**: Simple event publishing and subscription
- **Clean Architecture**: Full View/ViewModel separation
- **Advanced Features**: Throttling, buffering, and filtering
- **Testing**: Event-driven architecture testing patterns

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

### 3. Error Handling & Resilience

The library provides robust error handling to ensure production stability:

```dart
// ✅ Custom error handling in Hooks
useEventSubscription(
  eventBus.ofType<PaymentEvent>(),
  (event) => _processPayment(event),
  onError: (error, stackTrace) {
    // Custom error handling - optional
    _showErrorMessage('Payment failed');
    _logError(error, stackTrace);
  },
  debugName: 'PaymentProcessor',
);

// ✅ Error resilience in ViewModels
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

**Built-in Error Resilience:**

- **Graceful Disposal**: Events to disposed buses are safely ignored
- **Stream Continuity**: Subscriptions stay active even when handlers fail
- **Error Isolation**: Handler errors don't crash the app or affect other subscribers

### 4. Memory Management

```dart
// ✅ The library handles this automatically
// No need for manual subscription disposal!

// ❌ Don't try to manage subscriptions manually
// StreamSubscription? subscription; // Not needed!
```

## 🚀 Roadmap

### Upcoming Features

- **📌 Sticky Events**: Persistent event state for late subscribers
- **🔧 Event Interceptors**: Cross-cutting concerns (logging, analytics, error handling)
- **📚 Event History/Replay**: Time-travel debugging and state reconstruction
- **🎯 Advanced Features**: Wildcard subscriptions, priority handling, dead letter queue

We're always open to community feedback! If you have ideas for features or improvements, please [open an issue](https://github.com/bbeeco1218/riverpod_event_bus/issues) or join the discussion.

## 🤝 Contributing

Contributions are welcome! Please open an issue or submit a pull request on GitHub.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Riverpod](https://riverpod.dev) for excellent state management
- [Flutter Hooks](https://pub.dev/packages/flutter_hooks) for reactive UI patterns
- [RxDart](https://pub.dev/packages/rxdart) for powerful stream operators

---

**Made with ❤️ for the Flutter community**

[![GitHub stars](https://img.shields.io/github/stars/bbeeco1218/riverpod_event_bus.svg?style=social&label=Star)](https://github.com/bbeeco1218/riverpod_event_bus)
