import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/features/lists/data/list_dto.dart';

void main() {
  group('ListDto.fromJson', () {
    test('parses all fields including sharing fields', () {
      final json = {
        'id': 'b0000000-0000-4000-8000-000000000001',
        'userId': '00000000-0000-4000-a000-000000000001',
        'title': 'Work tasks',
        'defaultDueDate': null,
        'position': 0,
        'archivedAt': null,
        'createdAt': '2026-03-30T12:00:00.000Z',
        'updatedAt': '2026-03-30T12:00:00.000Z',
        'isShared': true,
        'memberCount': 3,
        'memberAvatarInitials': ['J', 'S', 'A'],
      };

      final dto = ListDto.fromJson(json);

      expect(dto.id, equals('b0000000-0000-4000-8000-000000000001'));
      expect(dto.title, equals('Work tasks'));
      expect(dto.isShared, isTrue);
      expect(dto.memberCount, equals(3));
      expect(dto.memberAvatarInitials, equals(['J', 'S', 'A']));
    });

    test('uses default values when sharing fields are absent', () {
      final json = {
        'id': 'b0000000-0000-4000-8000-000000000001',
        'userId': '00000000-0000-4000-a000-000000000001',
        'title': 'Personal list',
        'defaultDueDate': null,
        'position': 0,
        'archivedAt': null,
        'createdAt': '2026-03-30T12:00:00.000Z',
        'updatedAt': '2026-03-30T12:00:00.000Z',
        // No isShared, memberCount, or memberAvatarInitials
      };

      final dto = ListDto.fromJson(json);

      expect(dto.isShared, isFalse);
      expect(dto.memberCount, equals(1));
      expect(dto.memberAvatarInitials, isEmpty);
    });

    test('toDomain maps sharing fields correctly', () {
      final json = {
        'id': 'b0000000-0000-4000-8000-000000000001',
        'userId': '00000000-0000-4000-a000-000000000001',
        'title': 'Shared list',
        'defaultDueDate': null,
        'position': 0,
        'archivedAt': null,
        'createdAt': '2026-03-30T12:00:00.000Z',
        'updatedAt': '2026-03-30T12:00:00.000Z',
        'isShared': true,
        'memberCount': 2,
        'memberAvatarInitials': ['J', 'S'],
      };

      final taskList = ListDto.fromJson(json).toDomain();

      expect(taskList.isShared, isTrue);
      expect(taskList.memberCount, equals(2));
      expect(taskList.memberAvatarInitials, equals(['J', 'S']));
    });
  });
}
