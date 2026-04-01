import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_client.dart';
import '../domain/section.dart';
import 'section_dto.dart';

part 'sections_repository.g.dart';

/// Repository for section CRUD operations via the `/v1/sections` API.
class SectionsRepository {
  SectionsRepository(this._client);
  final ApiClient _client;

  /// Creates a new section within a list.
  Future<Section> createSection({
    required String title,
    required String listId,
    String? parentSectionId,
    String? defaultDueDate,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/v1/sections',
      data: {
        'title': title,
        'listId': listId,
        if (parentSectionId != null) 'parentSectionId': parentSectionId,
        if (defaultDueDate != null) 'defaultDueDate': defaultDueDate,
      },
    );
    return SectionDto.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    ).toDomain();
  }

  /// Fetches sections for a given list.
  Future<List<Section>> getSections(String listId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/v1/sections',
      queryParameters: {'listId': listId},
    );
    final items = (response.data!['data'] as List)
        .map((e) => SectionDto.fromJson(e as Map<String, dynamic>).toDomain())
        .toList();
    return items;
  }

  /// Updates section properties.
  Future<Section> updateSection(
      String id, Map<String, dynamic> fields) async {
    final response = await _client.dio.patch<Map<String, dynamic>>(
      '/v1/sections/$id',
      data: fields,
    );
    return SectionDto.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    ).toDomain();
  }

  /// Deletes a section (cascades to tasks).
  Future<void> deleteSection(String id) async {
    await _client.dio.delete('/v1/sections/$id');
  }

  /// Updates the proof requirement for a section (PATCH /v1/sections/{id}/accountability).
  ///
  /// Pass [proofRequirement] as `'none'`, `'photo'`, `'watchMode'`, `'healthKit'`, or `null` to
  /// remove (tasks will inherit from the parent list).
  /// In production, cascades to tasks in this section where proofModeIsCustom = false.
  Future<Section> updateSectionAccountability(String sectionId, String? proofRequirement) async {
    final response = await _client.dio.patch<Map<String, dynamic>>(
      '/v1/sections/$sectionId/accountability',
      data: {'proofRequirement': proofRequirement},
    );
    return SectionDto.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    ).toDomain();
  }
}

/// Riverpod provider for [SectionsRepository].
@riverpod
SectionsRepository sectionsRepository(Ref ref) {
  final client = ref.watch(apiClientProvider);
  return SectionsRepository(client);
}
