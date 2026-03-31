/// The milestone event that triggers a Chapter Break Screen.
///
/// V1 only wires [taskCompleted] (from NowScreen.onComplete).
/// The remaining triggers are stubs — wired in Epic 6 when the commitment
/// and charge flows are implemented.
enum ChapterBreakTrigger {
  /// A task was marked done from the Now tab (wired in Story 2.13).
  taskCompleted,

  // TODO(epic-6): trigger chapter break from commitment lock flow
  /// A commitment has been locked / confirmed by the user.
  commitmentLocked,

  // TODO(epic-6): trigger chapter break from missed commitment recovery
  /// The user has recovered from a missed commitment (charge processed).
  missedCommitmentRecovery,
}
