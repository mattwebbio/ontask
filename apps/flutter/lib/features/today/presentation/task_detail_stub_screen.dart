import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

/// Stub task detail screen — placeholder for task block tap navigation (AC3, FR79).
///
/// This stub is shown when the user taps a task block in the Today tab
/// timeline view. It displays the task ID until the full task detail
/// UI is implemented in a later story.
///
/// Navigation: pushed from `/today` via `context.push('/tasks/$taskId')`.
/// Back button pops back to the Today tab.
class TaskDetailStubScreen extends StatelessWidget {
  /// The task ID passed via route parameter.
  final String taskId;

  const TaskDetailStubScreen({required this.taskId, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<OnTaskColors>()!;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.pop(),
          child: const Icon(CupertinoIcons.back),
        ),
        middle: const Text('Task Detail'),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.checkmark_circle,
                size: 64,
                color: colors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'Task Detail',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: colors.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Task ID: $taskId',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Full task detail UI coming in a later story.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
