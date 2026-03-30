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
