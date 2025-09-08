
/// Interface for all event categories in the application.
///
/// This pure interface approach follows industry best practices by not imposing
/// predefined categories on users. Instead, users define their own categories
/// that fit their specific domain needs.
///
/// **Implementation Example:**
/// ```dart
/// class MyAppCategories implements IEventCategory {
///   @override
///   final String value;
///   @override
///   final String displayName;
///   
///   const MyAppCategories._(this.value, this.displayName);
///   
///   static const authentication = MyAppCategories._('auth', 'Authentication Events');
///   static const dataSync = MyAppCategories._('sync', 'Data Synchronization Events');
/// }
///
/// // Usage in events
/// class UserLoginEvent extends DomainEvent {
///   const UserLoginEvent({...}) : super(
///     eventType: 'user.login',
///     category: MyAppCategories.authentication, // Only accepts IEventCategory
///   );
/// }
/// ```
///
/// **Why Pure Interface:**
/// - No predefined categories that may not fit your domain
/// - Users define categories that match their business logic
/// - Follows patterns from other EventBus libraries (Android, JavaScript)
/// - Type-safe and extensible
/// - Clean separation of concerns
abstract class IEventCategory {
  /// The unique identifier value for this category
  String get value;
  
  /// Human-readable display name for this category
  String get displayName;
  
  @override
  bool operator ==(Object other) => 
    other is IEventCategory && value == other.value;
    
  @override
  int get hashCode => value.hashCode;
  
  @override
  String toString() => value;
}

/// Mixin to reduce boilerplate code for custom IEventCategory implementations.
///
/// This mixin provides default implementations for equals, hashCode, and toString
/// based on the value property, ensuring consistent behavior across all categories.
///
/// **Usage:**
/// ```dart
/// class MyCategories with EventCategoryMixin implements IEventCategory {
///   @override
///   final String value;
///   
///   @override
///   final String displayName;
///   
///   const MyCategories._(this.value, this.displayName);
///   
///   static const custom = MyCategories._('my.custom', 'Custom Category');
/// }
/// ```
mixin EventCategoryMixin implements IEventCategory {
  @override
  bool operator ==(Object other) => 
    other is IEventCategory && value == other.value;
    
  @override
  int get hashCode => value.hashCode;
  
  @override
  String toString() => value;
}

/// Utility extensions for event categories.
extension EventCategoryExtensions on IEventCategory {
  /// Checks if this category belongs to a specific family/namespace.
  ///
  /// **Example:**
  /// ```dart
  /// final medicalCategory = MedicalCategories.patient; // 'medical.patient'
  /// print(medicalCategory.belongsTo('medical')); // true
  /// print(medicalCategory.belongsTo('user')); // false
  /// ```
  bool belongsTo(String family) => value.startsWith('$family.');
  
  /// Checks if this is a user-related category.
  bool get isUserRelated => value.startsWith('user');
  
  /// Checks if this is a system-related category.
  bool get isSystemRelated => value.startsWith('system');
}