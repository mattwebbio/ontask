import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, showModalBottomSheet;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../proof/data/proof_repository.dart';
import '../../scheduling/presentation/widgets/nudge_input_sheet.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/database.dart';
import 'now_provider.dart';
import 'timer_provider.dart';
import 'widgets/now_card_skeleton.dart';
import 'widgets/now_empty_state.dart';
import 'widgets/now_task_card.dart';

/// Hero screen for the Now tab — shows ONE task with maximum breathing room.
///
/// States:
/// - **Loading**: [NowCardSkeleton] with shimmer; 800ms hard cap (AC 6)
/// - **Loaded with task**: [NowTaskCard] with proof mode context
/// - **Loaded without task (rest state)**: [NowEmptyState]
///
/// --- Analytics stubs (Story 1.12, NFR-B1) ---
/// When task completion is wired up in a future story, emit the PostHog event:
///   // TODO(impl): analyticsService.track('task_completed', properties: {'task_id': taskId})
///
/// When stake confirmation is wired up in a future story, emit:
///   // TODO(impl): analyticsService.track('stake_set', properties: {'stake_amount_cents': amount, 'task_id': taskId})
class NowScreen extends ConsumerStatefulWidget {
  const NowScreen({super.key});

  @override
  ConsumerState<NowScreen> createState() => _NowScreenState();
}

class _NowScreenState extends ConsumerState<NowScreen> {
  late final Future<void> _skeletonDelay;
  bool _timerInitialised = false;
  ProofRepository? _proofRepository;

  @override
  void initState() {
    super.initState();
    _skeletonDelay = Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context) {
    final nowState = ref.watch(nowProvider);
    final timerState = ref.watch(taskTimerProvider);

    // Auto-initialise timer from task's startedAt when task loads
    if (!_timerInitialised && nowState.hasValue && nowState.value != null) {
      final task = nowState.value!;
      if (task.startedAt != null && !timerState.isRunning) {
        // Schedule after build to avoid modifying provider during build
        Future.microtask(() {
          ref.read(taskTimerProvider.notifier).startTimer(
                task.id,
                existingStartedAt: task.startedAt,
                existingElapsed: task.elapsedSeconds ?? 0,
              );
        });
      }
      _timerInitialised = true;
    }

    return SafeArea(
      child: FutureBuilder<void>(
        future: _skeletonDelay,
        builder: (context, snapshot) {
          // Show skeleton until both the hard cap AND data are ready
          final delayDone =
              snapshot.connectionState == ConnectionState.done;

          if (!delayDone || nowState.isLoading) {
            return const NowCardSkeleton();
          }

          // Error state — fall back to empty state
          if (nowState.hasError) {
            return const NowEmptyState();
          }

          final task = nowState.value;
          if (task == null) {
            return const NowEmptyState();
          }

          // Compute current elapsed from timer provider
          final elapsed = timerState.isRunning
              ? ref.read(taskTimerProvider.notifier).currentElapsed
              : timerState.elapsedSeconds;

          // Lazily create ProofRepository once and cache it.
          // Uses try/catch to tolerate test environments where apiClientProvider
          // may not be fully configured (e.g., auth override as value provider).
          _proofRepository ??= _tryCreateProofRepository();

          return NowTaskCard(
            task: task,
            timerRunning: timerState.isRunning,
            timerElapsedSeconds: elapsed,
            proofRepository: _proofRepository,
            onComplete: () {
              ref.read(nowProvider.notifier).completeTask(task.id);
              // Navigate to the Chapter Break Screen after task completion.
              // Use context.push so the user can navigate back via system
              // back gesture if needed.
              context.push('/chapter-break', extra: <String, dynamic>{
                'taskTitle': task.title,
                // TODO(epic-6): pass stake amount when commitment flow is wired
                'stakeAmount': null,
              });
            },
            onStart: () {
              ref.read(taskTimerProvider.notifier).startTimer(task.id);
              ref.read(nowProvider.notifier).startTask(task.id);
            },
            onPause: () {
              ref.read(taskTimerProvider.notifier).pauseTimer(task.id);
            },
            onStop: () {
              ref.read(taskTimerProvider.notifier).stopTimer(task.id);
            },
            onNudge: () => _openNudgeSheet(task.id, task.title),
          );
        },
      ),
    );
  }

  /// Attempts to create a [ProofRepository] using the Riverpod-provided
  /// [ApiClient]. Returns null if the provider is unavailable (e.g., in tests
  /// where [authStateProvider] is overridden as a value provider).
  ProofRepository? _tryCreateProofRepository() {
    try {
      return ProofRepository(
        ref.read(apiClientProvider),
        ref.read(appDatabaseProvider),
      );
    } catch (e) {
      return null;
    }
  }

  void _openNudgeSheet(String taskId, String taskTitle) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => NudgeInputSheet(
        taskId: taskId,
        taskTitle: taskTitle,
        onApplied: () => ref.read(nowProvider.notifier).refresh(),
      ),
    );
  }
}
