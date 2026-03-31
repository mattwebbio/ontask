import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/sections_repository.dart';
import '../domain/section.dart';

part 'sections_provider.g.dart';

/// Notifier managing sections for a given list.
///
/// Exposes create, update, delete methods.
@riverpod
class SectionsNotifier extends _$SectionsNotifier {
  @override
  Future<List<Section>> build(String listId) async {
    final repo = ref.read(sectionsRepositoryProvider);
    return repo.getSections(listId);
  }

  /// Creates a new section.
  Future<Section> createSection({
    required String title,
    required String listId,
    String? parentSectionId,
    String? defaultDueDate,
  }) async {
    final repo = ref.read(sectionsRepositoryProvider);
    final created = await repo.createSection(
      title: title,
      listId: listId,
      parentSectionId: parentSectionId,
      defaultDueDate: defaultDueDate,
    );

    final current = state.value ?? [];
    state = AsyncData([...current, created]);
    return created;
  }

  /// Updates section properties.
  Future<void> updateSection(String id, Map<String, dynamic> fields) async {
    final repo = ref.read(sectionsRepositoryProvider);
    final updated = await repo.updateSection(id, fields);

    final current = state.value ?? [];
    state = AsyncData(
      current.map((s) => s.id == id ? updated : s).toList(),
    );
  }

  /// Deletes a section.
  Future<void> deleteSection(String id) async {
    final repo = ref.read(sectionsRepositoryProvider);
    await repo.deleteSection(id);

    final current = state.value ?? [];
    state = AsyncData(current.where((s) => s.id != id).toList());
  }
}
