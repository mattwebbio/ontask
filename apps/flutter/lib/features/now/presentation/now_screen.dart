import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'now_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _skeletonDelay = Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context) {
    final nowState = ref.watch(nowProvider);

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

          return NowTaskCard(
            task: task,
            onComplete: () {
              ref.read(nowProvider.notifier).completeTask(task.id);
            },
          );
        },
      ),
    );
  }
}
