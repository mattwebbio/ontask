import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/example.dart';
import '../domain/i_example_repository.dart';
import '../data/example_repository.dart';

part 'example_provider.g.dart';

/// Async provider that returns all examples.
///
/// ARCH RULE (ARCH-17): All async providers return [AsyncValue<T>] — never
/// raw [Future<T>]. Riverpod wraps the returned [Future] into [AsyncValue]
/// automatically; widgets access it via `ref.watch(examplesProvider)`.
@riverpod
Future<List<Example>> examples(Ref ref) {
  final repository = ref.watch(exampleRepositoryProvider);
  return repository.fetchAll();
}
