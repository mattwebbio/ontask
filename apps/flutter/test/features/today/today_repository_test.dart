import 'package:flutter_test/flutter_test.dart';

import 'package:ontask/features/today/domain/day_health.dart';
import 'package:ontask/features/today/domain/day_health_status.dart';
import 'package:ontask/features/today/data/day_health_dto.dart';

void main() {
  group('DayHealthStatus', () {
    test('fromJson parses healthy', () {
      expect(DayHealthStatus.fromJson('healthy'), DayHealthStatus.healthy);
    });

    test('fromJson parses at-risk', () {
      expect(DayHealthStatus.fromJson('at-risk'), DayHealthStatus.atRisk);
    });

    test('fromJson parses critical', () {
      expect(DayHealthStatus.fromJson('critical'), DayHealthStatus.critical);
    });

    test('fromJson defaults to healthy for unknown value', () {
      expect(DayHealthStatus.fromJson('unknown'), DayHealthStatus.healthy);
    });
  });

  group('DayHealthDto', () {
    test('fromJson parses correctly', () {
      final json = {
        'date': '2026-03-30',
        'status': 'healthy',
        'taskCount': 3,
        'capacityPercent': 75.0,
        'atRiskTaskIds': ['task-1', 'task-2'],
      };

      final dto = DayHealthDto.fromJson(json);
      expect(dto.date, '2026-03-30');
      expect(dto.status, 'healthy');
      expect(dto.taskCount, 3);
      expect(dto.capacityPercent, 75.0);
      expect(dto.atRiskTaskIds, ['task-1', 'task-2']);
    });

    test('toJson produces valid JSON for round-trip', () {
      final dto = DayHealthDto(
        date: '2026-03-30',
        status: 'at-risk',
        taskCount: 5,
        capacityPercent: 110.0,
        atRiskTaskIds: ['a', 'b'],
      );

      final json = dto.toJson();
      final roundTripped = DayHealthDto.fromJson(json);
      expect(roundTripped.date, dto.date);
      expect(roundTripped.status, dto.status);
      expect(roundTripped.taskCount, dto.taskCount);
      expect(roundTripped.capacityPercent, dto.capacityPercent);
      expect(roundTripped.atRiskTaskIds, dto.atRiskTaskIds);
    });

    test('toDomain maps correctly', () {
      final dto = DayHealthDto(
        date: '2026-03-30',
        status: 'critical',
        taskCount: 8,
        capacityPercent: 150.0,
        atRiskTaskIds: ['task-1'],
      );

      final domain = dto.toDomain();
      expect(domain, isA<DayHealth>());
      expect(domain.date, DateTime(2026, 3, 30));
      expect(domain.status, DayHealthStatus.critical);
      expect(domain.taskCount, 8);
      expect(domain.capacityPercent, 150.0);
      expect(domain.atRiskTaskIds, ['task-1']);
    });

    test('toDomain maps at-risk status', () {
      final dto = DayHealthDto(
        date: '2026-04-01',
        status: 'at-risk',
        taskCount: 4,
        capacityPercent: 95.0,
        atRiskTaskIds: [],
      );

      final domain = dto.toDomain();
      expect(domain.status, DayHealthStatus.atRisk);
    });
  });

  group('DayHealth domain model', () {
    test('creates with all fields', () {
      final model = DayHealth(
        date: DateTime(2026, 3, 30),
        status: DayHealthStatus.healthy,
        taskCount: 3,
        capacityPercent: 60.0,
        atRiskTaskIds: [],
      );

      expect(model.date, DateTime(2026, 3, 30));
      expect(model.status, DayHealthStatus.healthy);
      expect(model.taskCount, 3);
      expect(model.capacityPercent, 60.0);
      expect(model.atRiskTaskIds, isEmpty);
    });

    test('equality works', () {
      final a = DayHealth(
        date: DateTime(2026, 3, 30),
        status: DayHealthStatus.healthy,
        taskCount: 0,
        capacityPercent: 0,
        atRiskTaskIds: [],
      );
      final b = DayHealth(
        date: DateTime(2026, 3, 30),
        status: DayHealthStatus.healthy,
        taskCount: 0,
        capacityPercent: 0,
        atRiskTaskIds: [],
      );
      expect(a, equals(b));
    });
  });
}
