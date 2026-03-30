// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'two_factor_setup_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider that loads 2FA setup data from the API.
///
/// Called once on screen load — provides [TwoFactorSetupData] containing
/// the TOTP secret, QR code URI, and backup codes. Cached for the lifetime
/// of the screen; re-fetched on invalidation.

@ProviderFor(twoFactorSetup)
final twoFactorSetupProvider = TwoFactorSetupProvider._();

/// Riverpod provider that loads 2FA setup data from the API.
///
/// Called once on screen load — provides [TwoFactorSetupData] containing
/// the TOTP secret, QR code URI, and backup codes. Cached for the lifetime
/// of the screen; re-fetched on invalidation.

final class TwoFactorSetupProvider
    extends
        $FunctionalProvider<
          AsyncValue<TwoFactorSetupData>,
          TwoFactorSetupData,
          FutureOr<TwoFactorSetupData>
        >
    with
        $FutureModifier<TwoFactorSetupData>,
        $FutureProvider<TwoFactorSetupData> {
  /// Riverpod provider that loads 2FA setup data from the API.
  ///
  /// Called once on screen load — provides [TwoFactorSetupData] containing
  /// the TOTP secret, QR code URI, and backup codes. Cached for the lifetime
  /// of the screen; re-fetched on invalidation.
  TwoFactorSetupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'twoFactorSetupProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$twoFactorSetupHash();

  @$internal
  @override
  $FutureProviderElement<TwoFactorSetupData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TwoFactorSetupData> create(Ref ref) {
    return twoFactorSetup(ref);
  }
}

String _$twoFactorSetupHash() => r'b672d6c4b969f879eea7cba92fd099dbfe5bc8dc';
