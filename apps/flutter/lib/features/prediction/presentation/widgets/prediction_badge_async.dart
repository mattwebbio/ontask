import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import 'package:flutter/material.dart' show Theme;
import '../prediction_provider.dart';
import 'prediction_badge.dart';

/// Async wrapper widget that loads and renders the prediction badge for a task.
///
/// - Loading state: shimmer placeholder (60×20 pill)
/// - Error state: [SizedBox.shrink()] — badge is non-critical, never crash
/// - Data state: [PredictionBadge] with loaded [CompletionPrediction]
class TaskPredictionBadge extends ConsumerWidget {
  const TaskPredictionBadge({required this.taskId, super.key});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(taskPredictionProvider(taskId));
    return state.when(
      loading: () => _shimmer(context),
      error: (_, _) => const SizedBox.shrink(),
      data: (prediction) => PredictionBadge(prediction: prediction),
    );
  }
}

/// Async wrapper widget that loads and renders the prediction badge for a list.
class ListPredictionBadge extends ConsumerWidget {
  const ListPredictionBadge({required this.listId, super.key});

  final String listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(listPredictionProvider(listId));
    return state.when(
      loading: () => _shimmer(context),
      error: (_, _) => const SizedBox.shrink(),
      data: (prediction) => PredictionBadge(prediction: prediction),
    );
  }
}

/// Async wrapper widget that loads and renders the prediction badge for a section.
class SectionPredictionBadge extends ConsumerWidget {
  const SectionPredictionBadge({required this.sectionId, super.key});

  final String sectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sectionPredictionProvider(sectionId));
    return state.when(
      loading: () => _shimmer(context),
      error: (_, _) => const SizedBox.shrink(),
      data: (prediction) => PredictionBadge(prediction: prediction),
    );
  }
}

/// Shared shimmer placeholder for loading states.
Widget _shimmer(BuildContext context) {
  final colors = Theme.of(context).extension<OnTaskColors>()!;
  return Container(
    width: 60,
    height: 20,
    decoration: BoxDecoration(
      color: colors.surfaceSecondary,
      borderRadius: BorderRadius.circular(12),
    ),
  );
}
