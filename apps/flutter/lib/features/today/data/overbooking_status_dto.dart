import 'package:freezed_annotation/freezed_annotation.dart';

import '../domain/overbooking_status.dart';

part 'overbooking_status_dto.freezed.dart';
part 'overbooking_status_dto.g.dart';

/// DTO for a single overbooked task from the API.
@freezed
abstract class OverbookedTaskDto with _$OverbookedTaskDto {
  const OverbookedTaskDto._();

  const factory OverbookedTaskDto({
    required String taskId,
    required String taskTitle,
    required bool hasStake,
    required int durationMinutes,
  }) = _OverbookedTaskDto;

  factory OverbookedTaskDto.fromJson(Map<String, dynamic> json) =>
      _$OverbookedTaskDtoFromJson(json);

  /// Converts this DTO to an [OverbookedTask] domain model.
  OverbookedTask toDomain() => OverbookedTask(
        taskId: taskId,
        taskTitle: taskTitle,
        hasStake: hasStake,
        durationMinutes: durationMinutes,
      );
}

/// DTO for the overbooking status response from the API.
@freezed
abstract class OverbookingStatusDto with _$OverbookingStatusDto {
  const OverbookingStatusDto._();

  const factory OverbookingStatusDto({
    required bool isOverbooked,
    required String severity,
    required double capacityPercent,
    required List<OverbookedTaskDto> overbookedTasks,
  }) = _OverbookingStatusDto;

  factory OverbookingStatusDto.fromJson(Map<String, dynamic> json) =>
      _$OverbookingStatusDtoFromJson(json);

  /// Converts this DTO to an [OverbookingStatus] domain model.
  OverbookingStatus toDomain() => OverbookingStatus(
        isOverbooked: isOverbooked,
        severity: _parseSeverity(severity),
        capacityPercent: capacityPercent,
        overbookedTasks: overbookedTasks.map((e) => e.toDomain()).toList(),
      );

  static OverbookingSeverity _parseSeverity(String value) {
    switch (value) {
      case 'at_risk':
        return OverbookingSeverity.atRisk;
      case 'critical':
        return OverbookingSeverity.critical;
      default:
        return OverbookingSeverity.none;
    }
  }
}
