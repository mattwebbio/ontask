import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/features/tasks/data/task_dto.dart';

void main() {
  group('TaskDto.fromJson', () {
    const baseJson = {
      'id': 'a0000000-0000-4000-8000-000000000001',
      'title': 'Buy groceries',
      'position': 0,
      'createdAt': '2026-03-30T12:00:00.000Z',
      'updatedAt': '2026-03-30T12:00:00.000Z',
    };

    test('parses assignedToUserId correctly when present', () {
      final json = {
        ...baseJson,
        'assignedToUserId': 'd0000000-0000-4000-8000-000000000001',
      };

      final dto = TaskDto.fromJson(json);

      expect(
        dto.assignedToUserId,
        equals('d0000000-0000-4000-8000-000000000001'),
      );
    });

    test('parses assignedToUserId as null when field is absent', () {
      final json = Map<String, dynamic>.from(baseJson);
      // No assignedToUserId field

      final dto = TaskDto.fromJson(json);

      expect(dto.assignedToUserId, isNull);
    });

    test('parses assignedToUserId as null when field is explicitly null', () {
      final json = {
        ...baseJson,
        'assignedToUserId': null,
      };

      final dto = TaskDto.fromJson(json);

      expect(dto.assignedToUserId, isNull);
    });

    test('toDomain maps assignedToUserId through correctly', () {
      final json = {
        ...baseJson,
        'assignedToUserId': 'd0000000-0000-4000-8000-000000000002',
      };

      final task = TaskDto.fromJson(json).toDomain();

      expect(
        task.assignedToUserId,
        equals('d0000000-0000-4000-8000-000000000002'),
      );
    });

    test('toDomain maps assignedToUserId as null when absent', () {
      final json = Map<String, dynamic>.from(baseJson);

      final task = TaskDto.fromJson(json).toDomain();

      expect(task.assignedToUserId, isNull);
    });
  });

  group('TaskDto.fromJson — listName (Story 5.3, AC1)', () {
    const baseJson = {
      'id': 'a0000000-0000-4000-8000-000000000001',
      'title': 'Buy groceries',
      'position': 0,
      'createdAt': '2026-03-30T12:00:00.000Z',
      'updatedAt': '2026-03-30T12:00:00.000Z',
    };

    test('parses listName when present', () {
      final json = {
        ...baseJson,
        'listName': 'Household',
      };

      final dto = TaskDto.fromJson(json);

      expect(dto.listName, equals('Household'));
    });

    test('parses listName as null when field is absent (old API stub)', () {
      final json = Map<String, dynamic>.from(baseJson);
      // No listName field — simulates old API response without the field

      final dto = TaskDto.fromJson(json);

      expect(dto.listName, isNull);
    });

    test('parses listName as null when field is explicitly null', () {
      final json = {
        ...baseJson,
        'listName': null,
      };

      final dto = TaskDto.fromJson(json);

      expect(dto.listName, isNull);
    });

    test('toDomain passes listName through correctly', () {
      final json = {
        ...baseJson,
        'listName': 'Household',
      };

      final task = TaskDto.fromJson(json).toDomain();

      expect(task.listName, equals('Household'));
    });

    test('toDomain maps listName as null when absent', () {
      final json = Map<String, dynamic>.from(baseJson);

      final task = TaskDto.fromJson(json).toDomain();

      expect(task.listName, isNull);
    });
  });
}
