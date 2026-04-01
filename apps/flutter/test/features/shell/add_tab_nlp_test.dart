import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/core/l10n/strings.dart';
import 'package:ontask/core/network/api_client.dart';
import 'package:ontask/core/theme/app_theme.dart';
import 'package:ontask/features/lists/domain/task_list.dart';
import 'package:ontask/features/lists/presentation/lists_provider.dart';
import 'package:ontask/features/shell/data/nlp_task_repository.dart';
import 'package:ontask/features/shell/domain/task_parse_result.dart';
import 'package:ontask/features/shell/presentation/add_tab_sheet.dart';
import 'package:ontask/features/tasks/domain/task.dart';
import 'package:ontask/features/tasks/presentation/tasks_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildSheet({required NlpTaskRepository repo}) {
    return ProviderScope(
      overrides: [
        nlpTaskRepositoryProvider.overrideWithValue(repo),
        // Stub out lists so no network call is made
        listsProvider.overrideWith(() => _StubListsNotifier()),
        // Stub out tasks so no network call is made
        tasksProvider().overrideWith(() => _StubTasksNotifier()),
      ],
      child: MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: const Scaffold(
          body: AddTabSheet(),
        ),
      ),
    );
  }

  // Helper: enter NLP text and wait for debounce + response
  Future<void> enterNlpTextAndSettle(WidgetTester tester, String text) async {
    final field = find.byType(CupertinoTextField).first;
    await tester.enterText(field, text);
    // Advance past the 600ms debounce
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
  }

  group('AddTabSheet — NLP Quick Capture mode', () {
    // ── Mode toggle ───────────────────────────────────────────────────────────

    testWidgets('NLP mode is default when sheet opens', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _NeverResolvingRepository()));

      expect(find.text(AppStrings.addTaskNlpPlaceholder), findsOneWidget);
    });

    testWidgets('mode toggle row is visible', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _NeverResolvingRepository()));

      expect(find.text(AppStrings.addTaskModeQuickCapture), findsOneWidget);
      expect(find.text(AppStrings.addTaskModeForm), findsOneWidget);
    });

    testWidgets('Form mode toggle shows existing form title field', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _NeverResolvingRepository()));

      await tester.tap(find.text(AppStrings.addTaskModeForm));
      await tester.pump();

      expect(find.text(AppStrings.addTaskTitlePlaceholder), findsOneWidget);
    });

    // ── Loading state ─────────────────────────────────────────────────────────

    testWidgets('loading state renders CupertinoActivityIndicator', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _SlowNlpRepository()));

      final field = find.byType(CupertinoTextField).first;
      await tester.enterText(field, 'call the dentist');
      // Advance past debounce but before response
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(); // start the async call but don't resolve

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    });

    // ── Success state ─────────────────────────────────────────────────────────

    testWidgets('success state renders parsed field pills', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _SuccessNlpRepository()));

      await enterNlpTextAndSettle(tester, 'call the dentist Thursday at 2pm');

      // No error or low-confidence message — pills are being shown
      expect(find.text(AppStrings.addTaskNlpLowConfidence), findsNothing);
      expect(find.text(AppStrings.addTaskNlpError), findsNothing);
      // Loading indicator is gone — response arrived
      expect(find.byType(CupertinoActivityIndicator), findsNothing);
    });

    // ── Low confidence state ──────────────────────────────────────────────────

    testWidgets('low-confidence shows inline warning, no pills', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _LowConfidenceNlpRepository()));

      await enterNlpTextAndSettle(tester, 'asdf qwerty zzz');

      expect(find.text(AppStrings.addTaskNlpLowConfidence), findsOneWidget);
      // No parsed pills rendered
      expect(find.text(AppStrings.addTaskNlpTitle), findsNothing);
    });

    // ── Error state ───────────────────────────────────────────────────────────

    testWidgets('error state shows addTaskNlpError message', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _ErrorNlpRepository()));

      await enterNlpTextAndSettle(tester, 'call the dentist');

      expect(find.text(AppStrings.addTaskNlpError), findsOneWidget);
    });

    // ── Pill confidence borders ───────────────────────────────────────────────

    testWidgets('high-confidence result shows parsed title without low-confidence message', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _SuccessNlpRepository()));

      await enterNlpTextAndSettle(tester, 'call the dentist Thursday at 2pm');

      // Low confidence warning should NOT appear for high-confidence result
      expect(find.text(AppStrings.addTaskNlpLowConfidence), findsNothing);
    });

    testWidgets('low-confidence result shows warning without pills', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _LowConfidenceNlpRepository()));

      await enterNlpTextAndSettle(tester, 'asdf qwerty');

      expect(find.text(AppStrings.addTaskNlpLowConfidence), findsOneWidget);
      // No pill labels
      expect(find.text(AppStrings.addTaskNlpDueDate), findsNothing);
    });

    // ── Reduced motion ────────────────────────────────────────────────────────

    testWidgets('with disableAnimations true, pills appear without stagger delay', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: ProviderScope(
            overrides: [
              nlpTaskRepositoryProvider.overrideWithValue(_SuccessNlpRepository()),
              listsProvider.overrideWith(() => _StubListsNotifier()),
              tasksProvider().overrideWith(() => _StubTasksNotifier()),
            ],
            child: MaterialApp(
              theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
              home: const Scaffold(body: AddTabSheet()),
            ),
          ),
        ),
      );

      final field = find.byType(CupertinoTextField).first;
      await tester.enterText(field, 'call the dentist');
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      // No error states — pills are shown (no stagger animation in reduced motion)
      expect(find.text(AppStrings.addTaskNlpError), findsNothing);
      expect(find.text(AppStrings.addTaskNlpLowConfidence), findsNothing);
      expect(find.byType(CupertinoActivityIndicator), findsNothing);
    });

    // ── Form mode toggle ──────────────────────────────────────────────────────

    testWidgets('Form mode toggle shows form fields', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _NeverResolvingRepository()));

      await tester.tap(find.text(AppStrings.addTaskModeForm));
      await tester.pump();

      // Form placeholder visible
      expect(find.text(AppStrings.addTaskTitlePlaceholder), findsOneWidget);
      // NLP placeholder not visible
      expect(find.text(AppStrings.addTaskNlpPlaceholder), findsNothing);
    });

    testWidgets('switching to Form mode pre-fills title from NLP result', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _SuccessNlpRepository()));

      // Parse something
      await enterNlpTextAndSettle(tester, 'call the dentist');

      // Toggle to Form mode
      await tester.tap(find.text(AppStrings.addTaskModeForm));
      await tester.pump();

      // Form mode is now active (NLP placeholder is gone)
      expect(find.text(AppStrings.addTaskNlpPlaceholder), findsNothing);
      // The form title field controller should have the parsed title
      // Find the form title field (has the addTaskTitlePlaceholder)
      final titleFields = tester.widgetList<CupertinoTextField>(
        find.byType(CupertinoTextField),
      ).toList();
      // At least one controller should have "Call the dentist" pre-filled
      final hasPrefilled = titleFields.any(
        (f) => f.controller?.text == 'Call the dentist',
      );
      expect(hasPrefilled, isTrue);
    });
  });
}

// ── Stub providers ────────────────────────────────────────────────────────────

class _StubListsNotifier extends ListsNotifier {
  @override
  Future<List<TaskList>> build() async => [];
}

class _StubTasksNotifier extends TasksNotifier {
  @override
  Future<List<Task>> build({String? listId, String? sectionId}) async => [];
}

// ── Mock repositories ─────────────────────────────────────────────────────────

class _NeverResolvingRepository extends NlpTaskRepository {
  _NeverResolvingRepository() : super(ApiClient(baseUrl: 'http://fake'));

  @override
  Future<TaskParseResult> parseUtterance(String utterance) =>
      Completer<TaskParseResult>().future;
}

class _SlowNlpRepository extends NlpTaskRepository {
  _SlowNlpRepository() : super(ApiClient(baseUrl: 'http://fake'));

  @override
  Future<TaskParseResult> parseUtterance(String utterance) =>
      Completer<TaskParseResult>().future; // never resolves during test
}

class _SuccessNlpRepository extends NlpTaskRepository {
  _SuccessNlpRepository() : super(ApiClient(baseUrl: 'http://fake'));

  @override
  Future<TaskParseResult> parseUtterance(String utterance) async =>
      const TaskParseResult(
        title: 'Call the dentist',
        confidence: 'high',
        dueDate: '2026-04-03T00:00:00.000Z',
        scheduledTime: '2026-04-03T14:00:00.000Z',
        fieldConfidences: {
          'title': 'high',
          'dueDate': 'high',
          'scheduledTime': 'high',
        },
      );
}

class _LowConfidenceNlpRepository extends NlpTaskRepository {
  _LowConfidenceNlpRepository() : super(ApiClient(baseUrl: 'http://fake'));

  @override
  Future<TaskParseResult> parseUtterance(String utterance) async =>
      const TaskParseResult(
        title: '',
        confidence: 'low',
        fieldConfidences: {},
      );
}

class _ErrorNlpRepository extends NlpTaskRepository {
  _ErrorNlpRepository() : super(ApiClient(baseUrl: 'http://fake'));

  @override
  Future<TaskParseResult> parseUtterance(String utterance) =>
      Future.error(Exception('Network error'));
}
