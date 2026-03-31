import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/today_repository.dart';
import '../domain/day_health.dart';

part 'schedule_health_provider.g.dart';

/// AsyncNotifier that loads the weekly schedule health data.
///
/// Calculates the current week's Monday and loads 7-day health
/// from [TodayRepository.getScheduleHealth].
@riverpod
class ScheduleHealth extends _$ScheduleHealth {
  @override
  Future<List<DayHealth>> build() async {
    final repo = ref.read(todayRepositoryProvider);
    final monday = _currentWeekMonday();
    final mondayStr =
        '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
    return repo.getScheduleHealth(mondayStr);
  }

  /// Returns the Monday of the current week (ISO week starts on Monday).
  DateTime _currentWeekMonday() {
    final now = DateTime.now();
    // DateTime.weekday: Monday=1, Sunday=7
    final daysFromMonday = now.weekday - 1;
    return DateTime(now.year, now.month, now.day).subtract(Duration(days: daysFromMonday));
  }
}
