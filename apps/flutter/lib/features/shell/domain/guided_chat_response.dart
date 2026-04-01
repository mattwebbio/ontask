import 'package:freezed_annotation/freezed_annotation.dart';

import 'guided_chat_task_draft.dart';

part 'guided_chat_response.freezed.dart';

/// Domain model for a single guided chat turn response.
///
/// Returned by [GuidedChatRepository.sendMessage] after calling
/// `POST /v1/tasks/chat` (FR14 / UX-DR15).
///
/// When [isComplete] is true, [extractedTask] holds the full task draft
/// ready to be submitted via [TasksNotifier.createTask].
@freezed
abstract class GuidedChatResponse with _$GuidedChatResponse {
  const factory GuidedChatResponse({
    /// The LLM's next conversational message to display to the user.
    required String reply,

    /// True when the LLM has collected enough information to create the task.
    required bool isComplete,

    /// The partially or fully resolved task draft. Populated when [isComplete]
    /// is true.
    GuidedChatTaskDraft? extractedTask,
  }) = _GuidedChatResponse;
}
