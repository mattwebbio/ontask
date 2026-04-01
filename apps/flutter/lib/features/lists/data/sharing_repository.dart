import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../domain/list_member.dart';

part 'sharing_repository.g.dart';

/// Details returned when fetching an invitation by token.
class InvitationDetails {
  final String listTitle;
  final String inviterName;

  const InvitationDetails({
    required this.listTitle,
    required this.inviterName,
  });
}

/// Repository for list sharing and invitation operations via the sharing API.
///
/// Covers FR15 (share list by email) and FR16 (accept invitation, member list).
class SharingRepository {
  SharingRepository(this._client);
  final ApiClient _client;

  /// Sends an email invitation to join a list.
  ///
  /// Returns the created invitation details on success.
  Future<Map<String, dynamic>> shareList(String listId, String email) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/v1/lists/$listId/share',
      data: {'email': email},
    );
    return response.data!['data'] as Map<String, dynamic>;
  }

  /// Fetches invitation details for display on the accept screen.
  Future<InvitationDetails> getInvitationDetails(String token) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/v1/invitations/$token',
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return InvitationDetails(
      listTitle: data['listTitle'] as String,
      inviterName: data['inviterName'] as String,
    );
  }

  /// Accepts a list invitation by token, adding the current user as a member.
  Future<Map<String, dynamic>> acceptInvitation(String token) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/v1/invitations/$token/accept',
    );
    return response.data!['data'] as Map<String, dynamic>;
  }

  /// Declines a list invitation by token.
  Future<void> declineInvitation(String token) async {
    await _client.dio.post<void>('/v1/invitations/$token/decline');
  }

  /// Fetches all members of a shared list.
  Future<List<ListMember>> getListMembers(String listId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/v1/lists/$listId/members',
    );
    final items = response.data!['data'] as List;
    return items
        .map((e) => _memberFromJson(e as Map<String, dynamic>))
        .toList();
  }

  ListMember _memberFromJson(Map<String, dynamic> json) {
    return ListMember(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      avatarInitials: json['avatarInitials'] as String,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }
}

/// Riverpod provider for [SharingRepository].
@riverpod
SharingRepository sharingRepository(Ref ref) {
  final client = ref.watch(apiClientProvider);
  return SharingRepository(client);
}
