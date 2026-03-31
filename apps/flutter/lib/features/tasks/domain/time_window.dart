/// Time-of-day constraint for task scheduling (FR4).
///
/// Presets map to concrete time ranges via the user's energy preferences
/// (resolved by the scheduling engine in Epic 3). `custom` uses explicit
/// [timeWindowStart] and [timeWindowEnd] on the task.
enum TimeWindow {
  morning,
  afternoon,
  evening,
  custom;

  /// Parses a JSON string value to [TimeWindow].
  static TimeWindow? fromJson(String? value) {
    if (value == null) return null;
    return TimeWindow.values.where((e) => e.toJson() == value).firstOrNull;
  }

  /// Serialises to the API/DB string representation.
  String toJson() => name;
}
