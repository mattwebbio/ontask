import 'package:freezed_annotation/freezed_annotation.dart';
import '../domain/list_member.dart';

part 'list_member_dto.freezed.dart';
part 'list_member_dto.g.dart';

/// Data transfer object for the `/v1/lists/:id/members` API response item.
@freezed
abstract class ListMemberDto with _$ListMemberDto {
  const ListMemberDto._();

  const factory ListMemberDto({
    required String userId,
    required String displayName,
    required String avatarInitials,
    required String role,
    required String joinedAt,
    @JsonKey(defaultValue: 0) @Default(0) int roundRobinIndex,
  }) = _ListMemberDto;

  factory ListMemberDto.fromJson(Map<String, dynamic> json) =>
      _$ListMemberDtoFromJson(json);

  /// Converts this DTO to a [ListMember] domain model.
  ListMember toDomain() => ListMember(
        userId: userId,
        displayName: displayName,
        avatarInitials: avatarInitials,
        role: role,
        joinedAt: DateTime.parse(joinedAt),
        roundRobinIndex: roundRobinIndex,
      );
}
