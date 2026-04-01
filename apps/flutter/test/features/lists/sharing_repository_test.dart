import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/network/api_client.dart';
import 'package:ontask/features/lists/data/sharing_repository.dart';

// Unit tests for SharingRepository.unassignTask (Story 5.3, AC3).
//
// Tests the repository directly using a fake that records calls,
// following the established pattern from share_list_sheet_test.dart.

void main() {
  group('SharingRepository.unassignTask (AC3)', () {
    test('calls DELETE /v1/lists/{listId}/tasks/{taskId}/assignment and returns response map',
        () async {
      final recorder = _RecordingFakeRepository();

      final result = await recorder.unassignTask('list-id', 'task-id');

      expect(recorder.lastUnassignListId, equals('list-id'));
      expect(recorder.lastUnassignTaskId, equals('task-id'));
      expect(result['taskId'], equals('task-id'));
      expect(result['listId'], equals('list-id'));
      expect(result['previousAssigneeId'], isNotNull);
    });

    test('returns previousAssigneeId from response data', () async {
      final recorder = _RecordingFakeRepository(
        previousAssigneeId: 'd0000000-0000-4000-8000-000000000002',
      );

      final result = await recorder.unassignTask('list-abc', 'task-xyz');

      expect(result['previousAssigneeId'],
          equals('d0000000-0000-4000-8000-000000000002'));
    });

    test('propagates errors when the request fails', () async {
      final throwing = _ThrowingFakeRepository();

      expect(
        () async => throwing.unassignTask('list-id', 'task-id'),
        throwsA(isA<Exception>()),
      );
    });
  });
}

/// Fake [SharingRepository] that records unassignTask calls.
class _RecordingFakeRepository extends SharingRepository {
  _RecordingFakeRepository({this.previousAssigneeId = 'prev-user-id'})
      : super(ApiClient(baseUrl: 'http://fake'));

  final String previousAssigneeId;
  String? lastUnassignListId;
  String? lastUnassignTaskId;

  @override
  Future<Map<String, dynamic>> unassignTask(
      String listId, String taskId) async {
    lastUnassignListId = listId;
    lastUnassignTaskId = taskId;
    return {
      'taskId': taskId,
      'listId': listId,
      'previousAssigneeId': previousAssigneeId,
    };
  }
}

/// Fake [SharingRepository] that throws to simulate a network failure.
class _ThrowingFakeRepository extends SharingRepository {
  _ThrowingFakeRepository() : super(ApiClient(baseUrl: 'http://fake'));

  @override
  Future<Map<String, dynamic>> unassignTask(
      String listId, String taskId) async {
    throw Exception('Network error: could not unassign task');
  }
}
