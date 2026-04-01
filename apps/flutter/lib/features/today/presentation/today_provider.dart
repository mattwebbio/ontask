import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../tasks/data/tasks_repository.dart';
import '../../tasks/domain/task.dart';
import '../data/calendar_event_dto.dart';
import '../data/today_repository.dart';

part 'today_provider.g.dart';

/// AsyncNotifier that manages the list of tasks for the Today tab.
///
/// Loads tasks via [TodayRepository.getTodayTasks] and supports
/// completing and rescheduling tasks in-place.
@riverpod
class Today extends _$Today {
  @override
  Future<List<Task>> build() async {
    final repo = ref.read(todayRepositoryProvider);
    return repo.getTodayTasks();
  }

  /// Completes a task and removes it from the today list.
  Future<void> completeTask(String taskId) async {
    final tasksRepo = ref.read(tasksRepositoryProvider);
    await tasksRepo.completeTask(taskId);
    final current = state.value ?? [];
    state = AsyncData(current.where((t) => t.id != taskId).toList());
  }

  /// Reschedules a task to [newDate] and removes it from today's list.
  Future<void> rescheduleTask(String taskId, String newDate) async {
    final tasksRepo = ref.read(tasksRepositoryProvider);
    await tasksRepo.updateTask(taskId, {'dueDate': newDate});
    final current = state.value ?? [];
    state = AsyncData(current.where((t) => t.id != taskId).toList());
  }

  /// Re-fetches today's tasks from the server.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(todayRepositoryProvider);
      return repo.getTodayTasks();
    });
  }
}

/// AsyncNotifier for calendar events displayed in the Today tab timeline.
///
/// Loads events via [TodayRepository.getCalendarEvents] for today's window.
/// Returns an empty list on failure — calendar events are optional; they
/// must never cause the Today tab to fail to load.
@riverpod
class TodayCalendarEvents extends _$TodayCalendarEvents {
  @override
  Future<List<CalendarEventDto>> build() async {
    final repo = ref.read(todayRepositoryProvider);
    return repo.getCalendarEvents();
  }

  /// Re-fetches calendar events from the server.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(todayRepositoryProvider);
      return repo.getCalendarEvents();
    });
  }
}
