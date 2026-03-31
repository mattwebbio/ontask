import 'package:freezed_annotation/freezed_annotation.dart';

part 'section.freezed.dart';

/// Section domain model — organisational grouping within a list.
///
/// Supports infinite nesting via [parentSectionId] self-reference.
/// Maps to the `sections` table and the `/v1/sections` API response.
@freezed
abstract class Section with _$Section {
  const factory Section({
    required String id,
    required String listId,
    String? parentSectionId,
    required String title,
    DateTime? defaultDueDate,
    required int position,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Section;
}
