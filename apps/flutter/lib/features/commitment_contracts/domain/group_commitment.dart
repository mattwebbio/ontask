import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_commitment.freezed.dart';

/// Represents one member's state within a group commitment.
@freezed
abstract class GroupCommitmentMember with _$GroupCommitmentMember {
  const factory GroupCommitmentMember({
    required String userId,
    int? stakeAmountCents,
    @Default(false) bool approved,
    @Default(false) bool poolModeOptIn,
  }) = _GroupCommitmentMember;
}

/// Represents a group commitment arrangement for a shared list task (FR29, FR30).
///
/// Status lifecycle: pending → active → (charged or cancelled)
/// Pool mode is tracked per-member — not inherited from approval.
@freezed
abstract class GroupCommitment with _$GroupCommitment {
  const factory GroupCommitment({
    required String id,
    required String listId,
    required String taskId,
    required String proposedByUserId,
    required String status, // 'pending' | 'active' | 'cancelled'
    @Default(<GroupCommitmentMember>[]) List<GroupCommitmentMember> members,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _GroupCommitment;

  const GroupCommitment._();

  /// Returns true when all members have explicitly approved.
  bool get isActive => status == 'active';

  /// Returns true when the commitment is awaiting member approvals.
  bool get isPending => status == 'pending';
}
