/// Proof path variants for selecting the verification method inside the
/// Proof Capture Modal.
///
/// Distinct from [ProofMode] (which is set when a task is created/locked);
/// [ProofPath] is the in-modal choice of *how* to submit proof.
/// (Epic 7, Story 7.1, FR31)
enum ProofPath {
  photo,
  healthKit,

  /// Watch Mode Live Session path (Epic 7, Stories 7.4–7.5).
  /// Distinct from [healthKit] which is auto-verification from Apple Health.
  watchMode,
  screenshot,
  offline;

  /// Parses a JSON string to [ProofPath].
  ///
  /// Throws [ArgumentError] for unknown values — previously silently defaulted
  /// to [photo] (deferred fix from Story 7.1).
  static ProofPath fromJson(String? value) {
    switch (value) {
      case 'photo':
        return ProofPath.photo;
      case 'healthKit':
        return ProofPath.healthKit;
      case 'watchMode':
        return ProofPath.watchMode;
      case 'screenshot':
        return ProofPath.screenshot;
      case 'offline':
        return ProofPath.offline;
      default:
        throw ArgumentError.value(value, 'value', 'Unknown ProofPath value');
    }
  }

  /// Converts to JSON string.
  String toJson() => name;
}
