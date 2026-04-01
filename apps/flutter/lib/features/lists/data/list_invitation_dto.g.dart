// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_invitation_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ListInvitationDto _$ListInvitationDtoFromJson(Map<String, dynamic> json) =>
    _ListInvitationDto(
      invitationId: json['invitationId'] as String,
      listId: json['listId'] as String,
      listTitle: json['listTitle'] as String,
      invitedByName: json['invitedByName'] as String,
      inviteeEmail: json['inviteeEmail'] as String,
      status: json['status'] as String,
      expiresAt: json['expiresAt'] as String,
    );

Map<String, dynamic> _$ListInvitationDtoToJson(_ListInvitationDto instance) =>
    <String, dynamic>{
      'invitationId': instance.invitationId,
      'listId': instance.listId,
      'listTitle': instance.listTitle,
      'invitedByName': instance.invitedByName,
      'inviteeEmail': instance.inviteeEmail,
      'status': instance.status,
      'expiresAt': instance.expiresAt,
    };
