// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prediction_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider for [PredictionRepository].

@ProviderFor(predictionRepository)
final predictionRepositoryProvider = PredictionRepositoryProvider._();

/// Riverpod provider for [PredictionRepository].

final class PredictionRepositoryProvider
    extends
        $FunctionalProvider<
          PredictionRepository,
          PredictionRepository,
          PredictionRepository
        >
    with $Provider<PredictionRepository> {
  /// Riverpod provider for [PredictionRepository].
  PredictionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'predictionRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$predictionRepositoryHash();

  @$internal
  @override
  $ProviderElement<PredictionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PredictionRepository create(Ref ref) {
    return predictionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PredictionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PredictionRepository>(value),
    );
  }
}

String _$predictionRepositoryHash() =>
    r'b93645a6feaa2f11a7eb987cf7b596c9abce4564';
