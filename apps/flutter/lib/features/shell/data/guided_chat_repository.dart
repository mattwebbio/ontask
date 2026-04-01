import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../domain/chat_message.dart';
import '../domain/guided_chat_response.dart';
import 'guided_chat_response_dto.dart';

part 'guided_chat_repository.g.dart';

/// Repository for Guided Chat task capture API calls (FR14 / UX-DR15).
///
/// Provides multi-turn conversational task capture by calling
/// `POST /v1/tasks/chat`. Uses [ApiClient] injected via Riverpod — never
/// constructs ApiClient directly.
///
/// Stateless — conversation history is managed by the caller ([GuidedChatSheet]).
///
/// This repository belongs in `features/shell/data/` because guided chat is
/// an input surface concern of the Add tab, not a task CRUD concern.
class GuidedChatRepository {
  GuidedChatRepository(this._client);
  final ApiClient _client;

  /// Performs a single guided chat turn.
  ///
  /// Calls `POST /v1/tasks/chat` with the full conversation history and
  /// returns a [GuidedChatResponse] with the LLM's next reply.
  ///
  /// When [GuidedChatResponse.isComplete] is true, [GuidedChatResponse.extractedTask]
  /// is populated and ready for task creation.
  ///
  /// Throws [DioException] on network errors or non-2xx responses.
  Future<GuidedChatResponse> sendMessage(List<ChatMessage> messages) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/v1/tasks/chat',
      data: {
        'messages': messages
            .map((m) => {'role': m.role, 'content': m.content})
            .toList(),
      },
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('No chat data in response');
    }
    return GuidedChatResponseDto.fromJson(data).toDomain();
  }
}

/// Riverpod provider for [GuidedChatRepository].
@riverpod
GuidedChatRepository guidedChatRepository(Ref ref) {
  final client = ref.watch(apiClientProvider);
  return GuidedChatRepository(client);
}
