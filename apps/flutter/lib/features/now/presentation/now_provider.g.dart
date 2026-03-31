// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'now_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// AsyncNotifier that manages the current task for the Now tab.
///
/// Loads the current task via [NowRepository.getCurrentTask] and supports
/// completing the task and refreshing.
///
/// Returns `AsyncValue<NowTask?>` — null means rest state (no current task).

@ProviderFor(Now)
final nowProvider = NowProvider._();

/// AsyncNotifier that manages the current task for the Now tab.
///
/// Loads the current task via [NowRepository.getCurrentTask] and supports
/// completing the task and refreshing.
///
/// Returns `AsyncValue<NowTask?>` — null means rest state (no current task).
final class NowProvider extends $AsyncNotifierProvider<Now, NowTask?> {
  /// AsyncNotifier that manages the current task for the Now tab.
  ///
  /// Loads the current task via [NowRepository.getCurrentTask] and supports
  /// completing the task and refreshing.
  ///
  /// Returns `AsyncValue<NowTask?>` — null means rest state (no current task).
  NowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nowProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nowHash();

  @$internal
  @override
  Now create() => Now();
}

String _$nowHash() => r'ff328140611e5941a5bf60a52f1d5119036cf15f';

/// AsyncNotifier that manages the current task for the Now tab.
///
/// Loads the current task via [NowRepository.getCurrentTask] and supports
/// completing the task and refreshing.
///
/// Returns `AsyncValue<NowTask?>` — null means rest state (no current task).

abstract class _$Now extends $AsyncNotifier<NowTask?> {
  FutureOr<NowTask?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<NowTask?>, NowTask?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<NowTask?>, NowTask?>,
              AsyncValue<NowTask?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
