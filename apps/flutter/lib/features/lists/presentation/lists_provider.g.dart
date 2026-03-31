// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lists_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier managing all user lists.
///
/// Exposes create, update, archive methods.
/// Returns `AsyncValue<List<TaskList>>`.

@ProviderFor(ListsNotifier)
final listsProvider = ListsNotifierProvider._();

/// Notifier managing all user lists.
///
/// Exposes create, update, archive methods.
/// Returns `AsyncValue<List<TaskList>>`.
final class ListsNotifierProvider
    extends $AsyncNotifierProvider<ListsNotifier, List<TaskList>> {
  /// Notifier managing all user lists.
  ///
  /// Exposes create, update, archive methods.
  /// Returns `AsyncValue<List<TaskList>>`.
  ListsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'listsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$listsNotifierHash();

  @$internal
  @override
  ListsNotifier create() => ListsNotifier();
}

String _$listsNotifierHash() => r'7e0f60eb51da99cf511b225a05b72a67e9021a72';

/// Notifier managing all user lists.
///
/// Exposes create, update, archive methods.
/// Returns `AsyncValue<List<TaskList>>`.

abstract class _$ListsNotifier extends $AsyncNotifier<List<TaskList>> {
  FutureOr<List<TaskList>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<TaskList>>, List<TaskList>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<TaskList>>, List<TaskList>>,
              AsyncValue<List<TaskList>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
