import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shell_providers.g.dart';

/// Signal notifier: incrementing the counter tells [AppShell] to open the
/// Add tab sheet. Any widget (e.g. [TodayEmptyState] via [TodayScreen]) can
/// call `ref.read(openAddSheetRequestProvider.notifier).increment()` to
/// request the sheet without holding a direct callback reference.
///
/// [AppShell] listens to this provider and responds to counter increments by
/// calling [showModalBottomSheet] for [AddTabSheet].
@riverpod
class OpenAddSheetRequest extends _$OpenAddSheetRequest {
  @override
  int build() => 0;

  void increment() => state++;
}
