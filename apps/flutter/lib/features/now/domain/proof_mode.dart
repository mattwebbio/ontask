/// Proof mode variants for task verification.
///
/// Determines how a committed task's completion is verified:
/// - [standard]: no special verification (default)
/// - [photo]: photo proof required (Epic 7)
/// - [watchMode]: Watch Mode session required (Epic 7)
/// - [healthKit]: HealthKit data verification (Epic 7)
/// - [calendarEvent]: calendar event (read-only, no CTA)
enum ProofMode {
  standard,
  photo,
  watchMode,
  healthKit,
  calendarEvent;

  /// Parses a JSON string to [ProofMode]. Defaults to [standard] for unknown values.
  static ProofMode fromJson(String? value) {
    switch (value) {
      case 'standard':
        return ProofMode.standard;
      case 'photo':
        return ProofMode.photo;
      case 'watchMode':
        return ProofMode.watchMode;
      case 'healthKit':
        return ProofMode.healthKit;
      case 'calendarEvent':
        return ProofMode.calendarEvent;
      default:
        return ProofMode.standard;
    }
  }

  /// Converts to JSON string.
  String toJson() => name;
}
