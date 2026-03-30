// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feature_flag_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider that wraps PostHog feature flag evaluation (AC #3).
///
/// Returns [false] when:
///   - PostHog is not configured ([AppConfig.posthogApiKey] is empty)
///   - PostHog has not yet evaluated the flag
///   - The flag evaluates to false
///
/// Usage by other features:
///   ```dart
///   final flagAsync = ref.watch(featureFlagProvider('my-flag-key'));
///   final enabled = flagAsync.value ?? false;
///   ```

@ProviderFor(featureFlag)
final featureFlagProvider = FeatureFlagFamily._();

/// Riverpod provider that wraps PostHog feature flag evaluation (AC #3).
///
/// Returns [false] when:
///   - PostHog is not configured ([AppConfig.posthogApiKey] is empty)
///   - PostHog has not yet evaluated the flag
///   - The flag evaluates to false
///
/// Usage by other features:
///   ```dart
///   final flagAsync = ref.watch(featureFlagProvider('my-flag-key'));
///   final enabled = flagAsync.value ?? false;
///   ```

final class FeatureFlagProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Riverpod provider that wraps PostHog feature flag evaluation (AC #3).
  ///
  /// Returns [false] when:
  ///   - PostHog is not configured ([AppConfig.posthogApiKey] is empty)
  ///   - PostHog has not yet evaluated the flag
  ///   - The flag evaluates to false
  ///
  /// Usage by other features:
  ///   ```dart
  ///   final flagAsync = ref.watch(featureFlagProvider('my-flag-key'));
  ///   final enabled = flagAsync.value ?? false;
  ///   ```
  FeatureFlagProvider._({
    required FeatureFlagFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'featureFlagProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$featureFlagHash();

  @override
  String toString() {
    return r'featureFlagProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as String;
    return featureFlag(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FeatureFlagProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$featureFlagHash() => r'8e5454a9e37ce2cafb7ceef4837e236a9f3178b3';

/// Riverpod provider that wraps PostHog feature flag evaluation (AC #3).
///
/// Returns [false] when:
///   - PostHog is not configured ([AppConfig.posthogApiKey] is empty)
///   - PostHog has not yet evaluated the flag
///   - The flag evaluates to false
///
/// Usage by other features:
///   ```dart
///   final flagAsync = ref.watch(featureFlagProvider('my-flag-key'));
///   final enabled = flagAsync.value ?? false;
///   ```

final class FeatureFlagFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, String> {
  FeatureFlagFamily._()
    : super(
        retry: null,
        name: r'featureFlagProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Riverpod provider that wraps PostHog feature flag evaluation (AC #3).
  ///
  /// Returns [false] when:
  ///   - PostHog is not configured ([AppConfig.posthogApiKey] is empty)
  ///   - PostHog has not yet evaluated the flag
  ///   - The flag evaluates to false
  ///
  /// Usage by other features:
  ///   ```dart
  ///   final flagAsync = ref.watch(featureFlagProvider('my-flag-key'));
  ///   final enabled = flagAsync.value ?? false;
  ///   ```

  FeatureFlagProvider call(String flagKey) =>
      FeatureFlagProvider._(argument: flagKey, from: this);

  @override
  String toString() => r'featureFlagProvider';
}
