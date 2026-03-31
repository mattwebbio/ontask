import 'package:freezed_annotation/freezed_annotation.dart';

import '../domain/now_task.dart';
import '../domain/proof_mode.dart';

part 'now_task_dto.freezed.dart';
part 'now_task_dto.g.dart';

/// Data transfer object for the `GET /v1/tasks/current` API response.
///
/// Handles JSON serialisation and maps to the [NowTask] domain model via [toDomain].
@freezed
abstract class NowTaskDto with _$NowTaskDto {
  const NowTaskDto._();

  const factory NowTaskDto({
    required String id,
    required String title,
    String? notes,
    String? dueDate,
    String? listId,
    String? listName,
    String? assignorName,
    int? stakeAmountCents,
    String? proofMode,
    String? completedAt,
    required String createdAt,
    required String updatedAt,
  }) = _NowTaskDto;

  factory NowTaskDto.fromJson(Map<String, dynamic> json) =>
      _$NowTaskDtoFromJson(json);

  /// Converts this DTO to a [NowTask] domain model.
  NowTask toDomain() => NowTask(
        id: id,
        title: title,
        notes: notes,
        dueDate: dueDate != null ? DateTime.parse(dueDate!) : null,
        listId: listId,
        listName: listName,
        assignorName: assignorName,
        stakeAmountCents: stakeAmountCents,
        proofMode: ProofMode.fromJson(proofMode),
        completedAt: completedAt != null ? DateTime.parse(completedAt!) : null,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );
}
