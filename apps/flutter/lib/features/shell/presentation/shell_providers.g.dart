// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shell_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Signal notifier: incrementing the counter tells [AppShell] to open the
/// Add tab sheet. Any widget (e.g. [TodayEmptyState] via [TodayScreen]) can
/// call `ref.read(openAddSheetRequestProvider.notifier).increment()` to
/// request the sheet without holding a direct callback reference.
///
/// [AppShell] listens to this provider and responds to counter increments by
/// calling [showModalBottomSheet] for [AddTabSheet].

@ProviderFor(OpenAddSheetRequest)
final openAddSheetRequestProvider = OpenAddSheetRequestProvider._();

/// Signal notifier: incrementing the counter tells [AppShell] to open the
/// Add tab sheet. Any widget (e.g. [TodayEmptyState] via [TodayScreen]) can
/// call `ref.read(openAddSheetRequestProvider.notifier).increment()` to
/// request the sheet without holding a direct callback reference.
///
/// [AppShell] listens to this provider and responds to counter increments by
/// calling [showModalBottomSheet] for [AddTabSheet].
final class OpenAddSheetRequestProvider
    extends $NotifierProvider<OpenAddSheetRequest, int> {
  /// Signal notifier: incrementing the counter tells [AppShell] to open the
  /// Add tab sheet. Any widget (e.g. [TodayEmptyState] via [TodayScreen]) can
  /// call `ref.read(openAddSheetRequestProvider.notifier).increment()` to
  /// request the sheet without holding a direct callback reference.
  ///
  /// [AppShell] listens to this provider and responds to counter increments by
  /// calling [showModalBottomSheet] for [AddTabSheet].
  OpenAddSheetRequestProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'openAddSheetRequestProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$openAddSheetRequestHash();

  @$internal
  @override
  OpenAddSheetRequest create() => OpenAddSheetRequest();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$openAddSheetRequestHash() =>
    r'aa35384892c1021e17288ce6bef192c9da129472';

/// Signal notifier: incrementing the counter tells [AppShell] to open the
/// Add tab sheet. Any widget (e.g. [TodayEmptyState] via [TodayScreen]) can
/// call `ref.read(openAddSheetRequestProvider.notifier).increment()` to
/// request the sheet without holding a direct callback reference.
///
/// [AppShell] listens to this provider and responds to counter increments by
/// calling [showModalBottomSheet] for [AddTabSheet].

abstract class _$OpenAddSheetRequest extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
