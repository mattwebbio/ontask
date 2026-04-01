import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendar_event_dto.freezed.dart';
part 'calendar_event_dto.g.dart';

/// Data transfer object for a calendar event from the API.
///
/// Maps the JSON response from `GET /v1/calendar/events` to a typed object
/// for use in the Today tab timeline view.
@freezed
abstract class CalendarEventDto with _$CalendarEventDto {
  const CalendarEventDto._();

  const factory CalendarEventDto({
    required String id,
    required String startTime,
    required String endTime,
    required bool isAllDay,
    String? summary,
  }) = _CalendarEventDto;

  factory CalendarEventDto.fromJson(Map<String, dynamic> json) =>
      _$CalendarEventDtoFromJson(json);

  /// Parsed start time as [DateTime].
  DateTime get startDateTime => DateTime.parse(startTime);

  /// Parsed end time as [DateTime].
  DateTime get endDateTime => DateTime.parse(endTime);
}
