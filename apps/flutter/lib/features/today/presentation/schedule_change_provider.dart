import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/today_repository.dart';
import '../domain/schedule_change.dart';

part 'schedule_change_provider.g.dart';

/// Fetches the schedule changes from the API.
@riverpod
Future<ScheduleChanges> scheduleChanges(Ref ref) {
  final repo = ref.watch(todayRepositoryProvider);
  return repo.getScheduleChanges();
}

/// Manages visibility of the Schedule Change Banner.
///
/// Starts as loading, then resolves to [true] if there are meaningful changes.
/// Calling [dismiss] hides the banner for the current session.
@riverpod
class ScheduleChangeBannerVisible extends _$ScheduleChangeBannerVisible {
  @override
  Future<bool> build() async {
    final changes = await ref.watch(scheduleChangesProvider.future);
    return changes.hasMeaningfulChanges;
  }

  /// Dismisses the banner for the current session.
  void dismiss() {
    state = const AsyncData(false);
  }
}
