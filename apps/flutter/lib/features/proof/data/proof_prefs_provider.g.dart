// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proof_prefs_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Async provider that loads the user's proof retention default from
/// [SharedPreferences].
///
/// Defaults to `true` (keep proof) if no preference has been stored.
/// SharedPreferences key: `'proof_retain_default'`
///
/// keepAlive: prevents repeated SharedPreferences reads on every rebuild.

@ProviderFor(proofRetainDefault)
final proofRetainDefaultProvider = ProofRetainDefaultProvider._();

/// Async provider that loads the user's proof retention default from
/// [SharedPreferences].
///
/// Defaults to `true` (keep proof) if no preference has been stored.
/// SharedPreferences key: `'proof_retain_default'`
///
/// keepAlive: prevents repeated SharedPreferences reads on every rebuild.

final class ProofRetainDefaultProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Async provider that loads the user's proof retention default from
  /// [SharedPreferences].
  ///
  /// Defaults to `true` (keep proof) if no preference has been stored.
  /// SharedPreferences key: `'proof_retain_default'`
  ///
  /// keepAlive: prevents repeated SharedPreferences reads on every rebuild.
  ProofRetainDefaultProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'proofRetainDefaultProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$proofRetainDefaultHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return proofRetainDefault(ref);
  }
}

String _$proofRetainDefaultHash() =>
    r'e0fecbda3169cfdf56d216507959b2232462de32';

/// Notifier for writing the proof retention default to [SharedPreferences].
///
/// Exposes [setRetainDefault] which persists the new value and invalidates
/// [proofRetainDefaultProvider] so the UI rebuilds immediately.
///
/// keepAlive: true — matches the read provider lifetime.

@ProviderFor(ProofRetainSettings)
final proofRetainSettingsProvider = ProofRetainSettingsProvider._();

/// Notifier for writing the proof retention default to [SharedPreferences].
///
/// Exposes [setRetainDefault] which persists the new value and invalidates
/// [proofRetainDefaultProvider] so the UI rebuilds immediately.
///
/// keepAlive: true — matches the read provider lifetime.
final class ProofRetainSettingsProvider
    extends $NotifierProvider<ProofRetainSettings, void> {
  /// Notifier for writing the proof retention default to [SharedPreferences].
  ///
  /// Exposes [setRetainDefault] which persists the new value and invalidates
  /// [proofRetainDefaultProvider] so the UI rebuilds immediately.
  ///
  /// keepAlive: true — matches the read provider lifetime.
  ProofRetainSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'proofRetainSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$proofRetainSettingsHash();

  @$internal
  @override
  ProofRetainSettings create() => ProofRetainSettings();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$proofRetainSettingsHash() =>
    r'bdfba1556332dee451d1e320a688340cf8572fed';

/// Notifier for writing the proof retention default to [SharedPreferences].
///
/// Exposes [setRetainDefault] which persists the new value and invalidates
/// [proofRetainDefaultProvider] so the UI rebuilds immediately.
///
/// keepAlive: true — matches the read provider lifetime.

abstract class _$ProofRetainSettings extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
