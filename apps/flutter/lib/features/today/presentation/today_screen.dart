import 'package:flutter/material.dart';

import 'widgets/today_empty_state.dart';
import 'widgets/today_skeleton.dart';

/// Placeholder screen for the Today tab.
///
/// Shows skeleton for 800ms (hard cap) then transitions to the empty state.
/// Real task data will be wired in Story 1.8+ (after auth).
class TodayScreen extends StatelessWidget {
  final VoidCallback? onAddTapped;

  const TodayScreen({this.onAddTapped, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: Future.delayed(const Duration(milliseconds: 800)),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SafeArea(child: TodaySkeleton());
          }
          return SafeArea(
            child: TodayEmptyState(
              onAddTapped: onAddTapped ?? () {},
            ),
          );
        },
      ),
    );
  }
}
