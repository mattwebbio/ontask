import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'example_provider.dart';
import 'widgets/example_card.dart';

/// Example feature screen.
///
/// Demonstrates the pattern all feature screens follow:
///   - Extend [ConsumerWidget] (or [ConsumerStatefulWidget] for stateful).
///   - Watch an [AsyncValue] provider — handle loading/error/data states.
class ExampleScreen extends ConsumerWidget {
  const ExampleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch returns AsyncValue<List<Example>> — ARCH-17 compliant.
    final asyncExamples = ref.watch(examplesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Examples')),
      body: asyncExamples.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (examples) => ListView.builder(
          itemCount: examples.length,
          itemBuilder: (context, index) =>
              ExampleCard(example: examples[index]),
        ),
      ),
    );
  }
}
