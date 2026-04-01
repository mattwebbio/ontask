import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_stake.freezed.dart';

/// Domain model for the stake amount on a specific task.
///
/// Used by [StakeSliderWidget] and [StakeSheetScreen] to carry stake state.
/// A null [stakeAmountCents] means no stake is set on the task.
/// Stake is stored as integer cents to avoid floating-point issues (e.g., 2500 = $25.00).
/// [stakeModificationDeadline] is set to (dueDate - 24h) when stake is locked;
/// null means unstaked or not yet computed (FR63, Story 6.6).
@freezed
abstract class TaskStake with _$TaskStake {
  const factory TaskStake({
    required String taskId,
    int? stakeAmountCents,            // null = no stake
    DateTime? stakeModificationDeadline, // null when no stake or not yet computed
    @Default(false) bool canModify,   // true when window is open
  }) = _TaskStake;
}
