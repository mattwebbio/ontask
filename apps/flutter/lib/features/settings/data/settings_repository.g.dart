// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider for [SettingsRepository].
///
/// Every consumer must use this — never construct [SettingsRepository] directly.

@ProviderFor(settingsRepository)
final settingsRepositoryProvider = SettingsRepositoryProvider._();

/// Riverpod provider for [SettingsRepository].
///
/// Every consumer must use this — never construct [SettingsRepository] directly.

final class SettingsRepositoryProvider
    extends
        $FunctionalProvider<
          SettingsRepository,
          SettingsRepository,
          SettingsRepository
        >
    with $Provider<SettingsRepository> {
  /// Riverpod provider for [SettingsRepository].
  ///
  /// Every consumer must use this — never construct [SettingsRepository] directly.
  SettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SettingsRepository create(Ref ref) {
    return settingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsRepository>(value),
    );
  }
}

String _$settingsRepositoryHash() =>
    r'62e09fbc2596d71d5160f8035a92c039af434c54';

/// Riverpod provider that loads the active sessions list.
///
/// Exposes `AsyncValue<List<SessionModel>>` — use `.when(...)` in widgets.

@ProviderFor(activeSessions)
final activeSessionsProvider = ActiveSessionsProvider._();

/// Riverpod provider that loads the active sessions list.
///
/// Exposes `AsyncValue<List<SessionModel>>` — use `.when(...)` in widgets.

final class ActiveSessionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SessionModel>>,
          List<SessionModel>,
          FutureOr<List<SessionModel>>
        >
    with
        $FutureModifier<List<SessionModel>>,
        $FutureProvider<List<SessionModel>> {
  /// Riverpod provider that loads the active sessions list.
  ///
  /// Exposes `AsyncValue<List<SessionModel>>` — use `.when(...)` in widgets.
  ActiveSessionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeSessionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeSessionsHash();

  @$internal
  @override
  $FutureProviderElement<List<SessionModel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SessionModel>> create(Ref ref) {
    return activeSessions(ref);
  }
}

String _$activeSessionsHash() => r'cf5745d8b4f748d7dcf0d615686005c6344ef018';
