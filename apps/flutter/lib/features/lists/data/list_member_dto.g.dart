// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_member_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ListMemberDto _$ListMemberDtoFromJson(Map<String, dynamic> json) =>
    _ListMemberDto(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      avatarInitials: json['avatarInitials'] as String,
      role: json['role'] as String,
      joinedAt: json['joinedAt'] as String,
    );

Map<String, dynamic> _$ListMemberDtoToJson(_ListMemberDto instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'displayName': instance.displayName,
      'avatarInitials': instance.avatarInitials,
      'role': instance.role,
      'joinedAt': instance.joinedAt,
    };
