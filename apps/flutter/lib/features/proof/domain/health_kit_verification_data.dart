/// HealthKit verification data submitted as proof for auto-verified tasks.
///
/// (Epic 7, Story 7.5, FR35)
class HealthKitVerificationData {
  const HealthKitVerificationData({
    required this.activityType,
    required this.durationSeconds,
    required this.startedAt,
    required this.endedAt,
    this.calories,
  });

  /// The HealthKit activity type name (e.g. 'workout', 'mindfulSession').
  final String activityType;

  /// Duration of the activity in seconds.
  final int durationSeconds;

  /// When the activity started (from HealthKit).
  final DateTime startedAt;

  /// When the activity ended (from HealthKit).
  final DateTime endedAt;

  /// Calories burned, if available (may be null for non-workout activities).
  final double? calories;
}
