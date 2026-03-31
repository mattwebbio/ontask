import 'package:freezed_annotation/freezed_annotation.dart';

import 'proof_mode.dart';

part 'now_task.freezed.dart';

/// Enriched task model for the Now tab hero card.
///
/// Extends the standard task fields with Now-specific data resolved server-side:
/// [listName], [assignorName], [stakeAmountCents], and [proofMode].
///
/// Kept flat — does NOT embed a [Task] object.
@freezed
abstract class NowTask with _$NowTask {
  const factory NowTask({
    required String id,
    required String title,
    String? notes,
    DateTime? dueDate,
    String? listId,
    String? listName,
    String? assignorName,
    int? stakeAmountCents,
    @Default(ProofMode.standard) ProofMode proofMode,
    DateTime? startedAt,
    int? elapsedSeconds,
    DateTime? completedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _NowTask;
}
