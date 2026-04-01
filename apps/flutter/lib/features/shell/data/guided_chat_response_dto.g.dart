// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guided_chat_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GuidedChatResponseDto _$GuidedChatResponseDtoFromJson(
  Map<String, dynamic> json,
) => _GuidedChatResponseDto(
  reply: json['reply'] as String,
  isComplete: json['isComplete'] as bool,
  extractedTask: json['extractedTask'] == null
      ? null
      : GuidedChatTaskDraftDto.fromJson(
          json['extractedTask'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$GuidedChatResponseDtoToJson(
  _GuidedChatResponseDto instance,
) => <String, dynamic>{
  'reply': instance.reply,
  'isComplete': instance.isComplete,
  'extractedTask': instance.extractedTask,
};
