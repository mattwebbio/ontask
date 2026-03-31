import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/today_repository.dart';
import '../domain/overbooking_status.dart';

part 'overbooking_provider.g.dart';

/// Fetches the overbooking status from the API.
@riverpod
Future<OverbookingStatus> overbookingStatus(Ref ref) {
  final repo = ref.watch(todayRepositoryProvider);
  return repo.getOverbookingStatus();
}

/// Manages whether the Overbooking Warning Banner has been dismissed.
///
/// Default [false] — banner is visible (if overbooked). Calling [dismiss]
/// hides the banner for the current session.
@riverpod
class OverbookingBannerDismissed extends _$OverbookingBannerDismissed {
  @override
  bool build() => false;

  /// Dismisses the overbooking banner for the current session.
  void dismiss() {
    state = true;
  }
}
