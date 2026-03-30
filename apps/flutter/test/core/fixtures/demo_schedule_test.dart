import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/fixtures/demo_schedule.dart';

void main() {
  group('kDemoSchedule fixture', () {
    test('has 4–6 tasks', () {
      expect(kDemoSchedule.length, greaterThanOrEqualTo(4));
      expect(kDemoSchedule.length, lessThanOrEqualTo(6));
    });

    test('at least one task is completed', () {
      final completedCount =
          kDemoSchedule.where((t) => t.isCompleted).length;
      expect(completedCount, greaterThanOrEqualTo(1));
    });

    test('all tasks have non-empty titles', () {
      for (final task in kDemoSchedule) {
        expect(
          task.title.trim(),
          isNotEmpty,
          reason: 'Every demo task must have a non-empty title',
        );
      }
    });

    test('all tasks have positive duration', () {
      for (final task in kDemoSchedule) {
        expect(
          task.durationMinutes,
          greaterThan(0),
          reason:
              'Every demo task must have a positive durationMinutes: ${task.title}',
        );
      }
    });

    test('all tasks have valid scheduledTime', () {
      for (final task in kDemoSchedule) {
        expect(
          task.scheduledTime.hour,
          inInclusiveRange(0, 23),
          reason: 'scheduledTime.hour must be valid for: ${task.title}',
        );
        expect(
          task.scheduledTime.minute,
          inInclusiveRange(0, 59),
          reason: 'scheduledTime.minute must be valid for: ${task.title}',
        );
      }
    });
  });
}
