// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nlp_task_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider for [NlpTaskRepository].

@ProviderFor(nlpTaskRepository)
final nlpTaskRepositoryProvider = NlpTaskRepositoryProvider._();

/// Riverpod provider for [NlpTaskRepository].

final class NlpTaskRepositoryProvider
    extends
        $FunctionalProvider<
          NlpTaskRepository,
          NlpTaskRepository,
          NlpTaskRepository
        >
    with $Provider<NlpTaskRepository> {
  /// Riverpod provider for [NlpTaskRepository].
  NlpTaskRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nlpTaskRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nlpTaskRepositoryHash();

  @$internal
  @override
  $ProviderElement<NlpTaskRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NlpTaskRepository create(Ref ref) {
    return nlpTaskRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NlpTaskRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NlpTaskRepository>(value),
    );
  }
}

String _$nlpTaskRepositoryHash() => r'fe94b4a463643284fd2658afec856e1a56a92352';
