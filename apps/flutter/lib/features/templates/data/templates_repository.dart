import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../domain/template.dart';
import 'template_dto.dart';

part 'templates_repository.g.dart';

/// Repository for template CRUD operations via the `/v1/templates` API.
class TemplatesRepository {
  TemplatesRepository(this._client);
  final ApiClient _client;

  /// Fetches all templates for the current user (summaries only).
  Future<List<Template>> getTemplates() async {
    final response =
        await _client.dio.get<Map<String, dynamic>>('/v1/templates');
    final items = (response.data!['data'] as List)
        .map((e) => TemplateDto.fromJson(e as Map<String, dynamic>).toDomain())
        .toList();
    return items;
  }

  /// Fetches a single template by ID (includes full templateData).
  Future<Template> getTemplate(String id) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/v1/templates/$id',
    );
    return TemplateDto.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    ).toDomain();
  }

  /// Creates a template from a list or section.
  Future<Template> createTemplate({
    required String title,
    required String sourceType,
    required String sourceId,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/v1/templates',
      data: {
        'title': title,
        'sourceType': sourceType,
        'sourceId': sourceId,
      },
    );
    return TemplateDto.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    ).toDomain();
  }

  /// Applies a template, creating new lists/sections/tasks.
  ///
  /// Returns the raw response data map containing `list`, `sections`, and `tasks`.
  Future<Map<String, dynamic>> applyTemplate(
    String id, {
    String? targetListId,
    String? parentSectionId,
    int? dueDateOffsetDays,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/v1/templates/$id/apply',
      data: {
        if (targetListId != null) 'targetListId': targetListId,
        if (parentSectionId != null) 'parentSectionId': parentSectionId,
        if (dueDateOffsetDays != null) 'dueDateOffsetDays': dueDateOffsetDays,
      },
    );
    return response.data!['data'] as Map<String, dynamic>;
  }

  /// Deletes a template.
  Future<void> deleteTemplate(String id) async {
    await _client.dio.delete('/v1/templates/$id');
  }
}

/// Riverpod provider for [TemplatesRepository].
@riverpod
TemplatesRepository templatesRepository(Ref ref) {
  final client = ref.watch(apiClientProvider);
  return TemplatesRepository(client);
}
