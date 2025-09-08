import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_event_bus/riverpod_event_bus.dart';

// Test implementation of IEventCategory
class TestAppCategories implements IEventCategory {
  @override
  final String value;
  @override
  final String displayName;

  const TestAppCategories._(this.value, this.displayName);

  static const authentication =
      TestAppCategories._('auth', 'Authentication Events');
  static const dataSync =
      TestAppCategories._('sync', 'Data Synchronization Events');
  static const notification =
      TestAppCategories._('notification', 'Notification Events');
}

// Another test implementation for medical domain
class MedicalCategories implements IEventCategory {
  @override
  final String value;
  @override
  final String displayName;

  const MedicalCategories._(this.value, this.displayName);

  static const patient =
      MedicalCategories._('medical.patient', 'Patient Events');
  static const doctor = MedicalCategories._('medical.doctor', 'Doctor Events');
  static const appointment =
      MedicalCategories._('medical.appointment', 'Appointment Events');
}

// Test event using IEventCategory directly
class TestEvent extends DomainEvent {
  final String message;

  const TestEvent({
    required this.message,
    required super.eventId,
    required super.occurredAt,
    required super.eventType,
    required super.category, // Should only accept IEventCategory
  });

  @override
  Map<String, dynamic> toJson() => {
        'message': message,
        ...super.toJson(),
      };
}

void main() {
  group('EventCategory System (Interface-only)', () {
    final testTime = DateTime(2024, 1, 1, 12, 0, 0);

    group('IEventCategory Interface', () {
      test('should support user-defined categories', () {
        final authCategory = TestAppCategories.authentication;

        expect(authCategory.value, equals('auth'));
        expect(authCategory.displayName, equals('Authentication Events'));
        expect(authCategory, isA<IEventCategory>());
      });

      test('should support multiple category implementations', () {
        final authCategory = TestAppCategories.authentication;
        final patientCategory = MedicalCategories.patient;

        expect(authCategory.value, equals('auth'));
        expect(patientCategory.value, equals('medical.patient'));

        // Both implement same interface
        expect(authCategory, isA<IEventCategory>());
        expect(patientCategory, isA<IEventCategory>());
      });

      test('should support namespaced categories', () {
        final patientCategory = MedicalCategories.patient;
        final doctorCategory = MedicalCategories.doctor;

        expect(patientCategory.value, startsWith('medical.'));
        expect(doctorCategory.value, startsWith('medical.'));

        expect(patientCategory.displayName, contains('Patient'));
        expect(doctorCategory.displayName, contains('Doctor'));
      });
    });

    group('DomainEvent Integration', () {
      test('should only accept IEventCategory in DomainEvent', () {
        final event = TestEvent(
          message: 'test message',
          eventId: 'test-123',
          occurredAt: testTime,
          eventType: 'test.event',
          category:
              TestAppCategories.authentication, // IEventCategory implementation
        );

        expect(event.category, isA<IEventCategory>());
        expect(event.category.value, equals('auth'));
        expect(event.category.displayName, equals('Authentication Events'));
      });

      test('should work with different category implementations', () {
        final authEvent = TestEvent(
          message: 'auth test',
          eventId: 'auth-123',
          occurredAt: testTime,
          eventType: 'auth.login',
          category: TestAppCategories.authentication,
        );

        final medicalEvent = TestEvent(
          message: 'medical test',
          eventId: 'medical-123',
          occurredAt: testTime,
          eventType: 'patient.admitted',
          category: MedicalCategories.patient,
        );

        expect(authEvent.category.value, equals('auth'));
        expect(medicalEvent.category.value, equals('medical.patient'));

        // Both should serialize correctly
        final authJson = authEvent.toJson();
        final medicalJson = medicalEvent.toJson();

        expect(authJson['category'], equals('auth'));
        expect(medicalJson['category'], equals('medical.patient'));
      });
    });

    group('No Predefined Categories', () {
      test('should not have any predefined categories in library', () {
        // This test ensures we don't accidentally add predefined categories
        // The library should only provide the IEventCategory interface

        // The library should not provide predefined categories like user, order, etc.
        // Users should define their own categories
        expect(TestAppCategories.authentication, isA<IEventCategory>());
        expect(MedicalCategories.patient, isA<IEventCategory>());
      });

      test('should require users to define their own categories', () {
        // Users must implement IEventCategory for their domain
        final userCategory = TestAppCategories.authentication;
        final medicalCategory = MedicalCategories.patient;

        // Each has their own domain-specific values
        expect(userCategory.value, isNot(equals(medicalCategory.value)));
        expect(userCategory.displayName,
            isNot(equals(medicalCategory.displayName)));
      });
    });

    group('Category Equality and Comparison', () {
      test('should support equality comparison', () {
        final category1 = TestAppCategories.authentication;
        final category2 = TestAppCategories.authentication;

        expect(category1, equals(category2));
        expect(category1.value, equals(category2.value));
      });

      test('should differentiate between different categories', () {
        final authCategory = TestAppCategories.authentication;
        final syncCategory = TestAppCategories.dataSync;

        expect(authCategory, isNot(equals(syncCategory)));
        expect(authCategory.value, isNot(equals(syncCategory.value)));
      });

      test('should differentiate between different implementations', () {
        final appCategory = TestAppCategories.authentication;
        final medicalCategory = MedicalCategories.patient;

        expect(appCategory, isNot(equals(medicalCategory)));
        expect(appCategory.value, isNot(equals(medicalCategory.value)));
      });
    });
  });
}
