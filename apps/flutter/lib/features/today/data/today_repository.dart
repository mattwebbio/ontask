import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../../tasks/data/task_dto.dart';
import '../../tasks/domain/task.dart';
import '../domain/day_health.dart';
import '../domain/overbooking_status.dart';
import '../domain/schedule_change.dart';
import 'calendar_event_dto.dart';
import 'day_health_dto.dart';
import 'overbooking_status_dto.dart';
import 'schedule_change_dto.dart';

part 'today_repository.g.dart';

/// Repository for Today tab data: today's tasks and schedule health.
///
/// All network calls go through [ApiClient] injected via Riverpod.
class TodayRepository {
  TodayRepository(this._client);
  final ApiClient _client;

  /// Fetches tasks for a specific date (defaults to today).
  ///
  /// Calls `GET /v1/tasks/today?date=<date>`.
  /// Returns tasks sorted by [dueDate] ascending.
  Future<List<Task>> getTodayTasks({String? date}) async {
    final queryParams = <String, dynamic>{};
    if (date != null) queryParams['date'] = date;
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/v1/tasks/today',
      queryParameters: queryParams,
    );
    final items = (response.data!['data'] as List)
        .map((e) => TaskDto.fromJson(e as Map<String, dynamic>).toDomain())
        .toList();
    return items;
  }

  /// Fetches schedule health for a week starting from [weekStartDate].
  ///
  /// Calls `GET /v1/tasks/schedule-health?weekStartDate=<date>`.
  /// Returns 7 [DayHealth] entries (Mon-Sun).
  Future<List<DayHealth>> getScheduleHealth(String weekStartDate) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/v1/tasks/schedule-health',
      queryParameters: {'weekStartDate': weekStartDate},
    );
    final days = (response.data!['data']['days'] as List)
        .map(
            (e) => DayHealthDto.fromJson(e as Map<String, dynamic>).toDomain())
        .toList();
    return days;
  }

  /// Fetches schedule change events since last user view.
  ///
  /// Calls `GET /v1/tasks/schedule-changes`.
  /// Returns a [ScheduleChanges] describing moved/removed tasks.
  Future<ScheduleChanges> getScheduleChanges() async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/v1/tasks/schedule-changes',
    );
    return ScheduleChangesDto.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    ).toDomain();
  }

  /// Fetches overbooking status for today.
  ///
  /// Calls `GET /v1/tasks/overbooking-status`.
  /// Returns an [OverbookingStatus] with severity and overloaded task list.
  Future<OverbookingStatus> getOverbookingStatus() async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/v1/tasks/overbooking-status',
    );
    return OverbookingStatusDto.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    ).toDomain();
  }

  /// Fetches calendar events for a time window (defaults to today).
  ///
  /// Calls `GET /v1/calendar/events?windowStart=<ISO>&windowEnd=<ISO>`.
  /// Returns a flat list of [CalendarEventDto] for use in the timeline view (AC6).
  /// Returns an empty list on failure — partial failure tolerant.
  Future<List<CalendarEventDto>> getCalendarEvents({
    DateTime? windowStart,
    DateTime? windowEnd,
  }) async {
    try {
      final now = DateTime.now();
      final start = windowStart ?? DateTime(now.year, now.month, now.day);
      final end = windowEnd ??
          DateTime(now.year, now.month, now.day, 23, 59, 59);

      final queryParams = <String, dynamic>{
        'windowStart': start.toUtc().toIso8601String(),
        'windowEnd': end.toUtc().toIso8601String(),
      };

      final response = await _client.dio.get<Map<String, dynamic>>(
        '/v1/calendar/events',
        queryParameters: queryParams,
      );

      final items = (response.data!['data'] as List)
          .map(
              (e) => CalendarEventDto.fromJson(e as Map<String, dynamic>))
          .toList();
      return items;
    } catch (_) {
      // Calendar events are optional — never crash the Today tab
      return [];
    }
  }
}

/// Riverpod provider for [TodayRepository].
@riverpod
TodayRepository todayRepository(Ref ref) {
  final client = ref.watch(apiClientProvider);
  return TodayRepository(client);
}
