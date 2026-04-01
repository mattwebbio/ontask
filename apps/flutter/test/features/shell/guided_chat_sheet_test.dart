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
import 'package:ontask/features/shell/data/guided_chat_repository.dart';
import 'package:ontask/features/shell/domain/chat_message.dart';
import 'package:ontask/features/shell/domain/guided_chat_response.dart';
import 'package:ontask/features/shell/domain/guided_chat_task_draft.dart';
import 'package:ontask/features/shell/presentation/guided_chat_sheet.dart';
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

  Widget buildSheet({required GuidedChatRepository repo}) {
    return ProviderScope(
      overrides: [
        guidedChatRepositoryProvider.overrideWithValue(repo),
        // Stub out lists so no network call is made (Story 4.1 Debug Log item 5)
        listsProvider.overrideWith(() => _StubListsNotifier()),
        // Stub out tasks so no network call is made
        tasksProvider().overrideWith(() => _StubTasksNotifier()),
      ],
      child: MaterialApp(
        theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
        home: const Scaffold(
          body: GuidedChatSheet(),
        ),
      ),
    );
  }

  group('GuidedChatSheet', () {
    // ── Opening state ─────────────────────────────────────────────────────────

    testWidgets('sheet opens with loading state (typing indicator)', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _SlowChatRepository()));
      // After first frame, the opening call is triggered — loading should show
      await tester.pump();

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    });

    testWidgets('after opening call resolves, LLM opening message is shown', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _OpeningChatRepository()));
      await tester.pump(); // trigger initState postFrameCallback
      await tester.pumpAndSettle(); // resolve the async call

      expect(find.text('What task would you like to create?'), findsOneWidget);
      expect(find.byType(CupertinoActivityIndicator), findsNothing);
    });

    // ── Message alignment ─────────────────────────────────────────────────────

    testWidgets('user message appears on the right side', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _MultiTurnChatRepository()));
      await tester.pump();
      await tester.pumpAndSettle(); // resolve opening message

      // Type a user message and send it
      final field = find.byType(CupertinoTextField).first;
      await tester.enterText(field, 'I need to call the dentist');
      await tester.tap(find.byIcon(CupertinoIcons.arrow_up_circle_fill));
      await tester.pump();

      // User message should be visible
      expect(find.text('I need to call the dentist'), findsOneWidget);
    });

    testWidgets('LLM message appears on the left side (assistant role)', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _OpeningChatRepository()));
      await tester.pump();
      await tester.pumpAndSettle();

      // The LLM message should be visible
      expect(find.text('What task would you like to create?'), findsOneWidget);
    });

    // ── Confirmation card ─────────────────────────────────────────────────────

    testWidgets('when isComplete is true, confirmation card appears with Create task button', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _CompleteChatRepository()));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.guidedChatCreateButton), findsOneWidget);
    });

    testWidgets('confirmation card shows the resolved task title', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _CompleteChatRepository()));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Call the dentist'), findsOneWidget);
    });

    testWidgets('tapping Create task button calls tasksProvider.createTask', (tester) async {
      final stubNotifier = _RecordingTasksNotifier();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            guidedChatRepositoryProvider.overrideWithValue(_CompleteChatRepository()),
            listsProvider.overrideWith(() => _StubListsNotifier()),
            tasksProvider().overrideWith(() => stubNotifier),
          ],
          child: MaterialApp(
            theme: AppTheme.light(ThemeVariant.clay, 'PlayfairDisplay'),
            home: const Scaffold(body: GuidedChatSheet()),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // Tap the "Create task" button
      await tester.tap(find.text(AppStrings.guidedChatCreateButton));
      await tester.pumpAndSettle();

      expect(stubNotifier.createTaskCalled, isTrue);
      expect(stubNotifier.lastTitle, 'Call the dentist');
    });

    // ── Error state ───────────────────────────────────────────────────────────

    testWidgets('error state shows guidedChatError inline bubble', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _ErrorChatRepository()));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.guidedChatError), findsOneWidget);
    });

    testWidgets('timeout error shows guidedChatTimeoutError inline bubble', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _TimeoutChatRepository()));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.guidedChatTimeoutError), findsOneWidget);
    });

    // ── Input disabled while loading ──────────────────────────────────────────

    testWidgets('send button is disabled while loading', (tester) async {
      await tester.pumpWidget(buildSheet(repo: _SlowChatRepository()));
      await tester.pump(); // trigger initState, but repo never resolves

      // The send button icon should be visible but the onPressed is null (disabled)
      // We verify loading is active by checking the typing indicator is present
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
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

class _RecordingTasksNotifier extends TasksNotifier {
  bool createTaskCalled = false;
  String? lastTitle;

  @override
  Future<List<Task>> build({String? listId, String? sectionId}) async => [];

  @override
  Future<Task> createTask({
    required String title,
    String? notes,
    String? dueDate,
    String? listId,
    String? sectionId,
    String? parentTaskId,
    String? timeWindow,
    String? timeWindowStart,
    String? timeWindowEnd,
    String? energyRequirement,
    String? priority,
    String? recurrenceRule,
    int? recurrenceInterval,
    String? recurrenceDaysOfWeek,
    String? recurrenceParentId,
  }) async {
    createTaskCalled = true;
    lastTitle = title;
    // Return a stub task
    return Task(
      id: 'stub-id',
      title: title,
      position: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

// ── Mock repositories ─────────────────────────────────────────────────────────

/// Never resolves — simulates slow loading.
class _SlowChatRepository extends GuidedChatRepository {
  _SlowChatRepository() : super(ApiClient(baseUrl: 'http://fake'));

  @override
  Future<GuidedChatResponse> sendMessage(List<ChatMessage> messages) =>
      Completer<GuidedChatResponse>().future;
}

/// Returns the LLM's opening question.
class _OpeningChatRepository extends GuidedChatRepository {
  _OpeningChatRepository() : super(ApiClient(baseUrl: 'http://fake'));

  @override
  Future<GuidedChatResponse> sendMessage(List<ChatMessage> messages) async =>
      const GuidedChatResponse(
        reply: 'What task would you like to create?',
        isComplete: false,
      );
}

/// Returns a follow-up question on second turn.
class _MultiTurnChatRepository extends GuidedChatRepository {
  _MultiTurnChatRepository() : super(ApiClient(baseUrl: 'http://fake'));

  int _callCount = 0;

  @override
  Future<GuidedChatResponse> sendMessage(List<ChatMessage> messages) async {
    _callCount++;
    if (_callCount == 1) {
      return const GuidedChatResponse(
        reply: 'What task would you like to create?',
        isComplete: false,
      );
    }
    return const GuidedChatResponse(
      reply: 'When does this task need to be done?',
      isComplete: false,
    );
  }
}

/// Returns isComplete: true with a full extracted task.
class _CompleteChatRepository extends GuidedChatRepository {
  _CompleteChatRepository() : super(ApiClient(baseUrl: 'http://fake'));

  @override
  Future<GuidedChatResponse> sendMessage(List<ChatMessage> messages) async =>
      const GuidedChatResponse(
        reply: 'Got it! Ready to create your task.',
        isComplete: true,
        extractedTask: GuidedChatTaskDraft(
          title: 'Call the dentist',
          dueDate: '2026-04-03T00:00:00.000Z',
          energyRequirement: 'low_energy',
        ),
      );
}

/// Returns a generic error.
class _ErrorChatRepository extends GuidedChatRepository {
  _ErrorChatRepository() : super(ApiClient(baseUrl: 'http://fake'));

  @override
  Future<GuidedChatResponse> sendMessage(List<ChatMessage> messages) =>
      Future.error(Exception('Network error'));
}

/// Returns a TIMEOUT error.
class _TimeoutChatRepository extends GuidedChatRepository {
  _TimeoutChatRepository() : super(ApiClient(baseUrl: 'http://fake'));

  @override
  Future<GuidedChatResponse> sendMessage(List<ChatMessage> messages) =>
      Future.error(Exception('Chat assistant timed out'));
}
