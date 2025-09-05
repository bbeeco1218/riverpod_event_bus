import 'package:meta/meta.dart';

/// Base class for all domain events in the application.
///
/// Domain events represent something that has occurred within the domain
/// that is relevant to other parts of the application.
///
/// Example:
/// ```dart
/// class UserRegisteredEvent extends DomainEvent {
///   final String userId;
///   final String email;
///
///   const UserRegisteredEvent({
///     required this.userId,
///     required this.email,
///   }) : super(
///     eventType: 'user.registered',
///     category: EventCategory.user,
///   );
///
///   @override
///   Map<String, dynamic> toJson() => {
///     'userId': userId,
///     'email': email,
///     ...super.toJson(),
///   };
/// }
/// ```
@immutable
abstract class DomainEvent {
  /// Event type identifier (e.g., 'user.registered', 'order.completed')
  final String eventType;

  /// Event category for domain-based classification
  final EventCategory category;

  /// The timestamp when this event occurred
  final DateTime occurredAt;

  /// Unique identifier for this event
  final String eventId;

  /// Creates a new domain event with required fields.
  const DomainEvent({
    required this.eventType,
    required this.category,
    required this.occurredAt,
    required this.eventId,
  });

  /// Creates a domain event with the current timestamp and generated ID.
  factory DomainEvent.now({
    required String eventType,
    required EventCategory category,
    String? eventId,
  }) =>
      _TimestampedDomainEvent(
        eventType: eventType,
        category: category,
        occurredAt: DateTime.now(),
        eventId: eventId ?? _generateEventId(),
      );

  /// Generates a unique event ID (UUID v4)
  static String _generateEventId() {
    // Simple UUID v4 implementation
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.hashCode;
    return '$timestamp-$random';
  }

  /// Serializes the event to JSON for storage or transmission
  Map<String, dynamic> toJson() => {
        'eventType': eventType,
        'category': category.value,
        'occurredAt': occurredAt.toIso8601String(),
        'eventId': eventId,
        'metadata': metadata,
      };

  /// Additional metadata for the event (override in subclasses)
  Map<String, dynamic> get metadata => {};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DomainEvent &&
          runtimeType == other.runtimeType &&
          eventType == other.eventType &&
          eventId == other.eventId &&
          occurredAt == other.occurredAt;

  @override
  int get hashCode => Object.hash(runtimeType, eventType, eventId, occurredAt);

  @override
  String toString() =>
      '$runtimeType{eventType: $eventType, eventId: $eventId, occurredAt: $occurredAt}';
}

/// Internal implementation for domain events with explicit timestamps.
class _TimestampedDomainEvent extends DomainEvent {
  const _TimestampedDomainEvent({
    required super.eventType,
    required super.category,
    required super.occurredAt,
    required super.eventId,
  });
}

/// Event category enumeration for domain-based classification
///
/// This helps organize and filter events by business domain.
/// Add new categories as your application grows.
enum EventCategory {
  /// User-related events (registration, login, profile changes)
  user('user'),

  /// Order and transaction events
  order('order'),

  /// Product and inventory events
  product('product'),

  /// Payment and billing events
  payment('payment'),

  /// Notification events
  notification('notification'),

  /// System events (startup, shutdown, maintenance)
  system('system');

  const EventCategory(this.value);

  /// The string value of the category
  final String value;

  @override
  String toString() => value;
}
