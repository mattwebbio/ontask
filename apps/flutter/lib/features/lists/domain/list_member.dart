import 'package:freezed_annotation/freezed_annotation.dart';

part 'list_member.freezed.dart';

/// A member of a shared list (FR15, FR16).
///
/// Maps to the `list_members` table and the `/v1/lists/:id/members` API response.
@freezed
abstract class ListMember with _$ListMember {
  const factory ListMember({
    required String userId,
    required String displayName,
    required String avatarInitials,
    required String role, // 'owner' | 'member'
    required DateTime joinedAt,
  }) = _ListMember;
}
