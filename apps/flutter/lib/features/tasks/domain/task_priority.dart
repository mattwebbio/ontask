/// Task priority — independent of due date (FR68).
///
/// The scheduling engine (Epic 3) uses priority as a tiebreaker when
/// multiple tasks compete for the same time slot.
enum TaskPriority {
  normal,
  high,
  critical;

  /// Parses a JSON string value to [TaskPriority].
  static TaskPriority? fromJson(String? value) {
    if (value == null) return null;
    return TaskPriority.values.where((e) => e.toJson() == value).firstOrNull;
  }

  /// Serialises to the API/DB string representation.
  String toJson() => name;
}
