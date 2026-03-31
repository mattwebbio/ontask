import 'package:freezed_annotation/freezed_annotation.dart';

part 'template.freezed.dart';

/// Template domain model — a reusable snapshot of a list or section structure.
///
/// Maps to the `templates` table and the `/v1/templates` API response.
/// When loaded as a summary (e.g. from GET /v1/templates), [templateData]
/// will be null. Full template data is only fetched via GET /v1/templates/:id.
@freezed
abstract class Template with _$Template {
  const factory Template({
    required String id,
    required String userId,
    required String title,
    required String sourceType,
    String? templateData,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _Template;
}
