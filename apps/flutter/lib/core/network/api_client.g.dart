// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider for [ApiClient].
///
/// Every repository must receive this via `ref.watch(apiClientProvider)`.
/// Do NOT call `ApiClient(...)` directly — that breaks test overrides.

@ProviderFor(apiClient)
final apiClientProvider = ApiClientProvider._();

/// Riverpod provider for [ApiClient].
///
/// Every repository must receive this via `ref.watch(apiClientProvider)`.
/// Do NOT call `ApiClient(...)` directly — that breaks test overrides.

final class ApiClientProvider
    extends $FunctionalProvider<ApiClient, ApiClient, ApiClient>
    with $Provider<ApiClient> {
  /// Riverpod provider for [ApiClient].
  ///
  /// Every repository must receive this via `ref.watch(apiClientProvider)`.
  /// Do NOT call `ApiClient(...)` directly — that breaks test overrides.
  ApiClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiClientHash();

  @$internal
  @override
  $ProviderElement<ApiClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ApiClient create(Ref ref) {
    return apiClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApiClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApiClient>(value),
    );
  }
}

String _$apiClientHash() => r'6af97be93d52d3e46056c5ebf1f6719288811945';
