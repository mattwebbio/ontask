import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_stake.freezed.dart';

/// Domain model for the stake amount on a specific task.
///
/// Used by [StakeSliderWidget] and [StakeSheetScreen] to carry stake state.
/// A null [stakeAmountCents] means no stake is set on the task.
/// Stake is stored as integer cents to avoid floating-point issues (e.g., 2500 = $25.00).
@freezed
abstract class TaskStake with _$TaskStake {
  const factory TaskStake({
    required String taskId,
    int? stakeAmountCents, // null = no stake
  }) = _TaskStake;
}
