// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_manager.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the offline operation queue and conflict resolution.
///
/// On reconnect, processes [PendingOperations] from the local drift DB via FIFO.
/// Applies conflict resolution per the architecture policy (FR94):
///   - Content properties → last-write-wins with [clientTimestamp].
///   - Structural properties → server always wins.
///
/// After sync, if any conflicts were detected, returns a non-empty list of
/// [ConflictEvent] objects so the caller can surface a plain-language message
/// (NFR-UX2) — e.g. [AppStrings.syncConflictResolvedMessage].
///
/// ARCH NOTE: [connectivity_plus] integration (network reconnect triggering) is
/// wired externally — this class exposes [processQueue] for the caller to invoke
/// when connectivity is restored. This keeps the sync manager testable without
/// platform channel dependencies.

@ProviderFor(SyncManager)
final syncManagerProvider = SyncManagerProvider._();

/// Manages the offline operation queue and conflict resolution.
///
/// On reconnect, processes [PendingOperations] from the local drift DB via FIFO.
/// Applies conflict resolution per the architecture policy (FR94):
///   - Content properties → last-write-wins with [clientTimestamp].
///   - Structural properties → server always wins.
///
/// After sync, if any conflicts were detected, returns a non-empty list of
/// [ConflictEvent] objects so the caller can surface a plain-language message
/// (NFR-UX2) — e.g. [AppStrings.syncConflictResolvedMessage].
///
/// ARCH NOTE: [connectivity_plus] integration (network reconnect triggering) is
/// wired externally — this class exposes [processQueue] for the caller to invoke
/// when connectivity is restored. This keeps the sync manager testable without
/// platform channel dependencies.
final class SyncManagerProvider extends $NotifierProvider<SyncManager, void> {
  /// Manages the offline operation queue and conflict resolution.
  ///
  /// On reconnect, processes [PendingOperations] from the local drift DB via FIFO.
  /// Applies conflict resolution per the architecture policy (FR94):
  ///   - Content properties → last-write-wins with [clientTimestamp].
  ///   - Structural properties → server always wins.
  ///
  /// After sync, if any conflicts were detected, returns a non-empty list of
  /// [ConflictEvent] objects so the caller can surface a plain-language message
  /// (NFR-UX2) — e.g. [AppStrings.syncConflictResolvedMessage].
  ///
  /// ARCH NOTE: [connectivity_plus] integration (network reconnect triggering) is
  /// wired externally — this class exposes [processQueue] for the caller to invoke
  /// when connectivity is restored. This keeps the sync manager testable without
  /// platform channel dependencies.
  SyncManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncManagerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncManagerHash();

  @$internal
  @override
  SyncManager create() => SyncManager();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$syncManagerHash() => r'2929ebfb3adc35758eb4852a79cd0f4af9515007';

/// Manages the offline operation queue and conflict resolution.
///
/// On reconnect, processes [PendingOperations] from the local drift DB via FIFO.
/// Applies conflict resolution per the architecture policy (FR94):
///   - Content properties → last-write-wins with [clientTimestamp].
///   - Structural properties → server always wins.
///
/// After sync, if any conflicts were detected, returns a non-empty list of
/// [ConflictEvent] objects so the caller can surface a plain-language message
/// (NFR-UX2) — e.g. [AppStrings.syncConflictResolvedMessage].
///
/// ARCH NOTE: [connectivity_plus] integration (network reconnect triggering) is
/// wired externally — this class exposes [processQueue] for the caller to invoke
/// when connectivity is restored. This keeps the sync manager testable without
/// platform channel dependencies.

abstract class _$SyncManager extends $Notifier<void> {
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
