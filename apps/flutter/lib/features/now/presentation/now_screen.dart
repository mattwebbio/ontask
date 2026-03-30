import 'package:flutter/material.dart';

import 'widgets/now_card_skeleton.dart';
import 'widgets/now_empty_state.dart';

/// Placeholder screen for the Now tab.
///
/// Shows a skeleton for 800ms (hard cap, AC 6) then transitions to the empty
/// state. The 800ms [Future] is stored in [initState] so ancestor rebuilds
/// (orientation change, theme switch, tab re-entry) cannot restart the timer.
///
/// Real task data will be wired in Story 1.8+ (after auth).
///
/// --- Analytics stubs (Story 1.12, NFR-B1) ---
/// When task completion is wired up in a future story, emit the PostHog event:
///   // TODO(impl): analyticsService.track('task_completed', properties: {'task_id': taskId})
///
/// When stake confirmation is wired up in a future story, emit:
///   // TODO(impl): analyticsService.track('stake_set', properties: {'stake_amount_cents': amount, 'task_id': taskId})
class NowScreen extends StatefulWidget {
  const NowScreen({super.key});

  @override
  State<NowScreen> createState() => _NowScreenState();
}

class _NowScreenState extends State<NowScreen> {
  late final Future<void> _skeletonDelay;

  @override
  void initState() {
    super.initState();
    _skeletonDelay = Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _skeletonDelay,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SafeArea(child: NowCardSkeleton());
          }
          return const SafeArea(child: NowEmptyState());
        },
      ),
    );
  }
}
