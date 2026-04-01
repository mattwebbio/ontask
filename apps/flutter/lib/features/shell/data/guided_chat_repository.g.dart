// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guided_chat_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider for [GuidedChatRepository].

@ProviderFor(guidedChatRepository)
final guidedChatRepositoryProvider = GuidedChatRepositoryProvider._();

/// Riverpod provider for [GuidedChatRepository].

final class GuidedChatRepositoryProvider
    extends
        $FunctionalProvider<
          GuidedChatRepository,
          GuidedChatRepository,
          GuidedChatRepository
        >
    with $Provider<GuidedChatRepository> {
  /// Riverpod provider for [GuidedChatRepository].
  GuidedChatRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'guidedChatRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$guidedChatRepositoryHash();

  @$internal
  @override
  $ProviderElement<GuidedChatRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GuidedChatRepository create(Ref ref) {
    return guidedChatRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GuidedChatRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GuidedChatRepository>(value),
    );
  }
}

String _$guidedChatRepositoryHash() =>
    r'427348360ff55e547d3db9546b59f686644cf3aa';
