import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/features/now/domain/proof_mode.dart';
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

  group('TaskDto.fromJson — proofMode and proofModeIsCustom (Story 5.4, AC1, AC2)', () {
    const baseJson = {
      'id': 'a0000000-0000-4000-8000-000000000001',
      'title': 'Buy groceries',
      'position': 0,
      'createdAt': '2026-03-30T12:00:00.000Z',
      'updatedAt': '2026-03-30T12:00:00.000Z',
    };

    test('parses proofMode photo correctly', () {
      final json = {...baseJson, 'proofMode': 'photo'};
      final dto = TaskDto.fromJson(json);
      expect(dto.proofMode, equals('photo'));
      expect(dto.toDomain().proofMode, equals(ProofMode.photo));
    });

    test('parses proofMode watchMode correctly', () {
      final json = {...baseJson, 'proofMode': 'watchMode'};
      final dto = TaskDto.fromJson(json);
      expect(dto.toDomain().proofMode, equals(ProofMode.watchMode));
    });

    test('parses proofMode as standard when field is absent (old API stub)', () {
      final json = Map<String, dynamic>.from(baseJson);
      // No proofMode field — old API response
      final dto = TaskDto.fromJson(json);
      expect(dto.proofMode, equals('standard'));
      expect(dto.toDomain().proofMode, equals(ProofMode.standard));
    });

    test('parses proofModeIsCustom as true when present', () {
      final json = {...baseJson, 'proofMode': 'photo', 'proofModeIsCustom': true};
      final dto = TaskDto.fromJson(json);
      expect(dto.proofModeIsCustom, isTrue);
      expect(dto.toDomain().proofModeIsCustom, isTrue);
    });

    test('parses proofModeIsCustom as false when field is absent', () {
      final json = Map<String, dynamic>.from(baseJson);
      final dto = TaskDto.fromJson(json);
      expect(dto.proofModeIsCustom, isFalse);
      expect(dto.toDomain().proofModeIsCustom, isFalse);
    });
  });

  group('TaskDto.fromJson — proofRetained, proofMediaUrl, completedByName (Story 5.5, AC1)', () {
    const baseJson = {
      'id': 'a0000000-0000-4000-8000-000000000001',
      'title': 'Buy groceries',
      'position': 0,
      'createdAt': '2026-03-30T12:00:00.000Z',
      'updatedAt': '2026-03-30T12:00:00.000Z',
    };

    test('parses proofRetained true and proofMediaUrl from JSON', () {
      final json = {
        ...baseJson,
        'proofRetained': true,
        'proofMediaUrl': 'https://example.com/proof.jpg',
      };
      final dto = TaskDto.fromJson(json);
      expect(dto.proofRetained, isTrue);
      expect(dto.proofMediaUrl, equals('https://example.com/proof.jpg'));
      expect(dto.toDomain().proofRetained, isTrue);
      expect(dto.toDomain().proofMediaUrl, equals('https://example.com/proof.jpg'));
    });

    test('parses proofRetained as false when field is absent', () {
      final json = Map<String, dynamic>.from(baseJson);
      // No proofRetained field — default via @JsonKey(defaultValue: false)
      final dto = TaskDto.fromJson(json);
      expect(dto.proofRetained, isFalse);
      expect(dto.toDomain().proofRetained, isFalse);
    });

    test('parses proofMediaUrl as null when field is absent', () {
      final json = Map<String, dynamic>.from(baseJson);
      // No proofMediaUrl field — default via @JsonKey(defaultValue: null)
      final dto = TaskDto.fromJson(json);
      expect(dto.proofMediaUrl, isNull);
      expect(dto.toDomain().proofMediaUrl, isNull);
    });

    test('parses completedByName when present', () {
      final json = {...baseJson, 'completedByName': 'Jordan'};
      final dto = TaskDto.fromJson(json);
      expect(dto.completedByName, equals('Jordan'));
      expect(dto.toDomain().completedByName, equals('Jordan'));
    });

    test('parses completedByName as null when field is absent', () {
      final json = Map<String, dynamic>.from(baseJson);
      final dto = TaskDto.fromJson(json);
      expect(dto.completedByName, isNull);
      expect(dto.toDomain().completedByName, isNull);
    });
  });
}
