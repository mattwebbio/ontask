// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tasks_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Notifier managing task list state per list/section.
///
/// Exposes create, update, archive, reorder methods.
/// Returns `AsyncValue<List<Task>>`.

@ProviderFor(TasksNotifier)
final tasksProvider = TasksNotifierFamily._();

/// Notifier managing task list state per list/section.
///
/// Exposes create, update, archive, reorder methods.
/// Returns `AsyncValue<List<Task>>`.
final class TasksNotifierProvider
    extends $AsyncNotifierProvider<TasksNotifier, List<Task>> {
  /// Notifier managing task list state per list/section.
  ///
  /// Exposes create, update, archive, reorder methods.
  /// Returns `AsyncValue<List<Task>>`.
  TasksNotifierProvider._({
    required TasksNotifierFamily super.from,
    required ({String? listId, String? sectionId}) super.argument,
  }) : super(
         retry: null,
         name: r'tasksProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tasksNotifierHash();

  @override
  String toString() {
    return r'tasksProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  TasksNotifier create() => TasksNotifier();

  @override
  bool operator ==(Object other) {
    return other is TasksNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tasksNotifierHash() => r'86fd5eeb37a67aa8c538f2fe7a8a57631b2e5df9';

/// Notifier managing task list state per list/section.
///
/// Exposes create, update, archive, reorder methods.
/// Returns `AsyncValue<List<Task>>`.

final class TasksNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          TasksNotifier,
          AsyncValue<List<Task>>,
          List<Task>,
          FutureOr<List<Task>>,
          ({String? listId, String? sectionId})
        > {
  TasksNotifierFamily._()
    : super(
        retry: null,
        name: r'tasksProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Notifier managing task list state per list/section.
  ///
  /// Exposes create, update, archive, reorder methods.
  /// Returns `AsyncValue<List<Task>>`.

  TasksNotifierProvider call({String? listId, String? sectionId}) =>
      TasksNotifierProvider._(
        argument: (listId: listId, sectionId: sectionId),
        from: this,
      );

  @override
  String toString() => r'tasksProvider';
}

/// Notifier managing task list state per list/section.
///
/// Exposes create, update, archive, reorder methods.
/// Returns `AsyncValue<List<Task>>`.

abstract class _$TasksNotifier extends $AsyncNotifier<List<Task>> {
  late final _$args = ref.$arg as ({String? listId, String? sectionId});
  String? get listId => _$args.listId;
  String? get sectionId => _$args.sectionId;

  FutureOr<List<Task>> build({String? listId, String? sectionId});
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Task>>, List<Task>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Task>>, List<Task>>,
              AsyncValue<List<Task>>,
              Object?,
              Object?
            >;
    element.handleCreate(
      ref,
      () => build(listId: _$args.listId, sectionId: _$args.sectionId),
    );
  }
}
