import 'package:freezed_annotation/freezed_annotation.dart';
import '../domain/list_invitation.dart';

part 'list_invitation_dto.freezed.dart';
part 'list_invitation_dto.g.dart';

/// Data transfer object for the `/v1/invitations/:token` API response.
@freezed
abstract class ListInvitationDto with _$ListInvitationDto {
  const ListInvitationDto._();

  const factory ListInvitationDto({
    required String invitationId,
    required String listId,
    required String listTitle,
    required String invitedByName,
    required String inviteeEmail,
    required String status,
    required String expiresAt,
  }) = _ListInvitationDto;

  factory ListInvitationDto.fromJson(Map<String, dynamic> json) =>
      _$ListInvitationDtoFromJson(json);

  /// Converts this DTO to a [ListInvitation] domain model.
  ListInvitation toDomain() => ListInvitation(
        invitationId: invitationId,
        listId: listId,
        listTitle: listTitle,
        invitedByName: invitedByName,
        inviteeEmail: inviteeEmail,
        status: status,
        expiresAt: DateTime.parse(expiresAt),
      );
}
