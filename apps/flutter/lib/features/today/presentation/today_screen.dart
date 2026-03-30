import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/shell/presentation/shell_providers.dart';
import 'widgets/today_empty_state.dart';
import 'widgets/today_skeleton.dart';

/// Placeholder screen for the Today tab.
///
/// Shows skeleton for 800ms (hard cap, AC 6) then transitions to the empty
/// state. The 800ms [Future] is stored in [initState] so ancestor rebuilds
/// (orientation change, theme switch, tab re-entry) cannot restart the timer.
///
/// The [TodayEmptyState] Add CTA is wired to [openAddSheetRequestProvider],
/// which [AppShell] watches to open [AddTabSheet]. The optional [onAddTapped]
/// parameter is retained for widget tests that need direct callback injection.
///
/// Real task data will be wired in Story 1.8+ (after auth).
class TodayScreen extends ConsumerStatefulWidget {
  final VoidCallback? onAddTapped;

  const TodayScreen({this.onAddTapped, super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  late final Future<void> _skeletonDelay;

  @override
  void initState() {
    super.initState();
    _skeletonDelay = Future.delayed(const Duration(milliseconds: 800));
  }

  void _handleAddTapped() {
    if (widget.onAddTapped != null) {
      widget.onAddTapped!();
    } else {
      ref.read(openAddSheetRequestProvider.notifier).increment();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _skeletonDelay,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SafeArea(child: TodaySkeleton());
          }
          return SafeArea(
            child: TodayEmptyState(
              onAddTapped: _handleAddTapped,
            ),
          );
        },
      ),
    );
  }
}
