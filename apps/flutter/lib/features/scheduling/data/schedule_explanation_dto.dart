import 'package:freezed_annotation/freezed_annotation.dart';

import '../domain/schedule_explanation.dart';

part 'schedule_explanation_dto.freezed.dart';
part 'schedule_explanation_dto.g.dart';

/// Data transfer object for the scheduling explanation returned by
/// `GET /v1/tasks/:id/schedule`.
///
/// Maps the `explanation` sub-object in the API response to the
/// [ScheduleExplanation] domain model via [toDomain].
@freezed
abstract class ScheduleExplanationDto with _$ScheduleExplanationDto {
  const ScheduleExplanationDto._();

  const factory ScheduleExplanationDto({
    required List<String> reasons,
  }) = _ScheduleExplanationDto;

  factory ScheduleExplanationDto.fromJson(Map<String, dynamic> json) =>
      _$ScheduleExplanationDtoFromJson(json);

  /// Converts this DTO to a [ScheduleExplanation] domain model.
  ScheduleExplanation toDomain() => ScheduleExplanation(reasons: reasons);
}
