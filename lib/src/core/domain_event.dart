import 'package:meta/meta.dart';
import 'event_category.dart';

/// Base class for all domain events in the application.
///
/// Domain events represent something that has occurred within the domain
/// that is relevant to other parts of the application.
///
/// **Hybrid Category Support:**
/// This class supports multiple ways to specify event categories:
///
/// 1. **String-based** (simple):
/// ```dart
/// class UserRegisteredEvent extends DomainEvent {
///   const UserRegisteredEvent({
///     required this.userId,
///     required this.email,
///     required super.eventId,
///     required super.occurredAt,
///   }) : super(
///     eventType: 'user.registered',
///     category: 'user',  // Simple string
///   );
/// }
/// ```
///
/// 2. **Predefined constants** (recommended):
/// ```dart
/// class UserRegisteredEvent extends DomainEvent {
///   const UserRegisteredEvent({
///     required this.userId,
///     required this.email,
///     required super.eventId,
///     required super.occurredAt,
///   }) : super(
///     eventType: 'user.registered',
///     category: MyAppCategories.user,  // Predefined constant
///   );
/// }
/// ```
///
/// 3. **Custom interface implementations** (advanced):
/// ```dart
/// class MedicalCategories implements IEventCategory {
///   static const patient = MedicalCategories._('medical.patient', 'Patient Events');
///   // ...
/// }
///
/// class PatientAdmittedEvent extends DomainEvent {
///   const PatientAdmittedEvent({
///     required super.eventId,
///     required super.occurredAt,
///   }) : super(
///     eventType: 'patient.admitted',
///     category: MedicalCategories.patient,  // Custom interface
///   );
/// }
/// ```
@immutable
abstract class DomainEvent {
  /// Event type identifier (e.g., 'user.registered', 'order.completed')
  final String eventType;

  /// Event category for domain-based classification
  /// 
  /// Pure interface-based approach - only accepts IEventCategory implementations
  final IEventCategory category;

  /// The timestamp when this event occurred
  final DateTime occurredAt;

  /// Unique identifier for this event
  final String eventId;

  /// Creates a new domain event with pure interface-based category.
  /// 
  /// The [category] parameter only accepts IEventCategory implementations.
  /// Users must define their own categories by implementing IEventCategory.
  const DomainEvent({
    required this.eventType,
    required this.category,
    required this.occurredAt,
    required this.eventId,
  });

  /// Creates a domain event with the current timestamp and generated ID.
  /// 
  /// Only accepts IEventCategory implementations - no more dynamic categories.
  factory DomainEvent.now({
    required String eventType,
    required IEventCategory category,
    String? eventId,
  }) =>
      _SimpleDomainEvent(
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
      '$runtimeType{eventType: $eventType, eventId: $eventId, category: ${category.value}, occurredAt: $occurredAt}';
}

/// Simple implementation for domain events with pure interface-based categories.
/// 
/// This class is used by factory constructors when we need a concrete implementation.
class _SimpleDomainEvent extends DomainEvent {
  const _SimpleDomainEvent({
    required super.eventType,
    required super.category,
    required super.occurredAt,
    required super.eventId,
  });
}
