/// Sealed class representing the result of AI proof verification.
///
/// Returned by [ProofRepository.submitPhotoProof] after the API call completes.
/// (Epic 7, Story 7.2, FR31-32)
sealed class ProofVerificationResult {
  const ProofVerificationResult();
}

/// Verification succeeded — proof was accepted.
final class ProofVerificationApproved extends ProofVerificationResult {
  const ProofVerificationApproved();
}

/// Verification failed — proof was rejected with a plain-language reason.
final class ProofVerificationRejected extends ProofVerificationResult {
  const ProofVerificationRejected({required this.reason});

  /// Plain-language explanation of why the proof was rejected (from API).
  final String reason;
}

/// Verification errored — network or unexpected API failure.
final class ProofVerificationError extends ProofVerificationResult {
  const ProofVerificationError({required this.message});

  /// Human-readable error message.
  final String message;
}
