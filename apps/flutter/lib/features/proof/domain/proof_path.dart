/// Proof path variants for selecting the verification method inside the
/// Proof Capture Modal.
///
/// Distinct from [ProofMode] (which is set when a task is created/locked);
/// [ProofPath] is the in-modal choice of *how* to submit proof.
/// (Epic 7, Story 7.1, FR31)
enum ProofPath {
  photo,
  healthKit,
  screenshot,
  offline;

  /// Parses a JSON string to [ProofPath]. Defaults to [photo] for unknown values.
  static ProofPath fromJson(String? value) {
    switch (value) {
      case 'photo':
        return ProofPath.photo;
      case 'healthKit':
        return ProofPath.healthKit;
      case 'screenshot':
        return ProofPath.screenshot;
      case 'offline':
        return ProofPath.offline;
      default:
        return ProofPath.photo;
    }
  }

  /// Converts to JSON string.
  String toJson() => name;
}
