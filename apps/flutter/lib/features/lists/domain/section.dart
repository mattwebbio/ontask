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
    // Proof requirement for tasks in this section (FR20). Null = inherit from parent list.
    // Valid values: 'none' | 'photo' | 'watchMode' | 'healthKit' | null
    String? proofRequirement,
  }) = _Section;
}
