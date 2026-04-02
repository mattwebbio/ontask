// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_handler.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notification tap handler — handles push notification taps (reminder,
/// deadline, stake_warning) and navigates to the relevant task detail.
/// (FR42, FR72, Story 8.2)

@ProviderFor(NotificationHandler)
final notificationHandlerProvider = NotificationHandlerProvider._();

/// Notification tap handler — handles push notification taps (reminder,
/// deadline, stake_warning) and navigates to the relevant task detail.
/// (FR42, FR72, Story 8.2)
final class NotificationHandlerProvider
    extends $NotifierProvider<NotificationHandler, void> {
  /// Notification tap handler — handles push notification taps (reminder,
  /// deadline, stake_warning) and navigates to the relevant task detail.
  /// (FR42, FR72, Story 8.2)
  NotificationHandlerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationHandlerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationHandlerHash();

  @$internal
  @override
  NotificationHandler create() => NotificationHandler();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$notificationHandlerHash() =>
    r'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2';

/// Notification tap handler — handles push notification taps (reminder,
/// deadline, stake_warning) and navigates to the relevant task detail.
/// (FR42, FR72, Story 8.2)

abstract class _$NotificationHandler extends $Notifier<void> {
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
