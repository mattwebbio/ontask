import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/scheduling_repository.dart';
import '../domain/schedule_explanation.dart';

part 'schedule_explanation_provider.g.dart';

/// Provider that fetches the scheduling explanation for a given task.
///
/// Calls [SchedulingRepository.getScheduleExplanation] for the given [taskId].
/// Auto-disposes when the widget is removed — per-entity providers should not
/// be kept alive.
@riverpod
Future<ScheduleExplanation> scheduleExplanation(Ref ref, String taskId) {
  return ref.watch(schedulingRepositoryProvider).getScheduleExplanation(taskId);
}
