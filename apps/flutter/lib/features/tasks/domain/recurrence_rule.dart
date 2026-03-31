/// Recurrence schedule rule for recurring tasks (FR7).
///
/// Determines how often a task repeats. `custom` uses an explicit
/// [recurrenceInterval] (in days) on the task.
enum RecurrenceRule {
  daily,
  weekly,
  monthly,
  custom;

  /// Parses a JSON string value to [RecurrenceRule].
  static RecurrenceRule? fromJson(String? value) {
    if (value == null) return null;
    return RecurrenceRule.values.where((e) => e.toJson() == value).firstOrNull;
  }

  /// Serialises to the API/DB string representation.
  String toJson() => name;
}
