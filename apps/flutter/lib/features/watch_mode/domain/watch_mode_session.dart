/// Domain value object representing a Watch Mode live session.
///
/// Tracks session timing, frame capture counts, and computes the detected
/// activity percentage for display on the summary screen (FR66, FR67).
/// (Epic 7, Story 7.4, FR33-34, FR66-67)
class WatchModeSession {
  const WatchModeSession({
    required this.taskId,
    required this.taskName,
    required this.startedAt,
    this.endedAt,
    this.detectedActivityFrames = 0,
    this.totalFrames = 0,
  });

  final String taskId;
  final String taskName;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int detectedActivityFrames;
  final int totalFrames;

  Duration get elapsed => (endedAt ?? DateTime.now()).difference(startedAt);

  double get activityPercentage =>
      totalFrames == 0
          ? 0.0
          : (detectedActivityFrames / totalFrames * 100).clamp(0.0, 100.0);
}
