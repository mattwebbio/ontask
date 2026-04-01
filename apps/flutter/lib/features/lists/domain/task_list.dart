import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_list.freezed.dart';

/// List domain model — named [TaskList] to avoid conflict with `dart:core List`.
///
/// Maps to the `lists` table and the `/v1/lists` API response.
@freezed
abstract class TaskList with _$TaskList {
  const factory TaskList({
    required String id,
    required String title,
    DateTime? defaultDueDate,
    required int position,
    DateTime? archivedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(false) bool isShared,
    @Default(1) int memberCount,
    @Default(<String>[]) List<String> memberAvatarInitials,
  }) = _TaskList;
}
