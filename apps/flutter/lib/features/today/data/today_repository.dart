import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../../tasks/data/task_dto.dart';
import '../../tasks/domain/task.dart';
import '../domain/day_health.dart';
import 'day_health_dto.dart';

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
}

/// Riverpod provider for [TodayRepository].
@riverpod
TodayRepository todayRepository(Ref ref) {
  final client = ref.watch(apiClientProvider);
  return TodayRepository(client);
}
