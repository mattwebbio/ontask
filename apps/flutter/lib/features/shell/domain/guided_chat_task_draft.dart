import 'package:freezed_annotation/freezed_annotation.dart';

part 'guided_chat_task_draft.freezed.dart';

/// Domain model for the partially or fully resolved task draft during guided chat.
///
/// All fields are optional — they are progressively populated as the conversation
/// advances. When [GuidedChatResponse.isComplete] is true, this object holds
/// the full task to be created (FR14 / UX-DR15).
@freezed
abstract class GuidedChatTaskDraft with _$GuidedChatTaskDraft {
  const factory GuidedChatTaskDraft({
    /// The resolved task title, if collected.
    String? title,

    /// Resolved due date as ISO 8601 string, if mentioned.
    String? dueDate,

    /// Resolved scheduled time as ISO 8601 string, if mentioned.
    String? scheduledTime,

    /// Estimated duration in minutes, if mentioned.
    int? estimatedDurationMinutes,

    /// Energy requirement (high_focus / low_energy / flexible), if inferred.
    String? energyRequirement,

    /// Matched list ID from the user's lists, if mentioned.
    String? listId,
  }) = _GuidedChatTaskDraft;
}
