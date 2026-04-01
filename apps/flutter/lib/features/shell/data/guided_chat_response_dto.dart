import 'package:freezed_annotation/freezed_annotation.dart';

import '../domain/guided_chat_response.dart';
import 'guided_chat_task_draft_dto.dart';

part 'guided_chat_response_dto.freezed.dart';
part 'guided_chat_response_dto.g.dart';

/// Data transfer object for the guided chat response returned by
/// `POST /v1/tasks/chat` (FR14 / UX-DR15).
///
/// The API response wraps this in a `{ data: ... }` envelope.
/// Maps to the [GuidedChatResponse] domain model via [toDomain].
@freezed
abstract class GuidedChatResponseDto with _$GuidedChatResponseDto {
  const GuidedChatResponseDto._();

  const factory GuidedChatResponseDto({
    required String reply,
    required bool isComplete,
    GuidedChatTaskDraftDto? extractedTask,
  }) = _GuidedChatResponseDto;

  factory GuidedChatResponseDto.fromJson(Map<String, dynamic> json) =>
      _$GuidedChatResponseDtoFromJson(json);

  /// Converts this DTO to a [GuidedChatResponse] domain model.
  GuidedChatResponse toDomain() => GuidedChatResponse(
        reply: reply,
        isComplete: isComplete,
        extractedTask: extractedTask?.toDomain(),
      );
}
