import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/features/lists/data/section_dto.dart';

void main() {
  group('SectionDto.fromJson — proofRequirement (Story 5.4, AC1)', () {
    const baseJson = {
      'id': 'c0000000-0000-4000-8000-000000000001',
      'listId': 'b0000000-0000-4000-8000-000000000001',
      'title': 'Sprint 1',
      'position': 0,
      'createdAt': '2026-03-30T12:00:00.000Z',
      'updatedAt': '2026-03-30T12:00:00.000Z',
    };

    test('parses proofRequirement watchMode correctly', () {
      final json = {...baseJson, 'proofRequirement': 'watchMode'};

      final dto = SectionDto.fromJson(json);

      expect(dto.proofRequirement, equals('watchMode'));
      expect(dto.toDomain().proofRequirement, equals('watchMode'));
    });

    test('parses proofRequirement photo correctly', () {
      final json = {...baseJson, 'proofRequirement': 'photo'};

      final dto = SectionDto.fromJson(json);

      expect(dto.proofRequirement, equals('photo'));
    });

    test('parses proofRequirement as null when field is absent', () {
      final json = Map<String, dynamic>.from(baseJson);
      // No proofRequirement field — null means inherit from parent list

      final dto = SectionDto.fromJson(json);

      expect(dto.proofRequirement, isNull);
      expect(dto.toDomain().proofRequirement, isNull);
    });

    test('parses proofRequirement as null when explicitly null', () {
      final json = {...baseJson, 'proofRequirement': null};

      final dto = SectionDto.fromJson(json);

      expect(dto.proofRequirement, isNull);
    });
  });
}
