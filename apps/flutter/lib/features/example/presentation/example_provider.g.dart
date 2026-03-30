// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'example_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Async provider that returns all examples.
///
/// ARCH RULE (ARCH-17): All async providers return [AsyncValue<T>] — never
/// raw [Future<T>]. Riverpod wraps the returned [Future] into [AsyncValue]
/// automatically; widgets access it via `ref.watch(examplesProvider)`.

@ProviderFor(examples)
final examplesProvider = ExamplesProvider._();

/// Async provider that returns all examples.
///
/// ARCH RULE (ARCH-17): All async providers return [AsyncValue<T>] — never
/// raw [Future<T>]. Riverpod wraps the returned [Future] into [AsyncValue]
/// automatically; widgets access it via `ref.watch(examplesProvider)`.

final class ExamplesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Example>>,
          List<Example>,
          FutureOr<List<Example>>
        >
    with $FutureModifier<List<Example>>, $FutureProvider<List<Example>> {
  /// Async provider that returns all examples.
  ///
  /// ARCH RULE (ARCH-17): All async providers return [AsyncValue<T>] — never
  /// raw [Future<T>]. Riverpod wraps the returned [Future] into [AsyncValue]
  /// automatically; widgets access it via `ref.watch(examplesProvider)`.
  ExamplesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'examplesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$examplesHash();

  @$internal
  @override
  $FutureProviderElement<List<Example>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Example>> create(Ref ref) {
    return examples(ref);
  }
}

String _$examplesHash() => r'bbb95172ad85c806ebfbcecc85ed6fbea8ff9306';
