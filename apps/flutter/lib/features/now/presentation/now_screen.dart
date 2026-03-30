import 'package:flutter/material.dart';

import 'widgets/now_card_skeleton.dart';
import 'widgets/now_empty_state.dart';

/// Placeholder screen for the Now tab.
///
/// Shows a skeleton for 800ms then transitions to the empty state.
/// Real task data will be wired in Story 1.8+ (after auth).
class NowScreen extends StatelessWidget {
  const NowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: Future.delayed(const Duration(milliseconds: 800)),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SafeArea(child: NowCardSkeleton());
          }
          return const NowEmptyState();
        },
      ),
    );
  }
}
