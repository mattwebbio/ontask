import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ontask/features/live_activities/data/widget_data_writer.dart';

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.ontaskhq.ontask/widget_data');

  // Captures all calls made to the widget_data channel.
  final List<MethodCall> calls = [];

  setUp(() {
    calls.clear();
    // Register a mock handler for the widget_data channel.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() {
    // Remove mock handler and reset platform override.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  // ── writeWidgetData ────────────────────────────────────────────────────────

  group('writeWidgetData', () {
    test('is a no-op on non-iOS platforms', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      final writer = WidgetDataWriter();
      await writer.writeWidgetData(
        scheduleHealth: 'healthy',
        todayTasks: [],
      );

      expect(calls, isEmpty);
    });

    test('is a no-op on macOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

      final writer = WidgetDataWriter();
      await writer.writeWidgetData(
        scheduleHealth: 'healthy',
        todayTasks: [],
      );

      expect(calls, isEmpty);
    });

    test('invokes writeWidgetData method on iOS with correct arguments',
        () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final writer = WidgetDataWriter();
      final todayTasks = [
        {'title': 'Pay rent', 'scheduledTime': '14:30', 'listName': 'Personal'},
        {'title': 'Call dentist', 'scheduledTime': '15:00', 'listName': 'Personal'},
      ];

      await writer.writeWidgetData(
        activeTaskTitle: 'Pay rent',
        activeElapsedSeconds: 120,
        nextTaskTitle: 'Call dentist',
        nextTaskTimeIso: '2026-04-02T15:00:00Z',
        scheduleHealth: 'at_risk',
        todayTasks: todayTasks,
      );

      expect(calls, hasLength(1));
      expect(calls.first.method, equals('writeWidgetData'));

      final args = calls.first.arguments as Map<Object?, Object?>;
      expect(args['activeTaskTitle'], equals('Pay rent'));
      expect(args['activeElapsedSeconds'], equals(120));
      expect(args['nextTaskTitle'], equals('Call dentist'));
      expect(args['nextTaskTimeIso'], equals('2026-04-02T15:00:00Z'));
      expect(args['scheduleHealth'], equals('at_risk'));
      expect(args['todayTasks'], equals(todayTasks));
    });

    test('passes null optional values correctly on iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final writer = WidgetDataWriter();
      await writer.writeWidgetData(
        scheduleHealth: 'healthy',
        todayTasks: [],
      );

      expect(calls, hasLength(1));
      final args = calls.first.arguments as Map<Object?, Object?>;
      expect(args['activeTaskTitle'], isNull);
      expect(args['activeElapsedSeconds'], isNull);
      expect(args['nextTaskTitle'], isNull);
      expect(args['nextTaskTimeIso'], isNull);
      expect(args['scheduleHealth'], equals('healthy'));
      expect(args['todayTasks'], equals(<Map<String, String>>[]));
    });
  });

  // ── reloadWidgets ──────────────────────────────────────────────────────────

  group('reloadWidgets', () {
    test('is a no-op on non-iOS platforms', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      final writer = WidgetDataWriter();
      await writer.reloadWidgets();

      expect(calls, isEmpty);
    });

    test('is a no-op on macOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

      final writer = WidgetDataWriter();
      await writer.reloadWidgets();

      expect(calls, isEmpty);
    });

    test('invokes reloadWidgets method on iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final writer = WidgetDataWriter();
      await writer.reloadWidgets();

      expect(calls, hasLength(1));
      expect(calls.first.method, equals('reloadWidgets'));
    });

    test('invokes reloadWidgets with no arguments on iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final writer = WidgetDataWriter();
      await writer.reloadWidgets();

      expect(calls.first.arguments, isNull);
    });
  });
}
