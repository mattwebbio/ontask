import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/features/search/data/search_result_dto.dart';
import 'package:ontask/features/search/domain/search_filter.dart';
import 'package:ontask/features/search/domain/search_result.dart';
import 'package:ontask/features/search/domain/task_search_status.dart';
import 'package:ontask/features/tasks/domain/task.dart';

void main() {
  group('TaskSearchStatus', () {
    test('toApiValue returns correct strings', () {
      expect(TaskSearchStatus.upcoming.toApiValue(), 'upcoming');
      expect(TaskSearchStatus.overdue.toApiValue(), 'overdue');
      expect(TaskSearchStatus.completed.toApiValue(), 'completed');
    });

    test('displayLabel returns non-empty strings', () {
      for (final status in TaskSearchStatus.values) {
        expect(status.displayLabel(), isNotEmpty);
      }
    });
  });

  group('SearchFilter', () {
    test('empty factory creates all-null filter', () {
      final filter = SearchFilter.empty();
      expect(filter.query, isNull);
      expect(filter.listId, isNull);
      expect(filter.listName, isNull);
      expect(filter.dueDateFrom, isNull);
      expect(filter.dueDateTo, isNull);
      expect(filter.status, isNull);
      expect(filter.hasStake, isNull);
    });

    test('isActive returns false when no filters set', () {
      expect(SearchFilter.empty().isActive, isFalse);
    });

    test('isActive returns true when listId is set', () {
      final filter = SearchFilter.empty().copyWith(listId: 'list-1');
      expect(filter.isActive, isTrue);
    });

    test('isActive returns true when status is set', () {
      final filter =
          SearchFilter.empty().copyWith(status: TaskSearchStatus.completed);
      expect(filter.isActive, isTrue);
    });

    test('activeCount reflects non-null fields', () {
      expect(SearchFilter.empty().activeCount, 0);
      expect(
        SearchFilter.empty()
            .copyWith(listId: 'x', status: TaskSearchStatus.upcoming)
            .activeCount,
        2,
      );
    });

    test('activeCount counts date range as one dimension', () {
      final filter = SearchFilter.empty().copyWith(
        dueDateFrom: DateTime(2026, 4, 1),
        dueDateTo: DateTime(2026, 4, 7),
      );
      expect(filter.activeCount, 1);
    });
  });

  group('SearchResult', () {
    test('fromTask creates result with listName', () {
      final task = Task(
        id: 'task-1',
        title: 'Test task',
        position: 0,
        createdAt: DateTime(2026, 3, 30),
        updatedAt: DateTime(2026, 3, 30),
      );
      final result = SearchResult.fromTask(task, 'Personal');
      expect(result.id, 'task-1');
      expect(result.title, 'Test task');
      expect(result.listName, 'Personal');
    });

    test('fromTask preserves null listName', () {
      final task = Task(
        id: 'task-2',
        title: 'No list task',
        position: 0,
        createdAt: DateTime(2026, 3, 30),
        updatedAt: DateTime(2026, 3, 30),
      );
      final result = SearchResult.fromTask(task, null);
      expect(result.listName, isNull);
    });
  });

  group('SearchResultDto', () {
    final fullJson = {
      'id': 'a0000000-0000-4000-8000-000000000010',
      'userId': '00000000-0000-4000-a000-000000000001',
      'title': 'Buy groceries',
      'notes': 'Milk, eggs',
      'dueDate': '2026-04-01T09:00:00.000Z',
      'listId': 'list-1',
      'sectionId': null,
      'parentTaskId': null,
      'position': 0,
      'timeWindow': null,
      'timeWindowStart': null,
      'timeWindowEnd': null,
      'energyRequirement': null,
      'priority': 'normal',
      'recurrenceRule': null,
      'recurrenceInterval': null,
      'recurrenceDaysOfWeek': null,
      'recurrenceParentId': null,
      'archivedAt': null,
      'completedAt': null,
      'createdAt': '2026-03-30T12:00:00.000Z',
      'updatedAt': '2026-03-30T12:00:00.000Z',
      'listName': 'Personal',
    };

    test('fromJson parses correctly', () {
      final dto = SearchResultDto.fromJson(fullJson);
      expect(dto.id, 'a0000000-0000-4000-8000-000000000010');
      expect(dto.title, 'Buy groceries');
      expect(dto.listName, 'Personal');
    });

    test('toDomain converts to SearchResult', () {
      final dto = SearchResultDto.fromJson(fullJson);
      final result = dto.toDomain();
      expect(result, isA<SearchResult>());
      expect(result.title, 'Buy groceries');
      expect(result.listName, 'Personal');
      expect(result.dueDate, DateTime.utc(2026, 4, 1, 9));
    });

    test('fromJson handles null listName', () {
      final json = Map<String, dynamic>.from(fullJson)..['listName'] = null;
      final dto = SearchResultDto.fromJson(json);
      expect(dto.listName, isNull);
      expect(dto.toDomain().listName, isNull);
    });
  });
}
