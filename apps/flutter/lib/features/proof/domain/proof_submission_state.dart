import 'proof_path.dart';

/// Sealed class representing the state of a proof submission session inside
/// the [ProofCaptureModal].
///
/// States:
/// - [ProofSubmissionIdle]: modal open, user on path selector, no path selected
/// - [ProofSubmissionPathSelected]: user tapped a path — sub-view visible
/// - [ProofSubmissionSubmitted]: user completed proof submission
/// - [ProofSubmissionDismissed]: user dismissed without submitting
/// (Epic 7, Story 7.1, FR31)
sealed class ProofSubmissionState {
  const ProofSubmissionState();
}

/// Initial state — path selector is shown, no path selected.
class ProofSubmissionIdle extends ProofSubmissionState {
  const ProofSubmissionIdle();
}

/// A proof path has been selected — the corresponding sub-view is shown.
class ProofSubmissionPathSelected extends ProofSubmissionState {
  const ProofSubmissionPathSelected(this.path);

  final ProofPath path;
}

/// Proof has been submitted successfully.
class ProofSubmissionSubmitted extends ProofSubmissionState {
  const ProofSubmissionSubmitted();
}

/// Modal was dismissed without submitting; task remains in pending completion.
class ProofSubmissionDismissed extends ProofSubmissionState {
  const ProofSubmissionDismissed();
}
