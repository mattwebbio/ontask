// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'templates_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider for [TemplatesRepository].

@ProviderFor(templatesRepository)
final templatesRepositoryProvider = TemplatesRepositoryProvider._();

/// Riverpod provider for [TemplatesRepository].

final class TemplatesRepositoryProvider
    extends
        $FunctionalProvider<
          TemplatesRepository,
          TemplatesRepository,
          TemplatesRepository
        >
    with $Provider<TemplatesRepository> {
  /// Riverpod provider for [TemplatesRepository].
  TemplatesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'templatesRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$templatesRepositoryHash();

  @$internal
  @override
  $ProviderElement<TemplatesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TemplatesRepository create(Ref ref) {
    return templatesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TemplatesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TemplatesRepository>(value),
    );
  }
}

String _$templatesRepositoryHash() =>
    r'c4b2da11749b05605bbb0239e289d392fdd72830';
