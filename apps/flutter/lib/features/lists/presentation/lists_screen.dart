import 'package:flutter/material.dart';

import 'widgets/lists_empty_state.dart';

/// Placeholder screen for the Lists tab.
///
/// Shows the empty state immediately (no skeleton — lists are not loaded
/// asynchronously in this story). Real list data will be wired in Story 1.8+.
class ListsScreen extends StatelessWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(child: ListsEmptyState()),
    );
  }
}
