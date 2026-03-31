import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/templates_repository.dart';
import '../domain/template.dart';

part 'templates_provider.g.dart';

/// Notifier managing the user's template library.
///
/// Exposes load, create, apply, delete methods.
/// Returns `AsyncValue<List<Template>>`.
@riverpod
class TemplatesNotifier extends _$TemplatesNotifier {
  @override
  Future<List<Template>> build() async {
    final repo = ref.read(templatesRepositoryProvider);
    return repo.getTemplates();
  }

  /// Reloads templates from the API.
  Future<void> loadTemplates() async {
    final repo = ref.read(templatesRepositoryProvider);
    state = const AsyncLoading();
    state = AsyncData(await repo.getTemplates());
  }

  /// Creates a new template from a list or section and adds it to state.
  Future<Template> createTemplate({
    required String title,
    required String sourceType,
    required String sourceId,
  }) async {
    final repo = ref.read(templatesRepositoryProvider);
    final created = await repo.createTemplate(
      title: title,
      sourceType: sourceType,
      sourceId: sourceId,
    );

    final current = state.value ?? [];
    state = AsyncData([...current, created]);
    return created;
  }

  /// Applies a template, returning the raw response data.
  Future<Map<String, dynamic>> applyTemplate(
    String id, {
    String? targetListId,
    String? parentSectionId,
    int? dueDateOffsetDays,
  }) async {
    final repo = ref.read(templatesRepositoryProvider);
    return repo.applyTemplate(
      id,
      targetListId: targetListId,
      parentSectionId: parentSectionId,
      dueDateOffsetDays: dueDateOffsetDays,
    );
  }

  /// Deletes a template and removes it from state.
  Future<void> deleteTemplate(String id) async {
    final repo = ref.read(templatesRepositoryProvider);
    await repo.deleteTemplate(id);

    final current = state.value ?? [];
    state = AsyncData(current.where((t) => t.id != id).toList());
  }
}
