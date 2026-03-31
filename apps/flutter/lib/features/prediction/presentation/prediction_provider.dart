import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/prediction_repository.dart';
import '../domain/completion_prediction.dart';

part 'prediction_provider.g.dart';

/// Provider for task predicted completion.
///
/// Auto-invalidates every 30 seconds to simulate real-time updates (AC3).
/// In production, the scheduling engine pushes invalidations directly.
/// The timer approach is forward-compatible with that design.
///
/// Does NOT use keepAlive — per-entity providers dispose when the widget unmounts.
@riverpod
Future<CompletionPrediction> taskPrediction(Ref ref, String taskId) async {
  // Re-fetch every 30 seconds to simulate real-time badge updates (stub strategy)
  final timer = Timer(const Duration(seconds: 30), () => ref.invalidateSelf());
  ref.onDispose(timer.cancel); // CRITICAL: cancel on dispose to prevent leaks
  return ref.watch(predictionRepositoryProvider).fetchTaskPrediction(taskId);
}

/// Provider for list predicted completion.
///
/// Auto-invalidates every 30 seconds to simulate real-time updates (AC3).
@riverpod
Future<CompletionPrediction> listPrediction(Ref ref, String listId) async {
  final timer = Timer(const Duration(seconds: 30), () => ref.invalidateSelf());
  ref.onDispose(timer.cancel);
  return ref.watch(predictionRepositoryProvider).fetchListPrediction(listId);
}

/// Provider for section predicted completion.
///
/// Auto-invalidates every 30 seconds to simulate real-time updates (AC3).
@riverpod
Future<CompletionPrediction> sectionPrediction(Ref ref, String sectionId) async {
  final timer = Timer(const Duration(seconds: 30), () => ref.invalidateSelf());
  ref.onDispose(timer.cancel);
  return ref.watch(predictionRepositoryProvider).fetchSectionPrediction(sectionId);
}
