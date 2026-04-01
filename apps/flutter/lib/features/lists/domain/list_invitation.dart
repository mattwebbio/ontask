import 'package:freezed_annotation/freezed_annotation.dart';

part 'list_invitation.freezed.dart';

/// Domain model for a list invitation (FR15, FR16).
///
/// Represents a pending/accepted/declined invitation to join a shared list.
@freezed
abstract class ListInvitation with _$ListInvitation {
  const factory ListInvitation({
    required String invitationId,
    required String listId,
    required String listTitle,
    required String invitedByName,
    required String inviteeEmail,
    required String status, // 'pending' | 'accepted' | 'declined'
    required DateTime expiresAt,
  }) = _ListInvitation;
}
