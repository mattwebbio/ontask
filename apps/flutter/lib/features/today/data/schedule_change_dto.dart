import 'package:freezed_annotation/freezed_annotation.dart';

import '../domain/schedule_change.dart';

part 'schedule_change_dto.freezed.dart';
part 'schedule_change_dto.g.dart';

/// DTO for a single schedule change item from the API.
@freezed
abstract class ScheduleChangeItemDto with _$ScheduleChangeItemDto {
  const ScheduleChangeItemDto._();

  const factory ScheduleChangeItemDto({
    required String taskId,
    required String taskTitle,
    required String changeType,
    required String? oldTime,
    required String? newTime,
  }) = _ScheduleChangeItemDto;

  factory ScheduleChangeItemDto.fromJson(Map<String, dynamic> json) =>
      _$ScheduleChangeItemDtoFromJson(json);

  /// Converts this DTO to a [ScheduleChangeItem] domain model.
  ScheduleChangeItem toDomain() => ScheduleChangeItem(
        taskId: taskId,
        taskTitle: taskTitle,
        changeType: changeType == 'removed'
            ? ScheduleChangeType.removed
            : ScheduleChangeType.moved,
        oldTime: oldTime != null ? DateTime.tryParse(oldTime!) : null,
        newTime: newTime != null ? DateTime.tryParse(newTime!) : null,
      );
}

/// DTO for the full schedule changes response from the API.
@freezed
abstract class ScheduleChangesDto with _$ScheduleChangesDto {
  const ScheduleChangesDto._();

  const factory ScheduleChangesDto({
    required bool hasMeaningfulChanges,
    required int changeCount,
    required List<ScheduleChangeItemDto> changes,
  }) = _ScheduleChangesDto;

  factory ScheduleChangesDto.fromJson(Map<String, dynamic> json) =>
      _$ScheduleChangesDtoFromJson(json);

  /// Converts this DTO to a [ScheduleChanges] domain model.
  ScheduleChanges toDomain() => ScheduleChanges(
        hasMeaningfulChanges: hasMeaningfulChanges,
        changeCount: changeCount,
        changes: changes.map((e) => e.toDomain()).toList(),
      );
}
