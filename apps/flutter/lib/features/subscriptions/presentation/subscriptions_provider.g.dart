// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscriptions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

String _$subscriptionStatusHash() => r'impl(9.1):placeholder';

/// Fetches the current user's subscription status.
/// Async provider — callers use AsyncValue pattern.
/// Invalidate when subscription state might have changed (post-payment callback in Story 9.3).

@ProviderFor(subscriptionStatus)
final subscriptionStatusProvider = SubscriptionStatusProvider._();

/// Fetches the current user's subscription status.
/// Async provider — callers use AsyncValue pattern.
/// Invalidate when subscription state might have changed (post-payment callback in Story 9.3).

final class SubscriptionStatusProvider
    extends $FunctionalProvider<AsyncValue<SubscriptionStatus>, SubscriptionStatus, FutureOr<SubscriptionStatus>>
    with $FutureModifier<SubscriptionStatus>, $FutureProvider<SubscriptionStatus> {
  /// Fetches the current user's subscription status.
  /// Async provider — callers use AsyncValue pattern.
  /// Invalidate when subscription state might have changed (post-payment callback in Story 9.3).
  SubscriptionStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subscriptionStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subscriptionStatusHash();

  @$internal
  @override
  $FutureProviderElement<SubscriptionStatus> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<SubscriptionStatus> create(Ref ref) {
    return subscriptionStatus(ref);
  }
}
