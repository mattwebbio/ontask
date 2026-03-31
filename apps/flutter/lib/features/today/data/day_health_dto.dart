import 'package:freezed_annotation/freezed_annotation.dart';

import '../domain/day_health.dart';
import '../domain/day_health_status.dart';

part 'day_health_dto.freezed.dart';
part 'day_health_dto.g.dart';

/// Data transfer object for a single day's schedule health from the API.
///
/// Maps the JSON response from `GET /v1/tasks/schedule-health` to the
/// [DayHealth] domain model via [toDomain].
@freezed
abstract class DayHealthDto with _$DayHealthDto {
  const DayHealthDto._();

  const factory DayHealthDto({
    required String date,
    required String status,
    required int taskCount,
    required double capacityPercent,
    required List<String> atRiskTaskIds,
  }) = _DayHealthDto;

  factory DayHealthDto.fromJson(Map<String, dynamic> json) =>
      _$DayHealthDtoFromJson(json);

  /// Converts this DTO to a [DayHealth] domain model.
  DayHealth toDomain() => DayHealth(
        date: DateTime.parse(date),
        status: DayHealthStatus.fromJson(status),
        taskCount: taskCount,
        capacityPercent: capacityPercent,
        atRiskTaskIds: atRiskTaskIds,
      );
}
