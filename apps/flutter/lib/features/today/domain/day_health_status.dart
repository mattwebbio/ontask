/// Health status for a single day in the schedule health strip.
///
/// Determined server-side based on capacity vs task load.
/// Stub returns [healthy] for all days until the scheduling engine (Epic 3).
enum DayHealthStatus {
  /// On track -- capacity available for all tasks.
  healthy,

  /// At risk -- overloaded, some tasks may slip.
  atRisk,

  /// Critical -- tasks will miss deadlines.
  critical;

  /// Parses the API string value to enum.
  static DayHealthStatus fromJson(String value) {
    switch (value) {
      case 'healthy':
        return DayHealthStatus.healthy;
      case 'at-risk':
        return DayHealthStatus.atRisk;
      case 'critical':
        return DayHealthStatus.critical;
      default:
        return DayHealthStatus.healthy;
    }
  }
}
