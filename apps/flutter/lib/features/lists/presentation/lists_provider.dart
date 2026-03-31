import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/lists_repository.dart';
import '../domain/task_list.dart';

part 'lists_provider.g.dart';

/// Notifier managing all user lists.
///
/// Exposes create, update, archive methods.
/// Returns `AsyncValue<List<TaskList>>`.
@riverpod
class ListsNotifier extends _$ListsNotifier {
  @override
  Future<List<TaskList>> build() async {
    final repo = ref.read(listsRepositoryProvider);
    return repo.getLists();
  }

  /// Creates a new list and adds it to state.
  Future<TaskList> createList({
    required String title,
    String? defaultDueDate,
  }) async {
    final repo = ref.read(listsRepositoryProvider);
    final created = await repo.createList(
      title: title,
      defaultDueDate: defaultDueDate,
    );

    final current = state.value ?? [];
    state = AsyncData([...current, created]);
    return created;
  }

  /// Updates list properties.
  Future<void> updateList(String id, Map<String, dynamic> fields) async {
    final repo = ref.read(listsRepositoryProvider);
    final updated = await repo.updateList(id, fields);

    final current = state.value ?? [];
    state = AsyncData(
      current.map((l) => l.id == id ? updated : l).toList(),
    );
  }

  /// Archives a list (soft delete).
  Future<void> archiveList(String id) async {
    final repo = ref.read(listsRepositoryProvider);
    await repo.archiveList(id);

    final current = state.value ?? [];
    state = AsyncData(current.where((l) => l.id != id).toList());
  }
}
