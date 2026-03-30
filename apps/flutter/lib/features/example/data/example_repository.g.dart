// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'example_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider for [IExampleRepository].
///
/// Returns the concrete [ExampleRepository]; tests override with a mock.

@ProviderFor(exampleRepository)
final exampleRepositoryProvider = ExampleRepositoryProvider._();

/// Riverpod provider for [IExampleRepository].
///
/// Returns the concrete [ExampleRepository]; tests override with a mock.

final class ExampleRepositoryProvider
    extends
        $FunctionalProvider<
          IExampleRepository,
          IExampleRepository,
          IExampleRepository
        >
    with $Provider<IExampleRepository> {
  /// Riverpod provider for [IExampleRepository].
  ///
  /// Returns the concrete [ExampleRepository]; tests override with a mock.
  ExampleRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exampleRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exampleRepositoryHash();

  @$internal
  @override
  $ProviderElement<IExampleRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IExampleRepository create(Ref ref) {
    return exampleRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IExampleRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IExampleRepository>(value),
    );
  }
}

String _$exampleRepositoryHash() => r'b396600b7f11aa3866fb613cc2f5c49ef91d5ca0';
