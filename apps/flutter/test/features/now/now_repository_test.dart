import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/features/now/data/now_task_dto.dart';
import 'package:ontask/features/now/domain/now_task.dart';
import 'package:ontask/features/now/domain/proof_mode.dart';

void main() {
  group('ProofMode', () {
    test('fromJson parses standard', () {
      expect(ProofMode.fromJson('standard'), ProofMode.standard);
    });

    test('fromJson parses photo', () {
      expect(ProofMode.fromJson('photo'), ProofMode.photo);
    });

    test('fromJson parses watchMode', () {
      expect(ProofMode.fromJson('watchMode'), ProofMode.watchMode);
    });

    test('fromJson parses healthKit', () {
      expect(ProofMode.fromJson('healthKit'), ProofMode.healthKit);
    });

    test('fromJson parses calendarEvent', () {
      expect(ProofMode.fromJson('calendarEvent'), ProofMode.calendarEvent);
    });

    test('fromJson defaults to standard for unknown value', () {
      expect(ProofMode.fromJson('unknown'), ProofMode.standard);
    });

    test('fromJson defaults to standard for null', () {
      expect(ProofMode.fromJson(null), ProofMode.standard);
    });

    test('toJson returns name', () {
      expect(ProofMode.standard.toJson(), 'standard');
      expect(ProofMode.photo.toJson(), 'photo');
      expect(ProofMode.watchMode.toJson(), 'watchMode');
    });
  });

  group('NowTaskDto', () {
    final fullJson = {
      'id': 'a0000000-0000-4000-8000-000000000001',
      'title': 'Buy groceries',
      'notes': 'Milk, eggs',
      'dueDate': '2026-04-01T14:00:00.000Z',
      'listId': 'list-1',
      'listName': 'Personal',
      'assignorName': null,
      'stakeAmountCents': 2500,
      'proofMode': 'photo',
      'completedAt': null,
      'createdAt': '2026-03-30T12:00:00.000Z',
      'updatedAt': '2026-03-30T12:00:00.000Z',
    };

    test('fromJson parses correctly', () {
      final dto = NowTaskDto.fromJson(fullJson);
      expect(dto.id, 'a0000000-0000-4000-8000-000000000001');
      expect(dto.title, 'Buy groceries');
      expect(dto.notes, 'Milk, eggs');
      expect(dto.listName, 'Personal');
      expect(dto.stakeAmountCents, 2500);
      expect(dto.proofMode, 'photo');
    });

    test('toJson produces valid JSON for round-trip', () {
      final dto = NowTaskDto.fromJson(fullJson);
      final json = dto.toJson();
      final roundTripped = NowTaskDto.fromJson(json);
      expect(roundTripped.id, dto.id);
      expect(roundTripped.title, dto.title);
      expect(roundTripped.listName, dto.listName);
      expect(roundTripped.stakeAmountCents, dto.stakeAmountCents);
      expect(roundTripped.proofMode, dto.proofMode);
    });

    test('toDomain maps correctly including ProofMode enum', () {
      final dto = NowTaskDto.fromJson(fullJson);
      final domain = dto.toDomain();

      expect(domain, isA<NowTask>());
      expect(domain.id, 'a0000000-0000-4000-8000-000000000001');
      expect(domain.title, 'Buy groceries');
      expect(domain.listName, 'Personal');
      expect(domain.stakeAmountCents, 2500);
      expect(domain.proofMode, ProofMode.photo);
      expect(domain.dueDate, DateTime.utc(2026, 4, 1, 14, 0));
      expect(domain.completedAt, isNull);
    });

    test('toDomain handles null stakeAmountCents', () {
      final json = Map<String, dynamic>.from(fullJson);
      json['stakeAmountCents'] = null;
      final domain = NowTaskDto.fromJson(json).toDomain();
      expect(domain.stakeAmountCents, isNull);
    });

    test('toDomain defaults proofMode to standard for unknown', () {
      final json = Map<String, dynamic>.from(fullJson);
      json['proofMode'] = 'unknown_mode';
      final domain = NowTaskDto.fromJson(json).toDomain();
      expect(domain.proofMode, ProofMode.standard);
    });

    test('toDomain handles null proofMode', () {
      final json = Map<String, dynamic>.from(fullJson);
      json['proofMode'] = null;
      final domain = NowTaskDto.fromJson(json).toDomain();
      expect(domain.proofMode, ProofMode.standard);
    });

    test('toDomain maps all Now-specific enriched fields', () {
      final json = Map<String, dynamic>.from(fullJson);
      json['assignorName'] = 'Alice';
      final domain = NowTaskDto.fromJson(json).toDomain();
      expect(domain.assignorName, 'Alice');
      expect(domain.listName, 'Personal');
      expect(domain.stakeAmountCents, 2500);
      expect(domain.proofMode, ProofMode.photo);
    });
  });

  group('NowTask domain model', () {
    test('defaults proofMode to standard', () {
      final task = NowTask(
        id: 'task-1',
        title: 'Test',
        createdAt: DateTime(2026, 3, 30),
        updatedAt: DateTime(2026, 3, 30),
      );
      expect(task.proofMode, ProofMode.standard);
    });

    test('null stakeAmountCents is valid', () {
      final task = NowTask(
        id: 'task-1',
        title: 'Test',
        stakeAmountCents: null,
        createdAt: DateTime(2026, 3, 30),
        updatedAt: DateTime(2026, 3, 30),
      );
      expect(task.stakeAmountCents, isNull);
    });

    test('non-null stakeAmountCents is stored correctly', () {
      final task = NowTask(
        id: 'task-1',
        title: 'Test',
        stakeAmountCents: 5000,
        createdAt: DateTime(2026, 3, 30),
        updatedAt: DateTime(2026, 3, 30),
      );
      expect(task.stakeAmountCents, 5000);
    });
  });

  group('NowTaskDto timer fields', () {
    final timerJson = {
      'id': 'a0000000-0000-4000-8000-000000000001',
      'title': 'Timer task',
      'notes': null,
      'dueDate': null,
      'listId': null,
      'listName': null,
      'assignorName': null,
      'stakeAmountCents': null,
      'proofMode': 'standard',
      'startedAt': '2026-03-31T10:00:00.000Z',
      'elapsedSeconds': 120,
      'completedAt': null,
      'createdAt': '2026-03-30T12:00:00.000Z',
      'updatedAt': '2026-03-30T12:00:00.000Z',
    };

    test('fromJson parses startedAt and elapsedSeconds', () {
      final dto = NowTaskDto.fromJson(timerJson);
      expect(dto.startedAt, '2026-03-31T10:00:00.000Z');
      expect(dto.elapsedSeconds, 120);
    });

    test('toDomain maps startedAt and elapsedSeconds', () {
      final domain = NowTaskDto.fromJson(timerJson).toDomain();
      expect(domain.startedAt, DateTime.utc(2026, 3, 31, 10, 0));
      expect(domain.elapsedSeconds, 120);
    });

    test('toDomain handles null startedAt and elapsedSeconds', () {
      final nullTimerJson = Map<String, dynamic>.from(timerJson);
      nullTimerJson['startedAt'] = null;
      nullTimerJson['elapsedSeconds'] = null;
      final domain = NowTaskDto.fromJson(nullTimerJson).toDomain();
      expect(domain.startedAt, isNull);
      expect(domain.elapsedSeconds, isNull);
    });

    test('toJson round-trip preserves timer fields', () {
      final dto = NowTaskDto.fromJson(timerJson);
      final json = dto.toJson();
      final roundTripped = NowTaskDto.fromJson(json);
      expect(roundTripped.startedAt, dto.startedAt);
      expect(roundTripped.elapsedSeconds, dto.elapsedSeconds);
    });

    test('NowTask domain model stores timer fields', () {
      final task = NowTask(
        id: 'task-1',
        title: 'Test',
        startedAt: DateTime(2026, 3, 31, 10, 0),
        elapsedSeconds: 300,
        createdAt: DateTime(2026, 3, 30),
        updatedAt: DateTime(2026, 3, 30),
      );
      expect(task.startedAt, DateTime(2026, 3, 31, 10, 0));
      expect(task.elapsedSeconds, 300);
    });

    test('NowTask domain defaults timer fields to null', () {
      final task = NowTask(
        id: 'task-1',
        title: 'Test',
        createdAt: DateTime(2026, 3, 30),
        updatedAt: DateTime(2026, 3, 30),
      );
      expect(task.startedAt, isNull);
      expect(task.elapsedSeconds, isNull);
    });
  });
}
