// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notifications_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Triggers push permission request and device token registration.
/// Called once post-auth. Result is AsyncValue<void> — callers ignore the
/// value but can check for errors.

@ProviderFor(registerDeviceToken)
final registerDeviceTokenProvider = RegisterDeviceTokenProvider._();

/// Triggers push permission request and device token registration.
/// Called once post-auth. Result is AsyncValue<void> — callers ignore the
/// value but can check for errors.

final class RegisterDeviceTokenProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Triggers push permission request and device token registration.
  /// Called once post-auth. Result is AsyncValue<void> — callers ignore the
  /// value but can check for errors.
  RegisterDeviceTokenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'registerDeviceTokenProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$registerDeviceTokenHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return registerDeviceToken(ref);
  }
}

String _$registerDeviceTokenHash() =>
    r'b82da756a989c8e4231cc88d939e968f48739abc';
