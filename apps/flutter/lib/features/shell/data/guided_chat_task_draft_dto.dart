import 'package:freezed_annotation/freezed_annotation.dart';

import '../domain/guided_chat_task_draft.dart';

part 'guided_chat_task_draft_dto.freezed.dart';
part 'guided_chat_task_draft_dto.g.dart';

/// Data transfer object for the task draft returned inside a guided chat response.
///
/// Maps to the [GuidedChatTaskDraft] domain model via [toDomain].
@freezed
abstract class GuidedChatTaskDraftDto with _$GuidedChatTaskDraftDto {
  const GuidedChatTaskDraftDto._();

  const factory GuidedChatTaskDraftDto({
    String? title,
    String? dueDate,
    String? scheduledTime,
    int? estimatedDurationMinutes,
    String? energyRequirement,
    String? listId,
  }) = _GuidedChatTaskDraftDto;

  factory GuidedChatTaskDraftDto.fromJson(Map<String, dynamic> json) =>
      _$GuidedChatTaskDraftDtoFromJson(json);

  /// Converts this DTO to a [GuidedChatTaskDraft] domain model.
  GuidedChatTaskDraft toDomain() => GuidedChatTaskDraft(
        title: title,
        dueDate: dueDate,
        scheduledTime: scheduledTime,
        estimatedDurationMinutes: estimatedDurationMinutes,
        energyRequirement: energyRequirement,
        listId: listId,
      );
}
