/// Plain value type representing a single message in a guided chat conversation.
///
/// Used by [GuidedChatRepository.sendMessage] and [GuidedChatSheet].
/// Not freezed — simple class with final fields; no JSON serialization needed
/// as it maps directly to the API request body structure.
class ChatMessage {
  const ChatMessage({required this.role, required this.content});

  /// Role of the message sender: 'user' or 'assistant'.
  final String role;

  /// Text content of the message.
  final String content;
}
