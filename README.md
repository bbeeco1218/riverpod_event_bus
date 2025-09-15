# 🚀 Riverpod Event Bus

[![pub package](https://img.shields.io/pub/v/riverpod_event_bus.svg)](https://pub.dev/packages/riverpod_event_bus)
[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A type-safe event bus library that integrates seamlessly with **Riverpod** and **Flutter Hooks** for reactive Flutter applications. Built with clean architecture principles, automatic memory management, and category-based event filtering.

## ✨ Features

- 🎯 **Type-safe domain events** with category-based filtering
- 🔄 **Riverpod integration** with automatic lifecycle management
- 🪝 **Flutter Hooks support** for widget-level subscriptions
- 🏗️ **Architecture enforcement** (View/ViewModel separation)
- 🛡️ **Error resilience** with graceful disposal and recovery
- ⚡ **Advanced processing** (throttling, buffering, filtering)

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

### 1. Define Event Categories

```dart
import 'package:riverpod_event_bus/riverpod_event_bus.dart';

class MyAppCategories implements IEventCategory {
  @override
  final String value;
  @override
  final String displayName;

  const MyAppCategories._(this.value, this.displayName);

  static const user = MyAppCategories._('user', 'User Events');
  static const order = MyAppCategories._('order', 'Order Events');
}
```

### 2. Create Domain Events

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
    category: MyAppCategories.user,
  );
}
```

### 3. Subscribe to Events

**In ViewModels (Riverpod Notifiers):**
```dart
@riverpod
class HomeNotifier extends _$HomeNotifier {
  @override
  Future<HomeState> build() async {
    final eventBus = ref.read(domainEventBusProvider);

    // Type-based subscription
    ref.listenToEvent(
      eventBus.ofType<UserRegisteredEvent>(),
      (event) => ref.invalidateSelf(),
    );

    // ✨ NEW: Category-based subscription
    ref.listenToEvent(
      eventBus.on<UserRegisteredEvent>(MyAppCategories.user),
      (event) => _handleUserEvent(event),
    );

    return HomeState(users: await _loadUsers());
  }
}
```

**In Widgets (Hook Consumers):**
```dart
import 'package:riverpod_event_bus/hooks.dart';

class HomeScreen extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventBus = ref.read(domainEventBusProvider);

    // Category-based subscription in UI
    useEventSubscription(
      eventBus.on<UserRegisteredEvent>(MyAppCategories.user),
      (event) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Welcome ${event.email}!')),
        );
      },
      debugName: 'HomeScreen',
    );

    return Scaffold(/* ... */);
  }
}
```

### 4. Publish Events

```dart
@riverpod
class UserRepository extends _$UserRepository {
  Future<void> registerUser(String email) async {
    final userId = await _performRegistration(email);

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

## 🚨 Common Pitfalls

**❌ Architecture Violation - Using Riverpod extensions in Views:**
```dart
class MyWidget extends ConsumerWidget {
  Widget build(context, ref) {
    // ❌ This will throw ArgumentError!
    ref.listenToEvent(eventBus.ofType<UserEvent>(), (event) {});
    return Container();
  }
}
```

**✅ Correct Usage:**
```dart
class MyWidget extends HookConsumerWidget {
  Widget build(context, ref) {
    // ✅ Use hooks in Views
    useEventSubscription(eventBus.ofType<UserEvent>(), (event) {});
    return Container();
  }
}
```

**❌ Manual Subscription Management:**
```dart
// ❌ Don't manage subscriptions manually
StreamSubscription? subscription;

@override
void dispose() {
  subscription?.cancel(); // Not needed!
  super.dispose();
}
```

**✅ Automatic Management:**
```dart
// ✅ Library handles disposal automatically
useEventSubscription(eventBus.ofType<UserEvent>(), (event) {});
ref.listenToEvent(eventBus.ofType<UserEvent>(), (event) {});
```

## 🛣️ Roadmap

### Upcoming Features
- 📌 **Sticky Events**: Persistent event state for late subscribers
- 🔧 **Event Interceptors**: Cross-cutting concerns (logging, analytics, error handling)
- 📚 **Event History/Replay**: Time-travel debugging and state reconstruction
- 🎯 **Advanced Features**: Wildcard subscriptions, priority handling, dead letter queue

We're always open to community feedback! If you have ideas for features or improvements, please open an issue or join the discussion.

## 🤝 Contributing

Contributions are welcome! Please open an issue or submit a pull request on GitHub.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- [Riverpod](https://riverpod.dev) for excellent state management
- [Flutter Hooks](https://pub.dev/packages/flutter_hooks) for reactive UI patterns
- [RxDart](https://pub.dev/packages/rxdart) for powerful stream operators

---

**Made with ❤️ for the Flutter community**